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
/// HDMX device record.
pub struct HdmxRecord {
  pixel_size : Int
  max_width : Int
  widths : Array[Int]
} derive(Debug, ToJson)

///|
/// Parsed hdmx table.
pub struct HdmxTable {
  version : Int
  records : Array[HdmxRecord]
} derive(Debug, ToJson)

///|
/// Parse hdmx table bytes.
pub fn HdmxTable::parse(data : BytesView) -> Result[HdmxTable, SfntError] {
  let version = read_u16_int(data, 0)
  let num_records = read_u16_int(data, 2)
  let record_size = read_u32_int(data, 4)
  match (version, num_records, record_size) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(version), Ok(count), Ok(record_size)) => {
      if count < 0 || record_size < 2 {
        return Err(InvalidFormat)
      }
      let records : Array[HdmxRecord] = []
      let mut offset = 8
      for _ in 0..<count {
        if offset + record_size > data.length() {
          return Err(UnexpectedEof)
        }
        let pixel_size = data[offset].to_uint().reinterpret_as_int()
        let max_width = data[offset + 1].to_uint().reinterpret_as_int()
        let widths_len = record_size - 2
        let widths : Array[Int] = []
        let mut cursor = offset + 2
        let end = offset + record_size
        if cursor + widths_len > end {
          return Err(InvalidFormat)
        }
        while cursor < end {
          widths.push(data[cursor].to_uint().reinterpret_as_int())
          cursor = cursor + 1
        }
        records.push(HdmxRecord::{ pixel_size, max_width, widths })
        offset = offset + record_size
      }
      Ok(HdmxTable::{ version, records })
    }
  }
}
