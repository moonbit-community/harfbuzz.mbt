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
pub struct AvarMapping {
  from_raw : Int
  to_raw : Int
} derive(Eq, Debug, ToJson)

///|
pub struct AvarSegmentMap {
  mappings : Array[AvarMapping]
} derive(Eq, Debug, ToJson)

///|
pub struct AvarTable {
  axes : Array[AvarSegmentMap]
} derive(Eq, Debug, ToJson)

///|
pub fn AvarTable::axis_count(self : AvarTable) -> Int {
  self.axes.length()
}

///|
pub fn AvarTable::map_coords_16_16(
  self : AvarTable,
  coords : Array[Int],
) -> Array[Int] {
  let out = coords.copy()
  let count = if out.length() < self.axes.length() {
    out.length()
  } else {
    self.axes.length()
  }
  for i in 0..<count {
    let value = out[i].to_double() / 65536.0
    let mapped = self.axes[i].map_value(value)
    out[i] = double_to_fixed16(mapped)
  }
  out
}

///|
pub fn AvarSegmentMap::map_value(
  self : AvarSegmentMap,
  value : Double,
) -> Double {
  if self.mappings.length() == 0 {
    return value
  }
  if self.mappings.length() == 1 {
    let only = self.mappings[0]
    let from = f2dot14_to_double(only.from_raw)
    let to = f2dot14_to_double(only.to_raw)
    return value - from + to
  }
  for mapping in self.mappings {
    let from = f2dot14_to_double(mapping.from_raw)
    if value == from {
      return f2dot14_to_double(mapping.to_raw)
    }
  }
  let first = self.mappings[0]
  let first_from = f2dot14_to_double(first.from_raw)
  let first_to = f2dot14_to_double(first.to_raw)
  if value < first_from {
    return value - first_from + first_to
  }
  let last_idx = self.mappings.length() - 1
  let last = self.mappings[last_idx]
  let last_from = f2dot14_to_double(last.from_raw)
  let last_to = f2dot14_to_double(last.to_raw)
  if value > last_from {
    return value - last_from + last_to
  }
  for i in 1..<self.mappings.length() {
    let after = self.mappings[i]
    let after_from = f2dot14_to_double(after.from_raw)
    if value < after_from {
      let before = self.mappings[i - 1]
      let before_from = f2dot14_to_double(before.from_raw)
      let before_to = f2dot14_to_double(before.to_raw)
      let after_to = f2dot14_to_double(after.to_raw)
      let denom = after_from - before_from
      if denom == 0.0 {
        return after_to
      }
      return before_to + (after_to - before_to) * (value - before_from) / denom
    }
  }
  value
}

///|
pub fn AvarTable::parse(data : BytesView) -> Result[AvarTable, VarError] {
  let version = read_u32(data, 0)
  let axis_count = read_u16_int(data, 6)
  match (version, axis_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(axis_count)) => {
      let major = (version >> 16) & 0xFFFFU
      if major < 1U || major > 2U {
        return Err(InvalidFormat)
      }
      let mut offset = 8
      let axes : Array[AvarSegmentMap] = []
      for _ in 0..<axis_count {
        let segment_count = read_u16_int(data, offset)
        match segment_count {
          Err(err) => return Err(err)
          Ok(segment_count) => {
            offset = offset + 2
            let mappings : Array[AvarMapping] = []
            for _ in 0..<segment_count {
              let from_raw = read_i16(data, offset)
              let to_raw = read_i16(data, offset + 2)
              match (from_raw, to_raw) {
                (Err(err), _) => return Err(err)
                (_, Err(err)) => return Err(err)
                (Ok(from_raw), Ok(to_raw)) =>
                  mappings.push(AvarMapping::{ from_raw, to_raw })
              }
              offset = offset + 4
            }
            mappings.sort_by((a, b) => a.from_raw - b.from_raw)
            axes.push(AvarSegmentMap::{ mappings, })
          }
        }
      }
      Ok(AvarTable::{ axes, })
    }
  }
}
