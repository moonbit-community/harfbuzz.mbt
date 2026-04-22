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
/// STAT design axis record.
pub struct StatAxisRecord {
  tag : @common.Tag
  name_id : Int
  ordering : Int
} derive(Eq, Debug, ToJson)

///|
/// Axis value record used by format 4.
pub struct AxisValueRecord {
  axis_index : Int
  value : Int
} derive(Eq, Debug, ToJson)

///|
/// Axis value table formats.
pub enum AxisValue {
  Format1(Int, Int, Int, Int)
  Format2(Int, Int, Int, Int, Int, Int)
  Format3(Int, Int, Int, Int, Int)
  Format4(Int, Int, Array[AxisValueRecord])
} derive(Debug, ToJson)

///|
/// Parsed STAT table.
pub struct StatTable {
  version : Int
  design_axis_size : Int
  design_axes : Array[StatAxisRecord]
  axis_values : Array[AxisValue]
  elided_fallback_name_id : Int
} derive(Debug, ToJson)

///|
fn read_fixed_16_16(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

///|
fn parse_axis_value(
  data : BytesView,
  offset : Int,
) -> Result[AxisValue, SfntError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => {
      if format == 1 {
        let axis_index = read_u16_int(data, offset + 2)
        let flags = read_u16_int(data, offset + 4)
        let value_name_id = read_u16_int(data, offset + 6)
        let value = read_fixed_16_16(data, offset + 8)
        match (axis_index, flags, value_name_id, value) {
          (Err(err), _, _, _) => Err(err)
          (_, Err(err), _, _) => Err(err)
          (_, _, Err(err), _) => Err(err)
          (_, _, _, Err(err)) => Err(err)
          (Ok(axis_index), Ok(flags), Ok(value_name_id), Ok(value)) =>
            Ok(Format1(axis_index, flags, value_name_id, value))
        }
      } else if format == 2 {
        let axis_index = read_u16_int(data, offset + 2)
        let flags = read_u16_int(data, offset + 4)
        let value_name_id = read_u16_int(data, offset + 6)
        let nominal_value = read_fixed_16_16(data, offset + 8)
        let range_min = read_fixed_16_16(data, offset + 12)
        let range_max = read_fixed_16_16(data, offset + 16)
        match (
          axis_index,
          flags,
          value_name_id,
          nominal_value,
          range_min,
          range_max,
        ) {
          (Err(err), _, _, _, _, _) => Err(err)
          (_, Err(err), _, _, _, _) => Err(err)
          (_, _, Err(err), _, _, _) => Err(err)
          (_, _, _, Err(err), _, _) => Err(err)
          (_, _, _, _, Err(err), _) => Err(err)
          (_, _, _, _, _, Err(err)) => Err(err)
          (
            Ok(axis_index),
            Ok(flags),
            Ok(value_name_id),
            Ok(nominal_value),
            Ok(range_min),
            Ok(range_max),
          ) => Ok(Format2(
            axis_index,
            flags,
            value_name_id,
            nominal_value,
            range_min,
            range_max,
          ))
        }
      } else if format == 3 {
        let axis_index = read_u16_int(data, offset + 2)
        let flags = read_u16_int(data, offset + 4)
        let value_name_id = read_u16_int(data, offset + 6)
        let value = read_fixed_16_16(data, offset + 8)
        let linked_value = read_fixed_16_16(data, offset + 12)
        match (axis_index, flags, value_name_id, value, linked_value) {
          (Err(err), _, _, _, _) => Err(err)
          (_, Err(err), _, _, _) => Err(err)
          (_, _, Err(err), _, _) => Err(err)
          (_, _, _, Err(err), _) => Err(err)
          (_, _, _, _, Err(err)) => Err(err)
          (Ok(axis_index), Ok(flags), Ok(value_name_id), Ok(value), Ok(linked_value)) =>
            Ok(Format3(axis_index, flags, value_name_id, value, linked_value))
        }
      } else if format == 4 {
        let axis_count = read_u16_int(data, offset + 2)
        let flags = read_u16_int(data, offset + 4)
        let value_name_id = read_u16_int(data, offset + 6)
        match (axis_count, flags, value_name_id) {
          (Err(err), _, _) => Err(err)
          (_, Err(err), _) => Err(err)
          (_, _, Err(err)) => Err(err)
          (Ok(axis_count), Ok(flags), Ok(value_name_id)) => {
            if axis_count < 0 {
              return Err(InvalidFormat)
            }
            let axis_values : Array[AxisValueRecord] = []
            let mut cursor = offset + 8
            if cursor + axis_count * 6 > data.length() {
              return Err(UnexpectedEof)
            }
            for _ in 0..<axis_count {
              let axis_index = read_u16_int(data, cursor)
              let value = read_fixed_16_16(data, cursor + 2)
              match (axis_index, value) {
                (Err(err), _) => return Err(err)
                (_, Err(err)) => return Err(err)
                (Ok(axis_index), Ok(value)) =>
                  axis_values.push(AxisValueRecord::{ axis_index, value })
              }
              cursor = cursor + 6
            }
            Ok(Format4(flags, value_name_id, axis_values))
          }
        }
      } else {
        Err(InvalidFormat)
      }
    }
  }
}

