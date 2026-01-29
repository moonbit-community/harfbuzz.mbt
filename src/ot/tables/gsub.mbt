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
  let lookup_list_offsets = self.layout.lookup_list.offsets
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
        } else if lookup_type == 2 {
          let result = match apply_multiple_subtable_list(
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
        } else if lookup_type == 3 {
          let did_change = match apply_alternate_subtable_list(
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
        } else if lookup_type == 5 {
          let did_change = match apply_context_subtable_list(
            data,
            subtable_offsets,
            current_glyphs,
            lookup_list_offsets,
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
fn apply_context_subtable_list(
  data : BytesView,
  offsets : Array[Int],
  glyphs : Array[UInt],
  lookup_list_offsets : Array[Int],
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_context_subtable(data, offset, glyphs, lookup_list_offsets)
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
) -> Result[Bool, OtLayoutError] {
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
      let coverage_base = offset + coverage_offset
      let set_base = offset + 6
      if set_base < 0 || set_base + set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
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
fn apply_context_rule(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
  lookup_list_offsets : Array[Int],
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
      if index + glyph_count > glyphs.length() {
        return Ok(false)
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
            let actual = glyphs[index + 1 + i]
            if expected != u16_to_int(actual) {
              return Ok(false)
            }
          }
        }
      }
      let record_base = input_base + (glyph_count - 1) * 2
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
            let target = index + seq_index
            if target < 0 || target >= glyphs.length() {
              return Err(InvalidFormat)
            }
            let lookup_offset = lookup_list_offsets[lookup_index]
            let did_change = match apply_lookup_at(
              data,
              lookup_offset,
              glyphs,
              target,
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
  }
}

///|
fn apply_lookup_at(
  data : BytesView,
  lookup_offset : Int,
  glyphs : Array[UInt],
  index : Int,
) -> Result[Bool, OtLayoutError] {
  let parsed = parse_lookup(data, lookup_offset)
  match parsed {
    Err(err) => Err(err)
    Ok((lookup_type, subtable_offsets)) => {
      if lookup_type == 1 {
        apply_single_at(data, subtable_offsets, glyphs, index)
      } else if lookup_type == 3 {
        apply_alternate_at(data, subtable_offsets, glyphs, index)
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
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_chain_subtable(data, offset, glyphs, lookup_list_offsets)
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
) -> Result[Bool, OtLayoutError] {
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
      let coverage_base = offset + coverage_offset
      let set_base = offset + 6
      if set_base < 0 || set_base + set_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let mut changed = false
      for i in 0..<glyphs.length() {
        let glyph = glyphs[i]
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
fn apply_chain_rule(
  data : BytesView,
  offset : Int,
  glyphs : Array[UInt],
  index : Int,
  lookup_list_offsets : Array[Int],
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
                  for j in 0..<backtrack.length() {
                    let pos = index - 1 - j
                    if pos < 0 {
                      return Ok(false)
                    }
                    let expected = backtrack[j]
                    if expected != u16_to_int(glyphs[pos]) {
                      return Ok(false)
                    }
                  }
                  for j in 0..<input.length() {
                    let pos = index + 1 + j
                    if pos >= glyphs.length() {
                      return Ok(false)
                    }
                    if input[j] != u16_to_int(glyphs[pos]) {
                      return Ok(false)
                    }
                  }
                  for j in 0..<lookahead.length() {
                    let pos = index + input_count + j
                    if pos >= glyphs.length() {
                      return Ok(false)
                    }
                    if lookahead[j] != u16_to_int(glyphs[pos]) {
                      return Ok(false)
                    }
                  }
                  let mut changed = false
                  for i in 0..<subst_count {
                    let seq_index = read_u16_int(data, cursor + i * 4)
                    let lookup_index = read_u16_int(data, cursor + i * 4 + 2)
                    match (seq_index, lookup_index) {
                      (Err(err), _) => return Err(err)
                      (_, Err(err)) => return Err(err)
                      (Ok(seq_index), Ok(lookup_index)) => {
                        if seq_index < 0 || seq_index >= input_count {
                          return Err(InvalidFormat)
                        }
                        if lookup_index < 0 ||
                            lookup_index >= lookup_list_offsets.length() {
                          return Err(InvalidFormat)
                        }
                        let target = index + seq_index
                        let lookup_offset = lookup_list_offsets[lookup_index]
                        let did_change = match apply_lookup_at(
                          data,
                          lookup_offset,
                          glyphs,
                          target,
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
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Err(InvalidFormat)
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
) -> Result[Bool, OtLayoutError] {
  if index < 0 || index >= glyphs.length() {
    return Err(InvalidFormat)
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
) -> Result[(Array[UInt], Array[Int], Bool), OtLayoutError] {
  if clusters.length() != glyphs.length() {
    return Err(InvalidFormat)
  }
  let new_glyphs : Array[UInt] = []
  let new_clusters : Array[Int] = []
  let mut changed = false
  for i in 0..<glyphs.length() {
    let glyph = glyphs[i]
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
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for offset in offsets {
    let result = apply_alternate_subtable(data, offset, glyphs)
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
) -> Result[Bool, OtLayoutError] {
  let mut changed = false
  for i in 0..<glyphs.length() {
    let glyph = glyphs[i]
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
