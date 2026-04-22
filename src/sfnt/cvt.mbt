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
/// Control value table (cvt ) raw entries.
pub struct CvtTable {
  values : Array[Int]
} derive(Debug, ToJson)

///|
pub fn CvtTable::values(self : CvtTable) -> ArrayView[Int] {
  self.values[:]
}

///|
/// Parse cvt table bytes as signed 16-bit values.
pub fn CvtTable::parse(data : BytesView) -> Result[CvtTable, SfntError] {
  if data.length() % 2 != 0 {
    return Err(InvalidFormat)
  }
  let count = data.length() / 2
  let values : Array[Int] = []
  let mut pos = 0
  for _ in 0..<count {
    let value = read_i16(data, pos)
    match value {
      Err(err) => return Err(err)
      Ok(v) => values.push(v)
    }
    pos = pos + 2
  }
  Ok(CvtTable::{ values })
}
