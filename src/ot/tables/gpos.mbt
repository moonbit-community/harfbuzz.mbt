///|
/// Value record for GPOS adjustments.
pub struct ValueRecord {
  x_placement : Int
  y_placement : Int
  x_advance : Int
  y_advance : Int
} derive(Eq, Show, ToJson)

///|
/// Pair adjustment result.
pub struct PairAdjust {
  first : ValueRecord
  second : ValueRecord
} derive(Eq, Show, ToJson)

///|
fn value_record_zero() -> ValueRecord {
  ValueRecord::{ x_placement: 0, y_placement: 0, x_advance: 0, y_advance: 0 }
}

///|
fn add_value_record(a : ValueRecord, b : ValueRecord) -> ValueRecord {
  ValueRecord::{
    x_placement: a.x_placement + b.x_placement,
    y_placement: a.y_placement + b.y_placement,
    x_advance: a.x_advance + b.x_advance,
    y_advance: a.y_advance + b.y_advance,
  }
}

///|
/// Compute GPOS positioning deltas for a glyph sequence.
pub fn GposTable::position_deltas(
  self : GposTable,
  glyphs : ArrayView[UInt],
) -> Result[Array[ValueRecord], OtLayoutError] {
  let layout = self.layout
  self.position_deltas_with_lookups(glyphs, layout.lookup_list.offsets[:])
}

