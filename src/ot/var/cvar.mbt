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
pub struct CvarTable {
  version : Int
  tuple_data : TupleVariationData
} derive(Show, ToJson)

///|
pub fn CvarTable::parse(
  data : BytesView,
  axis_count : Int,
) -> Result[CvarTable, VarError] {
  let version = read_u32(data, 0)
  match version {
    Err(err) => Err(err)
    Ok(value) => {
      let major = (value >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if data.length() < 4 {
        return Err(UnexpectedEof)
      }
      let tuple_data = match TupleVariationData::parse(data[4:], axis_count, []) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(CvarTable::{
        version: value.reinterpret_as_int(),
        tuple_data,
      })
    }
  }
}

///|
pub fn CvarTable::cvt_deltas(
  self : CvarTable,
  coords : Array[Int],
  point_count : Int,
) -> Result[Array[Double], VarError] {
  let (deltas, _) = match self.tuple_data.apply(coords, point_count, false) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  Ok(deltas)
}

///|
pub fn CvarTable::apply_to_cvt(
  self : CvarTable,
  cvt : Array[Int],
  coords : Array[Int],
) -> Result[Array[Int], VarError] {
  let deltas = match self.cvt_deltas(coords, cvt.length()) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let out : Array[Int] = []
  for i in 0..<cvt.length() {
    out.push(cvt[i] + deltas[i].round().to_int())
  }
  Ok(out)
}
