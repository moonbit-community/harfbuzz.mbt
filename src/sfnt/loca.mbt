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
/// Parsed loca table (glyph offsets).
pub struct LocaTable {
  offsets : Array[Int]
} derive(Eq, Debug, ToJson)

///|
/// Parse loca table bytes.
/// index_to_loc_format: 0 (short, u16*2) or 1 (long, u32).
pub fn LocaTable::parse(
  data : BytesView,
  num_glyphs : Int,
  index_to_loc_format : Int,
) -> Result[LocaTable, SfntError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let count = num_glyphs + 1
  let offsets : Array[Int] = []
  let mut prev = 0
  if index_to_loc_format == 0 {
    let mut offset = 0
    for _ in 0..<count {
      let raw = read_u16_int(data, offset)
      match raw {
        Err(err) => return Err(err)
        Ok(value) => {
          let actual = value * 2
          if actual < prev {
            return Err(InvalidFormat)
          }
          offsets.push(actual)
          prev = actual
        }
      }
      offset = offset + 2
    }
    Ok(LocaTable::{ offsets })
  } else if index_to_loc_format == 1 {
    let mut offset = 0
    for _ in 0..<count {
      let raw = read_u32_int(data, offset)
      match raw {
        Err(err) => return Err(err)
        Ok(value) => {
          if value < prev {
            return Err(InvalidFormat)
          }
          offsets.push(value)
          prev = value
        }
      }
      offset = offset + 4
    }
    Ok(LocaTable::{ offsets })
  } else {
    Err(InvalidFormat)
  }
}
