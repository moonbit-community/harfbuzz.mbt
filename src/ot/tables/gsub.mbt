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
pub fn GsubTable::apply_with_lookups(
  self : GsubTable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  lookup_offsets : ArrayView[Int],
) -> Result[(Array[UInt], Array[Int], Bool), OtLayoutError] {
  if clusters.length() != glyphs.length() {
    return Err(InvalidFormat)
  }
  let data = self.layout.data
  let mut current_glyphs = glyphs
  let mut current_clusters = clusters
  let mut changed = false
  for lookup_offset in lookup_offsets {
    let parsed = parse_lookup(data, lookup_offset)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, subtable_offsets)) => {
        if lookup_type == 1 {
          let did_change = match apply_single_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if did_change {
            changed = true
          }
        } else if lookup_type == 4 {
          let result = match apply_ligature_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            current_clusters,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let (next_glyphs, next_clusters, did_change) = result
          current_glyphs = next_glyphs
          current_clusters = next_clusters
          if did_change {
            changed = true
          }
        } else {
          continue
        }
      }
    }
  }
  Ok((current_glyphs, current_clusters, changed))
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
fn apply_single_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_single_subtable(data, offset, glyphs)
    match result {
      Err(err) => return Err(err)
      Ok(value) => if value { changed = true }
    }
  }
  Ok(changed)
}

///|
fn apply_ligature_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  clusters : Array[Int],
) -> Result[(Array[UInt], Array[Int], Bool), OtLayoutError] {
  let new_glyphs : Array[UInt] = []
  let new_clusters : Array[Int] = []
  let mut changed = false
  let mut i = 0
  let len = glyphs.length()
  while i < len {
    let match_result = find_ligature_match(data, offsets, glyphs, i)
    match match_result {
      Err(err) => return Err(err)
      Ok(None) => {
        new_glyphs.push(glyphs[i])
        new_clusters.push(clusters[i])
        i = i + 1
      }
      Ok(Some((lig_glyph, comp_count))) => {
        if comp_count < 2 {
          return Err(InvalidFormat)
        }
        new_glyphs.push(lig_glyph)
        new_clusters.push(clusters[i])
        if comp_count > 1 || lig_glyph != glyphs[i] {
          changed = true
        }
        i = i + comp_count
      }
    }
  }
  Ok((new_glyphs, new_clusters, changed))
}

///|
fn find_ligature_match(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  index : Int,
) -> Result[(UInt, Int)?, OtLayoutError] {
  for offset in offsets {
    let result = ligature_match_subtable(data, offset, glyphs, index)
    match result {
      Err(err) => return Err(err)
      Ok(Some(value)) => return Ok(Some(value))
      Ok(None) => ()
    }
  }
  Ok(None)
}

///|
fn ligature_match_subtable(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
) -> Result[(UInt, Int)?, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Ok(None)
  }
  let first = glyphs[index]
  if first > 0xffffU {
    return Ok(None)
  }
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  let coverage_offset = read_u16_int(data, offset + 2)
  let lig_set_count = read_u16_int(data, offset + 4)
  match (format, coverage_offset, lig_set_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(coverage_offset), Ok(lig_set_count)) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let coverage = coverage_index(data, coverage_base, first)
      match coverage {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(coverage_index)) => {
          if coverage_index < 0 || coverage_index >= lig_set_count {
            return Err(InvalidFormat)
          }
          let set_offset = read_u16_int(
            data,
            offset + 6 + coverage_index * 2,
          )
          match set_offset {
            Err(err) => Err(err)
            Ok(set_offset) => {
              if set_offset == 0 {
                return Err(InvalidFormat)
              }
              let set_base = offset + set_offset
              if set_base < 0 || set_base + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let lig_count = read_u16_int(data, set_base)
              match lig_count {
                Err(err) => Err(err)
                Ok(lig_count) => {
                  let list_base = set_base + 2
                  if list_base < 0 || list_base + lig_count * 2 > data.length() {
                    return Err(UnexpectedEof)
                  }
                  for i in 0..<lig_count {
                    let lig_offset = read_u16_int(data, list_base + i * 2)
                    match lig_offset {
                      Err(err) => return Err(err)
                      Ok(lig_offset) => {
                        if lig_offset == 0 {
                          return Err(InvalidFormat)
                        }
                        let lig_base = set_base + lig_offset
                        if lig_base < 0 || lig_base + 4 > data.length() {
                          return Err(UnexpectedEof)
                        }
                        let lig_glyph = read_u16_int(data, lig_base)
                        let comp_count = read_u16_int(data, lig_base + 2)
                        match (lig_glyph, comp_count) {
                          (Err(err), _) => return Err(err)
                          (_, Err(err)) => return Err(err)
                          (Ok(lig_glyph), Ok(comp_count)) => {
                            if comp_count < 2 {
                              return Err(InvalidFormat)
                            }
                            if index + comp_count - 1 >= glyphs.length() {
                              continue
                            }
                            let comp_base = lig_base + 4
                            let comp_len = (comp_count - 1) * 2
                            if comp_base < 0 || comp_base + comp_len > data.length() {
                              return Err(UnexpectedEof)
                            }
                            let mut matches = true
                            for j in 0..<(comp_count - 1) {
                              let component = read_u16_int(data, comp_base + j * 2)
                              match component {
                                Err(err) => return Err(err)
                                Ok(component) => {
                                  let glyph = glyphs[index + 1 + j]
                                  if glyph > 0xffffU {
                                    matches = false
                                  } else if u16_to_int(glyph) != component {
                                    matches = false
                                  }
                                }
                              }
                              if !matches {
                                break
                              }
                            }
                            if matches {
                              return Ok(
                                Some((lig_glyph.reinterpret_as_uint(), comp_count)),
                              )
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
          }
        }
      }
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
