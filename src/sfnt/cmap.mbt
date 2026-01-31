///|
/// Parsed cmap table.
pub struct CmapTable {
  data : BytesView
  subtable_offset : Int
  format : Int
  variation_offset : Int?
} derive(Show, ToJson)

///|
/// Parse a cmap table from its blob.
pub fn CmapTable::parse(blob : @blob.Blob) -> Result[CmapTable, SfntError] {
  let data = blob.as_view()
  let num_tables = read_u16_int(data, 2)
  match num_tables {
    Err(err) => Err(err)
    Ok(count) => {
      let mut chosen_offset : Int? = None
      let mut chosen_format : Int? = None
      let mut variation_offset : Int? = None
      let mut offset = 4
      for _ in 0..<count {
        let record_offset = offset
        let sub_offset = read_u32_int(data, record_offset + 4)
        match sub_offset {
          Err(err) => return Err(err)
          Ok(subtable_offset) => {
            let format = read_u16_int(data, subtable_offset)
            match format {
              Err(err) => return Err(err)
              Ok(format) => {
                if format == 14 {
                  if variation_offset is None {
                    variation_offset = Some(subtable_offset)
                  }
                } else if format == 12 {
                  if chosen_format is None || chosen_format == Some(4) {
                    chosen_offset = Some(subtable_offset)
                    chosen_format = Some(format)
                  }
                } else if format == 4 && chosen_offset is None {
                  chosen_offset = Some(subtable_offset)
                  chosen_format = Some(format)
                }
              }
            }
          }
        }
        offset = offset + 8
      }
      match (chosen_offset, chosen_format) {
        (Some(subtable_offset), Some(format)) =>
          Ok(CmapTable::{ data, subtable_offset, format, variation_offset })
        _ => Err(InvalidFormat)
      }
    }
  }
}

///|
/// Map a codepoint to a glyph id.
pub fn CmapTable::glyph_for(
  self : CmapTable,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  if self.format == 12 {
    glyph_for_format12(self.data, self.subtable_offset, codepoint)
  } else if self.format == 4 {
    glyph_for_format4(self.data, self.subtable_offset, codepoint)
  } else {
    Err(InvalidFormat)
  }
}

///|
/// Map a codepoint + variation selector to a glyph id, if supported.
pub fn CmapTable::variation_mapping(
  self : CmapTable,
  codepoint : UInt,
  selector : UInt,
) -> Result[(Bool, UInt?), SfntError] {
  match self.variation_offset {
    None => Ok((false, None))
    Some(offset) => variation_mapping_format14(self.data, offset, codepoint, selector)
  }
}

fn variation_mapping_format14(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
  selector : UInt,
) -> Result[(Bool, UInt?), SfntError] {
  let num_records = read_u32_int(data, offset + 6)
  match num_records {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let mut base = offset + 10
      for _ in 0..<count {
        let vs = read_u24(data, base)
        let default_offset = read_u32_int(data, base + 3)
        let non_default_offset = read_u32_int(data, base + 7)
        match (vs, default_offset, non_default_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(vs), Ok(default_offset), Ok(non_default_offset)) => {
            if vs == selector {
              if non_default_offset != 0 {
                let mapping = non_default_variation_mapping(
                  data,
                  offset + non_default_offset,
                  codepoint,
                )
                match mapping {
                  Err(err) => return Err(err)
                  Ok(Some(glyph)) => return Ok((true, Some(glyph)))
                  Ok(None) => ()
                }
              }
              if default_offset != 0 {
                let found = default_variation_mapping(
                  data,
                  offset + default_offset,
                  codepoint,
                )
                match found {
                  Err(err) => return Err(err)
                  Ok(true) => return Ok((true, None))
                  Ok(false) => ()
                }
              }
              return Ok((false, None))
            }
          }
        }
        base = base + 11
      }
      Ok((false, None))
    }
  }
}

fn non_default_variation_mapping(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  let count = read_u32_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let mut base = offset + 4
      for _ in 0..<count {
        let value = read_u24(data, base)
        let glyph_id = read_u16_int(data, base + 3)
        match (value, glyph_id) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(value), Ok(glyph_id)) => {
            if value == codepoint {
              return Ok(Some(glyph_id.reinterpret_as_uint()))
            }
          }
        }
        base = base + 5
      }
      Ok(None)
    }
  }
}

fn default_variation_mapping(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[Bool, SfntError] {
  let count = read_u32_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let mut base = offset + 4
      for _ in 0..<count {
        let start = read_u24(data, base)
        let count_byte = read_u8_int(data, base + 3)
        match (start, count_byte) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(start), Ok(count_byte)) => {
            let add = count_byte.reinterpret_as_uint()
            let end = start + add
            if codepoint >= start && codepoint <= end {
              return Ok(true)
            }
          }
        }
        base = base + 4
      }
      Ok(false)
    }
  }
}

///|
fn glyph_for_format12(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  let groups = read_u32_int(data, offset + 12)
  match groups {
    Err(err) => Err(err)
    Ok(num_groups) => {
      let mut base = offset + 16
      for _ in 0..<num_groups {
        let start = read_u32(data, base)
        let end = read_u32(data, base + 4)
        let start_gid = read_u32(data, base + 8)
        match (start, end, start_gid) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start), Ok(end), Ok(start_gid)) =>
            if codepoint >= start && codepoint <= end {
              return Ok(Some(start_gid + (codepoint - start)))
            }
        }
        base = base + 12
      }
      Ok(None)
    }
  }
}

///|
fn glyph_for_format4(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  if codepoint > 0xffffU {
    return Ok(None)
  }
  let seg_count_x2 = read_u16_int(data, offset + 6)
  match seg_count_x2 {
    Err(err) => Err(err)
    Ok(seg_count_x2) => {
      let seg_count = seg_count_x2 / 2
      let end_code_offset = offset + 14
      let start_code_offset = end_code_offset + seg_count * 2 + 2
      let id_delta_offset = start_code_offset + seg_count * 2
      let id_range_offset_offset = id_delta_offset + seg_count * 2
      for i in 0..<seg_count {
        let end_code = read_u16_int(data, end_code_offset + i * 2)
        let start_code = read_u16_int(data, start_code_offset + i * 2)
        match (end_code, start_code) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(end_code), Ok(start_code)) => {
            let cp = u16_to_int(codepoint)
            if cp >= start_code && cp <= end_code {
              let id_delta = read_i16(data, id_delta_offset + i * 2)
              let id_range_offset = read_u16_int(
                data,
                id_range_offset_offset + i * 2,
              )
              match (id_delta, id_range_offset) {
                (Err(err), _) => return Err(err)
                (_, Err(err)) => return Err(err)
                (Ok(id_delta), Ok(id_range_offset)) => {
                  if id_range_offset == 0 {
                    let gid = (cp + id_delta) & 0xffff
                    return Ok(Some(gid.reinterpret_as_uint()))
                  }
                  let glyph_index_offset = id_range_offset_offset +
                    i * 2 +
                    id_range_offset +
                    (cp - start_code) * 2
                  let glyph_id = read_u16_int(data, glyph_index_offset)
                  match glyph_id {
                    Err(err) => return Err(err)
                    Ok(glyph_id) => {
                      if glyph_id == 0 {
                        return Ok(Some(0U))
                      }
                      let gid = (glyph_id + id_delta) & 0xffff
                      return Ok(Some(gid.reinterpret_as_uint()))
                    }
                  }
                }
              }
            }
          }
        }
      }
      Ok(None)
    }
  }
}
