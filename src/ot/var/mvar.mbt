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
pub struct MvarRecord {
  tag : @common.Tag
  var_idx : UInt
} derive(Eq, Debug, ToJson)

///|
pub struct MvarTable {
  records : Array[MvarRecord]
  var_store : ItemVariationStore
} derive(Debug, ToJson)

///|
pub fn MvarTable::parse(data : BytesView) -> Result[MvarTable, VarError] {
  let version = read_u32(data, 0)
  let value_record_size = read_u16_int(data, 6)
  let value_record_count = read_u16_int(data, 8)
  let var_store_offset = read_u16_int(data, 10)
  match (version, value_record_size, value_record_count, var_store_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(value_record_size),
      Ok(value_record_count),
      Ok(var_store_offset),
    ) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if value_record_size < 8 {
        return Err(InvalidFormat)
      }
      if var_store_offset < 0 || var_store_offset >= data.length() {
        return Err(UnexpectedEof)
      }
      let var_store = match ItemVariationStore::parse(data[var_store_offset:]) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut offset = 12
      let records : Array[MvarRecord] = []
      for _ in 0..<value_record_count {
        if offset + value_record_size > data.length() {
          return Err(UnexpectedEof)
        }
        let tag = read_tag(data, offset)
        let var_idx = read_u32(data, offset + 4)
        match (tag, var_idx) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(tag), Ok(var_idx)) => records.push(MvarRecord::{ tag, var_idx })
        }
        offset = offset + value_record_size
      }
      Ok(MvarTable::{ records, var_store })
    }
  }
}

///|
pub fn MvarTable::get_var(
  self : MvarTable,
  tag : @common.Tag,
  coords : Array[Int],
) -> Double {
  for record in self.records {
    if record.tag == tag {
      return self.var_store.get_delta(record.var_idx, coords)
    }
  }
  0.0
}
