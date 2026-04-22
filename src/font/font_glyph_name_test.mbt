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
fn build_post_format2(
  indices : Array[Int],
  custom_names : Array[String],
) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00020000)
  push_u32(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u16(bytes, indices.length())
  for index in indices {
    push_u16(bytes, index)
  }
  for name in custom_names {
    let name_bytes = @utf8.encode(name)
    bytes.push(name_bytes.length().to_byte())
    for b in name_bytes {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

///|
test "font glyph names from post format2" {
  let tag_maxp = @common.Tag::from_chars('m', 'a', 'x', 'p')
  let tag_post = @common.Tag::from_chars('p', 'o', 's', 't')
  let post = build_post_format2([0, 3, 258], ["icon0"])
  let sfnt = build_sfnt([(tag_maxp, build_maxp(3)), (tag_post, post)])
  let face = @face.Face::from_bytes(sfnt)
  let font = Font::new(face)
  let name0 = match font.glyph_name(0) {
    Err(err) => fail("glyph name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let name1 = match font.glyph_name(1) {
    Err(err) => fail("glyph name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let name2 = match font.glyph_name(2) {
    Err(err) => fail("glyph name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let name_missing = match font.glyph_name(99) {
    Err(err) => fail("glyph name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(name0, content="Some(\".notdef\")")
  @debug.debug_inspect(name1, content="Some(\"space\")")
  @debug.debug_inspect(name2, content="Some(\"icon0\")")
  @debug.debug_inspect(name_missing, content="None")
  let gid0 = match font.glyph_from_name(".notdef") {
    Err(err) => fail("glyph from name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gid_custom = match font.glyph_from_name("icon0") {
    Err(err) => fail("glyph from name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gid_missing = match font.glyph_from_name("missing") {
    Err(err) => fail("glyph from name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gid_empty = match font.glyph_from_name("") {
    Err(err) => fail("glyph from name error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(gid0, content="Some(0)")
  @debug.debug_inspect(gid_custom, content="Some(2)")
  @debug.debug_inspect(gid_missing, content="None")
  @debug.debug_inspect(gid_empty, content="None")
}