///|
pub fn GposTable::position_deltas_with_lookups(
  self : GposTable,
  glyphs : ArrayView[UInt],
  lookup_offsets : ArrayView[Int],
  gdef? : GdefTable,
) -> Result[Array[ValueRecord], OtLayoutError] {
  let deltas : Array[ValueRecord] = Array::make(
    glyphs.length(),
    value_record_zero(),
  )
  let data = self.layout.data
  let gdef = gdef
  for lookup_offset in lookup_offsets {
    let parsed = parse_lookup(data, lookup_offset, 9)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, lookup_flag, mark_filtering_set, subtable_offsets)) => {
        if lookup_type == 1 {
          for subtable_offset in subtable_offsets {
            let res = apply_single_pos_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 2 {
          for subtable_offset in subtable_offsets {
            let res = apply_pair_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 3 {
          for subtable_offset in subtable_offsets {
            let res = apply_cursive_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 4 {
          for subtable_offset in subtable_offsets {
            let res = apply_mark_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 7 {
          let lookup_list_offsets = self.layout.lookup_list.offsets[:]
          for subtable_offset in subtable_offsets {
            let res = apply_context_pos_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_list_offsets,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 8 {
          let lookup_list_offsets = self.layout.lookup_list.offsets[:]
          for subtable_offset in subtable_offsets {
            let res = apply_chain_pos_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_list_offsets,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 5 {
          for subtable_offset in subtable_offsets {
            let res = apply_mark_to_ligature_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else if lookup_type == 6 {
          for subtable_offset in subtable_offsets {
            let res = apply_mark_to_mark_subtable(
              data,
              subtable_offset,
              glyphs,
              deltas,
              lookup_flag,
              mark_filtering_set,
              gdef,
            )
            match res {
              Err(err) => return Err(err)
              Ok(_) => ()
            }
          }
        } else {
          continue
        }
      }
    }
  }
  Ok(deltas)
}

///|
/// Compute pair adjustment deltas for a glyph sequence.
pub fn GposTable::pair_adjust_deltas(
  self : GposTable,
  glyphs : ArrayView[UInt],
) -> Result[Array[ValueRecord], OtLayoutError] {
  let layout = self.layout
  self.pair_adjust_deltas_with_lookups(glyphs, layout.lookup_list.offsets[:])
}

///|
pub fn GposTable::pair_adjust_deltas_with_lookups(
  self : GposTable,
  glyphs : ArrayView[UInt],
  lookup_offsets : ArrayView[Int],
  gdef? : GdefTable,
) -> Result[Array[ValueRecord], OtLayoutError] {
  let deltas : Array[ValueRecord] = Array::make(
    glyphs.length(),
    value_record_zero(),
  )
  let data = self.layout.data
  let gdef = gdef
  for lookup_offset in lookup_offsets {
    let parsed = parse_lookup(data, lookup_offset, 9)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, lookup_flag, mark_filtering_set, subtable_offsets)) => {
        if lookup_type != 2 {
          continue
        }
        for subtable_offset in subtable_offsets {
          let res = apply_pair_subtable(
            data,
            subtable_offset,
            glyphs,
            deltas,
            lookup_flag,
            mark_filtering_set,
            gdef,
          )
          match res {
            Err(err) => return Err(err)
            Ok(_) => ()
          }
        }
      }
    }
  }
  Ok(deltas)
}

///|
fn apply_pair_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  for i in 0..<(glyphs.length() - 1) {
    let input_indices = collect_forward_indices(
      glyphs,
      i,
      2,
      lookup_flag,
      gdef,
      mark_filtering_set,
    )
    let indices = match input_indices {
      Err(err) => return Err(err)
      Ok(None) => continue
      Ok(Some(indices)) => indices
    }
    let first = glyphs[indices[0]]
    let second = glyphs[indices[1]]
    let adjust = pair_adjust_format1(data, offset, first, second)
    match adjust {
      Err(err) => return Err(err)
      Ok(None) => ()
      Ok(Some(adjust)) => {
        deltas[indices[0]] = add_value_record(deltas[indices[0]], adjust.first)
        deltas[indices[1]] = add_value_record(deltas[indices[1]], adjust.second)
      }
    }
  }
  Ok(())
}

///|
fn apply_pair_format2(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  for i in 0..<(glyphs.length() - 1) {
    let input_indices = collect_forward_indices(
      glyphs,
      i,
      2,
      lookup_flag,
      gdef,
      mark_filtering_set,
    )
    let indices = match input_indices {
      Err(err) => return Err(err)
      Ok(None) => continue
      Ok(Some(indices)) => indices
    }
    let first = glyphs[indices[0]]
    let second = glyphs[indices[1]]
    let adjust = pair_adjust_format2(data, offset, first, second)
    match adjust {
      Err(err) => return Err(err)
      Ok(None) => ()
      Ok(Some(adjust)) => {
        deltas[indices[0]] = add_value_record(deltas[indices[0]], adjust.first)
        deltas[indices[1]] = add_value_record(deltas[indices[1]], adjust.second)
      }
    }
  }
  Ok(())
}

///|
fn apply_pair_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_pair_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 2 {
      apply_pair_format2(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Ok(())
    }
  }
}

///|
fn apply_context_pos_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_context_pos_subtable_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 2 {
      apply_context_pos_subtable_format2(
        data,
        offset,
        glyphs,
        deltas,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 3 {
      apply_context_pos_subtable_format3(
        data,
        offset,
        glyphs,
        deltas,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Err(InvalidFormat)
    }
  }
}

///|
fn apply_context_pos_subtable_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let set_count = read_u16_int(data, offset + 4)
  match (coverage_offset, set_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(set_count)) => {
      if coverage_offset == 0 || set_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let set_base = offset + 6
      if set_base < 0 || set_base + set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
        let ignored = should_ignore_glyph(
          glyph,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        match ignored {
          Err(err) => return Err(err)
          Ok(true) => continue
          Ok(false) => ()
        }
        let index = coverage_index(data, coverage_base, glyph)
        match index {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(index)) => {
            if index < 0 || index >= set_count {
              return Err(InvalidFormat)
            }
            let rule_set_offset = read_u16_int(data, set_base + index * 2)
            match rule_set_offset {
              Err(err) => return Err(err)
              Ok(rule_set_offset) => {
                if rule_set_offset == 0 {
                  return Err(InvalidFormat)
                }
                let rule_set_base = offset + rule_set_offset
                if rule_set_base < 0 || rule_set_base + 2 > data.length() {
                  return Err(UnexpectedEof)
                }
                let rule_count = read_u16_int(data, rule_set_base)
                match rule_count {
                  Err(err) => return Err(err)
                  Ok(rule_count) => {
                    if rule_count <= 0 {
                      return Err(InvalidFormat)
                    }
                    let rule_list_base = rule_set_base + 2
                    if rule_list_base < 0 ||
                        rule_list_base + rule_count * 2 > data.length() {
                      return Err(UnexpectedEof)
                    }
                    for r in 0..<rule_count {
                      let rule_offset = read_u16_int(data, rule_list_base + r * 2)
                      match rule_offset {
                        Err(err) => return Err(err)
                        Ok(rule_offset) => {
                          if rule_offset == 0 {
                            return Err(InvalidFormat)
                          }
                          let rule_base = rule_set_base + rule_offset
                          let applied = match apply_context_pos_rule(
                            data,
                            rule_base,
                            glyphs,
                            deltas,
                            i,
                            lookup_list_offsets,
                            lookup_flag,
                            mark_filtering_set,
                            gdef,
                          ) {
                            Err(err) => return Err(err)
                            Ok(value) => value
                          }
                          if applied {
                            changed = true
                            break
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      Ok(changed)
    }
  }
}

///|
fn apply_context_pos_subtable_format2(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let class_def_offset = read_u16_int(data, offset + 4)
  let class_set_count = read_u16_int(data, offset + 6)
  match (coverage_offset, class_def_offset, class_set_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(class_def_offset), Ok(class_set_count)) => {
      if coverage_offset == 0 || class_def_offset == 0 || class_set_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let class_def_base = offset + class_def_offset
      let class_set_base = offset + 8
      if class_set_base < 0 ||
          class_set_base + class_set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
        let ignored = should_ignore_glyph(
          glyph,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        match ignored {
          Err(err) => return Err(err)
          Ok(true) => continue
          Ok(false) => ()
        }
        let covered = coverage_index(data, coverage_base, glyph)
        match covered {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(_)) => {
            let class_value = class_def_value(data, class_def_base, glyph)
            match class_value {
              Err(err) => return Err(err)
              Ok(class_value) => {
                if class_value < 0 || class_value >= class_set_count {
                  return Err(InvalidFormat)
                }
                let class_set_offset = read_u16_int(
                  data,
                  class_set_base + class_value * 2,
                )
                match class_set_offset {
                  Err(err) => return Err(err)
                  Ok(class_set_offset) => {
                    if class_set_offset == 0 {
                      return Err(InvalidFormat)
                    }
                    let rule_set_base = offset + class_set_offset
                    if rule_set_base < 0 || rule_set_base + 2 > data.length() {
                      return Err(UnexpectedEof)
                    }
                    let rule_count = read_u16_int(data, rule_set_base)
                    match rule_count {
                      Err(err) => return Err(err)
                      Ok(rule_count) => {
                        if rule_count <= 0 {
                          return Err(InvalidFormat)
                        }
                        let rule_list_base = rule_set_base + 2
                        if rule_list_base < 0 ||
                            rule_list_base + rule_count * 2 > data.length() {
                          return Err(UnexpectedEof)
                        }
                        for r in 0..<rule_count {
                          let rule_offset = read_u16_int(
                            data,
                            rule_list_base + r * 2,
                          )
                          match rule_offset {
                            Err(err) => return Err(err)
                            Ok(rule_offset) => {
                              if rule_offset == 0 {
                                return Err(InvalidFormat)
                              }
                              let rule_base = rule_set_base + rule_offset
                              let applied = match apply_context_pos_class_rule(
                                data,
                                rule_base,
                                glyphs,
                                deltas,
                                i,
                                class_def_base,
                                lookup_list_offsets,
                                lookup_flag,
                                mark_filtering_set,
                                gdef,
                              ) {
                                Err(err) => return Err(err)
                                Ok(value) => value
                              }
                              if applied {
                                changed = true
                                break
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      Ok(changed)
    }
  }
}

///|
fn apply_context_pos_subtable_format3(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let glyph_count = read_u16_int(data, offset + 2)
  let pos_count = read_u16_int(data, offset + 4)
  match (glyph_count, pos_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(glyph_count), Ok(pos_count)) => {
      if glyph_count <= 0 || pos_count < 0 {
        return Err(InvalidFormat)
      }
      let coverage_list_base = offset + 6
      if coverage_list_base < 0 ||
          coverage_list_base + glyph_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let record_base = coverage_list_base + glyph_count * 2
      let mut changed = false
      for i in 0..<glyphs.length() {
        let input_indices = collect_forward_indices(
          glyphs,
          i,
          glyph_count,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        let indices = match input_indices {
          Err(err) => return Err(err)
          Ok(None) => continue
          Ok(Some(indices)) => indices
        }
        let mut matched = true
        for j in 0..<glyph_count {
          let cov_offset = read_u16_int(data, coverage_list_base + j * 2)
          match cov_offset {
            Err(err) => return Err(err)
            Ok(cov_offset) => {
              if cov_offset == 0 {
                return Err(InvalidFormat)
              }
              let cov_base = offset + cov_offset
              let covered = coverage_index(data, cov_base, glyphs[indices[j]])
              match covered {
                Err(err) => return Err(err)
                Ok(None) => {
                  matched = false
                  break
                }
                Ok(Some(_)) => ()
              }
            }
          }
        }
        if matched {
          let applied = match apply_pos_lookup_records(
            data,
            record_base,
            pos_count,
            glyph_count,
            glyphs,
            deltas,
            indices[0],
            lookup_list_offsets,
            Some(indices),
            gdef,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if applied {
            changed = true
          }
        }
      }
      Ok(changed)
    }
  }
}

///|
fn apply_context_pos_class_rule(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  class_def_base : Int,
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let glyph_count = read_u16_int(data, offset)
  let pos_count = read_u16_int(data, offset + 2)
  match (glyph_count, pos_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(glyph_count), Ok(pos_count)) => {
      if glyph_count <= 0 || pos_count < 0 {
        return Err(InvalidFormat)
      }
      let input_indices = collect_forward_indices(
        glyphs,
        index,
        glyph_count,
        lookup_flag,
        gdef,
        mark_filtering_set,
      )
      let indices = match input_indices {
        Err(err) => return Err(err)
        Ok(None) => return Ok(false)
        Ok(Some(indices)) => indices
      }
      let class_list_base = offset + 4
      if class_list_base < 0 ||
          class_list_base + (glyph_count - 1) * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<(glyph_count - 1) {
        let expected = read_u16_int(data, class_list_base + i * 2)
        match expected {
          Err(err) => return Err(err)
          Ok(expected) => {
            let actual = class_def_value(
              data,
              class_def_base,
              glyphs[indices[i + 1]],
            )
            match actual {
              Err(err) => return Err(err)
              Ok(actual) => if actual != expected { return Ok(false) }
            }
          }
        }
      }
      let record_base = class_list_base + (glyph_count - 1) * 2
      apply_pos_lookup_records(
        data,
        record_base,
        pos_count,
        glyph_count,
        glyphs,
        deltas,
        index,
        lookup_list_offsets,
        Some(indices),
        gdef,
      )
    }
  }
}

///|
fn apply_pos_lookup_records(
  data : BytesView,
  record_base : Int,
  pos_count : Int,
  glyph_count : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_list_offsets : ArrayView[Int],
  input_indices : Array[Int]?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if pos_count < 0 {
    return Err(InvalidFormat)
  }
  match input_indices {
    None => ()
    Some(indices) => if indices.length() < glyph_count { return Err(InvalidFormat) }
  }
  if record_base < 0 || record_base + pos_count * 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let mut changed = false
  for i in 0..<pos_count {
    let seq_index = read_u16_int(data, record_base + i * 4)
    let lookup_index = read_u16_int(data, record_base + i * 4 + 2)
    match (seq_index, lookup_index) {
      (Err(err), _) => return Err(err)
      (_, Err(err)) => return Err(err)
      (Ok(seq_index), Ok(lookup_index)) => {
        if seq_index < 0 || seq_index >= glyph_count {
          return Err(InvalidFormat)
        }
        if lookup_index < 0 || lookup_index >= lookup_list_offsets.length() {
          return Err(InvalidFormat)
        }
        let target = match input_indices {
          None => index + seq_index
          Some(indices) => indices[seq_index]
        }
        if target < 0 || target >= glyphs.length() {
          return Err(InvalidFormat)
        }
        let lookup_offset = lookup_list_offsets[lookup_index]
        let did_change = match apply_pos_lookup_at(
          data,
          lookup_offset,
          glyphs,
          deltas,
          target,
          gdef,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if did_change {
          changed = true
        }
      }
    }
  }
  Ok(changed)
}

///|
fn apply_context_pos_rule(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let glyph_count = read_u16_int(data, offset)
  let pos_count = read_u16_int(data, offset + 2)
  match (glyph_count, pos_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(glyph_count), Ok(pos_count)) => {
      if glyph_count <= 0 || pos_count < 0 {
        return Err(InvalidFormat)
      }
      let input_indices = collect_forward_indices(
        glyphs,
        index,
        glyph_count,
        lookup_flag,
        gdef,
        mark_filtering_set,
      )
      let indices = match input_indices {
        Err(err) => return Err(err)
        Ok(None) => return Ok(false)
        Ok(Some(indices)) => indices
      }
      let input_base = offset + 4
      if input_base < 0 || input_base + (glyph_count - 1) * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<(glyph_count - 1) {
        let expected = read_u16_int(data, input_base + i * 2)
        match expected {
          Err(err) => return Err(err)
          Ok(expected) => {
            let actual = glyphs[indices[i + 1]]
            if expected != u16_to_int(actual) {
              return Ok(false)
            }
          }
        }
      }
      let record_base = input_base + (glyph_count - 1) * 2
      apply_pos_lookup_records(
        data,
        record_base,
        pos_count,
        glyph_count,
        glyphs,
        deltas,
        index,
        lookup_list_offsets,
        Some(indices),
        gdef,
      )
    }
  }
}

///|
fn apply_chain_pos_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_chain_pos_subtable_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 2 {
      apply_chain_pos_subtable_format2(
        data,
        offset,
        glyphs,
        deltas,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 3 {
      apply_chain_pos_subtable_format3(
        data,
        offset,
        glyphs,
        deltas,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Err(InvalidFormat)
    }
  }
}

///|
fn apply_chain_pos_subtable_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let set_count = read_u16_int(data, offset + 4)
  match (coverage_offset, set_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(set_count)) => {
      if coverage_offset == 0 || set_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let set_base = offset + 6
      if set_base < 0 || set_base + set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
        let ignored = should_ignore_glyph(
          glyph,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        match ignored {
          Err(err) => return Err(err)
          Ok(true) => continue
          Ok(false) => ()
        }
        let index = coverage_index(data, coverage_base, glyph)
        match index {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(index)) => {
            if index < 0 || index >= set_count {
              return Err(InvalidFormat)
            }
            let rule_set_offset = read_u16_int(data, set_base + index * 2)
            match rule_set_offset {
              Err(err) => return Err(err)
              Ok(rule_set_offset) => {
                if rule_set_offset == 0 {
                  return Err(InvalidFormat)
                }
                let rule_set_base = offset + rule_set_offset
                if rule_set_base < 0 || rule_set_base + 2 > data.length() {
                  return Err(UnexpectedEof)
                }
                let rule_count = read_u16_int(data, rule_set_base)
                match rule_count {
                  Err(err) => return Err(err)
                  Ok(rule_count) => {
                    if rule_count <= 0 {
                      return Err(InvalidFormat)
                    }
                    let rule_list_base = rule_set_base + 2
                    if rule_list_base < 0 ||
                        rule_list_base + rule_count * 2 > data.length() {
                      return Err(UnexpectedEof)
                    }
                    for r in 0..<rule_count {
                      let rule_offset = read_u16_int(data, rule_list_base + r * 2)
                      match rule_offset {
                        Err(err) => return Err(err)
                        Ok(rule_offset) => {
                          if rule_offset == 0 {
                            return Err(InvalidFormat)
                          }
                          let rule_base = rule_set_base + rule_offset
                          let applied = match apply_chain_pos_rule(
                            data,
                            rule_base,
                            glyphs,
                            deltas,
                            i,
                            lookup_list_offsets,
                            lookup_flag,
                            mark_filtering_set,
                            gdef,
                          ) {
                            Err(err) => return Err(err)
                            Ok(value) => value
                          }
                          if applied {
                            changed = true
                            break
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      Ok(changed)
    }
  }
}

///|
fn apply_chain_pos_subtable_format2(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 12 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let backtrack_class_def_offset = read_u16_int(data, offset + 4)
  let input_class_def_offset = read_u16_int(data, offset + 6)
  let lookahead_class_def_offset = read_u16_int(data, offset + 8)
  let class_set_count = read_u16_int(data, offset + 10)
  match (
    coverage_offset,
    backtrack_class_def_offset,
    input_class_def_offset,
    lookahead_class_def_offset,
    class_set_count,
  ) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(coverage_offset),
      Ok(backtrack_class_def_offset),
      Ok(input_class_def_offset),
      Ok(lookahead_class_def_offset),
      Ok(class_set_count),
    ) => {
      if coverage_offset == 0 || backtrack_class_def_offset == 0 ||
          input_class_def_offset == 0 || lookahead_class_def_offset == 0 {
        return Err(InvalidFormat)
      }
      if class_set_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let backtrack_class_def_base = offset + backtrack_class_def_offset
      let input_class_def_base = offset + input_class_def_offset
      let lookahead_class_def_base = offset + lookahead_class_def_offset
      let class_set_base = offset + 12
      if class_set_base < 0 ||
          class_set_base + class_set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
        let ignored = should_ignore_glyph(
          glyph,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        match ignored {
          Err(err) => return Err(err)
          Ok(true) => continue
          Ok(false) => ()
        }
        let covered = coverage_index(data, coverage_base, glyph)
        match covered {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(_)) => {
            let class_value = class_def_value(data, input_class_def_base, glyph)
            match class_value {
              Err(err) => return Err(err)
              Ok(class_value) => {
                if class_value < 0 || class_value >= class_set_count {
                  return Err(InvalidFormat)
                }
                let class_set_offset = read_u16_int(
                  data,
                  class_set_base + class_value * 2,
                )
                match class_set_offset {
                  Err(err) => return Err(err)
                  Ok(class_set_offset) => {
                    if class_set_offset == 0 {
                      return Err(InvalidFormat)
                    }
                    let rule_set_base = offset + class_set_offset
                    if rule_set_base < 0 || rule_set_base + 2 > data.length() {
                      return Err(UnexpectedEof)
                    }
                    let rule_count = read_u16_int(data, rule_set_base)
                    match rule_count {
                      Err(err) => return Err(err)
                      Ok(rule_count) => {
                        if rule_count <= 0 {
                          return Err(InvalidFormat)
                        }
                        let rule_list_base = rule_set_base + 2
                        if rule_list_base < 0 ||
                            rule_list_base + rule_count * 2 > data.length() {
                          return Err(UnexpectedEof)
                        }
                        for r in 0..<rule_count {
                          let rule_offset = read_u16_int(
                            data,
                            rule_list_base + r * 2,
                          )
                          match rule_offset {
                            Err(err) => return Err(err)
                            Ok(rule_offset) => {
                              if rule_offset == 0 {
                                return Err(InvalidFormat)
                              }
                              let rule_base = rule_set_base + rule_offset
                              let applied = match apply_chain_pos_class_rule(
                                data,
                                rule_base,
                                glyphs,
                                deltas,
                                i,
                                backtrack_class_def_base,
                                input_class_def_base,
                                lookahead_class_def_base,
                                lookup_list_offsets,
                                lookup_flag,
                                mark_filtering_set,
                                gdef,
                              ) {
                                Err(err) => return Err(err)
                                Ok(value) => value
                              }
                              if applied {
                                changed = true
                                break
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      Ok(changed)
    }
  }
}

///|
fn apply_chain_pos_subtable_format3(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let backtrack_count = read_u16_int(data, offset + 2)
  match backtrack_count {
    Err(err) => Err(err)
    Ok(backtrack_count) => {
      if backtrack_count < 0 {
        return Err(InvalidFormat)
      }
      let mut cursor = offset + 4
      if cursor < 0 || cursor + backtrack_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let backtrack_bases : Array[Int] = []
      for i in 0..<backtrack_count {
        let cov_offset = read_u16_int(data, cursor + i * 2)
        match cov_offset {
          Err(err) => return Err(err)
          Ok(cov_offset) => {
            if cov_offset == 0 {
              return Err(InvalidFormat)
            }
            let base = offset + cov_offset
            if base < 0 || base >= data.length() {
              return Err(UnexpectedEof)
            }
            backtrack_bases.push(base)
          }
        }
      }
      cursor = cursor + backtrack_count * 2
      if cursor < 0 || cursor + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let input_count = read_u16_int(data, cursor)
      match input_count {
        Err(err) => Err(err)
        Ok(input_count) => {
          cursor = cursor + 2
          if input_count <= 0 {
            return Err(InvalidFormat)
          }
          if cursor < 0 || cursor + input_count * 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let input_bases : Array[Int] = []
          for i in 0..<input_count {
            let cov_offset = read_u16_int(data, cursor + i * 2)
            match cov_offset {
              Err(err) => return Err(err)
              Ok(cov_offset) => {
                if cov_offset == 0 {
                  return Err(InvalidFormat)
                }
                let base = offset + cov_offset
                if base < 0 || base >= data.length() {
                  return Err(UnexpectedEof)
                }
                input_bases.push(base)
              }
            }
          }
          cursor = cursor + input_count * 2
          if cursor < 0 || cursor + 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let lookahead_count = read_u16_int(data, cursor)
          match lookahead_count {
            Err(err) => Err(err)
            Ok(lookahead_count) => {
              cursor = cursor + 2
              if lookahead_count < 0 {
                return Err(InvalidFormat)
              }
              if cursor < 0 || cursor + lookahead_count * 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let lookahead_bases : Array[Int] = []
              for i in 0..<lookahead_count {
                let cov_offset = read_u16_int(data, cursor + i * 2)
                match cov_offset {
                  Err(err) => return Err(err)
                  Ok(cov_offset) => {
                    if cov_offset == 0 {
                      return Err(InvalidFormat)
                    }
                    let base = offset + cov_offset
                    if base < 0 || base >= data.length() {
                      return Err(UnexpectedEof)
                    }
                    lookahead_bases.push(base)
                  }
                }
              }
              cursor = cursor + lookahead_count * 2
              if cursor < 0 || cursor + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let pos_count = read_u16_int(data, cursor)
              match pos_count {
                Err(err) => Err(err)
                Ok(pos_count) => {
                  cursor = cursor + 2
                  if pos_count < 0 {
                    return Err(InvalidFormat)
                  }
                  let record_base = cursor
                  let mut changed = false
                  for i in 0..<glyphs.length() {
                    let input_indices = collect_forward_indices(
                      glyphs,
                      i,
                      input_count,
                      lookup_flag,
                      gdef,
                      mark_filtering_set,
                    )
                    let indices = match input_indices {
                      Err(err) => return Err(err)
                      Ok(None) => continue
                      Ok(Some(indices)) => indices
                    }
                    let backtrack_indices = collect_backward_indices(
                      glyphs,
                      indices[0],
                      backtrack_bases.length(),
                      lookup_flag,
                      gdef,
                      mark_filtering_set,
                    )
                    let backtrack = match backtrack_indices {
                      Err(err) => return Err(err)
                      Ok(None) => continue
                      Ok(Some(values)) => values
                    }
                    let lookahead_indices = if lookahead_bases.is_empty() {
                      Ok(Some([]))
                    } else {
                      collect_forward_indices(
                        glyphs,
                        indices[input_count - 1] + 1,
                        lookahead_bases.length(),
                        lookup_flag,
                        gdef,
                        mark_filtering_set,
                      )
                    }
                    let lookahead = match lookahead_indices {
                      Err(err) => return Err(err)
                      Ok(None) => continue
                      Ok(Some(values)) => values
                    }
                    let mut matched = true
                    for j in 0..<backtrack_bases.length() {
                      let covered = coverage_index(
                        data,
                        backtrack_bases[j],
                        glyphs[backtrack[j]],
                      )
                      match covered {
                        Err(err) => return Err(err)
                        Ok(None) => {
                          matched = false
                          break
                        }
                        Ok(Some(_)) => ()
                      }
                    }
                    if matched {
                      for j in 0..<input_bases.length() {
                        let covered = coverage_index(
                          data,
                          input_bases[j],
                          glyphs[indices[j]],
                        )
                        match covered {
                          Err(err) => return Err(err)
                          Ok(None) => {
                            matched = false
                            break
                          }
                          Ok(Some(_)) => ()
                        }
                      }
                    }
                    if matched {
                      for j in 0..<lookahead_bases.length() {
                        let covered = coverage_index(
                          data,
                          lookahead_bases[j],
                          glyphs[lookahead[j]],
                        )
                        match covered {
                          Err(err) => return Err(err)
                          Ok(None) => {
                            matched = false
                            break
                          }
                          Ok(Some(_)) => ()
                        }
                      }
                    }
                    if matched {
                      let applied = match apply_pos_lookup_records(
                        data,
                        record_base,
                        pos_count,
                        input_count,
                        glyphs,
                        deltas,
                        indices[0],
                        lookup_list_offsets,
                        Some(indices),
                        gdef,
                      ) {
                        Err(err) => return Err(err)
                        Ok(value) => value
                      }
                      if applied {
                        changed = true
                      }
                    }
                  }
                  Ok(changed)
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
fn apply_chain_pos_class_rule(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  backtrack_class_def_base : Int,
  input_class_def_base : Int,
  lookahead_class_def_base : Int,
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let backtrack_count = read_u16_int(data, offset)
  match backtrack_count {
    Err(err) => Err(err)
    Ok(backtrack_count) => {
      if backtrack_count < 0 {
        return Err(InvalidFormat)
      }
      let mut cursor = offset + 2
      if cursor < 0 || cursor + backtrack_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let backtrack : Array[Int] = []
      for _ in 0..<backtrack_count {
        let value = read_u16_int(data, cursor)
        cursor = cursor + 2
        match value {
          Err(err) => return Err(err)
          Ok(value) => backtrack.push(value)
        }
      }
      if cursor < 0 || cursor + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let input_count = read_u16_int(data, cursor)
      match input_count {
        Err(err) => Err(err)
        Ok(input_count) => {
          cursor = cursor + 2
          if input_count <= 0 {
            return Err(InvalidFormat)
          }
          if index + input_count > glyphs.length() {
            return Ok(false)
          }
          if cursor < 0 || cursor + (input_count - 1) * 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let input : Array[Int] = []
          for _ in 0..<(input_count - 1) {
            let value = read_u16_int(data, cursor)
            cursor = cursor + 2
            match value {
              Err(err) => return Err(err)
              Ok(value) => input.push(value)
            }
          }
          if cursor < 0 || cursor + 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let lookahead_count = read_u16_int(data, cursor)
          match lookahead_count {
            Err(err) => Err(err)
            Ok(lookahead_count) => {
              cursor = cursor + 2
              if lookahead_count < 0 {
                return Err(InvalidFormat)
              }
              if cursor < 0 || cursor + lookahead_count * 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let lookahead : Array[Int] = []
              for _ in 0..<lookahead_count {
                let value = read_u16_int(data, cursor)
                cursor = cursor + 2
                match value {
                  Err(err) => return Err(err)
                  Ok(value) => lookahead.push(value)
                }
              }
              if cursor < 0 || cursor + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let pos_count = read_u16_int(data, cursor)
              match pos_count {
                Err(err) => Err(err)
                Ok(pos_count) => {
                  cursor = cursor + 2
                  if pos_count < 0 {
                    return Err(InvalidFormat)
                  }
                  let input_indices = collect_forward_indices(
                    glyphs,
                    index,
                    input_count,
                    lookup_flag,
                    gdef,
                    mark_filtering_set,
                  )
                  let indices = match input_indices {
                    Err(err) => return Err(err)
                    Ok(None) => return Ok(false)
                    Ok(Some(indices)) => indices
                  }
                  let backtrack_indices = collect_backward_indices(
                    glyphs,
                    indices[0],
                    backtrack.length(),
                    lookup_flag,
                    gdef,
                    mark_filtering_set,
                  )
                  let backtrack_indices = match backtrack_indices {
                    Err(err) => return Err(err)
                    Ok(None) => return Ok(false)
                    Ok(Some(values)) => values
                  }
                  let lookahead_indices = if lookahead.is_empty() {
                    Ok(Some([]))
                  } else {
                    collect_forward_indices(
                      glyphs,
                      indices[input_count - 1] + 1,
                      lookahead.length(),
                      lookup_flag,
                      gdef,
                      mark_filtering_set,
                    )
                  }
                  let lookahead_indices = match lookahead_indices {
                    Err(err) => return Err(err)
                    Ok(None) => return Ok(false)
                    Ok(Some(values)) => values
                  }
                  for j in 0..<backtrack.length() {
                    let expected = backtrack[j]
                    let actual = class_def_value(
                      data,
                      backtrack_class_def_base,
                      glyphs[backtrack_indices[j]],
                    )
                    match actual {
                      Err(err) => return Err(err)
                      Ok(actual) => if actual != expected { return Ok(false) }
                    }
                  }
                  for j in 0..<input.length() {
                    let expected = input[j]
                    let actual = class_def_value(
                      data,
                      input_class_def_base,
                      glyphs[indices[j + 1]],
                    )
                    match actual {
                      Err(err) => return Err(err)
                      Ok(actual) => if actual != expected { return Ok(false) }
                    }
                  }
                  for j in 0..<lookahead.length() {
                    let expected = lookahead[j]
                    let actual = class_def_value(
                      data,
                      lookahead_class_def_base,
                      glyphs[lookahead_indices[j]],
                    )
                    match actual {
                      Err(err) => return Err(err)
                      Ok(actual) => if actual != expected { return Ok(false) }
                    }
                  }
                  apply_pos_lookup_records(
                    data,
                    cursor,
                    pos_count,
                    input_count,
                    glyphs,
                    deltas,
                    indices[0],
                    lookup_list_offsets,
                    Some(indices),
                    gdef,
                  )
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
fn apply_chain_pos_rule(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_list_offsets : ArrayView[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let backtrack_count = read_u16_int(data, offset)
  match backtrack_count {
    Err(err) => Err(err)
    Ok(backtrack_count) => {
      if backtrack_count < 0 {
        return Err(InvalidFormat)
      }
      let mut cursor = offset + 2
      if cursor < 0 || cursor + backtrack_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let backtrack : Array[Int] = []
      for _ in 0..<backtrack_count {
        let value = read_u16_int(data, cursor)
        cursor = cursor + 2
        match value {
          Err(err) => return Err(err)
          Ok(value) => backtrack.push(value)
        }
      }
      if cursor < 0 || cursor + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let input_count = read_u16_int(data, cursor)
      match input_count {
        Err(err) => Err(err)
        Ok(input_count) => {
          cursor = cursor + 2
          if input_count <= 0 {
            return Err(InvalidFormat)
          }
          if index + input_count > glyphs.length() {
            return Ok(false)
          }
          if cursor < 0 || cursor + (input_count - 1) * 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let input : Array[Int] = []
          for _ in 0..<(input_count - 1) {
            let value = read_u16_int(data, cursor)
            cursor = cursor + 2
            match value {
              Err(err) => return Err(err)
              Ok(value) => input.push(value)
            }
          }
          if cursor < 0 || cursor + 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let lookahead_count = read_u16_int(data, cursor)
          match lookahead_count {
            Err(err) => Err(err)
            Ok(lookahead_count) => {
              cursor = cursor + 2
              if lookahead_count < 0 {
                return Err(InvalidFormat)
              }
              if cursor < 0 || cursor + lookahead_count * 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let lookahead : Array[Int] = []
              for _ in 0..<lookahead_count {
                let value = read_u16_int(data, cursor)
                cursor = cursor + 2
                match value {
                  Err(err) => return Err(err)
                  Ok(value) => lookahead.push(value)
                }
              }
              if cursor < 0 || cursor + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let pos_count = read_u16_int(data, cursor)
              match pos_count {
                Err(err) => Err(err)
                Ok(pos_count) => {
                  cursor = cursor + 2
                  if pos_count < 0 {
                    return Err(InvalidFormat)
                  }
                  if cursor < 0 || cursor + pos_count * 4 > data.length() {
                    return Err(UnexpectedEof)
                  }
                  let input_indices = collect_forward_indices(
                    glyphs,
                    index,
                    input_count,
                    lookup_flag,
                    gdef,
                    mark_filtering_set,
                  )
                  let indices = match input_indices {
                    Err(err) => return Err(err)
                    Ok(None) => return Ok(false)
                    Ok(Some(indices)) => indices
                  }
                  let backtrack_indices = collect_backward_indices(
                    glyphs,
                    indices[0],
                    backtrack.length(),
                    lookup_flag,
                    gdef,
                    mark_filtering_set,
                  )
                  let backtrack_indices = match backtrack_indices {
                    Err(err) => return Err(err)
                    Ok(None) => return Ok(false)
                    Ok(Some(values)) => values
                  }
                  let lookahead_indices = if lookahead.is_empty() {
                    Ok(Some([]))
                  } else {
                    collect_forward_indices(
                      glyphs,
                      indices[input_count - 1] + 1,
                      lookahead.length(),
                      lookup_flag,
                      gdef,
                      mark_filtering_set,
                    )
                  }
                  let lookahead_indices = match lookahead_indices {
                    Err(err) => return Err(err)
                    Ok(None) => return Ok(false)
                    Ok(Some(values)) => values
                  }
                  for j in 0..<backtrack.length() {
                    let expected = backtrack[j]
                    if expected != u16_to_int(glyphs[backtrack_indices[j]]) {
                      return Ok(false)
                    }
                  }
                  for j in 0..<input.length() {
                    if input[j] != u16_to_int(glyphs[indices[j + 1]]) {
                      return Ok(false)
                    }
                  }
                  for j in 0..<lookahead.length() {
                    if lookahead[j] != u16_to_int(glyphs[lookahead_indices[j]]) {
                      return Ok(false)
                    }
                  }
                  apply_pos_lookup_records(
                    data,
                    cursor,
                    pos_count,
                    input_count,
                    glyphs,
                    deltas,
                    indices[0],
                    lookup_list_offsets,
                    Some(indices),
                    gdef,
                  )
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
fn apply_pos_lookup_at(
  data : BytesView,
  lookup_offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let parsed = parse_lookup(data, lookup_offset, 9)
  match parsed {
    Err(err) => Err(err)
    Ok((lookup_type, lookup_flag, mark_filtering_set, subtable_offsets)) => {
      let ignored = should_ignore_glyph(
        glyphs[index],
        lookup_flag,
        gdef,
        mark_filtering_set,
      )
      match ignored {
        Err(err) => return Err(err)
        Ok(true) => return Ok(false)
        Ok(false) => ()
      }
      if lookup_type == 1 {
        apply_single_pos_at(data, subtable_offsets, glyphs, deltas, index)
      } else if lookup_type == 2 {
        apply_pair_pos_at(
          data,
          subtable_offsets,
          glyphs,
          deltas,
          index,
          lookup_flag,
          mark_filtering_set,
          gdef,
        )
      } else if lookup_type == 3 {
        apply_cursive_at(
          data,
          subtable_offsets,
          glyphs,
          deltas,
          index,
          lookup_flag,
          mark_filtering_set,
          gdef,
        )
      } else if lookup_type == 4 {
        apply_mark_to_base_at(
          data,
          subtable_offsets,
          glyphs,
          deltas,
          index,
          lookup_flag,
          mark_filtering_set,
          gdef,
        )
      } else if lookup_type == 5 {
        apply_mark_to_ligature_at(
          data,
          subtable_offsets,
          glyphs,
          deltas,
          index,
          lookup_flag,
          mark_filtering_set,
          gdef,
        )
      } else if lookup_type == 6 {
        apply_mark_to_mark_at(
          data,
          subtable_offsets,
          glyphs,
          deltas,
          index,
          lookup_flag,
          mark_filtering_set,
          gdef,
        )
      } else {
        Ok(false)
      }
    }
  }
}

///|
fn apply_single_pos_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Err(InvalidFormat)
  }
  let glyph = glyphs[index]
  let mut changed = false
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => if format == 1 {
        if offset < 0 || offset + 6 > data.length() {
          return Err(UnexpectedEof)
        }
        let coverage_offset = read_u16_int(data, offset + 2)
        let value_format = read_u16_int(data, offset + 4)
        match (coverage_offset, value_format) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(coverage_offset), Ok(value_format)) => {
            let coverage_base = offset + coverage_offset
            let record_size = value_record_size(value_format)
            let record_base = offset + 6
            if record_base < 0 || record_base + record_size > data.length() {
              return Err(UnexpectedEof)
            }
            let value = read_value_record(data, record_base, value_format)
            match value {
              Err(err) => return Err(err)
              Ok((value, _)) => {
                let covered = coverage_index(data, coverage_base, glyph)
                match covered {
                  Err(err) => return Err(err)
                  Ok(None) => ()
                  Ok(Some(_)) => {
                    deltas[index] = add_value_record(deltas[index], value)
                    changed = true
                  }
                }
              }
            }
          }
        }
      } else if format == 2 {
        if offset < 0 || offset + 8 > data.length() {
          return Err(UnexpectedEof)
        }
        let coverage_offset = read_u16_int(data, offset + 2)
        let value_format = read_u16_int(data, offset + 4)
        let value_count = read_u16_int(data, offset + 6)
        match (coverage_offset, value_format, value_count) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(coverage_offset), Ok(value_format), Ok(value_count)) => {
            if value_count <= 0 {
              return Err(InvalidFormat)
            }
            let coverage_base = offset + coverage_offset
            let record_size = value_record_size(value_format)
            let record_base = offset + 8
            let total_size = value_count * record_size
            if record_base < 0 || record_base + total_size > data.length() {
              return Err(UnexpectedEof)
            }
            let covered = coverage_index(data, coverage_base, glyph)
            match covered {
              Err(err) => return Err(err)
              Ok(None) => ()
              Ok(Some(covered)) => {
                if covered < 0 || covered >= value_count {
                  return Err(InvalidFormat)
                }
                let entry_base = record_base + covered * record_size
                let value = read_value_record(data, entry_base, value_format)
                match value {
                  Err(err) => return Err(err)
                  Ok((value, _)) => {
                    deltas[index] = add_value_record(deltas[index], value)
                    changed = true
                  }
                }
              }
            }
          }
        }
      } else {
        return Err(InvalidFormat)
      }
    }
  }
  Ok(changed)
}

///|
fn apply_pair_pos_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Err(InvalidFormat)
  }
  let input_indices = collect_forward_indices(
    glyphs,
    index,
    2,
    lookup_flag,
    gdef,
    mark_filtering_set,
  )
  let indices = match input_indices {
    Err(err) => return Err(err)
    Ok(None) => return Ok(false)
    Ok(Some(indices)) => indices
  }
  let first = glyphs[indices[0]]
  let second = glyphs[indices[1]]
  let mut changed = false
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => {
        let adjust = if format == 1 {
          pair_adjust_format1(data, offset, first, second)
        } else if format == 2 {
          pair_adjust_format2(data, offset, first, second)
        } else {
          Err(InvalidFormat)
        }
        match adjust {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(adjust)) => {
            deltas[indices[0]] = add_value_record(
              deltas[indices[0]],
              adjust.first,
            )
            deltas[indices[1]] = add_value_record(
              deltas[indices[1]],
              adjust.second,
            )
            changed = true
          }
        }
      }
    }
  }
  Ok(changed)
}

///|
fn apply_cursive_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Ok(false)
  }
  let mut changed = false
  let input_indices = collect_forward_indices(
    glyphs,
    index,
    2,
    lookup_flag,
    gdef,
    mark_filtering_set,
  )
  let indices = match input_indices {
    Err(err) => return Err(err)
    Ok(None) => return Ok(false)
    Ok(Some(indices)) => indices
  }
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => if format == 1 {
        if offset < 0 || offset + 6 > data.length() {
          return Err(UnexpectedEof)
        }
        let coverage_offset = read_u16_int(data, offset + 2)
        let entry_exit_count = read_u16_int(data, offset + 4)
        match (coverage_offset, entry_exit_count) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(coverage_offset), Ok(entry_exit_count)) => {
            if entry_exit_count <= 0 || coverage_offset == 0 {
              return Err(InvalidFormat)
            }
            let coverage_base = offset + coverage_offset
            let record_base = offset + 6
            let record_size = 4
            if record_base < 0 ||
                record_base + entry_exit_count * record_size > data.length() {
              return Err(UnexpectedEof)
            }
            let current = glyphs[indices[0]]
            let next = glyphs[indices[1]]
            let current_index = coverage_index(data, coverage_base, current)
            let next_index = coverage_index(data, coverage_base, next)
            match (current_index, next_index) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(Some(current_index)), Ok(Some(next_index))) => {
                if current_index < 0 || current_index >= entry_exit_count {
                  return Err(InvalidFormat)
                }
                if next_index < 0 || next_index >= entry_exit_count {
                  return Err(InvalidFormat)
                }
                let current_record_base = record_base + current_index * record_size
                let next_record_base = record_base + next_index * record_size
                let current_exit_offset = read_u16_int(
                  data,
                  current_record_base + 2,
                )
                let next_entry_offset = read_u16_int(data, next_record_base)
                match (current_exit_offset, next_entry_offset) {
                  (Err(err), _) => return Err(err)
                  (_, Err(err)) => return Err(err)
                  (Ok(current_exit_offset), Ok(next_entry_offset)) => {
                    if current_exit_offset == 0 || next_entry_offset == 0 {
                      continue
                    }
                    let current_exit_base = offset + current_exit_offset
                    let next_entry_base = offset + next_entry_offset
                    let current_exit = read_anchor(data, current_exit_base)
                    let next_entry = read_anchor(data, next_entry_base)
                    match (current_exit, next_entry) {
                      (Err(err), _) => return Err(err)
                      (_, Err(err)) => return Err(err)
                      (Ok(current_exit), Ok(next_entry)) => {
                        let dx = current_exit.0 - next_entry.0
                        let dy = current_exit.1 - next_entry.1
                        let delta = ValueRecord::{
                          x_placement: dx,
                          y_placement: dy,
                          x_advance: 0,
                          y_advance: 0,
                        }
                        deltas[indices[1]] = add_value_record(
                          deltas[indices[1]],
                          delta,
                        )
                        changed = true
                      }
                    }
                  }
                }
              }
              _ => ()
            }
          }
        }
      } else {
        return Err(InvalidFormat)
      }
    }
  }
  Ok(changed)
}

///|
fn find_prev_coverage_index(
  data : BytesView,
  coverage_base : Int,
  glyphs : ArrayView[UInt],
  start_index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Int?, OtLayoutError] {
  if start_index <= 0 {
    return Ok(None)
  }
  let mut cursor = start_index - 1
  while cursor >= 0 {
    let ignored = should_ignore_glyph(
      glyphs[cursor],
      lookup_flag,
      gdef,
      mark_filtering_set,
    )
    match ignored {
      Err(err) => return Err(err)
      Ok(true) => cursor = cursor - 1
      Ok(false) => {
        let coverage = coverage_index(data, coverage_base, glyphs[cursor])
        match coverage {
          Err(err) => return Err(err)
          Ok(Some(index)) => return Ok(Some(index))
          Ok(None) => cursor = cursor - 1
        }
      }
    }
  }
  Ok(None)
}

///|
fn apply_mark_to_base_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index <= 0 || index >= glyphs.length() {
    return Ok(false)
  }
  let ignored = should_ignore_glyph(
    glyphs[index],
    lookup_flag,
    gdef,
    mark_filtering_set,
  )
  match ignored {
    Err(err) => return Err(err)
    Ok(true) => return Ok(false)
    Ok(false) => ()
  }
  let mut changed = false
  let mark_glyph = glyphs[index]
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => if format == 1 {
        if offset < 0 || offset + 12 > data.length() {
          return Err(UnexpectedEof)
        }
        let mark_coverage_offset = read_u16_int(data, offset + 2)
        let base_coverage_offset = read_u16_int(data, offset + 4)
        let class_count = read_u16_int(data, offset + 6)
        let mark_array_offset = read_u16_int(data, offset + 8)
        let base_array_offset = read_u16_int(data, offset + 10)
        match (
          mark_coverage_offset,
          base_coverage_offset,
          class_count,
          mark_array_offset,
          base_array_offset,
        ) {
          (Err(err), _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _) => return Err(err)
          (_, _, Err(err), _, _) => return Err(err)
          (_, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, Err(err)) => return Err(err)
          (
            Ok(mark_coverage_offset),
            Ok(base_coverage_offset),
            Ok(class_count),
            Ok(mark_array_offset),
            Ok(base_array_offset),
          ) => {
            if mark_coverage_offset == 0 || base_coverage_offset == 0 ||
                mark_array_offset == 0 || base_array_offset == 0 {
              return Err(InvalidFormat)
            }
            if class_count <= 0 {
              return Err(InvalidFormat)
            }
            let mark_coverage_base = offset + mark_coverage_offset
            let base_coverage_base = offset + base_coverage_offset
            let mark_array_base = offset + mark_array_offset
            let base_array_base = offset + base_array_offset
            if mark_array_base < 0 || mark_array_base + 2 > data.length() {
              return Err(UnexpectedEof)
            }
            if base_array_base < 0 || base_array_base + 2 > data.length() {
              return Err(UnexpectedEof)
            }
            let mark_count = read_u16_int(data, mark_array_base)
            let base_count = read_u16_int(data, base_array_base)
            match (mark_count, base_count) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(mark_count), Ok(base_count)) => {
                if mark_count <= 0 || base_count <= 0 {
                  return Err(InvalidFormat)
                }
                let mark_record_base = mark_array_base + 2
                let mark_record_size = 4
                if mark_record_base < 0 ||
                    mark_record_base + mark_count * mark_record_size > data.length() {
                  return Err(UnexpectedEof)
                }
                let base_record_base = base_array_base + 2
                let base_record_size = class_count * 2
                if base_record_base < 0 ||
                    base_record_base + base_count * base_record_size > data.length() {
                  return Err(UnexpectedEof)
                }
                let mark_index = coverage_index(
                  data,
                  mark_coverage_base,
                  mark_glyph,
                )
                match mark_index {
                  Err(err) => return Err(err)
                  Ok(Some(mark_index)) => {
                    let base_index = find_prev_coverage_index(
                      data,
                      base_coverage_base,
                      glyphs,
                      index,
                      lookup_flag,
                      mark_filtering_set,
                      gdef,
                    )
                    let base_index = match base_index {
                      Err(err) => return Err(err)
                      Ok(None) => continue
                      Ok(Some(base_index)) => base_index
                    }
                    if mark_index < 0 || mark_index >= mark_count {
                      return Err(InvalidFormat)
                    }
                    if base_index < 0 || base_index >= base_count {
                      return Err(InvalidFormat)
                    }
                    let mark_record_offset =
                      mark_record_base + mark_index * mark_record_size
                    let mark_class = read_u16_int(data, mark_record_offset)
                    let mark_anchor_offset = read_u16_int(
                      data,
                      mark_record_offset + 2,
                    )
                    match (mark_class, mark_anchor_offset) {
                      (Err(err), _) => return Err(err)
                      (_, Err(err)) => return Err(err)
                      (Ok(mark_class), Ok(mark_anchor_offset)) => {
                        if mark_class < 0 || mark_class >= class_count {
                          return Err(InvalidFormat)
                        }
                        if mark_anchor_offset == 0 {
                          return Err(InvalidFormat)
                        }
                        let base_record_offset =
                          base_record_base + base_index * base_record_size
                        let base_anchor_offset = read_u16_int(
                          data,
                          base_record_offset + mark_class * 2,
                        )
                        match base_anchor_offset {
                          Err(err) => return Err(err)
                          Ok(base_anchor_offset) => {
                            if base_anchor_offset == 0 {
                              continue
                            }
                            let mark_anchor_base =
                              mark_array_base + mark_anchor_offset
                            let base_anchor_base =
                              base_array_base + base_anchor_offset
                            let mark_anchor = read_anchor(data, mark_anchor_base)
                            let base_anchor = read_anchor(data, base_anchor_base)
                            match (mark_anchor, base_anchor) {
                              (Err(err), _) => return Err(err)
                              (_, Err(err)) => return Err(err)
                              (Ok(mark_anchor), Ok(base_anchor)) => {
                                let dx = base_anchor.0 - mark_anchor.0
                                let dy = base_anchor.1 - mark_anchor.1
                                let delta = ValueRecord::{
                                  x_placement: dx,
                                  y_placement: dy,
                                  x_advance: 0,
                                  y_advance: 0,
                                }
                                deltas[index] = add_value_record(deltas[index], delta)
                                changed = true
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  Ok(None) => ()
                }
              }
            }
          }
        }
      } else {
        return Err(InvalidFormat)
      }
    }
  }
  Ok(changed)
}

///|
fn apply_mark_to_ligature_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index <= 0 || index >= glyphs.length() {
    return Ok(false)
  }
  let ignored = should_ignore_glyph(
    glyphs[index],
    lookup_flag,
    gdef,
    mark_filtering_set,
  )
  match ignored {
    Err(err) => return Err(err)
    Ok(true) => return Ok(false)
    Ok(false) => ()
  }
  let mut changed = false
  let mark_glyph = glyphs[index]
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => if format == 1 {
        if offset < 0 || offset + 12 > data.length() {
          return Err(UnexpectedEof)
        }
        let mark_coverage_offset = read_u16_int(data, offset + 2)
        let ligature_coverage_offset = read_u16_int(data, offset + 4)
        let class_count = read_u16_int(data, offset + 6)
        let mark_array_offset = read_u16_int(data, offset + 8)
        let ligature_array_offset = read_u16_int(data, offset + 10)
        match (
          mark_coverage_offset,
          ligature_coverage_offset,
          class_count,
          mark_array_offset,
          ligature_array_offset,
        ) {
          (Err(err), _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _) => return Err(err)
          (_, _, Err(err), _, _) => return Err(err)
          (_, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, Err(err)) => return Err(err)
          (
            Ok(mark_coverage_offset),
            Ok(ligature_coverage_offset),
            Ok(class_count),
            Ok(mark_array_offset),
            Ok(ligature_array_offset),
          ) => {
            if mark_coverage_offset == 0 || ligature_coverage_offset == 0 ||
                mark_array_offset == 0 || ligature_array_offset == 0 {
              return Err(InvalidFormat)
            }
            if class_count <= 0 {
              return Err(InvalidFormat)
            }
            let mark_coverage_base = offset + mark_coverage_offset
            let ligature_coverage_base = offset + ligature_coverage_offset
            let mark_array_base = offset + mark_array_offset
            let ligature_array_base = offset + ligature_array_offset
            if mark_array_base < 0 || mark_array_base + 2 > data.length() {
              return Err(UnexpectedEof)
            }
            if ligature_array_base < 0 || ligature_array_base + 2 > data.length() {
              return Err(UnexpectedEof)
            }
            let mark_count = read_u16_int(data, mark_array_base)
            let ligature_count = read_u16_int(data, ligature_array_base)
            match (mark_count, ligature_count) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(mark_count), Ok(ligature_count)) => {
                if mark_count <= 0 || ligature_count <= 0 {
                  return Err(InvalidFormat)
                }
                let mark_record_base = mark_array_base + 2
                let mark_record_size = 4
                if mark_record_base < 0 ||
                    mark_record_base + mark_count * mark_record_size > data.length() {
                  return Err(UnexpectedEof)
                }
                let ligature_offset_base = ligature_array_base + 2
                if ligature_offset_base < 0 ||
                    ligature_offset_base + ligature_count * 2 > data.length() {
                  return Err(UnexpectedEof)
                }
                let mark_index = coverage_index(
                  data,
                  mark_coverage_base,
                  mark_glyph,
                )
                match mark_index {
                  Err(err) => return Err(err)
                  Ok(Some(mark_index)) => {
                    let ligature_index = find_prev_coverage_index(
                      data,
                      ligature_coverage_base,
                      glyphs,
                      index,
                      lookup_flag,
                      mark_filtering_set,
                      gdef,
                    )
                    let ligature_index = match ligature_index {
                      Err(err) => return Err(err)
                      Ok(None) => continue
                      Ok(Some(ligature_index)) => ligature_index
                    }
                    if mark_index < 0 || mark_index >= mark_count {
                      return Err(InvalidFormat)
                    }
                    if ligature_index < 0 || ligature_index >= ligature_count {
                      return Err(InvalidFormat)
                    }
                    let mark_record_offset =
                      mark_record_base + mark_index * mark_record_size
                    let mark_class = read_u16_int(data, mark_record_offset)
                    let mark_anchor_offset = read_u16_int(
                      data,
                      mark_record_offset + 2,
                    )
                    match (mark_class, mark_anchor_offset) {
                      (Err(err), _) => return Err(err)
                      (_, Err(err)) => return Err(err)
                      (Ok(mark_class), Ok(mark_anchor_offset)) => {
                        if mark_class < 0 || mark_class >= class_count {
                          return Err(InvalidFormat)
                        }
                        if mark_anchor_offset == 0 {
                          return Err(InvalidFormat)
                        }
                        let ligature_attach_offset = read_u16_int(
                          data,
                          ligature_offset_base + ligature_index * 2,
                        )
                        match ligature_attach_offset {
                          Err(err) => return Err(err)
                          Ok(ligature_attach_offset) => {
                            if ligature_attach_offset == 0 {
                              return Err(InvalidFormat)
                            }
                            let ligature_attach_base =
                              ligature_array_base + ligature_attach_offset
                            if ligature_attach_base < 0 ||
                                ligature_attach_base + 2 > data.length() {
                              return Err(UnexpectedEof)
                            }
                            let component_count = read_u16_int(
                              data,
                              ligature_attach_base,
                            )
                            match component_count {
                              Err(err) => return Err(err)
                              Ok(component_count) => {
                                if component_count <= 0 {
                                  return Err(InvalidFormat)
                                }
                                let component_index = 0
                                if component_index < 0 ||
                                    component_index >= component_count {
                                  return Err(InvalidFormat)
                                }
                                let component_record_base =
                                  ligature_attach_base + 2
                                let component_record_size = class_count * 2
                                let component_total =
                                  component_record_size * component_count
                                if component_record_base < 0 ||
                                    component_record_base + component_total > data.length() {
                                  return Err(UnexpectedEof)
                                }
                                let component_base =
                                  component_record_base +
                                  component_index * component_record_size
                                let ligature_anchor_offset = read_u16_int(
                                  data,
                                  component_base + mark_class * 2,
                                )
                                match ligature_anchor_offset {
                                  Err(err) => return Err(err)
                                  Ok(ligature_anchor_offset) => {
                                    if ligature_anchor_offset == 0 {
                                      continue
                                    }
                                    let mark_anchor_base =
                                      mark_array_base + mark_anchor_offset
                                    let ligature_anchor_base =
                                      ligature_attach_base + ligature_anchor_offset
                                    let mark_anchor = read_anchor(
                                      data,
                                      mark_anchor_base,
                                    )
                                    let ligature_anchor = read_anchor(
                                      data,
                                      ligature_anchor_base,
                                    )
                                    match (mark_anchor, ligature_anchor) {
                                      (Err(err), _) => return Err(err)
                                      (_, Err(err)) => return Err(err)
                                      (Ok(mark_anchor), Ok(ligature_anchor)) => {
                                        let dx = ligature_anchor.0 - mark_anchor.0
                                        let dy = ligature_anchor.1 - mark_anchor.1
                                        let delta = ValueRecord::{
                                          x_placement: dx,
                                          y_placement: dy,
                                          x_advance: 0,
                                          y_advance: 0,
                                        }
                                        deltas[index] = add_value_record(
                                          deltas[index],
                                          delta,
                                        )
                                        changed = true
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  Ok(None) => ()
                }
              }
            }
          }
        }
      } else {
        return Err(InvalidFormat)
      }
    }
  }
  Ok(changed)
}

///|
fn apply_cursive_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_cursive_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Ok(())
    }
  }
}

///|
fn apply_cursive_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let entry_exit_count = read_u16_int(data, offset + 4)
  match (coverage_offset, entry_exit_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(entry_exit_count)) => {
      if entry_exit_count <= 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset == 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let record_base = offset + 6
      let record_size = 4
      if record_base < 0 ||
          record_base + entry_exit_count * record_size > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<(glyphs.length() - 1) {
        let input_indices = collect_forward_indices(
          glyphs,
          i,
          2,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        let indices = match input_indices {
          Err(err) => return Err(err)
          Ok(None) => continue
          Ok(Some(indices)) => indices
        }
        let current = glyphs[indices[0]]
        let next = glyphs[indices[1]]
        let current_index = coverage_index(data, coverage_base, current)
        let next_index = coverage_index(data, coverage_base, next)
        match (current_index, next_index) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(Some(current_index)), Ok(Some(next_index))) => {
            if current_index < 0 || current_index >= entry_exit_count {
              return Err(InvalidFormat)
            }
            if next_index < 0 || next_index >= entry_exit_count {
              return Err(InvalidFormat)
            }
            let current_record_base = record_base + current_index * record_size
            let next_record_base = record_base + next_index * record_size
            let current_exit_offset = read_u16_int(data, current_record_base + 2)
            let next_entry_offset = read_u16_int(data, next_record_base)
            match (current_exit_offset, next_entry_offset) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(current_exit_offset), Ok(next_entry_offset)) => {
                if current_exit_offset == 0 || next_entry_offset == 0 {
                  continue
                }
                let current_exit_base = offset + current_exit_offset
                let next_entry_base = offset + next_entry_offset
                let current_exit = read_anchor(data, current_exit_base)
                let next_entry = read_anchor(data, next_entry_base)
                match (current_exit, next_entry) {
                  (Err(err), _) => return Err(err)
                  (_, Err(err)) => return Err(err)
                  (Ok(current_exit), Ok(next_entry)) => {
                    let dx = current_exit.0 - next_entry.0
                    let dy = current_exit.1 - next_entry.1
                    let delta = ValueRecord::{
                      x_placement: dx,
                      y_placement: dy,
                      x_advance: 0,
                      y_advance: 0,
                    }
                    deltas[indices[1]] = add_value_record(
                      deltas[indices[1]],
                      delta,
                    )
                  }
                }
              }
            }
          }
          _ => ()
        }
      }
      Ok(())
    }
  }
}

///|
fn apply_mark_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_mark_to_base_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Ok(())
    }
  }
}

///|
fn apply_mark_to_base_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  if offset < 0 || offset + 12 > data.length() {
    return Err(UnexpectedEof)
  }
  let mark_coverage_offset = read_u16_int(data, offset + 2)
  let base_coverage_offset = read_u16_int(data, offset + 4)
  let class_count = read_u16_int(data, offset + 6)
  let mark_array_offset = read_u16_int(data, offset + 8)
  let base_array_offset = read_u16_int(data, offset + 10)
  match (
    mark_coverage_offset,
    base_coverage_offset,
    class_count,
    mark_array_offset,
    base_array_offset,
  ) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(mark_coverage_offset),
      Ok(base_coverage_offset),
      Ok(class_count),
      Ok(mark_array_offset),
      Ok(base_array_offset),
    ) => {
      if mark_coverage_offset == 0 || base_coverage_offset == 0 ||
          mark_array_offset == 0 || base_array_offset == 0 {
        return Err(InvalidFormat)
      }
      if class_count <= 0 {
        return Err(InvalidFormat)
      }
      let mark_coverage_base = offset + mark_coverage_offset
      let base_coverage_base = offset + base_coverage_offset
      let mark_array_base = offset + mark_array_offset
      let base_array_base = offset + base_array_offset
      if mark_array_base < 0 || mark_array_base + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      if base_array_base < 0 || base_array_base + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mark_count = read_u16_int(data, mark_array_base)
      let base_count = read_u16_int(data, base_array_base)
      match (mark_count, base_count) {
        (Err(err), _) => Err(err)
        (_, Err(err)) => Err(err)
        (Ok(mark_count), Ok(base_count)) => {
          if mark_count <= 0 || base_count <= 0 {
            return Err(InvalidFormat)
          }
          let mark_record_base = mark_array_base + 2
          let mark_record_size = 4
          if mark_record_base < 0 ||
              mark_record_base + mark_count * mark_record_size > data.length() {
            return Err(UnexpectedEof)
          }
          let base_record_base = base_array_base + 2
          let base_record_size = class_count * 2
          if base_record_base < 0 ||
              base_record_base + base_count * base_record_size > data.length() {
            return Err(UnexpectedEof)
          }
          for i in 1..<glyphs.length() {
            let mark_glyph = glyphs[i]
            let ignored = should_ignore_glyph(
              mark_glyph,
              lookup_flag,
              gdef,
              mark_filtering_set,
            )
            match ignored {
              Err(err) => return Err(err)
              Ok(true) => continue
              Ok(false) => ()
            }
            let mark_index = coverage_index(data, mark_coverage_base, mark_glyph)
            match mark_index {
              Err(err) => return Err(err)
              Ok(Some(mark_index)) => {
                let base_index = find_prev_coverage_index(
                  data,
                  base_coverage_base,
                  glyphs,
                  i,
                  lookup_flag,
                  mark_filtering_set,
                  gdef,
                )
                let base_index = match base_index {
                  Err(err) => return Err(err)
                  Ok(None) => continue
                  Ok(Some(base_index)) => base_index
                }
                if mark_index < 0 || mark_index >= mark_count {
                  return Err(InvalidFormat)
                }
                if base_index < 0 || base_index >= base_count {
                  return Err(InvalidFormat)
                }
                let mark_record_offset = mark_record_base + mark_index * mark_record_size
                let mark_class = read_u16_int(data, mark_record_offset)
                let mark_anchor_offset = read_u16_int(data, mark_record_offset + 2)
                match (mark_class, mark_anchor_offset) {
                  (Err(err), _) => return Err(err)
                  (_, Err(err)) => return Err(err)
                  (Ok(mark_class), Ok(mark_anchor_offset)) => {
                    if mark_class < 0 || mark_class >= class_count {
                      return Err(InvalidFormat)
                    }
                    if mark_anchor_offset == 0 {
                      return Err(InvalidFormat)
                    }
                    let base_record_offset =
                      base_record_base + base_index * base_record_size
                    let base_anchor_offset = read_u16_int(
                      data,
                      base_record_offset + mark_class * 2,
                    )
                    match base_anchor_offset {
                      Err(err) => return Err(err)
                      Ok(base_anchor_offset) => {
                        if base_anchor_offset == 0 {
                          continue
                        }
                        let mark_anchor_base = mark_array_base + mark_anchor_offset
                        let base_anchor_base = base_array_base + base_anchor_offset
                        let mark_anchor = read_anchor(data, mark_anchor_base)
                        let base_anchor = read_anchor(data, base_anchor_base)
                        match (mark_anchor, base_anchor) {
                          (Err(err), _) => return Err(err)
                          (_, Err(err)) => return Err(err)
                          (Ok(mark_anchor), Ok(base_anchor)) => {
                            let dx = base_anchor.0 - mark_anchor.0
                            let dy = base_anchor.1 - mark_anchor.1
                            let delta = ValueRecord::{
                              x_placement: dx,
                              y_placement: dy,
                              x_advance: 0,
                              y_advance: 0,
                            }
                            deltas[i] = add_value_record(deltas[i], delta)
                          }
                        }
                      }
                    }
                  }
                }
              }
              Ok(None) => ()
            }
          }
          Ok(())
        }
      }
    }
  }
}

///|
fn apply_mark_to_ligature_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_mark_to_ligature_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Ok(())
    }
  }
}

///|
fn apply_mark_to_ligature_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  if offset < 0 || offset + 12 > data.length() {
    return Err(UnexpectedEof)
  }
  let mark_coverage_offset = read_u16_int(data, offset + 2)
  let ligature_coverage_offset = read_u16_int(data, offset + 4)
  let class_count = read_u16_int(data, offset + 6)
  let mark_array_offset = read_u16_int(data, offset + 8)
  let ligature_array_offset = read_u16_int(data, offset + 10)
  match (
    mark_coverage_offset,
    ligature_coverage_offset,
    class_count,
    mark_array_offset,
    ligature_array_offset,
  ) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(mark_coverage_offset),
      Ok(ligature_coverage_offset),
      Ok(class_count),
      Ok(mark_array_offset),
      Ok(ligature_array_offset),
    ) => {
      if mark_coverage_offset == 0 || ligature_coverage_offset == 0 ||
          mark_array_offset == 0 || ligature_array_offset == 0 {
        return Err(InvalidFormat)
      }
      if class_count <= 0 {
        return Err(InvalidFormat)
      }
      let mark_coverage_base = offset + mark_coverage_offset
      let ligature_coverage_base = offset + ligature_coverage_offset
      let mark_array_base = offset + mark_array_offset
      let ligature_array_base = offset + ligature_array_offset
      if mark_array_base < 0 || mark_array_base + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      if ligature_array_base < 0 || ligature_array_base + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mark_count = read_u16_int(data, mark_array_base)
      let ligature_count = read_u16_int(data, ligature_array_base)
      match (mark_count, ligature_count) {
        (Err(err), _) => Err(err)
        (_, Err(err)) => Err(err)
        (Ok(mark_count), Ok(ligature_count)) => {
          if mark_count <= 0 || ligature_count <= 0 {
            return Err(InvalidFormat)
          }
          let mark_record_base = mark_array_base + 2
          let mark_record_size = 4
          if mark_record_base < 0 ||
              mark_record_base + mark_count * mark_record_size > data.length() {
            return Err(UnexpectedEof)
          }
          let ligature_offset_base = ligature_array_base + 2
          if ligature_offset_base < 0 ||
              ligature_offset_base + ligature_count * 2 > data.length() {
            return Err(UnexpectedEof)
          }
          for i in 1..<glyphs.length() {
            let mark_glyph = glyphs[i]
            let ignored = should_ignore_glyph(
              mark_glyph,
              lookup_flag,
              gdef,
              mark_filtering_set,
            )
            match ignored {
              Err(err) => return Err(err)
              Ok(true) => continue
              Ok(false) => ()
            }
            let mark_index = coverage_index(data, mark_coverage_base, mark_glyph)
            match mark_index {
              Err(err) => return Err(err)
              Ok(Some(mark_index)) => {
                let ligature_index = find_prev_coverage_index(
                  data,
                  ligature_coverage_base,
                  glyphs,
                  i,
                  lookup_flag,
                  mark_filtering_set,
                  gdef,
                )
                let ligature_index = match ligature_index {
                  Err(err) => return Err(err)
                  Ok(None) => continue
                  Ok(Some(ligature_index)) => ligature_index
                }
                if mark_index < 0 || mark_index >= mark_count {
                  return Err(InvalidFormat)
                }
                if ligature_index < 0 || ligature_index >= ligature_count {
                  return Err(InvalidFormat)
                }
                let mark_record_offset =
                  mark_record_base + mark_index * mark_record_size
                let mark_class = read_u16_int(data, mark_record_offset)
                let mark_anchor_offset = read_u16_int(data, mark_record_offset + 2)
                match (mark_class, mark_anchor_offset) {
                  (Err(err), _) => return Err(err)
                  (_, Err(err)) => return Err(err)
                  (Ok(mark_class), Ok(mark_anchor_offset)) => {
                    if mark_class < 0 || mark_class >= class_count {
                      return Err(InvalidFormat)
                    }
                    if mark_anchor_offset == 0 {
                      return Err(InvalidFormat)
                    }
                    let ligature_attach_offset = read_u16_int(
                      data,
                      ligature_offset_base + ligature_index * 2,
                    )
                    match ligature_attach_offset {
                      Err(err) => return Err(err)
                      Ok(ligature_attach_offset) => {
                        if ligature_attach_offset == 0 {
                          return Err(InvalidFormat)
                        }
                        let ligature_attach_base =
                          ligature_array_base + ligature_attach_offset
                        if ligature_attach_base < 0 ||
                            ligature_attach_base + 2 > data.length() {
                          return Err(UnexpectedEof)
                        }
                        let component_count = read_u16_int(data, ligature_attach_base)
                        match component_count {
                          Err(err) => return Err(err)
                          Ok(component_count) => {
                            if component_count <= 0 {
                              return Err(InvalidFormat)
                            }
                            let component_index = 0
                            if component_index < 0 || component_index >= component_count {
                              return Err(InvalidFormat)
                            }
                            let component_record_base = ligature_attach_base + 2
                            let component_record_size = class_count * 2
                            let component_total =
                              component_record_size * component_count
                            if component_record_base < 0 ||
                                component_record_base + component_total > data.length() {
                              return Err(UnexpectedEof)
                            }
                            let component_base =
                              component_record_base +
                              component_index * component_record_size
                            let ligature_anchor_offset = read_u16_int(
                              data,
                              component_base + mark_class * 2,
                            )
                            match ligature_anchor_offset {
                              Err(err) => return Err(err)
                              Ok(ligature_anchor_offset) => {
                                if ligature_anchor_offset == 0 {
                                  continue
                                }
                                let mark_anchor_base =
                                  mark_array_base + mark_anchor_offset
                                let ligature_anchor_base =
                                  ligature_attach_base + ligature_anchor_offset
                                let mark_anchor = read_anchor(data, mark_anchor_base)
                                let ligature_anchor = read_anchor(
                                  data,
                                  ligature_anchor_base,
                                )
                                match (mark_anchor, ligature_anchor) {
                                  (Err(err), _) => return Err(err)
                                  (_, Err(err)) => return Err(err)
                                  (Ok(mark_anchor), Ok(ligature_anchor)) => {
                                    let dx = ligature_anchor.0 - mark_anchor.0
                                    let dy = ligature_anchor.1 - mark_anchor.1
                                    let delta = ValueRecord::{
                                      x_placement: dx,
                                      y_placement: dy,
                                      x_advance: 0,
                                      y_advance: 0,
                                    }
                                    deltas[i] = add_value_record(deltas[i], delta)
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
              Ok(None) => ()
            }
          }
          Ok(())
        }
      }
    }
  }
}

///|
fn apply_mark_to_mark_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index <= 0 || index >= glyphs.length() {
    return Ok(false)
  }
  let ignored = should_ignore_glyph(
    glyphs[index],
    lookup_flag,
    gdef,
    mark_filtering_set,
  )
  match ignored {
    Err(err) => return Err(err)
    Ok(true) => return Ok(false)
    Ok(false) => ()
  }
  let mut changed = false
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => if format == 1 {
        if offset < 0 || offset + 12 > data.length() {
          return Err(UnexpectedEof)
        }
        let mark1_coverage_offset = read_u16_int(data, offset + 2)
        let mark2_coverage_offset = read_u16_int(data, offset + 4)
        let class_count = read_u16_int(data, offset + 6)
        let mark1_array_offset = read_u16_int(data, offset + 8)
        let mark2_array_offset = read_u16_int(data, offset + 10)
        match (
          mark1_coverage_offset,
          mark2_coverage_offset,
          class_count,
          mark1_array_offset,
          mark2_array_offset,
        ) {
          (Err(err), _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _) => return Err(err)
          (_, _, Err(err), _, _) => return Err(err)
          (_, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, Err(err)) => return Err(err)
          (
            Ok(mark1_coverage_offset),
            Ok(mark2_coverage_offset),
            Ok(class_count),
            Ok(mark1_array_offset),
            Ok(mark2_array_offset),
          ) => {
            if mark1_coverage_offset == 0 || mark2_coverage_offset == 0 ||
                mark1_array_offset == 0 || mark2_array_offset == 0 {
              return Err(InvalidFormat)
            }
            if class_count <= 0 {
              return Err(InvalidFormat)
            }
            let mark1_coverage_base = offset + mark1_coverage_offset
            let mark2_coverage_base = offset + mark2_coverage_offset
            let mark1_array_base = offset + mark1_array_offset
            let mark2_array_base = offset + mark2_array_offset
            if mark1_array_base < 0 || mark1_array_base + 2 > data.length() {
              return Err(UnexpectedEof)
            }
            if mark2_array_base < 0 || mark2_array_base + 2 > data.length() {
              return Err(UnexpectedEof)
            }
            let mark1_count = read_u16_int(data, mark1_array_base)
            let mark2_count = read_u16_int(data, mark2_array_base)
            match (mark1_count, mark2_count) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(mark1_count), Ok(mark2_count)) => {
                if mark1_count <= 0 || mark2_count <= 0 {
                  return Err(InvalidFormat)
                }
                let mark1_record_base = mark1_array_base + 2
                let mark1_record_size = 4
                if mark1_record_base < 0 ||
                    mark1_record_base + mark1_count * mark1_record_size > data.length() {
                  return Err(UnexpectedEof)
                }
                let mark2_record_base = mark2_array_base + 2
                let mark2_record_size = class_count * 2
                if mark2_record_base < 0 ||
                    mark2_record_base + mark2_count * mark2_record_size > data.length() {
                  return Err(UnexpectedEof)
                }
                let mark1_glyph = glyphs[index]
                let mark1_index = coverage_index(
                  data,
                  mark1_coverage_base,
                  mark1_glyph,
                )
                match mark1_index {
                  Err(err) => return Err(err)
                  Ok(Some(mark1_index)) => {
                    let mark2_index = find_prev_coverage_index(
                      data,
                      mark2_coverage_base,
                      glyphs,
                      index,
                      lookup_flag,
                      mark_filtering_set,
                      gdef,
                    )
                    let mark2_index = match mark2_index {
                      Err(err) => return Err(err)
                      Ok(None) => continue
                      Ok(Some(mark2_index)) => mark2_index
                    }
                    if mark1_index < 0 || mark1_index >= mark1_count {
                      return Err(InvalidFormat)
                    }
                    if mark2_index < 0 || mark2_index >= mark2_count {
                      return Err(InvalidFormat)
                    }
                    let mark1_record_offset =
                      mark1_record_base + mark1_index * mark1_record_size
                    let mark_class = read_u16_int(data, mark1_record_offset)
                    let mark1_anchor_offset = read_u16_int(
                      data,
                      mark1_record_offset + 2,
                    )
                    match (mark_class, mark1_anchor_offset) {
                      (Err(err), _) => return Err(err)
                      (_, Err(err)) => return Err(err)
                      (Ok(mark_class), Ok(mark1_anchor_offset)) => {
                        if mark_class < 0 || mark_class >= class_count {
                          return Err(InvalidFormat)
                        }
                        if mark1_anchor_offset == 0 {
                          return Err(InvalidFormat)
                        }
                        let mark2_record_offset =
                          mark2_record_base + mark2_index * mark2_record_size
                        let mark2_anchor_offset = read_u16_int(
                          data,
                          mark2_record_offset + mark_class * 2,
                        )
                        match mark2_anchor_offset {
                          Err(err) => return Err(err)
                          Ok(mark2_anchor_offset) => {
                            if mark2_anchor_offset == 0 {
                              continue
                            }
                            let mark1_anchor_base =
                              mark1_array_base + mark1_anchor_offset
                            let mark2_anchor_base =
                              mark2_array_base + mark2_anchor_offset
                            let mark1_anchor = read_anchor(
                              data,
                              mark1_anchor_base,
                            )
                            let mark2_anchor = read_anchor(
                              data,
                              mark2_anchor_base,
                            )
                            match (mark1_anchor, mark2_anchor) {
                              (Err(err), _) => return Err(err)
                              (_, Err(err)) => return Err(err)
                              (Ok(mark1_anchor), Ok(mark2_anchor)) => {
                                let dx = mark2_anchor.0 - mark1_anchor.0
                                let dy = mark2_anchor.1 - mark1_anchor.1
                                let delta = ValueRecord::{
                                  x_placement: dx,
                                  y_placement: dy,
                                  x_advance: 0,
                                  y_advance: 0,
                                }
                                deltas[index] = add_value_record(
                                  deltas[index],
                                  delta,
                                )
                                changed = true
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  Ok(None) => ()
                }
              }
            }
          }
        }
      } else {
        return Err(InvalidFormat)
      }
    }
  }
  Ok(changed)
}

///|
fn apply_mark_to_mark_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_mark_to_mark_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Ok(())
    }
  }
}

///|
fn apply_mark_to_mark_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  if offset < 0 || offset + 12 > data.length() {
    return Err(UnexpectedEof)
  }
  let mark1_coverage_offset = read_u16_int(data, offset + 2)
  let mark2_coverage_offset = read_u16_int(data, offset + 4)
  let class_count = read_u16_int(data, offset + 6)
  let mark1_array_offset = read_u16_int(data, offset + 8)
  let mark2_array_offset = read_u16_int(data, offset + 10)
  match (
    mark1_coverage_offset,
    mark2_coverage_offset,
    class_count,
    mark1_array_offset,
    mark2_array_offset,
  ) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(mark1_coverage_offset),
      Ok(mark2_coverage_offset),
      Ok(class_count),
      Ok(mark1_array_offset),
      Ok(mark2_array_offset),
    ) => {
      if mark1_coverage_offset == 0 || mark2_coverage_offset == 0 ||
          mark1_array_offset == 0 || mark2_array_offset == 0 {
        return Err(InvalidFormat)
      }
      if class_count <= 0 {
        return Err(InvalidFormat)
      }
      let mark1_coverage_base = offset + mark1_coverage_offset
      let mark2_coverage_base = offset + mark2_coverage_offset
      let mark1_array_base = offset + mark1_array_offset
      let mark2_array_base = offset + mark2_array_offset
      if mark1_array_base < 0 || mark1_array_base + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      if mark2_array_base < 0 || mark2_array_base + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mark1_count = read_u16_int(data, mark1_array_base)
      let mark2_count = read_u16_int(data, mark2_array_base)
      match (mark1_count, mark2_count) {
        (Err(err), _) => Err(err)
        (_, Err(err)) => Err(err)
        (Ok(mark1_count), Ok(mark2_count)) => {
          if mark1_count <= 0 || mark2_count <= 0 {
            return Err(InvalidFormat)
          }
          let mark1_record_base = mark1_array_base + 2
          let mark1_record_size = 4
          if mark1_record_base < 0 ||
              mark1_record_base + mark1_count * mark1_record_size > data.length() {
            return Err(UnexpectedEof)
          }
          let mark2_record_base = mark2_array_base + 2
          let mark2_record_size = class_count * 2
          if mark2_record_base < 0 ||
              mark2_record_base + mark2_count * mark2_record_size > data.length() {
            return Err(UnexpectedEof)
          }
          for i in 1..<glyphs.length() {
            let mark1_glyph = glyphs[i]
            let ignored = should_ignore_glyph(
              mark1_glyph,
              lookup_flag,
              gdef,
              mark_filtering_set,
            )
            match ignored {
              Err(err) => return Err(err)
              Ok(true) => continue
              Ok(false) => ()
            }
            let mark1_index = coverage_index(
              data,
              mark1_coverage_base,
              mark1_glyph,
            )
            match mark1_index {
              Err(err) => return Err(err)
              Ok(Some(mark1_index)) => {
                let mark2_index = find_prev_coverage_index(
                  data,
                  mark2_coverage_base,
                  glyphs,
                  i,
                  lookup_flag,
                  mark_filtering_set,
                  gdef,
                )
                let mark2_index = match mark2_index {
                  Err(err) => return Err(err)
                  Ok(None) => continue
                  Ok(Some(mark2_index)) => mark2_index
                }
                if mark1_index < 0 || mark1_index >= mark1_count {
                  return Err(InvalidFormat)
                }
                if mark2_index < 0 || mark2_index >= mark2_count {
                  return Err(InvalidFormat)
                }
                let mark1_record_offset =
                  mark1_record_base + mark1_index * mark1_record_size
                let mark_class = read_u16_int(data, mark1_record_offset)
                let mark1_anchor_offset = read_u16_int(
                  data,
                  mark1_record_offset + 2,
                )
                match (mark_class, mark1_anchor_offset) {
                  (Err(err), _) => return Err(err)
                  (_, Err(err)) => return Err(err)
                  (Ok(mark_class), Ok(mark1_anchor_offset)) => {
                    if mark_class < 0 || mark_class >= class_count {
                      return Err(InvalidFormat)
                    }
                    if mark1_anchor_offset == 0 {
                      return Err(InvalidFormat)
                    }
                    let mark2_record_offset =
                      mark2_record_base + mark2_index * mark2_record_size
                    let mark2_anchor_offset = read_u16_int(
                      data,
                      mark2_record_offset + mark_class * 2,
                    )
                    match mark2_anchor_offset {
                      Err(err) => return Err(err)
                      Ok(mark2_anchor_offset) => {
                        if mark2_anchor_offset == 0 {
                          continue
                        }
                        let mark1_anchor_base =
                          mark1_array_base + mark1_anchor_offset
                        let mark2_anchor_base =
                          mark2_array_base + mark2_anchor_offset
                        let mark1_anchor = read_anchor(data, mark1_anchor_base)
                        let mark2_anchor = read_anchor(data, mark2_anchor_base)
                        match (mark1_anchor, mark2_anchor) {
                          (Err(err), _) => return Err(err)
                          (_, Err(err)) => return Err(err)
                          (Ok(mark1_anchor), Ok(mark2_anchor)) => {
                            let dx = mark2_anchor.0 - mark1_anchor.0
                            let dy = mark2_anchor.1 - mark1_anchor.1
                            let delta = ValueRecord::{
                              x_placement: dx,
                              y_placement: dy,
                              x_advance: 0,
                              y_advance: 0,
                            }
                            deltas[i] = add_value_record(deltas[i], delta)
                          }
                        }
                      }
                    }
                  }
                }
              }
              Ok(None) => ()
            }
          }
          Ok(())
        }
      }
    }
  }
}

///|
fn read_anchor(
  data : BytesView,
  offset : Int,
) -> Result[(Int, Int), OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      let x = read_i16(data, offset + 2)
      let y = read_i16(data, offset + 4)
      match (x, y) {
        (Err(err), _) => Err(err)
        (_, Err(err)) => Err(err)
        (Ok(x), Ok(y)) => Ok((x, y))
      }
    } else {
      Err(InvalidFormat)
    }
  }
}

///|
fn apply_single_pos_subtable(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      apply_single_pos_format1(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 2 {
      apply_single_pos_format2(
        data,
        offset,
        glyphs,
        deltas,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else {
      Ok(())
    }
  }
}

///|
fn apply_single_pos_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let value_format = read_u16_int(data, offset + 4)
  match (coverage_offset, value_format) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(value_format)) => {
      let coverage_base = offset + coverage_offset
      let record_size = value_record_size(value_format)
      let record_base = offset + 6
      if record_base < 0 || record_base + record_size > data.length() {
        return Err(UnexpectedEof)
      }
      let value = read_value_record(data, record_base, value_format)
      match value {
        Err(err) => Err(err)
        Ok((value, _)) => {
          for i in 0..<glyphs.length() {
            let glyph = glyphs[i]
            let ignored = should_ignore_glyph(
              glyph,
              lookup_flag,
              gdef,
              mark_filtering_set,
            )
            match ignored {
              Err(err) => return Err(err)
              Ok(true) => continue
              Ok(false) => ()
            }
            let covered = coverage_index(data, coverage_base, glyph)
            match covered {
              Err(err) => return Err(err)
              Ok(None) => ()
              Ok(Some(_)) =>
                deltas[i] = add_value_record(deltas[i], value)
            }
          }
          Ok(())
        }
      }
    }
  }
}

///|
fn apply_single_pos_format2(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Unit, OtLayoutError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let value_format = read_u16_int(data, offset + 4)
  let value_count = read_u16_int(data, offset + 6)
  match (coverage_offset, value_format, value_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(value_format), Ok(value_count)) => {
      if value_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let record_size = value_record_size(value_format)
      let record_base = offset + 8
      let total_size = value_count * record_size
      if record_base < 0 || record_base + total_size > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
        let ignored = should_ignore_glyph(
          glyph,
          lookup_flag,
          gdef,
          mark_filtering_set,
        )
        match ignored {
          Err(err) => return Err(err)
          Ok(true) => continue
          Ok(false) => ()
        }
        let index = coverage_index(data, coverage_base, glyph)
        match index {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(index)) => {
            if index < 0 || index >= value_count {
              return Err(InvalidFormat)
            }
            let entry_base = record_base + index * record_size
            let value = read_value_record(data, entry_base, value_format)
            match value {
              Err(err) => return Err(err)
              Ok((value, _)) =>
                deltas[i] = add_value_record(deltas[i], value)
            }
          }
        }
      }
      Ok(())
    }
  }
}

///|
fn pair_adjust_format1(
  data : BytesView,
  offset : Int,
  first : UInt,
  second : UInt,
) -> Result[PairAdjust?, OtLayoutError] {
  if offset < 0 || offset + 10 > data.length() {
    return Err(UnexpectedEof)
  }
  if second > 0xffffU {
    return Ok(None)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let value_format1 = read_u16_int(data, offset + 4)
  let value_format2 = read_u16_int(data, offset + 6)
  let pair_set_count = read_u16_int(data, offset + 8)
  match (coverage_offset, value_format1, value_format2, pair_set_count) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(value_format1), Ok(value_format2), Ok(pair_set_count)) => {
      let coverage_base = offset + coverage_offset
      let index = coverage_index(data, coverage_base, first)
      match index {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(index)) => {
          if index < 0 || index >= pair_set_count {
            return Err(InvalidFormat)
          }
          let pair_offset_base = offset + 10
          let pair_offset = read_u16_int(data, pair_offset_base + index * 2)
          match pair_offset {
            Err(err) => Err(err)
            Ok(pair_offset) => {
              let pair_base = offset + pair_offset
              if pair_base < 0 || pair_base + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let value_count = read_u16_int(data, pair_base)
              match value_count {
                Err(err) => Err(err)
                Ok(value_count) => {
                  let record_size = 2 +
                    value_record_size(value_format1) +
                    value_record_size(value_format2)
                  let record_base = pair_base + 2
                  if record_base < 0 || record_base + value_count * record_size > data.length() {
                    return Err(UnexpectedEof)
                  }
                  for i in 0..<value_count {
                    let entry_base = record_base + i * record_size
                    let second_glyph = read_u16_int(data, entry_base)
                    match second_glyph {
                      Err(err) => return Err(err)
                      Ok(second_glyph) => {
                        if second_glyph == u16_to_int(second) {
                          let value1 = read_value_record(
                            data,
                            entry_base + 2,
                            value_format1,
                          )
                          match value1 {
                            Err(err) => return Err(err)
                            Ok((value1, next_offset)) => {
                              let value2 = read_value_record(
                                data,
                                next_offset,
                                value_format2,
                              )
                              match value2 {
                                Err(err) => return Err(err)
                                Ok((value2, _)) =>
                                  return Ok(
                                    Some(PairAdjust::{
                                      first: value1,
                                      second: value2,
                                    }),
                                  )
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
          }
        }
      }
    }
  }
}

///|
fn pair_adjust_format2(
  data : BytesView,
  offset : Int,
  first : UInt,
  second : UInt,
) -> Result[PairAdjust?, OtLayoutError] {
  if offset < 0 || offset + 16 > data.length() {
    return Err(UnexpectedEof)
  }
  if first > 0xffffU || second > 0xffffU {
    return Ok(None)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let value_format1 = read_u16_int(data, offset + 4)
  let value_format2 = read_u16_int(data, offset + 6)
  let class_def1_offset = read_u16_int(data, offset + 8)
  let class_def2_offset = read_u16_int(data, offset + 10)
  let class1_count = read_u16_int(data, offset + 12)
  let class2_count = read_u16_int(data, offset + 14)
  match (
    coverage_offset,
    value_format1,
    value_format2,
    class_def1_offset,
    class_def2_offset,
    class1_count,
    class2_count,
  ) {
    (Err(err), _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(coverage_offset),
      Ok(value_format1),
      Ok(value_format2),
      Ok(class_def1_offset),
      Ok(class_def2_offset),
      Ok(class1_count),
      Ok(class2_count),
    ) => {
      if coverage_offset == 0 || class_def1_offset == 0 || class_def2_offset == 0 {
        return Err(InvalidFormat)
      }
      if class1_count <= 0 || class2_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let coverage = coverage_index(data, coverage_base, first)
      match coverage {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(_)) => {
          let class1 = class_def_value(data, offset + class_def1_offset, first)
          let class2 = class_def_value(data, offset + class_def2_offset, second)
          match (class1, class2) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(class1), Ok(class2)) => {
              if class1 < 0 || class1 >= class1_count {
                return Err(InvalidFormat)
              }
              if class2 < 0 || class2 >= class2_count {
                return Err(InvalidFormat)
              }
              let record_size =
                value_record_size(value_format1) + value_record_size(value_format2)
              let class1_record_size = class2_count * record_size
              let records_base = offset + 16
              let total_size = class1_count * class1_record_size
              if records_base < 0 || records_base + total_size > data.length() {
                return Err(UnexpectedEof)
              }
              let entry_base =
                records_base + class1 * class1_record_size + class2 * record_size
              let value1 = read_value_record(data, entry_base, value_format1)
              match value1 {
                Err(err) => Err(err)
                Ok((value1, next_offset)) => {
                  let value2 = read_value_record(data, next_offset, value_format2)
                  match value2 {
                    Err(err) => Err(err)
                    Ok((value2, _)) =>
                      Ok(Some(PairAdjust::{ first: value1, second: value2 }))
                  }
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
fn value_record_size(format : Int) -> Int {
  let mut size = 0
  if (format & 0x0001) != 0 { size = size + 2 }
  if (format & 0x0002) != 0 { size = size + 2 }
  if (format & 0x0004) != 0 { size = size + 2 }
  if (format & 0x0008) != 0 { size = size + 2 }
  if (format & 0x0010) != 0 { size = size + 2 }
  if (format & 0x0020) != 0 { size = size + 2 }
  if (format & 0x0040) != 0 { size = size + 2 }
  if (format & 0x0080) != 0 { size = size + 2 }
  size
}

///|
fn read_value_record(
  data : BytesView,
  offset : Int,
  format : Int,
) -> Result[(ValueRecord, Int), OtLayoutError] {
  let mut current = offset
  let mut record = value_record_zero()
  if (format & 0x0001) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: value,
        y_placement: record.y_placement,
        x_advance: record.x_advance,
        y_advance: record.y_advance,
      }
    }
    current = current + 2
  }
  if (format & 0x0002) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: record.x_placement,
        y_placement: value,
        x_advance: record.x_advance,
        y_advance: record.y_advance,
      }
    }
    current = current + 2
  }
  if (format & 0x0004) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: record.x_placement,
        y_placement: record.y_placement,
        x_advance: value,
        y_advance: record.y_advance,
      }
    }
    current = current + 2
  }
  if (format & 0x0008) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: record.x_placement,
        y_placement: record.y_placement,
        x_advance: record.x_advance,
        y_advance: value,
      }
    }
    current = current + 2
  }
  if (format & 0x0010) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  if (format & 0x0020) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  if (format & 0x0040) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  if (format & 0x0080) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  Ok((record, current))
}

///|
fn class_def_value(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  if glyph > 0xffffU {
    return Ok(0)
  }
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      class_def_format1(data, offset, glyph)
    } else if format == 2 {
      class_def_format2(data, offset, glyph)
    } else {
      Err(InvalidFormat)
    }
  }
}

///|
fn class_def_format1(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let start_glyph = read_u16_int(data, offset + 2)
  let glyph_count = read_u16_int(data, offset + 4)
  match (start_glyph, glyph_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(start_glyph), Ok(glyph_count)) => {
      if glyph_count <= 0 {
        return Err(InvalidFormat)
      }
      let gid = u16_to_int(glyph)
      if gid < start_glyph || gid >= start_glyph + glyph_count {
        return Ok(0)
      }
      let index = gid - start_glyph
      let class_base = offset + 6
      if class_base < 0 || class_base + glyph_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let value = read_u16_int(data, class_base + index * 2)
      match value {
        Err(err) => Err(err)
        Ok(value) => Ok(value)
      }
    }
  }
}

///|
fn class_def_format2(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let range_count = read_u16_int(data, offset + 2)
  match range_count {
    Err(err) => Err(err)
    Ok(range_count) => {
      if range_count < 0 {
        return Err(InvalidFormat)
      }
      let record_base = offset + 4
      if record_base < 0 || record_base + range_count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      let gid = u16_to_int(glyph)
      for i in 0..<range_count {
        let base = record_base + i * 6
        let start = read_u16_int(data, base)
        let end = read_u16_int(data, base + 2)
        let class_value = read_u16_int(data, base + 4)
        match (start, end, class_value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start), Ok(end), Ok(class_value)) => {
            if gid >= start && gid <= end {
              return Ok(class_value)
            }
          }
        }
      }
      Ok(0)
    }
  }
}
