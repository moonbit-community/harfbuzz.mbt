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
fn push_u16_cvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_cvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_cvar(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_cvar(bytes, adjusted)
}

///|
fn build_cvar_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_cvar(bytes, 0x00010000) // version
  push_u16_cvar(bytes, 1) // tuple var count
  push_u16_cvar(bytes, 10) // data offset
  push_u16_cvar(bytes, 4) // tuple data size
  push_u16_cvar(bytes, 0x8000) // embedded peak
  push_i16_cvar(bytes, 0x4000) // peak 1.0
  bytes.push(2) // run length 3 (0x02)
  bytes.push(10)
  bytes.push(0)
  bytes.push(0xFB)
  Bytes::from_array(bytes)
}

///|
test "cvar apply deltas" {
  let cvar = match CvarTable::parse(build_cvar_bytes()[:], 1) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let cvt : Array[Int] = [100, 200, 300]
  let applied = match cvar.apply_to_cvt(cvt, [16384]) {
    Err(err) => fail("apply failed: \{err}")
    Ok(value) => value
  }
  inspect(applied, content="[110, 200, 295]")
}
