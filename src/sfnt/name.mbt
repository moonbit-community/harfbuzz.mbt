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
/// Name record (string bytes in original encoding).
pub struct NameRecord {
  platform_id : Int
  encoding_id : Int
  language_id : Int
  name_id : Int
  value : Bytes
} derive(Debug, ToJson)

///|
/// Parsed name table (subset).
pub struct NameTable {
  records : Array[NameRecord]
} derive(Debug, ToJson)

///|
/// Parse name table bytes (format 0/1; string decoding is caller's responsibility).
pub fn NameTable::parse(data : BytesView) -> Result[NameTable, SfntError] {
  let format = read_u16_int(data, 0)
  let count = read_u16_int(data, 2)
  let string_offset = read_u16_int(data, 4)
  match (format, count, string_offset) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(count), Ok(string_offset)) => {
      if format < 0 || format > 1 || count < 0 {
        return Err(InvalidFormat)
      }
      let records : Array[NameRecord] = []
      let record_base = 6
      let record_len = 12
      let table_len = data.length()
      if record_base + count * record_len > table_len {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let rec_offset = record_base + i * record_len
        let platform_id = read_u16_int(data, rec_offset)
        let encoding_id = read_u16_int(data, rec_offset + 2)
        let language_id = read_u16_int(data, rec_offset + 4)
        let name_id = read_u16_int(data, rec_offset + 6)
        let length = read_u16_int(data, rec_offset + 8)
        let offset = read_u16_int(data, rec_offset + 10)
        match (platform_id, encoding_id, language_id, name_id, length, offset) {
          (Err(err), _, _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _, _) => return Err(err)
          (_, _, Err(err), _, _, _) => return Err(err)
          (_, _, _, Err(err), _, _) => return Err(err)
          (_, _, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, _, Err(err)) => return Err(err)
          (
            Ok(platform_id),
            Ok(encoding_id),
            Ok(language_id),
            Ok(name_id),
            Ok(length),
            Ok(offset),
          ) => {
            if length < 0 || offset < 0 {
              return Err(InvalidFormat)
            }
            let str_start = string_offset + offset
            let str_end = str_start + length
            if str_end > table_len {
              return Err(UnexpectedEof)
            }
            let bytes : Array[Byte] = []
            for j in str_start..<str_end {
              bytes.push(data[j])
            }
            records.push(NameRecord::{
              platform_id,
              encoding_id,
              language_id,
              name_id,
              value: Bytes::from_array(bytes),
            })
          }
        }
      }
      Ok(NameTable::{ records })
    }
  }
}

///|
/// Return the first name record matching ids (simple helper).
pub fn NameTable::find_name(
  self : NameTable,
  platform_id : Int,
  encoding_id : Int,
  language_id : Int,
  name_id : Int,
) -> NameRecord? {
  for record in self.records {
    if record.platform_id == platform_id &&
       record.encoding_id == encoding_id &&
       record.language_id == language_id &&
       record.name_id == name_id {
      return Some(record)
    }
  }
  None
}
