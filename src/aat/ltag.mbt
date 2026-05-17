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
/// Parsed ltag table.
pub struct LtagTable {
  version : Int
  flags : Int
  tags : Array[Bytes]
} derive(Debug, ToJson)

///|
pub fn LtagTable::has_data(self : LtagTable) -> Bool {
  self.version != 0
}

///|
pub fn LtagTable::tags(self : LtagTable) -> ArrayView[Bytes] {
  self.tags[:]
}

///|
/// Parse an ltag table.
pub fn LtagTable::parse(data : BytesView) -> Result[LtagTable, AatError] {
  let version = read_u32_int(data, 0)
  let flags = read_u32_int(data, 4)
  let count = read_u32_non_negative(data, 8)
  match (version, flags, count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(version), Ok(flags), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let record_base = 12
      let record_size = 4
      if record_base + count * record_size > data.length() {
        return Err(UnexpectedEof)
      }
      let tags : Array[Bytes] = []
      for i in 0..<count {
        let record_offset = record_base + i * record_size
        let tag_offset = read_u16_int(data, record_offset)
        let tag_length = read_u16_int(data, record_offset + 2)
        match (tag_offset, tag_length) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(tag_offset), Ok(tag_length)) => {
            if tag_offset < 0 || tag_length < 0 {
              return Err(InvalidFormat)
            }
            let start = tag_offset
            let end = start + tag_length
            if start < 0 || end > data.length() {
              return Err(UnexpectedEof)
            }
            let slice = data[start:end]
            tags.push(slice.to_owned())
          }
        }
      }
      Ok(LtagTable::{ version, flags, tags })
    }
  }
}
