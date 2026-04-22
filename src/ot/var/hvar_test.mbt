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
fn push_u16_hvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_hvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_hvar(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_hvar(bytes, adjusted)
}

///|
fn build_var_store_hvar() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16_hvar(bytes, 1) // format
  push_u32_hvar(bytes, 12) // region list offset
  push_u16_hvar(bytes, 1) // data count
  push_u32_hvar(bytes, 22) // data offset
  push_u16_hvar(bytes, 1) // axis count
  push_u16_hvar(bytes, 1) // region count
  push_i16_hvar(bytes, 0) // start
  push_i16_hvar(bytes, 0x4000) // peak 1.0
  push_i16_hvar(bytes, 0x4000) // end 1.0
  push_u16_hvar(bytes, 2) // item count
  push_u16_hvar(bytes, 1) // word size count
  push_u16_hvar(bytes, 1) // region index count
  push_u16_hvar(bytes, 0) // region index
  push_i16_hvar(bytes, 10) // delta item 0
  push_i16_hvar(bytes, 20) // delta item 1
  Bytes::from_array(bytes)
}

///|
fn build_delta_map_hvar(reverse? : Bool = false) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0) // format
  bytes.push(0x1F) // width=2, inner bits=16
  push_u16_hvar(bytes, 2) // map count
  if reverse {
    bytes.push(0)
    bytes.push(1) // var idx 1
    bytes.push(0)
    bytes.push(0) // var idx 0
  } else {
    bytes.push(0)
    bytes.push(0) // var idx 0
    bytes.push(0)
    bytes.push(1) // var idx 1
  }
  Bytes::from_array(bytes)
}

///|
fn build_hvar_bytes() -> Bytes {
  let lsb_map = build_delta_map_hvar()
  let rsb_map = build_delta_map_hvar(reverse=true)
  let var_store = build_var_store_hvar()
  let header_len = 20
  let lsb_offset = header_len
  let rsb_offset = lsb_offset + lsb_map.length()
  let var_offset = rsb_offset + rsb_map.length()
  let bytes : Array[Byte] = []
  push_u32_hvar(bytes, 0x00010000) // version
  push_u32_hvar(bytes, var_offset)
  push_u32_hvar(bytes, 0) // adv map
  push_u32_hvar(bytes, lsb_offset)
  push_u32_hvar(bytes, rsb_offset)
  for b in lsb_map { bytes.push(b) }
  for b in rsb_map { bytes.push(b) }
  for b in var_store { bytes.push(b) }
  Bytes::from_array(bytes)
}

///|
test "hvar lsb rsb deltas" {
  let hvar = match HvarTable::parse(build_hvar_bytes()) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let coords : Array[Int] = [16384]
  let lsb = hvar.lsb_delta(1U, coords).round().to_int()
  let rsb = hvar.rsb_delta(1U, coords).round().to_int()
  @debug.debug_inspect((lsb, rsb), content="(20, 10)")
}
