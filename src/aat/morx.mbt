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

let subtable_type_rearrangement = 0
let subtable_type_contextual = 1
let subtable_type_ligature = 2
let subtable_type_noncontextual = 4
let subtable_type_insertion = 5

///|
pub(all) struct NoncontextualSubtable {
  coverage_flags : Int
  sub_feature_flags : UInt
  lookup : LookupTable
} derive(Eq, Show, ToJson)

///|
pub(all) struct StateEntry {
  new_state : Int
  flags : Int
  data1 : Int
  data2 : Int
} derive(Eq, Show, ToJson)

///|
pub(all) enum ClassTable {
  Lookup(LookupTable)
  Array(UInt, Array[Int])
} derive(Eq, Show, ToJson)

///|
pub(all) struct StateTable {
  n_classes : Int
  class_table : ClassTable
  state_array : Array[Int]
  entries : Array[StateEntry]
  state_array_offset : Int
  extended : Bool
} derive(Eq, Show, ToJson)

///|
pub(all) struct RearrangementSubtable {
  coverage_flags : Int
  sub_feature_flags : UInt
  table : StateTable
} derive(Eq, Show, ToJson)

///|
pub(all) enum ContextualSubstitutions {
  Lookups(Array[LookupTable])
  Values(Int, Array[UInt])
} derive(Eq, Show, ToJson)

///|
pub(all) struct ContextualSubtable {
  coverage_flags : Int
  sub_feature_flags : UInt
  table : StateTable
  substitutions : ContextualSubstitutions
} derive(Eq, Show, ToJson)

///|
pub(all) struct LigatureSubtable {
  coverage_flags : Int
  sub_feature_flags : UInt
  table : StateTable
  lig_actions : Array[UInt]
  components : Array[UInt]
  ligatures : Array[UInt]
  lig_action_offset : Int
  component_offset_words : Int
  ligature_offset : Int
} derive(Eq, Show, ToJson)

///|
pub(all) struct InsertionSubtable {
  coverage_flags : Int
  sub_feature_flags : UInt
  table : StateTable
  insertion_action : Array[UInt]
} derive(Eq, Show, ToJson)

///|
pub(all) enum MorxSubtable {
  Noncontextual(NoncontextualSubtable)
  Rearrangement(RearrangementSubtable)
  Contextual(ContextualSubtable)
  Ligature(LigatureSubtable)
  Insertion(InsertionSubtable)
} derive(Eq, Show, ToJson)

///|
pub struct MorxTable {
  version : Int
  subtables : Array[MorxSubtable]
} derive(Eq, Show, ToJson)

///|
pub struct MortTable {
  version : Int
  subtables : Array[MorxSubtable]
} derive(Eq, Show, ToJson)

fn coverage_flags_from(coverage : UInt, extended : Bool) -> Int {
  if extended {
    ((coverage >> 24) & 0xffU).reinterpret_as_int()
  } else {
    ((coverage >> 8) & 0xffU).reinterpret_as_int()
  }
}

fn coverage_type_from(coverage : UInt) -> Int {
  (coverage & 0xffU).reinterpret_as_int()
}

fn coverage_allows(flags : Int, horizontal : Bool) -> Bool {
  let all_directions = (flags & 0x20) != 0
  if all_directions {
    return true
  }
  let vertical = (flags & 0x80) != 0
  if horizontal { !vertical } else { vertical }
}

fn NoncontextualSubtable::apply(
  self : NoncontextualSubtable,
  glyphs : Array[UInt],
  horizontal : Bool,
) -> Bool {
  if !coverage_allows(self.coverage_flags, horizontal) {
    return false
  }
  let mut changed = false
  for i in 0..<glyphs.length() {
    let glyph = glyphs[i]
    match self.lookup.value_for(glyph) {
      None => ()
      Some(value) => {
        if value != glyph {
          glyphs[i] = value
          changed = true
        }
      }
    }
  }
  changed
}

let rearr_mark_first = 0x8000
let rearr_dont_advance = 0x4000
let rearr_mark_last = 0x2000
let rearr_verb_mask = 0x000f

let rearrange_map : Array[Int] = [
  0x00,
  0x10,
  0x01,
  0x11,
  0x20,
  0x30,
  0x02,
  0x03,
  0x12,
  0x13,
  0x21,
  0x31,
  0x22,
  0x32,
  0x23,
  0x33,
]

fn StateTable::class_for(self : StateTable, glyph : UInt) -> Int {
  if glyph == 0xffffU {
    return 2
  }
  match self.class_table {
    Lookup(lookup) =>
      match lookup.value_for(glyph) {
        None => 1
        Some(value) => {
          let klass = value.reinterpret_as_int()
          if klass < 0 || klass >= self.n_classes { 1 } else { klass }
        }
      }
    Array(first, classes) => {
      let idx = (glyph - first).reinterpret_as_int()
      if idx < 0 || idx >= classes.length() {
        1
      } else {
        let klass = classes[idx]
        if klass < 0 || klass >= self.n_classes { 1 } else { klass }
      }
    }
  }
}

