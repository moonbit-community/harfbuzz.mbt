// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Parsed cmap table.
pub struct CmapTable {
  data : BytesView
  subtable_offset : Int
  format : Int
  variation_offset : Int?
} derive(Debug, ToJson)

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
      let mut chosen_rank = 0
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
              Ok(format) =>
                if format == 14 {
                  if variation_offset is None {
                    variation_offset = Some(subtable_offset)
                  }
                } else {
                  let rank = cmap_format_rank(format)
                  if rank > chosen_rank {
                    chosen_rank = rank
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
fn cmap_format_rank(format : Int) -> Int {
  if format == 12 {
    5
  } else if format == 10 {
    4
  } else if format == 4 {
    3
  } else if format == 6 {
    2
  } else if format == 0 {
    1
  } else {
    0
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
  } else if self.format == 10 {
    glyph_for_format10(self.data, self.subtable_offset, codepoint)
  } else if self.format == 4 {
    glyph_for_format4(self.data, self.subtable_offset, codepoint)
  } else if self.format == 6 {
    glyph_for_format6(self.data, self.subtable_offset, codepoint)
  } else if self.format == 0 {
    glyph_for_format0(self.data, self.subtable_offset, codepoint)
  } else {
    Err(InvalidFormat)
  }
}

///|
/// Collect nominal glyph mappings from the cmap table.
pub fn CmapTable::collect_nominal_mapping(
  self : CmapTable,
) -> Result[@common.CodepointMap, SfntError] {
  let map = @common.CodepointMap::new()
  if self.format == 12 {
    match collect_format12(self.data, self.subtable_offset, map) {
      Err(err) => Err(err)
      Ok(_) => Ok(map)
    }
  } else if self.format == 10 {
    match collect_format10(self.data, self.subtable_offset, map) {
      Err(err) => Err(err)
      Ok(_) => Ok(map)
    }
  } else if self.format == 4 {
    match collect_format4(self.data, self.subtable_offset, map) {
      Err(err) => Err(err)
      Ok(_) => Ok(map)
    }
  } else if self.format == 6 {
    match collect_format6(self.data, self.subtable_offset, map) {
      Err(err) => Err(err)
      Ok(_) => Ok(map)
    }
  } else if self.format == 0 {
    match collect_format0(self.data, self.subtable_offset, map) {
      Err(err) => Err(err)
      Ok(_) => Ok(map)
    }
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
    Some(offset) =>
      variation_mapping_format14(self.data, offset, codepoint, selector)
  }
}

///|
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
          (Ok(vs), Ok(default_offset), Ok(non_default_offset)) =>
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
        base = base + 11
      }
      Ok((false, None))
    }
  }
}

///|
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
          (Ok(value), Ok(glyph_id)) =>
            if value == codepoint {
              return Ok(Some(glyph_id.reinterpret_as_uint()))
            }
        }
        base = base + 5
      }
      Ok(None)
    }
  }
}

///|
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
fn glyph_for_format0(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  if codepoint > 0xffU {
    return Ok(None)
  }
  let base = offset + 6
  if base < 0 || base + 256 > data.length() {
    return Err(UnexpectedEof)
  }
  let idx = codepoint.reinterpret_as_int()
  match read_u8_int(data, base + idx) {
    Err(err) => Err(err)
    Ok(glyph_id) => Ok(Some(glyph_id.reinterpret_as_uint()))
  }
}

///|
fn collect_format0(
  data : BytesView,
  offset : Int,
  map : @common.CodepointMap,
) -> Result[Unit, SfntError] {
  let base = offset + 6
  if base < 0 || base + 256 > data.length() {
    return Err(UnexpectedEof)
  }
  for i in 0..<256 {
    let gid = match read_u8_int(data, base + i) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if gid != 0 {
      map.set(i.reinterpret_as_uint(), gid.reinterpret_as_uint())
    }
  }
  Ok(())
}

///|
fn glyph_for_format6(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  if codepoint > 0xffffU {
    return Ok(None)
  }
  let first_code = read_u16_int(data, offset + 6)
  let entry_count = read_u16_int(data, offset + 8)
  match (first_code, entry_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(first_code), Ok(entry_count)) => {
      if entry_count < 0 {
        return Err(InvalidFormat)
      }
      let cp = u16_to_int(codepoint)
      if cp < first_code || cp >= first_code + entry_count {
        return Ok(None)
      }
      let index = cp - first_code
      let base = offset + 10
      let value = read_u16_int(data, base + index * 2)
      match value {
        Err(err) => Err(err)
        Ok(glyph_id) => Ok(Some(glyph_id.reinterpret_as_uint()))
      }
    }
  }
}

