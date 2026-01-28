///|
/// Apply GSUB single substitution lookups to glyph array.
pub fn GsubTable::apply_single(
  self : GsubTable,
  glyphs : Array[UInt],
) -> Result[Bool, OtLayoutError] {
  let layout = self.layout
  self.apply_single_with_lookups(glyphs, layout.lookup_list.offsets[:])
}

///|
pub fn GsubTable::apply_single_with_lookups(
  self : GsubTable,
  glyphs : Array[UInt],
  lookup_offsets : ArrayView[Int],
) -> Result[Bool, OtLayoutError] {
  let data = self.layout.data
  let mut changed = false
  for lookup_offset in lookup_offsets {
    let parsed = parse_lookup(data, lookup_offset)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, subtable_offsets)) => {
        if lookup_type != 1 {
          continue
        }
        for subtable_offset in subtable_offsets {
          let res = apply_single_subtable(data, subtable_offset, glyphs)
          match res {
            Err(err) => return Err(err)
            Ok(did_change) => if did_change { changed = true }
          }
        }
      }
    }
  }
  Ok(changed)
}

///|
fn apply_single_subtable(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
) -> Result[Bool, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => {
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
        let next = if format == 1 {
          single_substitute_format1(data, offset, glyph)
        } else if format == 2 {
          single_substitute_format2(data, offset, glyph)
        } else {
          Err(InvalidFormat)
        }
        match next {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(value)) => {
            if value != glyph {
              glyphs[i] = value
              changed = true
            }
          }
        }
      }
      Ok(changed)
    }
  }
}

///|
fn single_substitute_format1(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[UInt?, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let delta = read_i16(data, offset + 4)
  match (coverage_offset, delta) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(delta)) => {
      let coverage_base = offset + coverage_offset
      let index = coverage_index(data, coverage_base, glyph)
      match index {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(_)) => {
          let base = u16_to_int(glyph)
          let next = (base + delta) & 0xffff
          Ok(Some(next.reinterpret_as_uint()))
        }
      }
    }
  }
}

///|
fn single_substitute_format2(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[UInt?, OtLayoutError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let glyph_count = read_u16_int(data, offset + 4)
  match (coverage_offset, glyph_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(glyph_count)) => {
      let coverage_base = offset + coverage_offset
      let index = coverage_index(data, coverage_base, glyph)
      match index {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(index)) => {
          if index < 0 || index >= glyph_count {
            return Err(InvalidFormat)
          }
          let list_base = offset + 6
          let list_offset = list_base + index * 2
          let substitute = read_u16_int(data, list_offset)
          match substitute {
            Err(err) => Err(err)
            Ok(substitute) => Ok(Some(substitute.reinterpret_as_uint()))
          }
        }
      }
    }
  }
}
