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
/// Kern pair record (format 0).
pub struct KernPair {
  left : UInt
  right : UInt
  value : Int
} derive(Eq, Debug, ToJson)

///|
/// Parsed kern subtable (format 0/2).
pub struct KernSubtable {
  format : Int
  horizontal : Bool
  minimum : Bool
  cross_stream : Bool
  override_flag : Bool
  pairs : Array[KernPair]
  format2 : KernSubtableFormat2?
  format3 : KernSubtableFormat3?
} derive(Debug, ToJson)

///|
/// Kern class table (format 2).
pub struct KernClassTable {
  first_glyph : Int
  classes : Array[Int]
  class_count : Int
} derive(Debug, ToJson)

///|
/// Kern subtable format 2 (class-based).
pub struct KernSubtableFormat2 {
  row_width : Int
  left : KernClassTable
  right : KernClassTable
  right_class_count : Int
  values : Array[Int]
} derive(Debug, ToJson)

///|
/// Kern subtable format 3 (class-based, byte indices).
pub struct KernSubtableFormat3 {
  glyph_count : Int
  kern_value_count : Int
  left_class_count : Int
  right_class_count : Int
  values : Array[Int]
  left_class : Array[Int]
  right_class : Array[Int]
  kern_index : Array[Int]
} derive(Debug, ToJson)

///|
/// Parsed kern table (subset).
pub struct KernTable {
  subtables : Array[KernSubtable]
} derive(Debug, ToJson)

///|
fn parse_kern_subtable_format0(
  data : BytesView,
  offset : Int,
  length : Int,
  format : Int,
  horizontal : Bool,
  minimum : Bool,
  cross_stream : Bool,
  override_flag : Bool,
) -> Result[KernSubtable, SfntError] {
  let count = read_u16_int(data, offset + 6)
  match count {
    Err(err) => Err(err)
    Ok(pair_count) => {
      if pair_count < 0 {
        return Err(InvalidFormat)
      }
      let pair_base = offset + 14
      let required = pair_base + pair_count * 6
      if required > offset + length {
        return Err(InvalidFormat)
      }
      let pairs : Array[KernPair] = []
      for i in 0..<pair_count {
        let record_offset = pair_base + i * 6
        let left = read_u16(data, record_offset)
        let right = read_u16(data, record_offset + 2)
        let value = read_i16(data, record_offset + 4)
        match (left, right, value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(left), Ok(right), Ok(value)) =>
            pairs.push(KernPair::{ left, right, value })
        }
      }
      Ok(KernSubtable::{
        format,
        horizontal,
        minimum,
        cross_stream,
        override_flag,
        pairs,
        format2: None,
        format3: None,
      })
    }
  }
}

///|
fn read_u8_int(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  if offset < 0 || offset + 1 > data.length() {
    return Err(UnexpectedEof)
  }
  Ok(u16_to_int(data[offset].to_uint()))
}

///|
fn parse_kern_class_table(
  data : BytesView,
  offset : Int,
  limit : Int,
) -> Result[KernClassTable, SfntError] {
  if offset < 0 || offset + 4 > limit {
    return Err(UnexpectedEof)
  }
  let first_glyph = read_u16_int(data, offset)
  let count = read_u16_int(data, offset + 2)
  match (first_glyph, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(first_glyph), Ok(count)) => {
      if first_glyph < 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let classes : Array[Int] = []
      let base = offset + 4
      if base + count * 2 > limit {
        return Err(UnexpectedEof)
      }
      let mut max_class = 0
      for i in 0..<count {
        let class_value = read_u16_int(data, base + i * 2)
        match class_value {
          Err(err) => return Err(err)
          Ok(class_value) => {
            classes.push(class_value)
            if class_value > max_class {
              max_class = class_value
            }
          }
        }
      }
      Ok(KernClassTable::{ first_glyph, classes, class_count: max_class + 1 })
    }
  }
}