fn StateTable::entry_for(self : StateTable, state : Int, klass : Int) -> StateEntry {
  if self.n_classes <= 0 {
    return StateEntry::{ new_state: 0, flags: 0, data1: 0, data2: 0 }
  }
  let mut safe_state = state
  if safe_state < 0 {
    safe_state = 0
  }
  let mut safe_klass = klass
  if safe_klass < 0 || safe_klass >= self.n_classes {
    safe_klass = 1
  }
  let index = safe_state * self.n_classes + safe_klass
  if index < 0 || index >= self.state_array.length() {
    return StateEntry::{ new_state: 0, flags: 0, data1: 0, data2: 0 }
  }
  let entry_index = self.state_array[index]
  if entry_index < 0 || entry_index >= self.entries.length() {
    StateEntry::{ new_state: 0, flags: 0, data1: 0, data2: 0 }
  } else {
    self.entries[entry_index]
  }
}

fn StateTable::new_state(self : StateTable, raw : Int) -> Int {
  if self.n_classes <= 0 {
    return 0
  }
  if self.extended {
    raw
  } else {
    (raw - self.state_array_offset) / self.n_classes
  }
}

fn merge_clusters(clusters : Array[Int], start : Int, end : Int) -> Unit {
  if start < 0 || end > clusters.length() || start >= end {
    return ()
  }
  let mut min_cluster = clusters[start]
  for i in (start + 1)..<end {
    let value = clusters[i]
    if value < min_cluster {
      min_cluster = value
    }
  }
  for i in start..<end {
    clusters[i] = min_cluster
  }
}

fn rearrange_range(
  glyphs : Array[UInt],
  clusters : Array[Int],
  start : Int,
  end : Int,
  l : Int,
  r : Int,
  reverse_l : Bool,
  reverse_r : Bool,
) -> Unit {
  let total = end - start
  if total < l + r || total > 4 {
    return ()
  }
  let buf_glyphs : Array[UInt] = [0U, 0U, 0U, 0U]
  let buf_clusters : Array[Int] = [0, 0, 0, 0]
  for i in 0..<l {
    buf_glyphs[i] = glyphs[start + i]
    buf_clusters[i] = clusters[start + i]
  }
  for i in 0..<r {
    buf_glyphs[2 + i] = glyphs[end - r + i]
    buf_clusters[2 + i] = clusters[end - r + i]
  }
  if l != r {
    let middle_len = total - l - r
    if middle_len > 0 {
      let temp_glyphs : Array[UInt] = []
      let temp_clusters : Array[Int] = []
      for i in 0..<middle_len {
        temp_glyphs.push(glyphs[start + l + i])
        temp_clusters.push(clusters[start + l + i])
      }
      for i in 0..<middle_len {
        glyphs[start + r + i] = temp_glyphs[i]
        clusters[start + r + i] = temp_clusters[i]
      }
    }
  }
  for i in 0..<r {
    glyphs[start + i] = buf_glyphs[2 + i]
    clusters[start + i] = buf_clusters[2 + i]
  }
  for i in 0..<l {
    glyphs[end - l + i] = buf_glyphs[i]
    clusters[end - l + i] = buf_clusters[i]
  }
  if reverse_l && l >= 2 {
    let g = glyphs[end - 1]
    glyphs[end - 1] = glyphs[end - 2]
    glyphs[end - 2] = g
    let c = clusters[end - 1]
    clusters[end - 1] = clusters[end - 2]
    clusters[end - 2] = c
  }
  if reverse_r && r >= 2 {
    let g = glyphs[start]
    glyphs[start] = glyphs[start + 1]
    glyphs[start + 1] = g
    let c = clusters[start]
    clusters[start] = clusters[start + 1]
    clusters[start + 1] = c
  }
}

fn RearrangementSubtable::apply(
  self : RearrangementSubtable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  if !coverage_allows(self.coverage_flags, horizontal) {
    return false
  }
  if glyphs.length() != clusters.length() {
    return false
  }
  let table = self.table
  if table.n_classes <= 0 {
    return false
  }
  let mut changed = false
  let mut state = 0
  let mut idx = 0
  let len = glyphs.length()
  let mut start = 0
  let mut end = 0
  while true {
    let klass = if idx < len {
      table.class_for(glyphs[idx])
    } else {
      0
    }
    let entry = table.entry_for(state, klass)
    let flags = entry.flags
    if (flags & rearr_mark_first) != 0 {
      start = idx
    }
    if (flags & rearr_mark_last) != 0 {
      end = if idx + 1 < len { idx + 1 } else { len }
    }
    let verb = flags & rearr_verb_mask
    if verb != 0 && start < end {
      let m = rearrange_map[verb]
      let l = if (m >> 4) < 2 { m >> 4 } else { 2 }
      let r = if (m & 0xf) < 2 { m & 0xf } else { 2 }
      let reverse_l = (m >> 4) == 3
      let reverse_r = (m & 0xf) == 3
      if end - start >= l + r && end - start <= 4 {
        merge_clusters(clusters, start, if idx + 1 < len { idx + 1 } else { len })
        merge_clusters(clusters, start, end)
        rearrange_range(glyphs, clusters, start, end, l, r, reverse_l, reverse_r)
        changed = true
      }
    }
    state = table.new_state(entry.new_state)
    if idx >= len {
      break
    }
    if (flags & rearr_dont_advance) == 0 {
      idx = idx + 1
    }
  }
  changed
}

