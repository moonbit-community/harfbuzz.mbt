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

let bsln_format0 = 0
let bsln_format1 = 1
let bsln_format2 = 2
let bsln_format3 = 3

///|
/// Parsed bsln baseline data.
pub enum BslnData {
  Format0(Array[Int])
  Format1(Array[Int], LookupTable)
  Format2(Int, Array[Int])
  Format3(Int, Array[Int], LookupTable)
} derive(Show, ToJson)

///|
/// Parsed bsln table.
pub struct BslnTable {
  version : Int
  format : Int
  default_baseline : Int
  data : BslnData
} derive(Show, ToJson)

///|
pub fn BslnTable::has_data(self : BslnTable) -> Bool {
  self.version != 0
}

fn parse_deltas(data : BytesView, offset : Int) -> Result[Array[Int], AatError] {
  if offset < 0 || offset + 64 > data.length() {
    return Err(UnexpectedEof)
  }
  let deltas : Array[Int] = []
  for i in 0..<32 {
    let value = read_i16(data, offset + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => deltas.push(value)
    }
  }
  Ok(deltas)
}

fn parse_ctl_points(
  data : BytesView,
  offset : Int,
) -> Result[Array[Int], AatError] {
  if offset < 0 || offset + 64 > data.length() {
    return Err(UnexpectedEof)
  }
  let points : Array[Int] = []
  for i in 0..<32 {
    let value = read_u16_int(data, offset + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => {
        if value == 0xffff {
          points.push(-1)
        } else {
          points.push(value)
        }
      }
    }
  }
  Ok(points)
}

///|
/// Parse a bsln table.
pub fn BslnTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[BslnTable, AatError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let version = read_i32(data, 0)
  let format = read_u16_int(data, 4)
  let default_baseline = read_u16_int(data, 6)
  match (version, format, default_baseline) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(version), Ok(format), Ok(default_baseline)) => {
      if default_baseline < 0 || default_baseline >= 32 {
        return Err(InvalidFormat)
      }
      let base = 8
      let data = if format == bsln_format0 {
        let deltas = match parse_deltas(data, base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        BslnData::Format0(deltas)
      } else if format == bsln_format1 {
        let deltas = match parse_deltas(data, base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let lookup_offset = base + 64
        let lookup = match parse_lookup(data, lookup_offset, num_glyphs) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        BslnData::Format1(deltas, lookup)
      } else if format == bsln_format2 {
        if base < 0 || base + 66 > data.length() {
          return Err(UnexpectedEof)
        }
        let std_glyph = match read_u16_int(data, base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let points = match parse_ctl_points(data, base + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        BslnData::Format2(std_glyph, points)
      } else if format == bsln_format3 {
        if base < 0 || base + 66 > data.length() {
          return Err(UnexpectedEof)
        }
        let std_glyph = match read_u16_int(data, base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let points = match parse_ctl_points(data, base + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let lookup_offset = base + 66
        let lookup = match parse_lookup(data, lookup_offset, num_glyphs) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        BslnData::Format3(std_glyph, points, lookup)
      } else {
        return Err(InvalidFormat)
      }
      Ok(BslnTable::{ version, format, default_baseline, data })
    }
  }
}
