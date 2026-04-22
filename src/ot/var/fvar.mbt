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
pub struct AxisRecord {
  tag : @common.Tag
  min_value : Double
  default_value : Double
  max_value : Double
  flags : Int
  name_id : Int
} derive(Eq, Debug, ToJson)

///|
pub struct InstanceRecord {
  subfamily_name_id : Int
  flags : Int
  coordinates : Array[Double]
  postscript_name_id : Int?
} derive(Eq, Debug, ToJson)

///|
pub struct FvarTable {
  axes : Array[AxisRecord]
  instances : Array[InstanceRecord]
} derive(Eq, Debug, ToJson)

///|
pub fn FvarTable::axes(self : FvarTable) -> ArrayView[AxisRecord] {
  self.axes[:]
}

///|
pub fn FvarTable::instances(self : FvarTable) -> ArrayView[InstanceRecord] {
  self.instances[:]
}

///|
pub fn AxisRecord::normalize_value(self : AxisRecord, value : Double) -> Double {
  let min_value = self.min_value
  let default_value = self.default_value
  let max_value = self.max_value
  let v = clamp_double(value, min_value, max_value)
  if v == default_value {
    0.0
  } else if v < default_value {
    let denom = default_value - min_value
    if denom == 0.0 { 0.0 } else { (v - default_value) / denom }
  } else {
    let denom = max_value - default_value
    if denom == 0.0 { 0.0 } else { (v - default_value) / denom }
  }
}

///|
pub fn FvarTable::normalize_axis_value(
  self : FvarTable,
  axis_index : Int,
  value : Double,
) -> Double {
  if axis_index < 0 || axis_index >= self.axes.length() {
    return 0.0
  }
  self.axes[axis_index].normalize_value(value)
}

///|
pub fn FvarTable::axis_index(
  self : FvarTable,
  tag : @common.Tag,
) -> Int? {
  for i in 0..<self.axes.length() {
    if self.axes[i].tag == tag {
      return Some(i)
    }
  }
  None
}

///|
pub fn FvarTable::normalize_design_coords(
  self : FvarTable,
  coords : Array[Double],
) -> Array[Int] {
  let axis_count = self.axes.length()
  let out : Array[Int] = Array::make(axis_count, 0)
  for i in 0..<axis_count {
    let axis = self.axes[i]
    let value = if i < coords.length() { coords[i] } else { axis.default_value }
    let normalized = axis.normalize_value(value)
    out[i] = double_to_fixed16(normalized)
  }
  out
}

///|
pub fn FvarTable::parse(data : BytesView) -> Result[FvarTable, VarError] {
  let version = read_u32(data, 0)
  let axis_offset = read_u16_int(data, 4)
  let axis_count = read_u16_int(data, 8)
  let axis_size = read_u16_int(data, 10)
  let instance_count = read_u16_int(data, 12)
  let instance_size = read_u16_int(data, 14)
  match (version, axis_offset, axis_count, axis_size, instance_count, instance_size) {
    (Err(err), _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _) => Err(err)
    (_, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(axis_offset), Ok(axis_count), Ok(axis_size), Ok(instance_count), Ok(instance_size)) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if axis_offset < 16 {
        return Err(InvalidFormat)
      }
      if axis_size < 20 {
        return Err(InvalidFormat)
      }
      let axis_bytes = axis_count * axis_size
      if axis_offset < 0 || axis_offset + axis_bytes > data.length() {
        return Err(UnexpectedEof)
      }
      if instance_size < axis_count * 4 + 4 {
        return Err(InvalidFormat)
      }
      let axes : Array[AxisRecord] = []
      for i in 0..<axis_count {
        let offset = axis_offset + i * axis_size
        let tag = read_tag(data, offset)
        let min_raw = read_i32(data, offset + 4)
        let default_raw = read_i32(data, offset + 8)
        let max_raw = read_i32(data, offset + 12)
        let flags = read_u16_int(data, offset + 16)
        let name_id = read_u16_int(data, offset + 18)
        match (tag, min_raw, default_raw, max_raw, flags, name_id) {
          (Err(err), _, _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _, _) => return Err(err)
          (_, _, Err(err), _, _, _) => return Err(err)
          (_, _, _, Err(err), _, _) => return Err(err)
          (_, _, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, _, Err(err)) => return Err(err)
          (Ok(tag), Ok(min_raw), Ok(default_raw), Ok(max_raw), Ok(flags), Ok(name_id)) => {
            let min_value = fixed16_to_double(min_raw)
            let default_value = fixed16_to_double(default_raw)
            let max_value = fixed16_to_double(max_raw)
            let min_value = if min_value > default_value { default_value } else { min_value }
            let max_value = if max_value < default_value { default_value } else { max_value }
            axes.push(AxisRecord::{
              tag,
              min_value,
              default_value,
              max_value,
              flags,
              name_id,
            })
          }
        }
      }
      let instances : Array[InstanceRecord] = []
      let mut instance_offset = axis_offset + axis_bytes
      for _ in 0..<instance_count {
        if instance_offset + instance_size > data.length() {
          return Err(UnexpectedEof)
        }
        let subfamily_name_id = read_u16_int(data, instance_offset)
        let flags = read_u16_int(data, instance_offset + 2)
        match (subfamily_name_id, flags) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(subfamily_name_id), Ok(flags)) => {
            let coords : Array[Double] = []
            let coords_offset = instance_offset + 4
            for i in 0..<axis_count {
              let value = read_i32(data, coords_offset + i * 4)
              match value {
                Err(err) => return Err(err)
                Ok(raw) => coords.push(fixed16_to_double(raw))
              }
            }
            let mut postscript_name_id : Int? = None
            let ps_offset = coords_offset + axis_count * 4
            if instance_size >= axis_count * 4 + 6 {
              let ps = read_u16_int(data, ps_offset)
              match ps {
                Err(err) => return Err(err)
                Ok(id) => postscript_name_id = Some(id)
              }
            }
            instances.push(InstanceRecord::{
              subfamily_name_id,
              flags,
              coordinates: coords,
              postscript_name_id,
            })
          }
        }
        instance_offset = instance_offset + instance_size
      }
      Ok(FvarTable::{ axes, instances })
    }
  }
}
