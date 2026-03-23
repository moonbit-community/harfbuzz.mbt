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
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, adjusted)
}

///|
fn build_item_variation_store() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1) // format
  push_u32(bytes, 12) // region list offset
  push_u16(bytes, 1) // data count
  push_u32(bytes, 22) // data offset
  push_u16(bytes, 1) // axis count
  push_u16(bytes, 1) // region count
  push_i16(bytes, 0) // start
  push_i16(bytes, 0x4000) // peak 1.0
  push_i16(bytes, 0x4000) // end 1.0
  push_u16(bytes, 1) // item count
  push_u16(bytes, 1) // word size count
  push_u16(bytes, 1) // region index count
  push_u16(bytes, 0) // region index
  push_i16(bytes, 100) // delta
  Bytes::from_array(bytes)
}

///|
test "item variation store delta" {
  let store = match ItemVariationStore::parse(build_item_variation_store()) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let full = store.get_delta(0U, [16384])
  let half = store.get_delta(0U, [8192])
  let zero = store.get_delta(0U, [0])
  let full_int = full.round().to_int()
  let half_int = half.round().to_int()
  let zero_int = zero.round().to_int()
  inspect((full_int, half_int, zero_int), content="(100, 50, 0)")
}
