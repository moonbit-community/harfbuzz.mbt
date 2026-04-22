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
fn push_u16_gvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_gvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_gvar_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_gvar(bytes, 0x00010000) // version 1.0
  push_u16_gvar(bytes, 1) // axis count
  push_u16_gvar(bytes, 0) // shared tuple count
  push_u32_gvar(bytes, 0) // shared tuples offset
  push_u16_gvar(bytes, 2) // glyph count
  push_u16_gvar(bytes, 0) // flags short offsets
  push_u32_gvar(bytes, 26) // data offset
  // offsets array (glyphCount+1) short, value is /2
  push_u16_gvar(bytes, 0) // start 0
  push_u16_gvar(bytes, 1) // start 2
  push_u16_gvar(bytes, 3) // start 6
  // glyph variation data bytes
  bytes.push(1)
  bytes.push(2)
  bytes.push(3)
  bytes.push(4)
  bytes.push(5)
  bytes.push(6)
  Bytes::from_array(bytes)
}

///|
fn build_gvar_with_tuple() -> Bytes {
  let tuple = build_tuple_variation_bytes()
  let bytes : Array[Byte] = []
  push_u32_gvar(bytes, 0x00010000) // version 1.0
  push_u16_gvar(bytes, 1) // axis count
  push_u16_gvar(bytes, 0) // shared tuple count
  push_u32_gvar(bytes, 0) // shared tuples offset
  push_u16_gvar(bytes, 1) // glyph count
  push_u16_gvar(bytes, 0) // flags short offsets
  push_u32_gvar(bytes, 24) // data offset (20 header + 4 offsets)
  push_u16_gvar(bytes, 0) // start 0
  push_u16_gvar(bytes, tuple.length() / 2) // end
  for b in tuple {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
test "gvar parse offsets" {
  let gvar = match GvarTable::parse(build_gvar_bytes()) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let g0 = gvar.glyph_variation_data(0)
  let g1 = gvar.glyph_variation_data(1)
  @debug.debug_inspect(
    g0.map(bytes => bytes.to_array().map(b => b.to_int())),
    content="Some([1, 2])",
  )
  @debug.debug_inspect(
    g1.map(bytes => bytes.to_array().map(b => b.to_int())),
    content="Some([3, 4, 5, 6])",
  )
}

///|
test "gvar glyph deltas" {
  let gvar = match GvarTable::parse(build_gvar_with_tuple()) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let deltas = match gvar.glyph_deltas(0, [16384], 4) {
    Err(err) => fail("delta failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let deltas_x = deltas.0.map(delta => delta.round().to_int())
  let deltas_y = match deltas.1 {
    None => []
    Some(values) => values.map(delta => delta.round().to_int())
  }
  @debug.debug_inspect(deltas_x, content="[0, 50, 0, -20]")
  @debug.debug_inspect(deltas_y, content="[0, 10, 0, 0]")
}
