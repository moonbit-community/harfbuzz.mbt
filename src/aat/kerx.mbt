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

let coverage_vertical = 0x80000000U
let coverage_cross_stream = 0x40000000U
let coverage_backwards = 0x10000000U
let coverage_type_mask = 0xffU

///|
pub struct KerxPair {
  left : UInt
  right : UInt
  value : Int
} derive(Eq, Show, ToJson)

///|
pub struct KerxFormat1 {
  table : StateTable
  actions : Array[Int]
} derive(Show, ToJson)

///|
pub struct KerxFormat2 {
  row_width : Int
  left : LookupTable
  right : LookupTable
  values : Array[Int]
} derive(Show, ToJson)

///|
pub struct KerxFormat4 {
  table : StateTable
  flags : UInt
  actions : Array[Int]
} derive(Show, ToJson)

///|
pub struct KerxFormat6 {
  row_index : LookupTable
  column_index : LookupTable
  values : Array[Int]
  long_values : Bool
} derive(Show, ToJson)

///|
pub struct KerxAdjustment {
  x_advance : Int
  y_advance : Int
  x_offset : Int
  y_offset : Int
} derive(Eq, Show, ToJson)

///|
pub struct KerxSubtableHeader {
  coverage : UInt
  tuple_count : Int
} derive(Eq, Show, ToJson)

///|
pub enum KerxSubtable {
  Format0(KerxSubtableHeader, Array[KerxPair])
  Format1(KerxSubtableHeader, KerxFormat1)
  Format2(KerxSubtableHeader, KerxFormat2)
  Format4(KerxSubtableHeader, KerxFormat4)
  Format6(KerxSubtableHeader, KerxFormat6)
} derive(Show, ToJson)

///|
pub struct KerxTable {
  version : Int
  subtables : Array[KerxSubtable]
} derive(Show, ToJson)

fn coverage_type(coverage : UInt) -> Int {
  (coverage & coverage_type_mask).reinterpret_as_int()
}

fn coverage_is_horizontal(coverage : UInt) -> Bool {
  (coverage & coverage_vertical) == 0U
}

fn coverage_is_cross_stream(coverage : UInt) -> Bool {
  (coverage & coverage_cross_stream) != 0U
}

fn coverage_is_backwards(coverage : UInt) -> Bool {
  (coverage & coverage_backwards) != 0U
}

fn resolve_tuple_value(
  data : BytesView,
  base : Int,
  tuple_count : Int,
  value : Int,
) -> Int {
  if tuple_count <= 0 {
    return value
  }
  if value < 0 {
    return 0
  }
  let offset = base + value
  if offset < 0 || offset + tuple_count * 2 > data.length() {
    return 0
  }
  match read_i16(data, offset) {
    Err(_) => 0
    Ok(v) => v
  }
}

fn scale_value(value : Int, scale : Int, upem : Int) -> Int {
  if upem == 0 { value } else { (value * scale) / upem }
}

fn make_adjustments(len : Int) -> Array[KerxAdjustment] {
  let adjustments : Array[KerxAdjustment] = []
  for _ in 0..<len {
    adjustments.push(
      KerxAdjustment::{
        x_advance: 0,
        y_advance: 0,
        x_offset: 0,
        y_offset: 0,
      },
    )
  }
  adjustments
}

fn parse_kerx_format0(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
) -> Result[KerxSubtable, AatError] {
  let pair_count = read_u32_non_negative(data, offset + 12)
  match pair_count {
    Err(err) => Err(err)
    Ok(pair_count) => {
      let pair_base = offset + 28
      if pair_base < 0 || pair_base + pair_count * 6 > offset + length {
        return Err(UnexpectedEof)
      }
      let pairs : Array[KerxPair] = []
      for i in 0..<pair_count {
        let rec_offset = pair_base + i * 6
        let left = read_u16(data, rec_offset)
        let right = read_u16(data, rec_offset + 2)
        let value = read_i16(data, rec_offset + 4)
        match (left, right, value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(left), Ok(right), Ok(value)) => {
            let resolved = resolve_tuple_value(data, offset, header.tuple_count, value)
            pairs.push(KerxPair::{ left, right, value: resolved })
          }
        }
      }
      Ok(KerxSubtable::Format0(header, pairs))
    }
  }
}