///|
/// Parse STAT table bytes (formats 1-4).
pub fn StatTable::parse(data : BytesView) -> Result[StatTable, SfntError] {
  let version = read_u32_int(data, 0)
  let design_axis_size = read_u16_int(data, 4)
  let design_axis_count = read_u16_int(data, 6)
  let design_axes_offset = read_u32_int(data, 8)
  let axis_value_count = read_u16_int(data, 12)
  let axis_value_offset = read_u32_int(data, 14)
  let elided_fallback_name_id = read_u16_int(data, 18)
  match (
    version,
    design_axis_size,
    design_axis_count,
    design_axes_offset,
    axis_value_count,
    axis_value_offset,
    elided_fallback_name_id,
  ) {
    (Err(err), _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(design_axis_size),
      Ok(design_axis_count),
      Ok(design_axes_offset),
      Ok(axis_value_count),
      Ok(axis_value_offset),
      Ok(elided_fallback_name_id),
    ) => {
      if design_axis_size < 8 || design_axis_count < 0 || axis_value_count < 0 {
        return Err(InvalidFormat)
      }
      let table_len = data.length()
      let design_axes : Array[StatAxisRecord] = []
      if design_axis_count > 0 {
        if design_axes_offset < 0 {
          return Err(InvalidFormat)
        }
        let required = design_axes_offset + design_axis_count * design_axis_size
        if required > table_len {
          return Err(UnexpectedEof)
        }
        for i in 0..<design_axis_count {
          let axis_offset = design_axes_offset + i * design_axis_size
          let tag = @common.Tag::from_bytes(
            data[axis_offset],
            data[axis_offset + 1],
            data[axis_offset + 2],
            data[axis_offset + 3],
          )
          let name_id = read_u16_int(data, axis_offset + 4)
          let ordering = read_u16_int(data, axis_offset + 6)
          match (name_id, ordering) {
            (Err(err), _) => return Err(err)
            (_, Err(err)) => return Err(err)
            (Ok(name_id), Ok(ordering)) =>
              design_axes.push(StatAxisRecord::{ tag, name_id, ordering })
          }
        }
      }
      let axis_values : Array[AxisValue] = []
      if axis_value_count > 0 {
        if axis_value_offset < 0 {
          return Err(InvalidFormat)
        }
        let offsets_end = axis_value_offset + axis_value_count * 2
        if offsets_end > table_len {
          return Err(UnexpectedEof)
        }
        for i in 0..<axis_value_count {
          let offset = read_u16_int(data, axis_value_offset + i * 2)
          match offset {
            Err(err) => return Err(err)
            Ok(offset) => {
              if offset <= 0 {
                continue
              }
              let abs_offset = axis_value_offset + offset
              if abs_offset + 2 > table_len {
                return Err(UnexpectedEof)
              }
              let value = match parse_axis_value(data, abs_offset) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              axis_values.push(value)
            }
          }
        }
      }
      Ok(StatTable::{
        version,
        design_axis_size,
        design_axes,
        axis_values,
        elided_fallback_name_id,
      })
    }
  }
}
