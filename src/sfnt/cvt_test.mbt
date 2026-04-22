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
fn push_u16_cvt(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_cvt(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_cvt(bytes, adjusted)
}

///|
test "cvt parse" {
  let bytes : Array[Byte] = []
  push_i16_cvt(bytes, 100)
  push_i16_cvt(bytes, -200)
  push_i16_cvt(bytes, 0)
  let table = match CvtTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(table.values().to_array(), content="[100, -200, 0]")
}
