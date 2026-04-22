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
/// Meta record entry.
pub struct MetaRecord {
  tag : @common.Tag
  data : Bytes
} derive(Debug, ToJson)

///|
/// Parsed meta table.
pub struct MetaTable {
  version : Int
  flags : Int
  records : Array[MetaRecord]
} derive(Debug, ToJson)

///|
/// Parse meta table bytes.
pub fn MetaTable::parse(data : BytesView) -> Result[MetaTable, SfntError] {
  let version = read_u32_int(data, 0)
  let flags = read_u32_int(data, 4)
  let map_offset = read_u32_int(data, 8)
  let map_count = read_u32_int(data, 12)
  match (version, flags, map_offset, map_count) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(flags), Ok(map_offset), Ok(map_count)) => {
      if map_offset < 0 || map_count < 0 {
        return Err(InvalidFormat)
      }
      let offset = map_offset
      let count = map_count
      let table_len = data.length()
      if offset + count * 12 > table_len {
        return Err(UnexpectedEof)
      }
      let records : Array[MetaRecord] = []
      for i in 0..<count {
        let record_offset = offset + i * 12
        let tag = @common.Tag::from_bytes(
          data[record_offset],
          data[record_offset + 1],
          data[record_offset + 2],
          data[record_offset + 3],
        )
        let data_offset = read_u32_int(data, record_offset + 4)
        let data_length = read_u32_int(data, record_offset + 8)
        match (data_offset, data_length) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(data_offset), Ok(data_length)) => {
            if data_offset < 0 || data_length < 0 {
              return Err(InvalidFormat)
            }
            let start = data_offset
            let end = start + data_length
            if end > table_len {
              return Err(UnexpectedEof)
            }
            let bytes : Array[Byte] = []
            for j in start..<end {
              bytes.push(data[j])
            }
            records.push(MetaRecord::{ tag, data: Bytes::from_array(bytes) })
          }
        }
      }
      Ok(MetaTable::{ version, flags, records })
    }
  }
}

///|
/// Find a meta record by tag.
pub fn MetaTable::find(self : MetaTable, tag : @common.Tag) -> Bytes? {
  for record in self.records {
    if record.tag == tag {
      return Some(record.data)
    }
  }
  None
}