let contextual_set_mark = 0x8000
let contextual_dont_advance = 0x4000

fn contextual_replacement(
  substitutions : ContextualSubstitutions,
  index : Int,
  glyph : UInt,
) -> UInt? {
  match substitutions {
    Lookups(lookups) => {
      if index < 0 || index >= lookups.length() {
        None
      } else {
        lookups[index].value_for(glyph)
      }
    }
    Values(base_word, values) => {
      let glyph_int = glyph.reinterpret_as_int()
      let word_index = index + glyph_int
      let value_index = word_index - base_word
      if value_index < 0 || value_index >= values.length() {
        None
      } else {
        let value = values[value_index]
        if value == 0U { None } else { Some(value) }
      }
    }
  }
}

fn ContextualSubtable::apply(
  self : ContextualSubtable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  if !coverage_allows(self.coverage_flags, horizontal) {
    return false
  }
  if glyphs.length() != clusters.length() {
    return false
  }
  let table = self.table
  if table.n_classes <= 0 {
    return false
  }
  let mut changed = false
  let mut state = 0
  let mut idx = 0
  let len = glyphs.length()
  let mut mark = 0
  let mut mark_set = false
  while true {
    let klass = if idx < len {
      table.class_for(glyphs[idx])
    } else {
      0
    }
    let entry = table.entry_for(state, klass)
    let flags = entry.flags
    if !(idx >= len && !mark_set) {
      if entry.data1 != 0xffff && len > 0 {
        if mark >= 0 && mark < len {
          match contextual_replacement(self.substitutions, entry.data1, glyphs[mark]) {
            None => ()
            Some(replacement) => {
              if replacement != glyphs[mark] {
                glyphs[mark] = replacement
                changed = true
              }
            }
          }
        }
      }
      if entry.data2 != 0xffff && len > 0 {
        let current_idx = if idx < len { idx } else { len - 1 }
        if current_idx >= 0 && current_idx < len {
          match contextual_replacement(self.substitutions, entry.data2, glyphs[current_idx]) {
            None => ()
            Some(replacement) => {
              if replacement != glyphs[current_idx] {
                glyphs[current_idx] = replacement
                changed = true
              }
            }
          }
        }
      }
      if (flags & contextual_set_mark) != 0 {
        mark_set = true
        mark = if idx < len { idx } else { len }
      }
    }
    state = table.new_state(entry.new_state)
    if idx >= len {
      break
    }
    if (flags & contextual_dont_advance) == 0 {
      idx = idx + 1
    }
  }
  changed
}

let ligature_set_component = 0x8000
let ligature_dont_advance = 0x4000
let ligature_perform_action = 0x2000
let ligature_offset_mask = 0x3fff

let lig_action_last = 0x80000000U
let lig_action_store = 0x40000000U
let lig_action_offset_mask = 0x3fffffffU

fn sign_extend_30(value : UInt) -> Int {
  let mut offset = value & lig_action_offset_mask
  if (offset & 0x20000000U) != 0U {
    offset = offset | 0xC0000000U
  }
  offset.reinterpret_as_int()
}

fn shift_positions(values : Array[Int], start : Int, delta : Int) -> Unit {
  for i in 0..<values.length() {
    if values[i] >= start {
      values[i] = values[i] + delta
    }
  }
}

