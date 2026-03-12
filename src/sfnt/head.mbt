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
/// Parsed head table (subset).
pub struct HeadTable {
  units_per_em : Int
  index_to_loc_format : Int
} derive(Eq, Show, ToJson)

///|
/// Parse head table bytes.
pub fn HeadTable::parse(data : BytesView) -> Result[HeadTable, SfntError] {
  let upem = read_u16_int(data, 18)
  let loc = read_i16(data, 50)
  match (upem, loc) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(units_per_em), Ok(index_to_loc_format)) =>
      Ok(HeadTable::{ units_per_em, index_to_loc_format })
  }
}
