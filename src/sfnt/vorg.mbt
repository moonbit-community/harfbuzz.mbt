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
/// VORG metric entry.
pub struct VorgMetric {
  glyph : Int
  origin_y : Int
} derive(Eq, Debug, ToJson)

///|
/// Parsed VORG table.
pub struct VorgTable {
  major_version : Int
  minor_version : Int
  default_origin_y : Int
  metrics : Array[VorgMetric]
} derive(Debug, ToJson)

///|
/// Parse VORG table bytes.
pub fn VorgTable::parse(data : BytesView) -> Result[VorgTable, SfntError] {
  let major = read_u16_int(data, 0)
  let minor = read_u16_int(data, 2)
  let default_origin_y = read_i16(data, 4)
  let count = read_u16_int(data, 6)
  match (major, minor, default_origin_y, count) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(major), Ok(minor), Ok(default_origin_y), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let metrics : Array[VorgMetric] = []
      let mut offset = 8
      if offset + count * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<count {
        let glyph = read_u16_int(data, offset)
        let origin_y = read_i16(data, offset + 2)
        match (glyph, origin_y) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(glyph), Ok(origin_y)) =>
            metrics.push(VorgMetric::{ glyph, origin_y })
        }
        offset = offset + 4
      }
      Ok(VorgTable::{ major_version: major, minor_version: minor, default_origin_y, metrics })
    }
  }
}

///|
/// Return override origin for glyph if present.
pub fn VorgTable::origin_y_override(self : VorgTable, glyph : Int) -> Int? {
  for metric in self.metrics {
    if metric.glyph == glyph {
      return Some(metric.origin_y)
    }
  }
  None
}

///|
/// Return origin Y for glyph, falling back to default.
pub fn VorgTable::origin_y_for(self : VorgTable, glyph : Int) -> Int {
  match self.origin_y_override(glyph) {
    Some(value) => value
    None => self.default_origin_y
  }
}