fn LigatureSubtable::apply(
  self : LigatureSubtable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  if !coverage_allows(self.coverage_flags, horizontal) {
    return false
  }
  if glyphs.length() != clusters.length() {
    return false
  }
  let table = self.table
  if table.n_classes <= 0 {
    return false
  }
  let mut changed = false
  let mut state = 0
  let mut idx = 0
  let match_positions : Array[Int] = []
  while true {
    let len = glyphs.length()
    let klass = if idx < len {
      table.class_for(glyphs[idx])
    } else {
      0
    }
    let entry = table.entry_for(state, klass)
    let flags = entry.flags
    if (flags & ligature_set_component) != 0 && idx < len {
      if match_positions.length() > 0 {
        let last = match_positions[match_positions.length() - 1]
        if last == idx {
          ignore(match_positions.pop())
        }
      }
      match_positions.push(idx)
    }
    let perform = if table.extended {
      (flags & ligature_perform_action) != 0
    } else {
      (flags & ligature_offset_mask) != 0
    }
    if perform {
      if match_positions.length() == 0 || idx >= len {
        ()
      } else {
        let mut action_index = if table.extended { entry.data1 } else { flags & ligature_offset_mask }
        if !table.extended {
          action_index = (action_index - self.lig_action_offset) / 4
        }
        if action_index >= 0 && action_index < self.lig_actions.length() {
          let mut cursor = match_positions.length()
          let mut ligature_idx = 0
          let mut action_pos = action_index
          while action_pos < self.lig_actions.length() {
            if cursor == 0 {
              match_positions.clear()
              break
            }
            cursor = cursor - 1
            let comp_pos = match_positions[cursor]
            if comp_pos < 0 || comp_pos >= glyphs.length() {
              action_pos = action_pos + 1
              continue
            }
            let action = self.lig_actions[action_pos]
            let offset = sign_extend_30(action)
            let glyph = glyphs[comp_pos].reinterpret_as_int()
            let component_base = glyph + offset
            let component_index = if table.extended {
              component_base
            } else {
              component_base - self.component_offset_words
            }
            if component_index < 0 || component_index >= self.components.length() {
              break
            }
            let component_value = self.components[component_index].reinterpret_as_int()
            ligature_idx = ligature_idx + component_value
            if (action & (lig_action_store | lig_action_last)) != 0U {
              let lig_index = if table.extended {
                ligature_idx
              } else {
                (ligature_idx - self.ligature_offset) / 2
              }
              if lig_index >= 0 && lig_index < self.ligatures.length() {
                let lig_glyph = self.ligatures[lig_index]
                let mut min_cluster = clusters[comp_pos]
                for i in cursor..<match_positions.length() {
                  let pos = match_positions[i]
                  if pos >= 0 && pos < clusters.length() {
                    let value = clusters[pos]
                    if value < min_cluster {
                      min_cluster = value
                    }
                  }
                }
                glyphs[comp_pos] = lig_glyph
                clusters[comp_pos] = min_cluster
                changed = true
                let mut removed = 0
                let mut j = match_positions.length() - 1
                while j > cursor {
                  let del_pos = match_positions[j]
                  if del_pos >= 0 && del_pos < glyphs.length() {
                    ignore(glyphs.remove(del_pos))
                    ignore(clusters.remove(del_pos))
                    shift_positions(match_positions, del_pos, -1)
                    if del_pos < idx {
                      idx = idx - 1
                    }
                    removed = removed + 1
                  }
                  if j == 0 { break }
                  j = j - 1
                }
                if removed > 0 {
                  match_positions.truncate(cursor + 1)
                }
              }
            }
            action_pos = action_pos + 1
            if (action & lig_action_last) != 0U {
              break
            }
          }
        }
      }
    }
    state = table.new_state(entry.new_state)
    if idx >= glyphs.length() {
      break
    }
    if (flags & ligature_dont_advance) == 0 {
      idx = idx + 1
    }
  }
  changed
}

let insertion_set_mark = 0x8000
let insertion_dont_advance = 0x4000
let _insertion_current_kashida = 0x2000
let _insertion_marked_kashida = 0x1000
let insertion_current_before = 0x0800
let insertion_marked_before = 0x0400
let insertion_current_count = 0x03e0
let insertion_marked_count = 0x001f

fn adjust_index(idx : Int, pos : Int, delta : Int) -> Int {
  if idx >= pos { idx + delta } else { idx }
}

fn insert_glyphs_from(
  glyphs : Array[UInt],
  clusters : Array[Int],
  pos : Int,
  source : Array[UInt],
  start : Int,
  count : Int,
  cluster_value : Int,
) -> Int {
  if count <= 0 {
    return 0
  }
  if start < 0 || start >= source.length() {
    return 0
  }
  let mut actual = count
  if start + actual > source.length() {
    actual = source.length() - start
  }
  if actual <= 0 {
    return 0
  }
  let mut insert_pos = pos
  if insert_pos < 0 {
    insert_pos = 0
  }
  if insert_pos > glyphs.length() {
    insert_pos = glyphs.length()
  }
  for i in 0..<actual {
    glyphs.insert(insert_pos + i, source[start + i])
    clusters.insert(insert_pos + i, cluster_value)
  }
  actual
}

fn InsertionSubtable::apply(
  self : InsertionSubtable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  if !coverage_allows(self.coverage_flags, horizontal) {
    return false
  }
  if glyphs.length() != clusters.length() {
    return false
  }
  let table = self.table
  if table.n_classes <= 0 {
    return false
  }
  let mut changed = false
  let mut state = 0
  let mut idx = 0
  let mut mark = 0
  while true {
    let len = glyphs.length()
    let klass = if idx < len {
      table.class_for(glyphs[idx])
    } else {
      0
    }
    let entry = table.entry_for(state, klass)
    let flags = entry.flags
    let mark_loc = idx
    if entry.data2 != 0xffff {
      let count = flags & insertion_marked_count
      if count > 0 {
        let start = entry.data2
        let before = (flags & insertion_marked_before) != 0
        let mark_cluster = if mark >= 0 && mark < clusters.length() { clusters[mark] } else { 0 }
        let insert_pos = if before { mark } else { mark + 1 }
        let inserted = insert_glyphs_from(
          glyphs,
          clusters,
          insert_pos,
          self.insertion_action,
          start,
          count,
          mark_cluster,
        )
        if inserted > 0 {
          changed = true
          idx = adjust_index(idx, insert_pos, inserted)
          mark = adjust_index(mark, insert_pos, inserted)
        }
      }
    }
    if (flags & insertion_set_mark) != 0 {
      mark = mark_loc
    }
    let mut inserted_before = 0
    let mut inserted_after = 0
    if entry.data1 != 0xffff {
      let count = (flags & insertion_current_count) >> 5
      if count > 0 {
        let start = entry.data1
        let before = (flags & insertion_current_before) != 0
        let current_cluster = if idx >= 0 && idx < clusters.length() { clusters[idx] } else { 0 }
        let insert_pos = if before { idx } else { idx + 1 }
        let inserted = insert_glyphs_from(
          glyphs,
          clusters,
          insert_pos,
          self.insertion_action,
          start,
          count,
          current_cluster,
        )
        if inserted > 0 {
          changed = true
          if before {
            inserted_before = inserted
          } else {
            inserted_after = inserted
          }
          idx = adjust_index(idx, insert_pos, inserted)
          mark = adjust_index(mark, insert_pos, inserted)
        }
      }
    }
    state = table.new_state(entry.new_state)
    if idx >= glyphs.length() {
      break
    }
    if (flags & insertion_dont_advance) != 0 {
      if inserted_after > 0 {
        idx = idx + 1
      } else if inserted_before > 0 {
        idx = idx - inserted_before
        if idx < 0 {
          idx = 0
        }
      }
    } else {
      idx = idx + 1 + inserted_after
    }
  }
  changed
}