///|
fn parse_kern_subtable_format2(
  data : BytesView,
  offset : Int,
  length : Int,
  format : Int,
  horizontal : Bool,
  minimum : Bool,
  cross_stream : Bool,
  override_flag : Bool,
) -> Result[KernSubtable, SfntError] {
  let row_width = read_u16_int(data, offset + 6)
  let left_offset = read_u16_int(data, offset + 8)
  let right_offset = read_u16_int(data, offset + 10)
  let array_offset = read_u16_int(data, offset + 12)
  match (row_width, left_offset, right_offset, array_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(row_width), Ok(left_offset), Ok(right_offset), Ok(array_offset)) => {
      if row_width <= 0 || (row_width & 1) != 0 {
        return Err(InvalidFormat)
      }
      if left_offset < 0 || right_offset < 0 || array_offset < 0 {
        return Err(InvalidFormat)
      }
      let limit = offset + length
      if offset + 14 > limit {
        return Err(UnexpectedEof)
      }
      let left = match
        parse_kern_class_table(data, offset + left_offset, limit) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let right = match
        parse_kern_class_table(data, offset + right_offset, limit) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let right_class_count = row_width / 2
      if right_class_count <= 0 {
        return Err(InvalidFormat)
      }
      let array_base = offset + array_offset
      let required = left.class_count * row_width
      if array_base < 0 || array_base + required > limit {
        return Err(UnexpectedEof)
      }
      let total_values = left.class_count * right_class_count
      let values : Array[Int] = []
      let mut cursor = array_base
      for _ in 0..<total_values {
        let value = read_i16(data, cursor)
        match value {
          Err(err) => return Err(err)
          Ok(value) => values.push(value)
        }
        cursor = cursor + 2
      }
      Ok(KernSubtable::{
        format,
        horizontal,
        minimum,
        cross_stream,
        override_flag,
        pairs: [],
        format2: Some(KernSubtableFormat2::{
          row_width,
          left,
          right,
          right_class_count,
          values,
        }),
        format3: None,
      })
    }
  }
}

///|
fn parse_kern_subtable_format3(
  data : BytesView,
  offset : Int,
  length : Int,
  format : Int,
  horizontal : Bool,
  minimum : Bool,
  cross_stream : Bool,
  override_flag : Bool,
) -> Result[KernSubtable, SfntError] {
  let glyph_count = read_u16_int(data, offset + 6)
  let kern_value_count = read_u8_int(data, offset + 8)
  let left_class_count = read_u8_int(data, offset + 9)
  let right_class_count = read_u8_int(data, offset + 10)
  let flags = read_u8_int(data, offset + 11)
  match
    (glyph_count, kern_value_count, left_class_count, right_class_count, flags) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(glyph_count),
      Ok(kern_value_count),
      Ok(left_class_count),
      Ok(right_class_count),
      Ok(_),
    ) => {
      if glyph_count < 0 ||
        kern_value_count < 0 ||
        left_class_count < 0 ||
        right_class_count < 0 {
        return Err(InvalidFormat)
      }
      if left_class_count == 0 || right_class_count == 0 {
        return Err(InvalidFormat)
      }
      let limit = offset + length
      let values_base = offset + 12
      let values_bytes = kern_value_count * 2
      if values_base < 0 || values_base + values_bytes > limit {
        return Err(UnexpectedEof)
      }
      let values : Array[Int] = []
      let mut cursor = values_base
      for _ in 0..<kern_value_count {
        let value = read_i16(data, cursor)
        match value {
          Err(err) => return Err(err)
          Ok(value) => values.push(value)
        }
        cursor = cursor + 2
      }
      let left_base = values_base + values_bytes
      let left_len = glyph_count
      if left_base < 0 || left_base + left_len > limit {
        return Err(UnexpectedEof)
      }
      let left_class : Array[Int] = []
      for i in 0..<glyph_count {
        let class_value = read_u8_int(data, left_base + i)
        match class_value {
          Err(err) => return Err(err)
          Ok(value) => left_class.push(value)
        }
      }
      let right_base = left_base + left_len
      let right_len = glyph_count
      if right_base < 0 || right_base + right_len > limit {
        return Err(UnexpectedEof)
      }
      let right_class : Array[Int] = []
      for i in 0..<glyph_count {
        let class_value = read_u8_int(data, right_base + i)
        match class_value {
          Err(err) => return Err(err)
          Ok(value) => right_class.push(value)
        }
      }
      let index_base = right_base + right_len
      let index_len = left_class_count * right_class_count
      if index_base < 0 || index_base + index_len > limit {
        return Err(UnexpectedEof)
      }
      let kern_index : Array[Int] = []
      for i in 0..<index_len {
        let idx = read_u8_int(data, index_base + i)
        match idx {
          Err(err) => return Err(err)
          Ok(value) => kern_index.push(value)
        }
      }
      Ok(KernSubtable::{
        format,
        horizontal,
        minimum,
        cross_stream,
        override_flag,
        pairs: [],
        format2: None,
        format3: Some(KernSubtableFormat3::{
          glyph_count,
          kern_value_count,
          left_class_count,
          right_class_count,
          values,
          left_class,
          right_class,
          kern_index,
        }),
      })
    }
  }
}