///|
fn collect_format6(
  data : BytesView,
  offset : Int,
  map : @common.CodepointMap,
) -> Result[Unit, SfntError] {
  let first_code = read_u16_int(data, offset + 6)
  let entry_count = read_u16_int(data, offset + 8)
  match (first_code, entry_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(first_code), Ok(entry_count)) => {
      if entry_count < 0 {
        return Err(InvalidFormat)
      }
      let base = offset + 10
      for i in 0..<entry_count {
        let value = read_u16_int(data, base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(glyph_id) =>
            if glyph_id != 0 {
              let cp = (first_code + i).reinterpret_as_uint()
              map.set(cp, glyph_id.reinterpret_as_uint())
            }
        }
      }
      Ok(())
    }
  }
}

///|
fn glyph_for_format10(
  data : BytesView,
  offset : Int,
  codepoint : UInt,
) -> Result[UInt?, SfntError] {
  let start_code = read_u32_int(data, offset + 12)
  let entry_count = read_u32_int(data, offset + 16)
  match (start_code, entry_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(start_code), Ok(entry_count)) => {
      if entry_count < 0 {
        return Err(InvalidFormat)
      }
      let start = start_code.reinterpret_as_uint()
      let count = entry_count.reinterpret_as_uint()
      let end = start + count
      if codepoint < start || codepoint >= end {
        return Ok(None)
      }
      let index = (codepoint - start).reinterpret_as_int()
      let base = offset + 20
      let value = read_u16_int(data, base + index * 2)
      match value {
        Err(err) => Err(err)
        Ok(glyph_id) => Ok(Some(glyph_id.reinterpret_as_uint()))
      }
    }
  }
}

///|
fn collect_format10(
  data : BytesView,
  offset : Int,
  map : @common.CodepointMap,
) -> Result[Unit, SfntError] {
  let start_code = read_u32_int(data, offset + 12)
  let entry_count = read_u32_int(data, offset + 16)
  match (start_code, entry_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(start_code), Ok(entry_count)) => {
      if entry_count < 0 {
        return Err(InvalidFormat)
      }
      let start = start_code.reinterpret_as_uint()
      let base = offset + 20
      for i in 0..<entry_count {
        let value = read_u16_int(data, base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(glyph_id) =>
            if glyph_id != 0 {
              let cp = start + i.reinterpret_as_uint()
              map.set(cp, glyph_id.reinterpret_as_uint())
            }
        }
      }
      Ok(())
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
fn collect_format12(
  data : BytesView,
  offset : Int,
  map : @common.CodepointMap,
) -> Result[Unit, SfntError] {
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
          (Ok(start), Ok(end), Ok(start_gid)) => {
            let mut cp = start
            while cp <= end {
              let gid = start_gid + (cp - start)
              if gid != 0U {
                map.set(cp, gid)
              }
              cp = cp + 1U
            }
          }
        }
        base = base + 12
      }
      Ok(())
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

///|
fn collect_format4(
  data : BytesView,
  offset : Int,
  map : @common.CodepointMap,
) -> Result[Unit, SfntError] {
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
            let id_delta = read_i16(data, id_delta_offset + i * 2)
            let id_range_offset = read_u16_int(
              data,
              id_range_offset_offset + i * 2,
            )
            match (id_delta, id_range_offset) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(id_delta), Ok(id_range_offset)) => {
                let mut cp = start_code
                while cp <= end_code {
                  let gid = if id_range_offset == 0 {
                    (cp + id_delta) & 0xffff
                  } else {
                    let glyph_index_offset = id_range_offset_offset +
                      i * 2 +
                      id_range_offset +
                      (cp - start_code) * 2
                    match read_u16_int(data, glyph_index_offset) {
                      Err(err) => return Err(err)
                      Ok(glyph_id) =>
                        if glyph_id == 0 {
                          0
                        } else {
                          (glyph_id + id_delta) & 0xffff
                        }
                    }
                  }
                  if gid != 0 {
                    map.set(cp.reinterpret_as_uint(), gid.reinterpret_as_uint())
                  }
                  cp = cp + 1
                }
              }
            }
          }
        }
      }
      Ok(())
    }
  }
}