fn read_count(
  data : BytesView,
  offset : Int,
  extended : Bool,
) -> Result[Int, AatError] {
  if extended {
    read_u32_non_negative(data, offset)
  } else {
    read_u16_int(data, offset)
  }
}

fn read_u8_int(data : BytesView, offset : Int) -> Result[Int, AatError] {
  if offset < 0 || offset >= data.length() {
    return Err(UnexpectedEof)
  }
  Ok(data[offset].to_int())
}

fn entry_count_from_state(state_array : Array[Int]) -> Result[Int, AatError] {
  let mut max_entry = -1
  for value in state_array {
    if value < 0 {
      return Err(InvalidFormat)
    }
    if value > max_entry {
      max_entry = value
    }
  }
  if max_entry < 0 { Ok(0) } else { Ok(max_entry + 1) }
}

fn parse_state_table(
  data : BytesView,
  extended : Bool,
  num_glyphs : Int,
  entry_data_fields : Int,
) -> Result[StateTable, AatError] {
  let n_classes = read_count(data, 0, extended)
  let class_offset = read_count(data, if extended { 4 } else { 2 }, extended)
  let state_offset = read_count(data, if extended { 8 } else { 4 }, extended)
  let entry_offset = read_count(data, if extended { 12 } else { 6 }, extended)
  match (n_classes, class_offset, state_offset, entry_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(n_classes), Ok(class_offset), Ok(state_offset), Ok(entry_offset)) => {
      if n_classes < 0 {
        return Err(InvalidFormat)
      }
      if class_offset < 0 || state_offset < 0 || entry_offset < 0 {
        return Err(InvalidFormat)
      }
      if class_offset >= data.length() || state_offset >= data.length() || entry_offset > data.length() {
        return Err(UnexpectedEof)
      }
      if state_offset > entry_offset {
        return Err(InvalidFormat)
      }
      let class_table = if extended {
        let lookup = parse_lookup(data, class_offset, num_glyphs)
        match lookup {
          Err(err) => return Err(err)
          Ok(lookup) => ClassTable::Lookup(lookup)
        }
      } else {
        let first = read_u16(data, class_offset)
        let length = read_u16_int(data, class_offset + 2)
        match (first, length) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(first), Ok(length)) => {
            if length < 0 {
              return Err(InvalidFormat)
            }
            let array_start = class_offset + 4
            if array_start < 0 || array_start + length > data.length() {
              return Err(UnexpectedEof)
            }
            let classes : Array[Int] = []
            for i in 0..<length {
              let value = read_u8_int(data, array_start + i)
              match value {
                Err(err) => return Err(err)
                Ok(value) => classes.push(value)
              }
            }
            ClassTable::Array(first, classes)
          }
        }
      }
      let element_size = if extended { 2 } else { 1 }
      let state_bytes = entry_offset - state_offset
      if state_bytes < 0 || state_bytes % element_size != 0 {
        return Err(InvalidFormat)
      }
      let state_count = state_bytes / element_size
      let state_array : Array[Int] = []
      for i in 0..<state_count {
        let value = if extended {
          read_u16_int(data, state_offset + i * 2)
        } else {
          read_u8_int(data, state_offset + i)
        }
        match value {
          Err(err) => return Err(err)
          Ok(value) => state_array.push(value)
        }
      }
      let entry_bytes = data.length() - entry_offset
      if entry_bytes < 0 {
        return Err(InvalidFormat)
      }
      if entry_data_fields < 0 || entry_data_fields > 2 {
        return Err(InvalidFormat)
      }
      let entry_size = 4 + entry_data_fields * 2
      if entry_size <= 0 {
        return Err(InvalidFormat)
      }
      let entry_count = match entry_count_from_state(state_array) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if entry_offset < 0 || entry_offset + entry_count * entry_size > data.length() {
        return Err(UnexpectedEof)
      }
      let entries : Array[StateEntry] = []
      for i in 0..<entry_count {
        let base = entry_offset + i * entry_size
        let new_state = read_u16_int(data, base)
        let flags = read_u16_int(data, base + 2)
        let data1 = if entry_data_fields >= 1 { read_u16_int(data, base + 4) } else { Ok(0) }
        let data2 = if entry_data_fields >= 2 { read_u16_int(data, base + 6) } else { Ok(0) }
        match (new_state, flags, data1, data2) {
          (Err(err), _, _, _) => return Err(err)
          (_, Err(err), _, _) => return Err(err)
          (_, _, Err(err), _) => return Err(err)
          (_, _, _, Err(err)) => return Err(err)
          (Ok(new_state), Ok(flags), Ok(data1), Ok(data2)) =>
            entries.push(StateEntry::{ new_state, flags, data1, data2 })
        }
      }
      Ok(StateTable::{
        n_classes,
        class_table,
        state_array,
        entries,
        state_array_offset: state_offset,
        extended,
      })
    }
  }
}

