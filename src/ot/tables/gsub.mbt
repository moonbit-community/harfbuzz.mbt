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
    let parsed = parse_lookup(data, lookup_offset, 7)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, lookup_flag, mark_filtering_set, subtable_offsets)) => {
        if lookup_type != 1 {
          continue
        }
        for subtable_offset in subtable_offsets {
          let res = apply_single_subtable(
            data,
            subtable_offset,
            glyphs,
            lookup_flag,
            mark_filtering_set,
            None,
          )
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
  gdef? : GdefTable,
) -> Result[(Array[UInt], Array[Int], Bool), OtLayoutError] {
  if clusters.length() != glyphs.length() {
    return Err(InvalidFormat)
  }
  let data = self.layout.data
  let lookup_list_offsets = self.layout.lookup_list.offsets
  let mut current_glyphs = glyphs
  let mut current_clusters = clusters
  let mut changed = false
  let gdef = gdef
  for lookup_offset in lookup_offsets {
    let parsed = parse_lookup(data, lookup_offset, 7)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, lookup_flag, mark_filtering_set, subtable_offsets)) => {
        if lookup_type == 1 {
          let did_change = match apply_single_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            lookup_flag,
            mark_filtering_set,
            gdef,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if did_change {
            changed = true
          }
        } else if lookup_type == 2 {
          let result = match apply_multiple_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            current_clusters,
            lookup_flag,
            mark_filtering_set,
            gdef,
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
        } else if lookup_type == 3 {
          let did_change = match apply_alternate_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            lookup_flag,
            mark_filtering_set,
            gdef,
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
            lookup_flag,
            mark_filtering_set,
            gdef,
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
        } else if lookup_type == 5 {
          let did_change = match apply_context_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            lookup_list_offsets,
            lookup_flag,
            mark_filtering_set,
            gdef,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if did_change {
            changed = true
          }
        } else if lookup_type == 6 {
          let did_change = match apply_chain_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            lookup_list_offsets,
            lookup_flag,
            mark_filtering_set,
            gdef,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if did_change {
            changed = true
          }
        } else if lookup_type == 8 {
          let did_change = match apply_reverse_chain_subtable_list(
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
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => {
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
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_single_subtable(
      data,
      offset,
      glyphs,
      lookup_flag,
      mark_filtering_set,
      gdef,
    )
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
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[(Array[UInt], Array[Int], Bool), OtLayoutError] {
  let new_glyphs : Array[UInt] = []
  let new_clusters : Array[Int] = []
  let skip = Array::make(glyphs.length(), false)
  let mut changed = false
  let len = glyphs.length()
  let mut i = 0
  while i < len {
    if skip[i] {
      i = i + 1
      continue
    }
    let glyph = glyphs[i]
    let ignored = should_ignore_glyph(
      glyph,
      lookup_flag,
      gdef,
      mark_filtering_set,
    )
    match ignored {
      Err(err) => return Err(err)
      Ok(true) => {
        new_glyphs.push(glyph)
        new_clusters.push(clusters[i])
        i = i + 1
        continue
      }
      Ok(false) => ()
    }
    let match_result = find_ligature_match(
      data,
      offsets,
      glyphs,
      i,
      lookup_flag,
      mark_filtering_set,
      gdef,
    )
    match match_result {
      Err(err) => return Err(err)
      Ok(None) => {
        new_glyphs.push(glyphs[i])
        new_clusters.push(clusters[i])
        i = i + 1
      }
      Ok(Some((lig_glyph, indices))) => {
        if indices.length() < 2 {
          return Err(InvalidFormat)
        }
        new_glyphs.push(lig_glyph)
        new_clusters.push(clusters[indices[0]])
        if lig_glyph != glyphs[indices[0]] {
          changed = true
        }
        for j in 1..<indices.length() {
          let idx = indices[j]
          if idx < 0 || idx >= skip.length() {
            return Err(InvalidFormat)
          }
          skip[idx] = true
        }
        changed = true
        i = i + 1
      }
    }
  }
  Ok((new_glyphs, new_clusters, changed))
}

///|
fn apply_context_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_context_subtable(
      data,
      offset,
      glyphs,
      lookup_list_offsets,
      lookup_flag,
      mark_filtering_set,
      gdef,
    )
    match result {
      Err(err) => return Err(err)
      Ok(value) => if value { changed = true }
    }
  }
  Ok(changed)
}

///|
fn apply_context_subtable(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
      apply_context_subtable_format1(
        data,
        offset,
        glyphs,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 2 {
      apply_context_subtable_format2(
        data,
        offset,
        glyphs,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 3 {
      apply_context_subtable_format3(
        data,
        offset,
        glyphs,
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
fn apply_context_subtable_format1(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
                          let applied = match apply_context_rule(
                            data,
                            rule_base,
                            glyphs,
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
fn apply_context_subtable_format2(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
                              let applied = match apply_context_class_rule(
                                data,
                                rule_base,
                                glyphs,
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
fn apply_context_subtable_format3(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let glyph_count = read_u16_int(data, offset + 2)
  let subst_count = read_u16_int(data, offset + 4)
  match (glyph_count, subst_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(glyph_count), Ok(subst_count)) => {
      if glyph_count <= 0 || subst_count < 0 {
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
          glyphs[:],
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
          let applied = match apply_subst_lookup_records(
            data,
            record_base,
            subst_count,
            glyph_count,
            glyphs,
            i,
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
fn apply_context_class_rule(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
  class_def_base : Int,
  lookup_list_offsets : Array[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let glyph_count = read_u16_int(data, offset)
  let subst_count = read_u16_int(data, offset + 2)
  match (glyph_count, subst_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(glyph_count), Ok(subst_count)) => {
      if glyph_count <= 0 || subst_count < 0 {
        return Err(InvalidFormat)
      }
      let input_indices = collect_forward_indices(
        glyphs[:],
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
      apply_subst_lookup_records(
        data,
        record_base,
        subst_count,
        glyph_count,
        glyphs,
        index,
        lookup_list_offsets,
        Some(indices),
        gdef,
      )
    }
  }
}

///|
fn apply_subst_lookup_records(
  data : BytesView,
  record_base : Int,
  subst_count : Int,
  glyph_count : Int,
  glyphs : Array[UInt],
  index : Int,
  lookup_list_offsets : Array[Int],
  input_indices : Array[Int]?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if subst_count < 0 {
    return Err(InvalidFormat)
  }
  match input_indices {
    None => ()
    Some(indices) => if indices.length() < glyph_count { return Err(InvalidFormat) }
  }
  if record_base < 0 || record_base + subst_count * 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let mut changed = false
  for i in 0..<subst_count {
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
        let did_change = match apply_lookup_at(
          data,
          lookup_offset,
          glyphs,
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
fn apply_context_rule(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
  lookup_list_offsets : Array[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let glyph_count = read_u16_int(data, offset)
  let subst_count = read_u16_int(data, offset + 2)
  match (glyph_count, subst_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(glyph_count), Ok(subst_count)) => {
      if glyph_count <= 0 || subst_count < 0 {
        return Err(InvalidFormat)
      }
      let input_indices = collect_forward_indices(
        glyphs[:],
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
      apply_subst_lookup_records(
        data,
        record_base,
        subst_count,
        glyph_count,
        glyphs,
        index,
        lookup_list_offsets,
        Some(indices),
        gdef,
      )
    }
  }
}

///|
fn apply_lookup_at(
  data : BytesView,
  lookup_offset : Int,
  glyphs : Array[UInt],
  index : Int,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let parsed = parse_lookup(data, lookup_offset, 7)
  match parsed {
    Err(err) => Err(err)
    Ok((lookup_type, lookup_flag, mark_filtering_set, subtable_offsets)) => {
      if lookup_type == 1 {
        apply_single_at(
          data,
          subtable_offsets,
          glyphs,
          index,
          lookup_flag,
          mark_filtering_set,
          gdef,
        )
      } else if lookup_type == 3 {
        apply_alternate_at(
          data,
          subtable_offsets,
          glyphs,
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
fn apply_chain_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_chain_subtable(
      data,
      offset,
      glyphs,
      lookup_list_offsets,
      lookup_flag,
      mark_filtering_set,
      gdef,
    )
    match result {
      Err(err) => return Err(err)
      Ok(value) => if value { changed = true }
    }
  }
  Ok(changed)
}

///|
fn apply_chain_subtable(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
      apply_chain_subtable_format1(
        data,
        offset,
        glyphs,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 2 {
      apply_chain_subtable_format2(
        data,
        offset,
        glyphs,
        lookup_list_offsets,
        lookup_flag,
        mark_filtering_set,
        gdef,
      )
    } else if format == 3 {
      apply_chain_subtable_format3(
        data,
        offset,
        glyphs,
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
fn apply_chain_subtable_format1(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
                          let applied = match apply_chain_rule(
                            data,
                            rule_base,
                            glyphs,
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
fn apply_chain_subtable_format2(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
                              let applied = match apply_chain_class_rule(
                                data,
                                rule_base,
                                glyphs,
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
fn apply_chain_subtable_format3(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
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
              let subst_count = read_u16_int(data, cursor)
              match subst_count {
                Err(err) => Err(err)
                Ok(subst_count) => {
                  cursor = cursor + 2
                  if subst_count < 0 {
                    return Err(InvalidFormat)
                  }
                  let record_base = cursor
                  let mut changed = false
                  for i in 0..<glyphs.length() {
                    let input_indices = collect_forward_indices(
                      glyphs[:],
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
                      glyphs[:],
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
                    let lookahead = if lookahead_bases.is_empty() {
                      Ok(Some([]))
                    } else {
                      collect_forward_indices(
                        glyphs[:],
                        indices[input_count - 1] + 1,
                        lookahead_bases.length(),
                        lookup_flag,
                        gdef,
                        mark_filtering_set,
                      )
                    }
                    let lookahead = match lookahead {
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
                      let applied = match apply_subst_lookup_records(
                        data,
                        record_base,
                        subst_count,
                        input_count,
                        glyphs,
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
fn apply_chain_class_rule(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
  backtrack_class_def_base : Int,
  input_class_def_base : Int,
  lookahead_class_def_base : Int,
  lookup_list_offsets : Array[Int],
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
              let subst_count = read_u16_int(data, cursor)
              match subst_count {
                Err(err) => Err(err)
                Ok(subst_count) => {
                  cursor = cursor + 2
                  if subst_count < 0 {
                    return Err(InvalidFormat)
                  }
                  let input_indices = collect_forward_indices(
                    glyphs[:],
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
                    glyphs[:],
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
                      glyphs[:],
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
                  apply_subst_lookup_records(
                    data,
                    cursor,
                    subst_count,
                    input_count,
                    glyphs,
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
fn apply_chain_rule(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
  lookup_list_offsets : Array[Int],
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
              let subst_count = read_u16_int(data, cursor)
              match subst_count {
                Err(err) => Err(err)
                Ok(subst_count) => {
                  cursor = cursor + 2
                  if subst_count < 0 {
                    return Err(InvalidFormat)
                  }
                  if cursor < 0 || cursor + subst_count * 4 > data.length() {
                    return Err(UnexpectedEof)
                  }
                  let input_indices = collect_forward_indices(
                    glyphs[:],
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
                    glyphs[:],
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
                      glyphs[:],
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
                  apply_subst_lookup_records(
                    data,
                    cursor,
                    subst_count,
                    input_count,
                    glyphs,
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
fn apply_single_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Err(InvalidFormat)
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
  let mut glyph = glyphs[index]
  for offset in offsets {
    let format = read_u16_int(data, offset)
    match format {
      Err(err) => return Err(err)
      Ok(format) => {
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
              glyph = value
              glyphs[index] = value
              changed = true
            }
          }
        }
      }
    }
  }
  Ok(changed)
}

///|
fn apply_alternate_at(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Err(InvalidFormat)
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
  let mut glyph = glyphs[index]
  for offset in offsets {
    let next = alternate_substitute_format1(data, offset, glyph)
    match next {
      Err(err) => return Err(err)
      Ok(None) => ()
      Ok(Some(value)) => {
        if value != glyph {
          glyph = value
          glyphs[index] = value
          changed = true
        }
      }
    }
  }
  Ok(changed)
}

fn apply_reverse_chain_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_reverse_chain_subtable(data, offset, glyphs)
    match result {
      Err(err) => return Err(err)
      Ok(value) => if value { changed = true }
    }
  }
  Ok(changed)
}

///|
fn apply_reverse_chain_subtable(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
) -> Result[Bool, OtLayoutError] {
  if glyphs.is_empty() {
    return Ok(false)
  }
  if offset < 0 || offset + 10 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  let coverage_offset = read_u16_int(data, offset + 2)
  let backtrack_count = read_u16_int(data, offset + 4)
  match (format, coverage_offset, backtrack_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(coverage_offset), Ok(backtrack_count)) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      if coverage_offset == 0 || backtrack_count < 0 {
        return Err(InvalidFormat)
      }
      let mut cursor = offset + 6
      let backtrack_bases : Array[Int] = []
      if cursor < 0 || cursor + backtrack_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<backtrack_count {
        let sub_offset = read_u16_int(data, cursor)
        cursor = cursor + 2
        match sub_offset {
          Err(err) => return Err(err)
          Ok(sub_offset) => {
            if sub_offset == 0 {
              return Err(InvalidFormat)
            }
            let base = offset + sub_offset
            if base < 0 || base >= data.length() {
              return Err(UnexpectedEof)
            }
            backtrack_bases.push(base)
          }
        }
      }
      if cursor < 0 || cursor + 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let lookahead_count = read_u16_int(data, cursor)
      match lookahead_count {
        Err(err) => return Err(err)
        Ok(lookahead_count) => {
          cursor = cursor + 2
          if lookahead_count < 0 {
            return Err(InvalidFormat)
          }
          if cursor < 0 || cursor + lookahead_count * 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let lookahead_bases : Array[Int] = []
          for _ in 0..<lookahead_count {
            let sub_offset = read_u16_int(data, cursor)
            cursor = cursor + 2
            match sub_offset {
              Err(err) => return Err(err)
              Ok(sub_offset) => {
                if sub_offset == 0 {
                  return Err(InvalidFormat)
                }
                let base = offset + sub_offset
                if base < 0 || base >= data.length() {
                  return Err(UnexpectedEof)
                }
                lookahead_bases.push(base)
              }
            }
          }
          if cursor < 0 || cursor + 2 > data.length() {
            return Err(UnexpectedEof)
          }
          let glyph_count = read_u16_int(data, cursor)
          match glyph_count {
            Err(err) => Err(err)
            Ok(glyph_count) => {
              cursor = cursor + 2
              if glyph_count <= 0 {
                return Err(InvalidFormat)
              }
              if cursor < 0 || cursor + glyph_count * 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let substitutes : Array[UInt] = []
              for _ in 0..<glyph_count {
                let value = read_u16_int(data, cursor)
                cursor = cursor + 2
                match value {
                  Err(err) => return Err(err)
                  Ok(value) => substitutes.push(value.reinterpret_as_uint())
                }
              }
              let coverage_base = offset + coverage_offset
              let original : Array[UInt] = []
              for value in glyphs {
                original.push(value)
              }
              let mut changed = false
              let mut i = glyphs.length() - 1
              while i >= 0 {
                let glyph = original[i]
                let index = coverage_index(data, coverage_base, glyph)
                match index {
                  Err(err) => return Err(err)
                  Ok(None) => ()
                  Ok(Some(index)) => {
                    if index < 0 || index >= glyph_count {
                      return Err(InvalidFormat)
                    }
                    let mut match_ok = true
                    if backtrack_count > 0 {
                      for j in 0..<backtrack_count {
                        let pos = i - 1 - j
                        if pos < 0 {
                          match_ok = false
                          break
                        }
                        let back_glyph = original[pos]
                        let covered = coverage_index(
                          data,
                          backtrack_bases[j],
                          back_glyph,
                        )
                        match covered {
                          Err(err) => return Err(err)
                          Ok(None) => {
                            match_ok = false
                            break
                          }
                          Ok(Some(_)) => ()
                        }
                      }
                    }
                    if match_ok && lookahead_count > 0 {
                      for j in 0..<lookahead_count {
                        let pos = i + 1 + j
                        if pos >= original.length() {
                          match_ok = false
                          break
                        }
                        let look_glyph = original[pos]
                        let covered = coverage_index(
                          data,
                          lookahead_bases[j],
                          look_glyph,
                        )
                        match covered {
                          Err(err) => return Err(err)
                          Ok(None) => {
                            match_ok = false
                            break
                          }
                          Ok(Some(_)) => ()
                        }
                      }
                    }
                    if match_ok {
                      let sub = substitutes[index]
                      if sub != glyphs[i] {
                        glyphs[i] = sub
                        changed = true
                      }
                    }
                  }
                }
                if i == 0 {
                  break
                }
                i = i - 1
              }
              Ok(changed)
            }
          }
        }
      }
    }
  }
}

///|
fn apply_multiple_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  clusters : Array[Int],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[(Array[UInt], Array[Int], Bool), OtLayoutError] {
  if clusters.length() != glyphs.length() {
    return Err(InvalidFormat)
  }
  let new_glyphs : Array[UInt] = []
  let new_clusters : Array[Int] = []
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
      Ok(true) => {
        new_glyphs.push(glyph)
        new_clusters.push(clusters[i])
        continue
      }
      Ok(false) => ()
    }
    let sub_result = find_multiple_substitution(data, offsets, glyph)
    match sub_result {
      Err(err) => return Err(err)
      Ok(None) => {
        new_glyphs.push(glyph)
        new_clusters.push(clusters[i])
      }
      Ok(Some(sequence)) => {
        if sequence.is_empty() {
          return Err(InvalidFormat)
        }
        for value in sequence {
          new_glyphs.push(value)
          new_clusters.push(clusters[i])
        }
        if sequence.length() != 1 || sequence[0] != glyph {
          changed = true
        }
      }
    }
  }
  Ok((new_glyphs, new_clusters, changed))
}

///|
fn apply_alternate_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_alternate_subtable(
      data,
      offset,
      glyphs,
      lookup_flag,
      mark_filtering_set,
      gdef,
    )
    match result {
      Err(err) => return Err(err)
      Ok(value) => if value { changed = true }
    }
  }
  Ok(changed)
}

///|
fn apply_alternate_subtable(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[Bool, OtLayoutError] {
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
    let next = alternate_substitute_format1(data, offset, glyph)
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

///|
fn alternate_substitute_format1(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[UInt?, OtLayoutError] {
  if glyph > 0xffffU {
    return Ok(None)
  }
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  let coverage_offset = read_u16_int(data, offset + 2)
  let set_count = read_u16_int(data, offset + 4)
  match (format, coverage_offset, set_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(coverage_offset), Ok(set_count)) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      if coverage_offset == 0 || set_count <= 0 {
        return Err(InvalidFormat)
      }
      let list_base = offset + 6
      if list_base < 0 || list_base + set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let coverage_base = offset + coverage_offset
      let index = coverage_index(data, coverage_base, glyph)
      match index {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(index)) => {
          if index < 0 || index >= set_count {
            return Err(InvalidFormat)
          }
          let set_offset = read_u16_int(data, list_base + index * 2)
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
              let glyph_count = read_u16_int(data, set_base)
              match glyph_count {
                Err(err) => Err(err)
                Ok(glyph_count) => {
                  if glyph_count <= 0 {
                    return Err(InvalidFormat)
                  }
                  let alt_base = set_base + 2
                  if alt_base < 0 || alt_base + glyph_count * 2 > data.length() {
                    return Err(UnexpectedEof)
                  }
                  let first = read_u16_int(data, alt_base)
                  match first {
                    Err(err) => Err(err)
                    Ok(first) => Ok(Some(first.reinterpret_as_uint()))
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
fn find_multiple_substitution(
  data : BytesView,
  offsets : Array[Int],
  glyph : UInt,
) -> Result[Array[UInt]?, OtLayoutError] {
  for offset in offsets {
    let result = multiple_substitute_format1(data, offset, glyph)
    match result {
      Err(err) => return Err(err)
      Ok(Some(value)) => return Ok(Some(value))
      Ok(None) => ()
    }
  }
  Ok(None)
}

///|
fn multiple_substitute_format1(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Array[UInt]?, OtLayoutError] {
  if glyph > 0xffffU {
    return Ok(None)
  }
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  let coverage_offset = read_u16_int(data, offset + 2)
  let sequence_count = read_u16_int(data, offset + 4)
  match (format, coverage_offset, sequence_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(coverage_offset), Ok(sequence_count)) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      if coverage_offset == 0 || sequence_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let index = coverage_index(data, coverage_base, glyph)
      match index {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(index)) => {
          if index < 0 || index >= sequence_count {
            return Err(InvalidFormat)
          }
          let sequence_offset = read_u16_int(data, offset + 6 + index * 2)
          match sequence_offset {
            Err(err) => Err(err)
            Ok(sequence_offset) => {
              if sequence_offset == 0 {
                return Err(InvalidFormat)
              }
              let sequence_base = offset + sequence_offset
              if sequence_base < 0 || sequence_base + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let glyph_count = read_u16_int(data, sequence_base)
              match glyph_count {
                Err(err) => Err(err)
                Ok(glyph_count) => {
                  if glyph_count <= 0 {
                    return Err(InvalidFormat)
                  }
                  let list_base = sequence_base + 2
                  if list_base < 0 || list_base + glyph_count * 2 > data.length() {
                    return Err(UnexpectedEof)
                  }
                  let sequence : Array[UInt] = []
                  for i in 0..<glyph_count {
                    let value = read_u16_int(data, list_base + i * 2)
                    match value {
                      Err(err) => return Err(err)
                      Ok(value) => sequence.push(value.reinterpret_as_uint())
                    }
                  }
                  Ok(Some(sequence))
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
fn find_ligature_match(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  index : Int,
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[(UInt, Array[Int])?, OtLayoutError] {
  for offset in offsets {
    let result = ligature_match_subtable(
      data,
      offset,
      glyphs,
      index,
      lookup_flag,
      mark_filtering_set,
      gdef,
    )
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
  lookup_flag : Int,
  mark_filtering_set : Int?,
  gdef : GdefTable?,
) -> Result[(UInt, Array[Int])?, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Ok(None)
  }
  let first = glyphs[index]
  let ignored = should_ignore_glyph(
    first,
    lookup_flag,
    gdef,
    mark_filtering_set,
  )
  match ignored {
    Err(err) => return Err(err)
    Ok(true) => return Ok(None)
    Ok(false) => ()
  }
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
                            let comp_base = lig_base + 4
                            let comp_len = (comp_count - 1) * 2
                            if comp_base < 0 || comp_base + comp_len > data.length() {
                              return Err(UnexpectedEof)
                            }
                            let input_indices = collect_forward_indices(
                              glyphs[:],
                              index,
                              comp_count,
                              lookup_flag,
                              gdef,
                              mark_filtering_set,
                            )
                            let indices = match input_indices {
                              Err(err) => return Err(err)
                              Ok(None) => continue
                              Ok(Some(indices)) => indices
                            }
                            let mut matches = true
                            for j in 0..<(comp_count - 1) {
                              let component = read_u16_int(data, comp_base + j * 2)
                              match component {
                                Err(err) => return Err(err)
                                Ok(component) => {
                                  let glyph = glyphs[indices[j + 1]]
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
                                Some((lig_glyph.reinterpret_as_uint(), indices)),
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
