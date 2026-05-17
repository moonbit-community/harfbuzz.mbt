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
pub struct VarcTable {
  version : Int
  coverage_offset : Int
  var_store_offset : Int
  condition_list_offset : Int
  axis_indices_offset : Int
  glyph_records_offset : Int
  data : Bytes
} derive(Debug, ToJson)

///|
pub enum VarcCondition {
  AxisRange(Int, Int, Int)
  Value(Int, Int)
  And(Array[VarcCondition])
  Or(Array[VarcCondition])
  Not(VarcCondition)
} derive(Debug, ToJson)

///|
struct CffIndex {
  count : Int
  off_size : Int
  offsets : Array[Int]
  data : Bytes
} derive(Debug, ToJson)

///|
fn validate_offset(offset : Int, length : Int) -> Result[Unit, VarError] {
  if offset < 0 || offset > length {
    return Err(UnexpectedEof)
  }
  Ok(())
}

///|
fn parse_condition_at(
  data : BytesView,
  base : Int,
  offset : Int,
  depth : Int,
) -> Result[VarcCondition, VarError] {
  if depth > 32 {
    return Err(InvalidFormat)
  }
  if offset <= 0 {
    return Err(InvalidFormat)
  }
  let pos = base + offset
  if pos < 0 || pos + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, pos)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      if format == 1 {
        let axis_index = read_u16_int(data, pos + 2)
        let min_value = read_i16(data, pos + 4)
        let max_value = read_i16(data, pos + 6)
        match (axis_index, min_value, max_value) {
          (Err(err), _, _) => Err(err)
          (_, Err(err), _) => Err(err)
          (_, _, Err(err)) => Err(err)
          (Ok(axis_index), Ok(min_value), Ok(max_value)) =>
            Ok(VarcCondition::AxisRange(axis_index, min_value, max_value))
        }
      } else if format == 2 {
        let default_value = read_i16(data, pos + 2)
        let var_idx = read_u32_int(data, pos + 4)
        match (default_value, var_idx) {
          (Err(err), _) => Err(err)
          (_, Err(err)) => Err(err)
          (Ok(default_value), Ok(var_idx)) =>
            Ok(VarcCondition::Value(default_value, var_idx))
        }
      } else if format == 3 || format == 4 {
        let count = read_u8_int(data, pos + 2)
        match count {
          Err(err) => Err(err)
          Ok(count) => {
            let list_base = pos + 3
            let total = count * 3
            if list_base < 0 || list_base + total > data.length() {
              return Err(UnexpectedEof)
            }
            let conditions : Array[VarcCondition] = []
            for i in 0..<count {
              let child_offset = read_cff_offset(data, list_base + i * 3, 3)
              match child_offset {
                Err(err) => return Err(err)
                Ok(child_offset) => {
                  let child = match
                    parse_condition_at(data, pos, child_offset, depth + 1) {
                    Err(err) => return Err(err)
                    Ok(value) => value
                  }
                  conditions.push(child)
                }
              }
            }
            if format == 3 {
              Ok(VarcCondition::And(conditions))
            } else {
              Ok(VarcCondition::Or(conditions))
            }
          }
        }
      } else if format == 5 {
        let child_offset = read_cff_offset(data, pos + 2, 3)
        match child_offset {
          Err(err) => Err(err)
          Ok(child_offset) =>
            match parse_condition_at(data, pos, child_offset, depth + 1) {
              Err(err) => Err(err)
              Ok(value) => Ok(VarcCondition::Not(value))
            }
        }
      } else {
        Err(InvalidFormat)
      }
  }
}

///|
pub fn VarcCondition::evaluate(
  self : VarcCondition,
  coords : Array[Int],
  var_delta : ((Int) -> Double)?,
) -> Bool {
  match self {
    AxisRange(axis_index, min_value, max_value) => {
      let coord = if axis_index >= 0 && axis_index < coords.length() {
        coords[axis_index]
      } else {
        0
      }
      min_value <= coord && coord <= max_value
    }
    Value(default_value, var_idx) => {
      let delta = match var_delta {
        None => 0.0
        Some(f) => f(var_idx)
      }
      default_value.to_double() + delta > 0.0
    }
    And(conditions) => {
      for condition in conditions {
        if !condition.evaluate(coords, var_delta) {
          return false
        }
      }
      true
    }
    Or(conditions) => {
      for condition in conditions {
        if condition.evaluate(coords, var_delta) {
          return true
        }
      }
      false
    }
    Not(condition) => !condition.evaluate(coords, var_delta)
  }
}

///|
fn read_cff_offset(
  data : BytesView,
  offset : Int,
  size : Int,
) -> Result[Int, VarError] {
  if size <= 0 || size > 4 {
    return Err(InvalidFormat)
  }
  if offset < 0 || offset + size > data.length() {
    return Err(UnexpectedEof)
  }
  let mut value = 0
  for i in 0..<size {
    value = (value << 8) | data[offset + i].to_int()
  }
  Ok(value)
}

