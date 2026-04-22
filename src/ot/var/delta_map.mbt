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
pub struct DeltaSetIndexMap {
  map_count : Int
  width : Int
  inner_bit_count : Int
  map_data : Bytes
} derive(Eq, Debug, ToJson)

///|
fn parse_format0(
  data : BytesView,
  offset : Int,
  entry_format : Int,
) -> Result[DeltaSetIndexMap, VarError] {
  let map_count = read_u16_int(data, offset + 2)
  match map_count {
    Err(err) => Err(err)
    Ok(map_count) => {
      let width = ((entry_format >> 4) & 0x3) + 1
      let inner_bit_count = (entry_format & 0xF) + 1
      let data_offset = offset + 4
      let length = map_count * width
      if data_offset < 0 || data_offset + length > data.length() {
        return Err(UnexpectedEof)
      }
      let map_data = data[data_offset:data_offset + length].to_bytes()
      Ok(DeltaSetIndexMap::{ map_count, width, inner_bit_count, map_data })
    }
  }
}

///|
fn parse_format1(
  data : BytesView,
  offset : Int,
  entry_format : Int,
) -> Result[DeltaSetIndexMap, VarError] {
  let map_count = read_u32_int(data, offset + 2)
  match map_count {
    Err(err) => Err(err)
    Ok(map_count) => {
      let width = ((entry_format >> 4) & 0x3) + 1
      let inner_bit_count = (entry_format & 0xF) + 1
      let data_offset = offset + 6
      let length = map_count * width
      if data_offset < 0 || data_offset + length > data.length() {
        return Err(UnexpectedEof)
      }
      let map_data = data[data_offset:data_offset + length].to_bytes()
      Ok(DeltaSetIndexMap::{ map_count, width, inner_bit_count, map_data })
    }
  }
}

///|
pub fn DeltaSetIndexMap::parse(
  data : BytesView,
  offset : Int,
) -> Result[DeltaSetIndexMap, VarError] {
  let format = read_u8_int(data, offset)
  let entry_format = read_u8_int(data, offset + 1)
  match (format, entry_format) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(format), Ok(entry_format)) =>
      match format {
        0 => parse_format0(data, offset, entry_format)
        1 => parse_format1(data, offset, entry_format)
        _ => Err(InvalidFormat)
      }
  }
}

///|
pub fn DeltaSetIndexMap::map(self : DeltaSetIndexMap, value : UInt) -> UInt {
  if self.map_count == 0 {
    return value
  }
  let mut index = value.reinterpret_as_int()
  if index < 0 {
    index = 0
  }
  if index >= self.map_count {
    index = self.map_count - 1
  }
  let mut u : UInt = 0
  let offset = index * self.width
  for i in 0..<self.width {
    let byte = self.map_data[offset + i].to_uint()
    u = (u << 8) | byte
  }
  let inner_bits = self.inner_bit_count
  let outer = u >> inner_bits
  let inner = u & ((1U << inner_bits) - 1U)
  (outer << 16) | inner
}
