let subtable_type_rearrangement = 0
let subtable_type_noncontextual = 4

///|
pub(all) struct NoncontextualSubtable {
  coverage_flags : Int
  sub_feature_flags : UInt
  lookup : LookupTable
} derive(Eq, Show, ToJson)

///|
pub(all) struct RearrangementEntry {
  new_state : Int
  flags : Int
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
  entries : Array[RearrangementEntry]
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
pub(all) enum MorxSubtable {
  Noncontextual(NoncontextualSubtable)
  Rearrangement(RearrangementSubtable)
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

fn StateTable::entry_for(self : StateTable, state : Int, klass : Int) -> RearrangementEntry {
  if self.n_classes <= 0 {
    return RearrangementEntry::{ new_state: 0, flags: 0 }
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
    return RearrangementEntry::{ new_state: 0, flags: 0 }
  }
  let entry_index = self.state_array[index]
  if entry_index < 0 || entry_index >= self.entries.length() {
    RearrangementEntry::{ new_state: 0, flags: 0 }
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

fn parse_state_table(
  data : BytesView,
  extended : Bool,
  num_glyphs : Int,
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
      let entry_size = 4
      if entry_bytes < 0 {
        return Err(InvalidFormat)
      }
      let entry_count = entry_bytes / entry_size
      let entries : Array[RearrangementEntry] = []
      for i in 0..<entry_count {
        let new_state = read_u16_int(data, entry_offset + i * entry_size)
        let flags = read_u16_int(data, entry_offset + i * entry_size + 2)
        match (new_state, flags) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(new_state), Ok(flags)) =>
            entries.push(RearrangementEntry::{ new_state, flags })
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
                  let table = parse_state_table(sub_data, extended, num_glyphs)
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