fn parse_kerx_format1(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
  num_glyphs : Int,
) -> Result[KerxSubtable, AatError] {
  let machine_start = offset + 12
  let table_end = offset + length
  if machine_start < 0 || machine_start + 20 > table_end {
    return Err(UnexpectedEof)
  }
  let machine_data = data[machine_start:table_end]
  let table = match parse_state_table(machine_data, true, num_glyphs, 1) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let action_offset = read_u32_non_negative(data, machine_start + 16)
  let action_offset = match action_offset {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let action_base = machine_start + action_offset
  if action_base < machine_start || action_base > table_end {
    return Err(UnexpectedEof)
  }
  let bytes_len = table_end - action_base
  if bytes_len < 0 || (bytes_len & 1) != 0 {
    return Err(InvalidFormat)
  }
  let action_count = bytes_len / 2
  let actions : Array[Int] = []
  for i in 0..<action_count {
    let value = read_i16(data, action_base + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => actions.push(value)
    }
  }
  Ok(KerxSubtable::Format1(header, KerxFormat1::{ table, actions }))
}

fn parse_kerx_format2(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
  num_glyphs : Int,
) -> Result[KerxSubtable, AatError] {
  let row_width = read_u32_non_negative(data, offset + 12)
  let left_offset = read_u32_non_negative(data, offset + 16)
  let right_offset = read_u32_non_negative(data, offset + 20)
  let array_offset = read_u32_non_negative(data, offset + 24)
  match (row_width, left_offset, right_offset, array_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(row_width), Ok(left_offset), Ok(right_offset), Ok(array_offset)) => {
      if row_width <= 0 || (row_width & 1) != 0 {
        return Err(InvalidFormat)
      }
      let left_table = match parse_lookup(data, offset + left_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let right_table = match parse_lookup(data, offset + right_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let array_base = offset + array_offset
      if array_base < 0 || array_base > offset + length {
        return Err(UnexpectedEof)
      }
      let bytes_len = offset + length - array_base
      if bytes_len < 0 || (bytes_len & 1) != 0 {
        return Err(InvalidFormat)
      }
      let value_count = bytes_len / 2
      let values : Array[Int] = []
      for i in 0..<value_count {
        let value = read_i16(data, array_base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => {
            let resolved = resolve_tuple_value(data, offset, header.tuple_count, value)
            values.push(resolved)
          }
        }
      }
      Ok(
        KerxSubtable::Format2(
          header,
          KerxFormat2::{
            row_width,
            left: left_table,
            right: right_table,
            values,
          },
        ),
      )
    }
  }
}

fn parse_kerx_format4(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
  num_glyphs : Int,
) -> Result[KerxSubtable, AatError] {
  let machine_start = offset + 12
  let table_end = offset + length
  if machine_start < 0 || machine_start + 20 > table_end {
    return Err(UnexpectedEof)
  }
  let machine_data = data[machine_start:table_end]
  let table = match parse_state_table(machine_data, true, num_glyphs, 1) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let flags = read_u32(data, machine_start + 16)
  let flags = match flags {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let action_offset = (flags & 0x00FFFFFFU).reinterpret_as_int()
  let action_base = machine_start + action_offset
  if action_base < machine_start || action_base > table_end {
    return Err(UnexpectedEof)
  }
  let bytes_len = table_end - action_base
  if bytes_len < 0 || (bytes_len & 1) != 0 {
    return Err(InvalidFormat)
  }
  let action_count = bytes_len / 2
  let actions : Array[Int] = []
  for i in 0..<action_count {
    let value = read_i16(data, action_base + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => actions.push(value)
    }
  }
  Ok(KerxSubtable::Format4(header, KerxFormat4::{ table, flags, actions }))
}

fn parse_kerx_format6(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
  num_glyphs : Int,
) -> Result[KerxSubtable, AatError] {
  let flags = read_u32_int(data, offset + 12)
  let row_count = read_u16_int(data, offset + 16)
  let column_count = read_u16_int(data, offset + 18)
  let row_index_offset = read_u32_non_negative(data, offset + 20)
  let column_index_offset = read_u32_non_negative(data, offset + 24)
  let array_offset = read_u32_non_negative(data, offset + 28)
  let vector_offset = read_u32_non_negative(data, offset + 32)
  match (
    flags,
    row_count,
    column_count,
    row_index_offset,
    column_index_offset,
    array_offset,
    vector_offset,
  ) {
    (Err(err), _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(flags),
      Ok(_),
      Ok(_),
      Ok(row_index_offset),
      Ok(column_index_offset),
      Ok(array_offset),
      Ok(vector_offset),
    ) => {
      let long_values = (flags & 1) != 0
      let index_value_size = if long_values { 4 } else { 2 }
      let row_table = match parse_lookup_with_value_size(
        data,
        offset + row_index_offset,
        num_glyphs,
        index_value_size,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let column_table = match parse_lookup_with_value_size(
        data,
        offset + column_index_offset,
        num_glyphs,
        index_value_size,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let array_base = offset + array_offset
      let mut array_end = offset + length
      if vector_offset > 0 && offset + vector_offset < array_end && offset + vector_offset > array_base {
        array_end = offset + vector_offset
      }
      if array_base < 0 || array_base > array_end || array_end > offset + length {
        return Err(UnexpectedEof)
      }
      let bytes_len = array_end - array_base
      let value_size = if long_values { 4 } else { 2 }
      if bytes_len < 0 || (bytes_len % value_size) != 0 {
        return Err(InvalidFormat)
      }
      let value_count = bytes_len / value_size
      let vector_base = if vector_offset > 0 { offset + vector_offset } else { -1 }
      let values : Array[Int] = []
      for i in 0..<value_count {
        let value = if long_values {
          read_i32(data, array_base + i * 4)
        } else {
          read_i16(data, array_base + i * 2)
        }
        match value {
          Err(err) => return Err(err)
          Ok(value) => {
            let resolved =
              if header.tuple_count > 0 && vector_base >= 0 {
                resolve_tuple_value(data, vector_base, header.tuple_count, value)
              } else {
                value
              }
            values.push(resolved)
          }
        }
      }
      Ok(
        KerxSubtable::Format6(
          header,
          KerxFormat6::{
            row_index: row_table,
            column_index: column_table,
            values,
            long_values,
          },
        ),
      )
    }
  }
}

fn lookup_value(lookup : LookupTable, glyph : UInt) -> Int {
  match lookup.value_for(glyph) {
    None => 0
    Some(value) => value.reinterpret_as_int()
  }
}

fn KerxSubtable::value_for(
  self : KerxSubtable,
  left : UInt,
  right : UInt,
) -> Int {
  match self {
    Format0(_, pairs) => {
      for pair in pairs {
        if pair.left == left && pair.right == right {
          return pair.value
        }
      }
      0
    }
    Format2(_, format2) => {
      let left_value = lookup_value(format2.left, left)
      let right_value = lookup_value(format2.right, right)
      let index = left_value + right_value
      if index < 0 || index >= format2.values.length() {
        0
      } else {
        format2.values[index]
      }
    }
    Format6(_, format6) => {
      let left_value = lookup_value(format6.row_index, left)
      let right_value = lookup_value(format6.column_index, right)
      let index = left_value + right_value
      if index < 0 || index >= format6.values.length() {
        0
      } else {
        format6.values[index]
      }
    }
    Format1(_, _) => 0
    Format4(_, _) => 0
  }
}

fn KerxSubtable::header(self : KerxSubtable) -> KerxSubtableHeader {
  match self {
    Format0(header, _) => header
    Format1(header, _) => header
    Format2(header, _) => header
    Format4(header, _) => header
    Format6(header, _) => header
  }
}

///|
pub fn KerxTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[KerxTable, AatError] {
  let version = read_u16_int(data, 0)
  let table_count = read_u32_non_negative(data, 4)
  match (version, table_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(table_count)) => {
      let mut offset = 8
      let subtables : Array[KerxSubtable] = []
      for _ in 0..<table_count {
        let length = read_u32_non_negative(data, offset)
        let coverage = read_u32(data, offset + 4)
        let tuple_count = read_u32_non_negative(data, offset + 8)
        match (length, coverage, tuple_count) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(length), Ok(coverage), Ok(tuple_count)) => {
            if length < 12 || offset + length > data.length() {
              return Err(UnexpectedEof)
            }
            let header = KerxSubtableHeader::{ coverage, tuple_count }
            let sub_type = coverage_type(coverage)
            if sub_type == 0 {
              let subtable = match parse_kerx_format0(data, offset, length, header) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if sub_type == 1 {
              let subtable = match parse_kerx_format1(
                data,
                offset,
                length,
                header,
                num_glyphs,
              ) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if sub_type == 2 {
              let subtable = match parse_kerx_format2(data, offset, length, header, num_glyphs) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if sub_type == 4 {
              let subtable = match parse_kerx_format4(
                data,
                offset,
                length,
                header,
                num_glyphs,
              ) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if sub_type == 6 {
              let subtable = match parse_kerx_format6(data, offset, length, header, num_glyphs) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            }
            offset = offset + length
          }
        }
      }
      Ok(KerxTable::{ version, subtables })
    }
  }
}

///|
pub fn KerxTable::has_data(self : KerxTable) -> Bool {
  self.version != 0
}

///|
pub fn KerxTable::kern_value(
  self : KerxTable,
  left : UInt,
  right : UInt,
  horizontal : Bool,
) -> Int {
  let mut value = 0
  for subtable in self.subtables {
    let header = subtable.header()
    if coverage_is_cross_stream(header.coverage) || coverage_is_backwards(header.coverage) {
      continue
    }
    if horizontal != coverage_is_horizontal(header.coverage) {
      continue
    }
    let kern = subtable.value_for(left, right)
    if kern != 0 {
      value = value + kern
    }
  }
  value
}

fn map_index(idx : Int, len : Int, backwards : Bool) -> Int {
  if backwards { len - 1 - idx } else { idx }
}

fn apply_pair_kerning(
  subtable : KerxSubtable,
  header : KerxSubtableHeader,
  glyphs : Array[UInt],
  horizontal : Bool,
  scale : Int,
  upem : Int,
  adjustments : Array[KerxAdjustment],
) -> Bool {
  if glyphs.length() < 2 {
    return false
  }
  let cross_stream = coverage_is_cross_stream(header.coverage)
  let mut changed = false
  for i in 0..<(glyphs.length() - 1) {
    let kern = subtable.value_for(glyphs[i], glyphs[i + 1])
    if kern == 0 {
      continue
    }
    let scaled = scale_value(kern, scale, upem)
    if scaled == 0 {
      continue
    }
    changed = true
    if cross_stream {
      let right = adjustments[i + 1]
      adjustments[i + 1] = if horizontal {
        KerxAdjustment::{
          x_advance: right.x_advance,
          y_advance: right.y_advance,
          x_offset: right.x_offset,
          y_offset: right.y_offset + scaled,
        }
      } else {
        KerxAdjustment::{
          x_advance: right.x_advance,
          y_advance: right.y_advance,
          x_offset: right.x_offset + scaled,
          y_offset: right.y_offset,
        }
      }
    } else {
      let kern1 = scaled >> 1
      let kern2 = scaled - kern1
      let left = adjustments[i]
      let right = adjustments[i + 1]
      if horizontal {
        adjustments[i] = KerxAdjustment::{
          x_advance: left.x_advance + kern1,
          y_advance: left.y_advance,
          x_offset: left.x_offset,
          y_offset: left.y_offset,
        }
        adjustments[i + 1] = KerxAdjustment::{
          x_advance: right.x_advance + kern2,
          y_advance: right.y_advance,
          x_offset: right.x_offset + kern2,
          y_offset: right.y_offset,
        }
      } else {
        adjustments[i] = KerxAdjustment::{
          x_advance: left.x_advance,
          y_advance: left.y_advance + kern1,
          x_offset: left.x_offset,
          y_offset: left.y_offset,
        }
        adjustments[i + 1] = KerxAdjustment::{
          x_advance: right.x_advance,
          y_advance: right.y_advance + kern2,
          x_offset: right.x_offset,
          y_offset: right.y_offset + kern2,
        }
      }
    }
  }
  changed
}

let format1_push = 0x8000
let format1_dont_advance = 0x4000
let format1_reset = 0x2000

fn apply_format1(
  header : KerxSubtableHeader,
  format1 : KerxFormat1,
  glyphs : Array[UInt],
  horizontal : Bool,
  scale : Int,
  upem : Int,
  adjustments : Array[KerxAdjustment],
) -> Bool {
  if format1.table.n_classes <= 0 {
    return false
  }
  let cross_stream = coverage_is_cross_stream(header.coverage)
  let backwards = coverage_is_backwards(header.coverage)
  let stride = if header.tuple_count > 0 { header.tuple_count } else { 1 }
  let mut changed = false
  let mut state = 0
  let mut idx = 0
  let len = glyphs.length()
  let stack : Array[Int] = [0, 0, 0, 0, 0, 0, 0, 0]
  let mut depth = 0
  while true {
    let klass =
      if idx < len {
        let actual = map_index(idx, len, backwards)
        format1.table.class_for(glyphs[actual])
      } else {
        0
      }
    let entry = format1.table.entry_for(state, klass)
    let flags = entry.flags
    if (flags & format1_reset) != 0 {
      depth = 0
    }
    if (flags & format1_push) != 0 && idx < len {
      if depth < stack.length() {
        let actual = map_index(idx, len, backwards)
        stack[depth] = actual
        depth = depth + 1
      } else {
        depth = 0
      }
    }
    if entry.data1 != 0xffff && depth > 0 {
      let mut action_index = entry.data1 / 2
      let mut last = false
      while !last && depth > 0 {
        if action_index < 0 || action_index >= format1.actions.length() {
          depth = 0
          break
        }
        depth = depth - 1
        let target = stack[depth]
        let mut value = format1.actions[action_index]
        action_index = action_index + stride
        last = (value & 1) != 0
        value = value & -2
        let scaled = scale_value(value, scale, upem)
        if scaled != 0 && target >= 0 && target < adjustments.length() {
          let pos = adjustments[target]
          if cross_stream {
            adjustments[target] = if horizontal {
              KerxAdjustment::{
                x_advance: pos.x_advance,
                y_advance: pos.y_advance,
                x_offset: pos.x_offset,
                y_offset: pos.y_offset + scaled,
              }
            } else {
              KerxAdjustment::{
                x_advance: pos.x_advance,
                y_advance: pos.y_advance,
                x_offset: pos.x_offset + scaled,
                y_offset: pos.y_offset,
              }
            }
          } else {
            adjustments[target] = if horizontal {
              KerxAdjustment::{
                x_advance: pos.x_advance + scaled,
                y_advance: pos.y_advance,
                x_offset: pos.x_offset + scaled,
                y_offset: pos.y_offset,
              }
            } else {
              KerxAdjustment::{
                x_advance: pos.x_advance,
                y_advance: pos.y_advance + scaled,
                x_offset: pos.x_offset,
                y_offset: pos.y_offset + scaled,
              }
            }
          }
          changed = true
        }
      }
    }
    state = format1.table.new_state(entry.new_state)
    if idx >= len {
      break
    }
    if (flags & format1_dont_advance) == 0 {
      idx = idx + 1
    }
  }
  changed
}

let format4_mark = 0x8000
let format4_dont_advance = 0x4000

fn apply_format4(
  header : KerxSubtableHeader,
  format4 : KerxFormat4,
  glyphs : Array[UInt],
  scale_x : Int,
  scale_y : Int,
  upem : Int,
  adjustments : Array[KerxAdjustment],
  ankr : AnkrTable?,
  contour_point : (UInt, Int) -> (Int, Int)?,
) -> Bool {
  if format4.table.n_classes <= 0 {
    return false
  }
  let backwards = coverage_is_backwards(header.coverage)
  let action_type = ((format4.flags >> 30) & 0x3U).reinterpret_as_int()
  let mut changed = false
  let mut state = 0
  let mut idx = 0
  let len = glyphs.length()
  let mut mark_set = false
  let mut mark_index = 0
  while true {
    let klass =
      if idx < len {
        let actual = map_index(idx, len, backwards)
        format4.table.class_for(glyphs[actual])
      } else {
        0
      }
    let entry = format4.table.entry_for(state, klass)
    if mark_set && entry.data1 != 0xffff && idx < len {
      let actual = map_index(idx, len, backwards)
      if actual >= 0 && actual < adjustments.length() {
        if action_type == 0 {
          let base = entry.data1 * 2
          if base >= 0 && base + 1 < format4.actions.length() {
            let mark_point = format4.actions[base]
            let curr_point = format4.actions[base + 1]
            if mark_point >= 0 && curr_point >= 0 {
              let mark = contour_point(glyphs[mark_index], mark_point)
              let curr = contour_point(glyphs[actual], curr_point)
              match (mark, curr) {
                (Some((mark_x, mark_y)), Some((curr_x, curr_y))) => {
                  let dx = mark_x - curr_x
                  let dy = mark_y - curr_y
                  let pos = adjustments[actual]
                  let x_scaled = scale_value(dx, scale_x, upem)
                  let y_scaled = scale_value(dy, scale_y, upem)
                  adjustments[actual] = KerxAdjustment::{
                    x_advance: pos.x_advance,
                    y_advance: pos.y_advance,
                    x_offset: pos.x_offset + x_scaled,
                    y_offset: pos.y_offset + y_scaled,
                  }
                  changed = true
                }
                _ => ()
              }
            }
          }
        } else if action_type == 1 {
          let base = entry.data1 * 2
          if base >= 0 && base + 1 < format4.actions.length() {
            let mark_anchor = format4.actions[base]
            let curr_anchor = format4.actions[base + 1]
            if mark_anchor >= 0 && curr_anchor >= 0 {
              match ankr {
                None => ()
                Some(ankr) => {
                  let mark = ankr.get_anchor(glyphs[mark_index], mark_anchor)
                  let curr = ankr.get_anchor(glyphs[actual], curr_anchor)
                  match (mark, curr) {
                    (Some(mark), Some(curr)) => {
                      let dx = mark.x - curr.x
                      let dy = mark.y - curr.y
                      let pos = adjustments[actual]
                      let x_scaled = scale_value(dx, scale_x, upem)
                      let y_scaled = scale_value(dy, scale_y, upem)
                      adjustments[actual] = KerxAdjustment::{
                        x_advance: pos.x_advance,
                        y_advance: pos.y_advance,
                        x_offset: pos.x_offset + x_scaled,
                        y_offset: pos.y_offset + y_scaled,
                      }
                      changed = true
                    }
                    _ => ()
                  }
                }
              }
            }
          }
        } else if action_type == 2 {
          let base = entry.data1 * 4
          if base >= 0 && base + 3 < format4.actions.length() {
            let mark_x = format4.actions[base]
            let mark_y = format4.actions[base + 1]
            let curr_x = format4.actions[base + 2]
            let curr_y = format4.actions[base + 3]
            let dx = mark_x - curr_x
            let dy = mark_y - curr_y
            let pos = adjustments[actual]
            let x_scaled = scale_value(dx, scale_x, upem)
            let y_scaled = scale_value(dy, scale_y, upem)
            adjustments[actual] = KerxAdjustment::{
              x_advance: pos.x_advance,
              y_advance: pos.y_advance,
              x_offset: pos.x_offset + x_scaled,
              y_offset: pos.y_offset + y_scaled,
            }
            changed = true
          }
        }
      }
    }
    if (entry.flags & format4_mark) != 0 && idx < len {
      mark_set = true
      mark_index = map_index(idx, len, backwards)
    }
    state = format4.table.new_state(entry.new_state)
    if idx >= len {
      break
    }
    if (entry.flags & format4_dont_advance) == 0 {
      idx = idx + 1
    }
  }
  changed
}

///|
pub fn KerxTable::apply_scaled(
  self : KerxTable,
  glyphs : Array[UInt],
  horizontal : Bool,
  scale_x : Int,
  scale_y : Int,
  upem : Int,
  ankr : AnkrTable?,
  contour_point? : (UInt, Int) -> (Int, Int)? = (_, _) => None,
) -> Array[KerxAdjustment] {
  let adjustments = make_adjustments(glyphs.length())
  if self.version == 0 || glyphs.is_empty() {
    return adjustments
  }
  let primary_scale = if horizontal { scale_x } else { scale_y }
  for subtable in self.subtables {
    let header = subtable.header()
    if horizontal != coverage_is_horizontal(header.coverage) {
      continue
    }
    match subtable {
      Format0(_, _) | Format2(_, _) | Format6(_, _) => {
        if coverage_is_backwards(header.coverage) {
          continue
        }
        ignore(
          apply_pair_kerning(
            subtable,
            header,
            glyphs,
            horizontal,
            primary_scale,
            upem,
            adjustments,
          ),
        )
      }
      Format1(_, format1) =>
        ignore(
          apply_format1(
            header,
            format1,
            glyphs,
            horizontal,
            primary_scale,
            upem,
            adjustments,
          ),
        )
      Format4(_, format4) =>
        ignore(
          apply_format4(
            header,
            format4,
            glyphs,
            scale_x,
            scale_y,
            upem,
            adjustments,
            ankr,
            contour_point,
          ),
        )
    }
  }
  adjustments
}
