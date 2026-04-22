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
/// Parsed vhea table (subset).
pub struct VheaTable {
  number_of_vmetrics : Int
} derive(Eq, Debug, ToJson)

///|
/// Parse vhea table bytes.
pub fn VheaTable::parse(data : BytesView) -> Result[VheaTable, SfntError] {
  match read_u16_int(data, 34) {
    Err(err) => Err(err)
    Ok(number_of_vmetrics) => Ok(VheaTable::{ number_of_vmetrics, })
  }
}