fn parse_contextual_subtable(
  data : BytesView,
  extended : Bool,
  num_glyphs : Int,
  coverage_flags : Int,
  sub_feature_flags : UInt,
) -> Result[MorxSubtable, AatError] {
  let table = match parse_state_table(data, extended, num_glyphs, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let header_size = if extended { 16 } else { 8 }
  let subs_offset = read_count(data, header_size, extended)
  let subs_offset = match subs_offset {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if subs_offset < 0 || subs_offset >= data.length() {
    return Err(UnexpectedEof)
  }
  let substitutions = if extended {
    let mut max_index = -1
    for entry in table.entries {
      if entry.data1 != 0xffff && entry.data1 > max_index {
        max_index = entry.data1
      }
      if entry.data2 != 0xffff && entry.data2 > max_index {
        max_index = entry.data2
      }
    }
    let count = if max_index < 0 { 0 } else { max_index + 1 }
    let lookups : Array[LookupTable] = []
    for i in 0..<count {
      let offset = if extended {
        read_u32_non_negative(data, subs_offset + i * 4)
      } else {
        read_u16_int(data, subs_offset + i * 2)
      }
      match offset {
        Err(err) => return Err(err)
        Ok(offset) => {
          let lookup_offset = subs_offset + offset
          if lookup_offset < 0 || lookup_offset >= data.length() {
            return Err(UnexpectedEof)
          }
          let lookup = match parse_lookup(data, lookup_offset, num_glyphs) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          lookups.push(lookup)
        }
      }
    }
    ContextualSubstitutions::Lookups(lookups)
  } else {
    if (subs_offset & 1) != 0 {
      return Err(InvalidFormat)
    }
    let bytes_len = data.length() - subs_offset
    if bytes_len < 0 || (bytes_len & 1) != 0 {
      return Err(InvalidFormat)
    }
    let count = bytes_len / 2
    let values : Array[UInt] = []
    for i in 0..<count {
      let value = read_u16(data, subs_offset + i * 2)
      match value {
        Err(err) => return Err(err)
        Ok(value) => values.push(value)
      }
    }
    ContextualSubstitutions::Values(subs_offset / 2, values)
  }
  Ok(
    MorxSubtable::Contextual(
      ContextualSubtable::{
        coverage_flags,
        sub_feature_flags,
        table,
        substitutions,
      },
    ),
  )
}

fn parse_ligature_subtable(
  data : BytesView,
  extended : Bool,
  num_glyphs : Int,
  coverage_flags : Int,
  sub_feature_flags : UInt,
) -> Result[MorxSubtable, AatError] {
  let table = match parse_state_table(data, extended, num_glyphs, if extended { 1 } else { 0 }) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let header_size = if extended { 16 } else { 8 }
  let lig_action_offset = read_count(data, header_size, extended)
  let component_offset = read_count(data, header_size + (if extended { 4 } else { 2 }), extended)
  let ligature_offset = read_count(data, header_size + (if extended { 8 } else { 4 }), extended)
  let (lig_action_offset, component_offset, ligature_offset) =
    match (lig_action_offset, component_offset, ligature_offset) {
      (Err(err), _, _) => return Err(err)
      (_, Err(err), _) => return Err(err)
      (_, _, Err(err)) => return Err(err)
      (Ok(lig_action_offset), Ok(component_offset), Ok(ligature_offset)) =>
        (lig_action_offset, component_offset, ligature_offset)
    }
  if lig_action_offset <= 0 || component_offset <= 0 || ligature_offset <= 0 {
    return Err(InvalidFormat)
  }
  if lig_action_offset >= data.length() ||
     component_offset >= data.length() ||
     ligature_offset >= data.length() {
    return Err(UnexpectedEof)
  }
  if (component_offset & 1) != 0 {
    return Err(InvalidFormat)
  }
  let mut lig_action_end = data.length()
  if component_offset > lig_action_offset && component_offset < lig_action_end {
    lig_action_end = component_offset
  }
  if ligature_offset > lig_action_offset && ligature_offset < lig_action_end {
    lig_action_end = ligature_offset
  }
  if lig_action_end <= lig_action_offset {
    return Err(InvalidFormat)
  }
  let mut component_end = data.length()
  if lig_action_offset > component_offset && lig_action_offset < component_end {
    component_end = lig_action_offset
  }
  if ligature_offset > component_offset && ligature_offset < component_end {
    component_end = ligature_offset
  }
  if component_end <= component_offset {
    return Err(InvalidFormat)
  }
  let mut ligature_end = data.length()
  if lig_action_offset > ligature_offset && lig_action_offset < ligature_end {
    ligature_end = lig_action_offset
  }
  if component_offset > ligature_offset && component_offset < ligature_end {
    ligature_end = component_offset
  }
  if ligature_end <= ligature_offset {
    return Err(InvalidFormat)
  }
  let lig_action_bytes = lig_action_end - lig_action_offset
  if lig_action_bytes < 0 || (lig_action_bytes & 3) != 0 {
    return Err(InvalidFormat)
  }
  let lig_action_count = lig_action_bytes / 4
  let lig_actions : Array[UInt] = []
  for i in 0..<lig_action_count {
    let value = read_u32(data, lig_action_offset + i * 4)
    match value {
      Err(err) => return Err(err)
      Ok(value) => lig_actions.push(value)
    }
  }
  let component_bytes = component_end - component_offset
  if component_bytes < 0 || (component_bytes & 1) != 0 {
    return Err(InvalidFormat)
  }
  let component_count = component_bytes / 2
  let components : Array[UInt] = []
  for i in 0..<component_count {
    let value = read_u16(data, component_offset + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => components.push(value)
    }
  }
  let ligature_bytes = ligature_end - ligature_offset
  if ligature_bytes < 0 || (ligature_bytes & 1) != 0 {
    return Err(InvalidFormat)
  }
  let ligature_count = ligature_bytes / 2
  let ligatures : Array[UInt] = []
  for i in 0..<ligature_count {
    let value = read_u16(data, ligature_offset + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => ligatures.push(value)
    }
  }
  Ok(
    MorxSubtable::Ligature(
      LigatureSubtable::{
        coverage_flags,
        sub_feature_flags,
        table,
        lig_actions,
        components,
        ligatures,
        lig_action_offset,
        component_offset_words: component_offset / 2,
        ligature_offset,
      },
    ),
  )
}

fn parse_insertion_subtable(
  data : BytesView,
  extended : Bool,
  num_glyphs : Int,
  coverage_flags : Int,
  sub_feature_flags : UInt,
) -> Result[MorxSubtable, AatError] {
  let table = match parse_state_table(data, extended, num_glyphs, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let header_size = if extended { 16 } else { 8 }
  let insertion_offset = read_count(data, header_size, extended)
  let insertion_offset = match insertion_offset {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if insertion_offset < 0 || insertion_offset >= data.length() {
    return Err(UnexpectedEof)
  }
  if (insertion_offset & 1) != 0 {
    return Err(InvalidFormat)
  }
  let bytes_len = data.length() - insertion_offset
  if bytes_len < 0 || (bytes_len & 1) != 0 {
    return Err(InvalidFormat)
  }
  let count = bytes_len / 2
  let insertion_action : Array[UInt] = []
  for i in 0..<count {
    let value = read_u16(data, insertion_offset + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => insertion_action.push(value)
    }
  }
  Ok(
    MorxSubtable::Insertion(
      InsertionSubtable::{
        coverage_flags,
        sub_feature_flags,
        table,
        insertion_action,
      },
    ),
  )
}

fn parse_chain(
  data : BytesView,
  offset : Int,
  extended : Bool,
  num_glyphs : Int,
) -> Result[(Array[MorxSubtable], Int), AatError] {
  let default_flags = read_u32_int(data, offset)
  let length = read_u32_non_negative(data, offset + 4)
  match (default_flags, length) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(_), Ok(length)) => {
      let header_size = if extended { 16 } else { 12 }
      if length < header_size {
        return Err(InvalidFormat)
      }
      if offset < 0 || offset + length > data.length() {
        return Err(UnexpectedEof)
      }
      let feature_count = read_count(data, offset + 8, extended)
      let subtable_count = if extended {
        read_count(data, offset + 12, extended)
      } else {
        read_count(data, offset + 10, extended)
      }
      match (feature_count, subtable_count) {
        (Err(err), _) => Err(err)
        (_, Err(err)) => Err(err)
        (Ok(feature_count), Ok(subtable_count)) => {
          if feature_count < 0 || subtable_count < 0 {
            return Err(InvalidFormat)
          }
          let feature_bytes = feature_count * 12
          let mut subtable_offset = offset + header_size + feature_bytes
          if subtable_offset < 0 || subtable_offset > offset + length {
            return Err(UnexpectedEof)
          }
          let subtables : Array[MorxSubtable] = []
          for _ in 0..<subtable_count {
            let sub_length = if extended {
              read_u32_non_negative(data, subtable_offset)
            } else {
              read_u16_int(data, subtable_offset)
            }
            let coverage = if extended {
              read_u32_int(data, subtable_offset + 4)
            } else {
              read_u16_int(data, subtable_offset + 2)
            }
            let sub_feature_flags = if extended {
              read_u32(data, subtable_offset + 8)
            } else {
              read_u32(data, subtable_offset + 4)
            }
            match (sub_length, coverage, sub_feature_flags) {
              (Err(err), _, _) => return Err(err)
              (_, Err(err), _) => return Err(err)
              (_, _, Err(err)) => return Err(err)
              (Ok(sub_length), Ok(coverage), Ok(sub_feature_flags)) => {
                let header_size = if extended { 12 } else { 8 }
                if sub_length < header_size {
                  return Err(InvalidFormat)
                }
                let sub_end = subtable_offset + sub_length
                if subtable_offset < 0 || sub_end > offset + length || sub_end > data.length() {
                  return Err(UnexpectedEof)
                }
                let coverage_u = coverage.reinterpret_as_uint()
                let sub_type = coverage_type_from(coverage_u)
                let flags = coverage_flags_from(coverage_u, extended)
                if sub_type == subtable_type_noncontextual {
                  let sub_data = data[subtable_offset + header_size:sub_end]
                  let lookup = parse_lookup(sub_data, 0, num_glyphs)
                  match lookup {
                    Err(err) => return Err(err)
                    Ok(lookup) => {
                      subtables.push(
                        MorxSubtable::Noncontextual(
                          NoncontextualSubtable::{
                            coverage_flags: flags,
                            sub_feature_flags,
                            lookup,
                          },
                        ),
                      )
                    }
                  }
                } else if sub_type == subtable_type_rearrangement {
                  let sub_data = data[subtable_offset + header_size:sub_end]
                  let table = parse_state_table(sub_data, extended, num_glyphs, 0)
                  match table {
                    Err(err) => return Err(err)
                    Ok(table) =>
                      subtables.push(
                        MorxSubtable::Rearrangement(
                          RearrangementSubtable::{
                            coverage_flags: flags,
                            sub_feature_flags,
                            table,
                          },
                        ),
                      )
                  }
                } else if sub_type == subtable_type_contextual {
                  let sub_data = data[subtable_offset + header_size:sub_end]
                  let contextual = parse_contextual_subtable(
                    sub_data,
                    extended,
                    num_glyphs,
                    flags,
                    sub_feature_flags,
                  )
                  match contextual {
                    Err(err) => return Err(err)
                    Ok(contextual) => subtables.push(contextual)
                  }
                } else if sub_type == subtable_type_ligature {
                  let sub_data = data[subtable_offset + header_size:sub_end]
                  let ligature = parse_ligature_subtable(
                    sub_data,
                    extended,
                    num_glyphs,
                    flags,
                    sub_feature_flags,
                  )
                  match ligature {
                    Err(err) => return Err(err)
                    Ok(ligature) => subtables.push(ligature)
                  }
                } else if sub_type == subtable_type_insertion {
                  let sub_data = data[subtable_offset + header_size:sub_end]
                  let insertion = parse_insertion_subtable(
                    sub_data,
                    extended,
                    num_glyphs,
                    flags,
                    sub_feature_flags,
                  )
                  match insertion {
                    Err(err) => return Err(err)
                    Ok(insertion) => subtables.push(insertion)
                  }
                }
                subtable_offset = sub_end
              }
            }
          }
          Ok((subtables, length))
        }
      }
    }
  }
}

fn parse_mort_morx(
  data : BytesView,
  extended : Bool,
  num_glyphs : Int,
) -> Result[(Int, Array[MorxSubtable]), AatError] {
  let version = read_u16_int(data, 0)
  let chain_count = read_u32_non_negative(data, 4)
  match (version, chain_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(chain_count)) => {
      let subtables : Array[MorxSubtable] = []
      let mut chain_offset = 8
      for _ in 0..<chain_count {
        let parsed = parse_chain(data, chain_offset, extended, num_glyphs)
        match parsed {
          Err(err) => return Err(err)
          Ok((chain_subtables, length)) => {
            for subtable in chain_subtables {
              subtables.push(subtable)
            }
            chain_offset = chain_offset + length
          }
        }
      }
      Ok((version, subtables))
    }
  }
}

///|
pub fn MorxTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[MorxTable, AatError] {
  match parse_mort_morx(data, true, num_glyphs) {
    Err(err) => Err(err)
    Ok((version, subtables)) => Ok(MorxTable::{ version, subtables })
  }
}

///|
pub fn MortTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[MortTable, AatError] {
  match parse_mort_morx(data, false, num_glyphs) {
    Err(err) => Err(err)
    Ok((version, subtables)) => Ok(MortTable::{ version, subtables })
  }
}

///|
pub fn MorxTable::has_data(self : MorxTable) -> Bool {
  self.version != 0
}

///|
pub fn MortTable::has_data(self : MortTable) -> Bool {
  self.version != 0
}

fn MorxSubtable::apply(
  self : MorxSubtable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  match self {
    Noncontextual(subtable) => subtable.apply(glyphs, horizontal)
    Rearrangement(subtable) => subtable.apply(glyphs, clusters, horizontal)
    Contextual(subtable) => subtable.apply(glyphs, clusters, horizontal)
    Ligature(subtable) => subtable.apply(glyphs, clusters, horizontal)
    Insertion(subtable) => subtable.apply(glyphs, clusters, horizontal)
  }
}

///|
pub fn MorxTable::apply(
  self : MorxTable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  let mut changed = false
  for subtable in self.subtables {
    if subtable.apply(glyphs, clusters, horizontal) {
      changed = true
    }
  }
  changed
}

///|
pub fn MortTable::apply(
  self : MortTable,
  glyphs : Array[UInt],
  clusters : Array[Int],
  horizontal : Bool,
) -> Bool {
  let mut changed = false
  for subtable in self.subtables {
    if subtable.apply(glyphs, clusters, horizontal) {
      changed = true
    }
  }
  changed
}