///|
fn parse_cff2_index(
  data : BytesView,
  offset : Int,
) -> Result[CffIndex, VarError] {
  let count = read_u32_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      if count == 0 {
        return Ok(CffIndex::{
          count: 0,
          off_size: 0,
          offsets: [],
          data: Bytes::from_array([]),
        })
      }
      let off_size = read_u8_int(data, offset + 4)
      match off_size {
        Err(err) => Err(err)
        Ok(off_size) => {
          if off_size <= 0 || off_size > 4 {
            return Err(InvalidFormat)
          }
          let mut pos = offset + 5
          let offsets : Array[Int] = []
          for _ in 0..<(count + 1) {
            let value = read_cff_offset(data, pos, off_size)
            match value {
              Err(err) => return Err(err)
              Ok(v) => offsets.push(v)
            }
            pos = pos + off_size
          }
          let data_start = pos
          let last = offsets[offsets.length() - 1]
          if last <= 0 {
            return Err(InvalidFormat)
          }
          let data_len = last - 1
          if data_len < 0 || data_start + data_len > data.length() {
            return Err(UnexpectedEof)
          }
          let data_bytes = data[data_start:data_start + data_len].to_owned()
          Ok(CffIndex::{ count, off_size, offsets, data: data_bytes })
        }
      }
    }
  }
}

///|
fn CffIndex::item_bytes(
  self : CffIndex,
  index : Int,
) -> Result[Bytes, VarError] {
  if index < 0 || index >= self.count {
    return Err(InvalidFormat)
  }
  if self.count == 0 {
    return Ok(Bytes::from_array([]))
  }
  let start = self.offsets[index] - 1
  let end = self.offsets[index + 1] - 1
  if start < 0 || end < start || end > self.data.length() {
    return Err(InvalidFormat)
  }
  Ok(self.data[start:end].to_owned())
}

///|
fn int8_from_byte_varc(value : Byte) -> Int {
  let v = value.to_int()
  if v >= 0x80 {
    v - 0x100
  } else {
    v
  }
}

///|
fn decode_tuple_values(data : BytesView) -> Result[Array[Int], VarError] {
  let values : Array[Int] = []
  let mut pos = 0
  while pos < data.length() {
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x3F) + 1
    let mode = control & 0xC0
    if mode == 0x80 {
      for _ in 0..<run_count {
        values.push(0)
      }
    } else if mode == 0x40 {
      let needed = run_count * 2
      if pos + needed > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i16(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => values.push(v)
        }
        pos = pos + 2
      }
    } else if mode == 0xC0 {
      let needed = run_count * 4
      if pos + needed > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i32(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => values.push(v)
        }
        pos = pos + 4
      }
    } else {
      if pos + run_count > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        values.push(int8_from_byte_varc(data[pos]))
        pos = pos + 1
      }
    }
  }
  Ok(values)
}

///|
fn decode_tuple_values_count(
  data : BytesView,
  count : Int,
) -> Result[(Array[Int], Int), VarError] {
  if count < 0 {
    return Err(InvalidFormat)
  }
  let values : Array[Int] = []
  let mut pos = 0
  while values.length() < count {
    if pos >= data.length() {
      return Err(UnexpectedEof)
    }
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x3F) + 1
    let mode = control & 0xC0
    if mode == 0x80 {
      for _ in 0..<run_count {
        if values.length() < count {
          values.push(0)
        }
      }
    } else if mode == 0x40 {
      let needed = run_count * 2
      if pos + needed > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i16(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => if values.length() < count { values.push(v) }
        }
        pos = pos + 2
      }
    } else if mode == 0xC0 {
      let needed = run_count * 4
      if pos + needed > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i32(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => if values.length() < count { values.push(v) }
        }
        pos = pos + 4
      }
    } else {
      if pos + run_count > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        if values.length() < count {
          values.push(int8_from_byte_varc(data[pos]))
        }
        pos = pos + 1
      }
    }
  }
  Ok((values, pos))
}

///|
fn read_u32var(data : BytesView, offset : Int) -> Result[(UInt, Int), VarError] {
  if offset < 0 || offset >= data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  if b0 < 0x80U {
    return Ok((b0, 1))
  }
  if b0 < 0xC0U {
    if offset + 2 > data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[offset + 1].to_uint()
    let value = ((b0 & 0x3FU) << 8) | b1
    return Ok((value, 2))
  }
  if b0 < 0xE0U {
    if offset + 3 > data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[offset + 1].to_uint()
    let b2 = data[offset + 2].to_uint()
    let value = ((b0 & 0x1FU) << 16) | (b1 << 8) | b2
    return Ok((value, 3))
  }
  if b0 < 0xF0U {
    if offset + 4 > data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[offset + 1].to_uint()
    let b2 = data[offset + 2].to_uint()
    let b3 = data[offset + 3].to_uint()
    let value = ((b0 & 0x0FU) << 24) | (b1 << 16) | (b2 << 8) | b3
    return Ok((value, 4))
  }
  if offset + 5 > data.length() {
    return Err(UnexpectedEof)
  }
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  let b4 = data[offset + 4].to_uint()
  let value = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
  Ok((value, 5))
}

