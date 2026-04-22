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
fn push_u16_gdef(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_gdef(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_gdef_table_format1_2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_gdef(bytes, 0x00010002)
  push_u16_gdef(bytes, 14)
  push_u16_gdef(bytes, 0)
  push_u16_gdef(bytes, 0)
  push_u16_gdef(bytes, 24)
  push_u16_gdef(bytes, 32)
  // glyph class def (glyphs 3..4 -> class 1,2)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 3)
  push_u16_gdef(bytes, 2)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 2)
  // mark attach class def (glyph 5 -> class 3)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 5)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 3)
  // mark glyph sets def (format 1, 1 set)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 6)
  // coverage table (glyph 5)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 1)
  push_u16_gdef(bytes, 5)
  Bytes::from_array(bytes)
}

///|
test "gdef parse class defs and mark sets" {
  let bytes = build_gdef_table_format1_2()
  let gdef = match GdefTable::parse(@blob.Blob::from_bytes(bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let class3 = match gdef.glyph_class(3U) {
    Err(err) => fail("glyph class error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let class4 = match gdef.glyph_class(4U) {
    Err(err) => fail("glyph class error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let class2 = match gdef.glyph_class(2U) {
    Err(err) => fail("glyph class error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(class3, content="1")
  @debug.debug_inspect(class4, content="2")
  @debug.debug_inspect(class2, content="0")
  let mark_class5 = match gdef.mark_attach_class(5U) {
    Err(err) => fail("mark class error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let mark_class4 = match gdef.mark_attach_class(4U) {
    Err(err) => fail("mark class error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(mark_class5, content="3")
  @debug.debug_inspect(mark_class4, content="0")
  let in_set = match gdef.mark_glyph_set_contains(0, 5U) {
    Err(err) => fail("mark set error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let not_in_set = match gdef.mark_glyph_set_contains(0, 3U) {
    Err(err) => fail("mark set error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(in_set, content="true")
  @debug.debug_inspect(not_in_set, content="false")
}
