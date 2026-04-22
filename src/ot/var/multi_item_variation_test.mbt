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
fn push_u8_multi(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u16_multi(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_multi(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_multi(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_multi(bytes, adjusted)
}

fn append_bytes(dst : Array[Byte], src : Array[Byte]) -> Unit {
  for b in src {
    dst.push(b)
  }
}

fn build_sparse_region_list() -> Array[Byte] {
  let bytes : Array[Byte] = []
  push_u16_multi(bytes, 1) // region count
  push_u32_multi(bytes, 6) // offset to region
  push_u16_multi(bytes, 1) // axis count
  push_u16_multi(bytes, 0) // axis index
  push_i16_multi(bytes, 0)
  push_i16_multi(bytes, 0x4000)
  push_i16_multi(bytes, 0x4000)
  bytes
}

fn build_multi_var_data() -> Array[Byte] {
  let bytes : Array[Byte] = []
  push_u8_multi(bytes, 1) // format
  push_u16_multi(bytes, 1) // region index count
  push_u16_multi(bytes, 0) // region index 0
  push_u32_multi(bytes, 1) // tuple list count
  push_u8_multi(bytes, 1) // offSize
  push_u8_multi(bytes, 1) // offset[0]
  push_u8_multi(bytes, 3) // offset[1]
  push_u8_multi(bytes, 0) // tuple values control (1 byte)
  push_u8_multi(bytes, 10) // value
  bytes
}

///|
fn build_multi_item_store() -> Bytes {
  let region_list = build_sparse_region_list()
  let data_set = build_multi_var_data()
  let header_len = 12
  let region_offset = header_len
  let data_offset = region_offset + region_list.length()
  let bytes : Array[Byte] = []
  push_u16_multi(bytes, 1) // format
  push_u32_multi(bytes, region_offset)
  push_u16_multi(bytes, 1) // data count
  push_u32_multi(bytes, data_offset)
  append_bytes(bytes, region_list)
  append_bytes(bytes, data_set)
  Bytes::from_array(bytes)
}

///|
test "multi item var store delta" {
  let store = match MultiItemVariationStore::parse(build_multi_item_store()[:]) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let out0 : Array[Double] = [0.0]
  store.get_delta(0x00000000U, [0x4000], out0)
  @debug.debug_inspect(out0.map(v => v.round().to_int()), content="[10]")
  let out1 : Array[Double] = [0.0]
  store.get_delta(0x00000000U, [0], out1)
  @debug.debug_inspect(out1.map(v => v.round().to_int()), content="[0]")
}