///|
fn coverage_index_varc(
  data : BytesView,
  offset : Int,
  glyph : Int,
) -> Result[Int?, VarError] {
  if glyph < 0 || glyph > 0xFFFF {
    return Ok(None)
  }
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      if format == 1 {
        coverage_format1_varc(data, offset, glyph)
      } else if format == 2 {
        coverage_format2_varc(data, offset, glyph)
      } else {
        Err(InvalidFormat)
      }
  }
}

///|
fn coverage_format1_varc(
  data : BytesView,
  offset : Int,
  glyph : Int,
) -> Result[Int?, VarError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, offset + 2)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      let list_offset = offset + 4
      if list_offset < 0 || list_offset + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let value = read_u16_int(data, list_offset + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => if value == glyph { return Ok(Some(i)) }
        }
      }
      Ok(None)
    }
  }
}

///|
fn coverage_format2_varc(
  data : BytesView,
  offset : Int,
  glyph : Int,
) -> Result[Int?, VarError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, offset + 2)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      let record_offset = offset + 4
      let record_size = 6
      if record_offset < 0 ||
        record_offset + count * record_size > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let base = record_offset + i * record_size
        let start = read_u16_int(data, base)
        let end = read_u16_int(data, base + 2)
        let start_index = read_u16_int(data, base + 4)
        match (start, end, start_index) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start), Ok(end), Ok(start_index)) =>
            if glyph >= start && glyph <= end {
              return Ok(Some(start_index + (glyph - start)))
            }
        }
      }
      Ok(None)
    }
  }
}

///|
pub fn VarcTable::parse(data : BytesView) -> Result[VarcTable, VarError] {
  let version = read_u32(data, 0)
  let coverage_offset = read_u32_int(data, 4)
  let var_store_offset = read_u32_int(data, 8)
  let condition_list_offset = read_u32_int(data, 12)
  let axis_indices_offset = read_u32_int(data, 16)
  let glyph_records_offset = read_u32_int(data, 20)
  match
    (
      version, coverage_offset, var_store_offset, condition_list_offset, axis_indices_offset,
      glyph_records_offset,
    ) {
    (Err(err), _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _) => Err(err)
    (_, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(coverage_offset),
      Ok(var_store_offset),
      Ok(condition_list_offset),
      Ok(axis_indices_offset),
      Ok(glyph_records_offset),
    ) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      let length = data.length()
      match validate_offset(coverage_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(var_store_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(condition_list_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(axis_indices_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(glyph_records_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      Ok(VarcTable::{
        version: version.reinterpret_as_int(),
        coverage_offset,
        var_store_offset,
        condition_list_offset,
        axis_indices_offset,
        glyph_records_offset,
        data: data.to_owned(),
      })
    }
  }
}

///|
pub fn VarcTable::var_store(
  self : VarcTable,
) -> Result[MultiItemVariationStore?, VarError] {
  if self.var_store_offset == 0 {
    return Ok(None)
  }
  if self.var_store_offset < 0 || self.var_store_offset >= self.data.length() {
    return Err(UnexpectedEof)
  }
  match MultiItemVariationStore::parse(self.data[self.var_store_offset:]) {
    Err(err) => Err(err)
    Ok(value) => Ok(Some(value))
  }
}

///|
pub fn VarcTable::axis_indices(
  self : VarcTable,
  index : Int,
) -> Result[Array[Int], VarError] {
  if self.axis_indices_offset == 0 {
    return Err(InvalidFormat)
  }
  let idx = match parse_cff2_index(self.data[:], self.axis_indices_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let bytes = match idx.item_bytes(index) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  decode_tuple_values(bytes[:])
}

///|
pub fn VarcTable::glyph_record(
  self : VarcTable,
  glyph : Int,
) -> Result[Bytes?, VarError] {
  if self.coverage_offset == 0 || self.glyph_records_offset == 0 {
    return Ok(None)
  }
  let index = match
    coverage_index_varc(self.data[:], self.coverage_offset, glyph) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match index {
    None => Ok(None)
    Some(index) => {
      let records = match
        parse_cff2_index(self.data[:], self.glyph_records_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      match records.item_bytes(index) {
        Err(err) => Err(err)
        Ok(value) => Ok(Some(value))
      }
    }
  }
}

///|
pub fn VarcTable::conditions(
  self : VarcTable,
) -> Result[Array[VarcCondition], VarError] {
  if self.condition_list_offset == 0 {
    return Ok([])
  }
  let base = self.condition_list_offset
  let count = read_u32_int(self.data[:], base)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let offsets_base = base + 4
      let total = count * 4
      if offsets_base < 0 || offsets_base + total > self.data.length() {
        return Err(UnexpectedEof)
      }
      let conditions : Array[VarcCondition] = []
      for i in 0..<count {
        let offset = read_u32_int(self.data[:], offsets_base + i * 4)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            let condition = match
              parse_condition_at(self.data[:], base, offset, 0) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            conditions.push(condition)
          }
        }
      }
      Ok(conditions)
    }
  }
}