///|
/// Parse kern table bytes (version 0, format 0/2/3 subtables).
pub fn KernTable::parse(data : BytesView) -> Result[KernTable, SfntError] {
  let version = read_u16_int(data, 0)
  let num_tables = read_u16_int(data, 2)
  match (version, num_tables) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(count)) => {
      if version != 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let subtables : Array[KernSubtable] = []
      let mut offset = 4
      for _ in 0..<count {
        if offset + 6 > data.length() {
          return Err(UnexpectedEof)
        }
        let sub_version = read_u16_int(data, offset)
        let length = read_u16_int(data, offset + 2)
        let coverage = read_u16_int(data, offset + 4)
        match (sub_version, length, coverage) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(sub_version), Ok(length), Ok(coverage)) => {
            if sub_version != 0 || length < 6 {
              return Err(InvalidFormat)
            }
            if offset + length > data.length() {
              return Err(UnexpectedEof)
            }
            let format = (coverage >> 8) & 0xff
            let flags = coverage & 0xff
            let horizontal = (flags & 0x01) != 0
            let minimum = (flags & 0x02) != 0
            let cross_stream = (flags & 0x04) != 0
            let override_flag = (flags & 0x08) != 0
            if format == 0 {
              let subtable = match
                parse_kern_subtable_format0(
                  data, offset, length, format, horizontal, minimum, cross_stream,
                  override_flag,
                ) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if format == 2 {
              let subtable = match
                parse_kern_subtable_format2(
                  data, offset, length, format, horizontal, minimum, cross_stream,
                  override_flag,
                ) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if format == 3 {
              let subtable = match
                parse_kern_subtable_format3(
                  data, offset, length, format, horizontal, minimum, cross_stream,
                  override_flag,
                ) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            }
            offset = offset + length
          }
        }
      }
      Ok(KernTable::{ subtables, })
    }
  }
}

///|
/// Lookup kern value for a glyph pair (horizontal format 0/2/3 only).
pub fn KernTable::kern_value(
  self : KernTable,
  left : UInt,
  right : UInt,
) -> Int? {
  let mut found = false
  let mut value = 0
  for subtable in self.subtables {
    if !subtable.horizontal || subtable.cross_stream {
      continue
    }
    if subtable.format == 0 {
      let mut pair_value : Int? = None
      for pair in subtable.pairs {
        if pair.left == left && pair.right == right {
          pair_value = Some(pair.value)
          break
        }
      }
      match pair_value {
        None => ()
        Some(kern) => {
          if !found || subtable.override_flag {
            value = kern
          } else {
            value = value + kern
          }
          found = true
        }
      }
    } else if subtable.format == 2 {
      let format2 = match subtable.format2 {
        None => continue
        Some(value) => value
      }
      let left_class = kern_class_for(format2.left, left)
      let right_class = kern_class_for(format2.right, right)
      let index = left_class * format2.right_class_count + right_class
      if index < 0 || index >= format2.values.length() {
        continue
      }
      let kern = format2.values[index]
      if !found || subtable.override_flag {
        value = kern
      } else {
        value = value + kern
      }
      found = true
    } else if subtable.format == 3 {
      let format3 = match subtable.format3 {
        None => continue
        Some(value) => value
      }
      let left_class = kern_class_for_u8(
        format3.left_class,
        format3.glyph_count,
        left,
      )
      let right_class = kern_class_for_u8(
        format3.right_class,
        format3.glyph_count,
        right,
      )
      if left_class < 0 ||
        right_class < 0 ||
        left_class >= format3.left_class_count ||
        right_class >= format3.right_class_count {
        continue
      }
      let index = left_class * format3.right_class_count + right_class
      if index < 0 || index >= format3.kern_index.length() {
        continue
      }
      let value_index = format3.kern_index[index]
      if value_index < 0 || value_index >= format3.values.length() {
        continue
      }
      let kern = format3.values[value_index]
      if !found || subtable.override_flag {
        value = kern
      } else {
        value = value + kern
      }
      found = true
    }
  }
  if found {
    Some(value)
  } else {
    None
  }
}

///|
fn kern_class_for(table : KernClassTable, glyph : UInt) -> Int {
  if glyph > 0xffffU {
    return 0
  }
  let glyph_int = u16_to_int(glyph)
  let start = table.first_glyph
  let count = table.classes.length()
  if glyph_int < start || glyph_int >= start + count {
    return 0
  }
  table.classes[glyph_int - start]
}

///|
fn kern_class_for_u8(
  classes : Array[Int],
  glyph_count : Int,
  glyph : UInt,
) -> Int {
  if glyph > 0xffffU {
    return 0
  }
  let glyph_int = u16_to_int(glyph)
  if glyph_int < 0 || glyph_int >= glyph_count || glyph_int >= classes.length() {
    return 0
  }
  classes[glyph_int]
}
