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
test "thai preprocess sara am reorder" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_thai)
  buffer.add_codepoint(0x0E14U)
  buffer.add_codepoint(0x0E4BU)
  buffer.add_codepoint(0x0E33U)
  preprocess_thai_sara_am(buffer)
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  inspect(cps, content="[3604, 3661, 3659, 3634]")
}

///|
fn thai_test_push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn thai_test_push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn thai_test_push_tag(bytes : Array[Byte], tag : @common.Tag) -> Unit {
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
}

///|
fn thai_test_build_sfnt(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u32(bytes, 0x00010000)
  thai_test_push_u16(bytes, tables.length())
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 0)
  let mut offset = 12 + tables.length() * 16
  let records : Array[(@common.Tag, Int, Int)] = []
  for entry in tables {
    let (tag, table) = entry
    records.push((tag, offset, table.length()))
    offset = offset + table.length()
  }
  for entry in records {
    let (tag, table_offset, length) = entry
    let (b1, b2, b3, b4) = tag.bytes()
    bytes.push(b1)
    bytes.push(b2)
    bytes.push(b3)
    bytes.push(b4)
    thai_test_push_u32(bytes, 0)
    thai_test_push_u32(bytes, table_offset)
    thai_test_push_u32(bytes, length)
  }
  for entry in tables {
    let (_, table) = entry
    for b in table {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_head(upem : Int, loc_format : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(54, b'\x00')
  bytes[18] = ((upem >> 8) & 0xff).to_byte()
  bytes[19] = (upem & 0xff).to_byte()
  bytes[50] = ((loc_format >> 8) & 0xff).to_byte()
  bytes[51] = (loc_format & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_maxp(num_glyphs : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(6, b'\x00')
  bytes[4] = ((num_glyphs >> 8) & 0xff).to_byte()
  bytes[5] = (num_glyphs & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_hhea(number_of_hmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_hmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_hmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_hmtx_ot() -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 200)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 300)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 400)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 500)
  thai_test_push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_cmap_table(subtable : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 3)
  thai_test_push_u16(bytes, 10)
  thai_test_push_u32(bytes, 12)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_cmap_format12_groups(
  groups : Array[(UInt, UInt, UInt)],
) -> Bytes {
  let bytes : Array[Byte] = []
  let length = 16 + groups.length() * 12
  thai_test_push_u16(bytes, 12)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u32(bytes, length)
  thai_test_push_u32(bytes, 0)
  thai_test_push_u32(bytes, groups.length())
  for group in groups {
    let (start, end, start_gid) = group
    thai_test_push_u32(bytes, start.reinterpret_as_int())
    thai_test_push_u32(bytes, end.reinterpret_as_int())
    thai_test_push_u32(bytes, start_gid.reinterpret_as_int())
  }
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_script_list_for(tag : @common.Tag) -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 1)
  thai_test_push_tag(bytes, tag)
  thai_test_push_u16(bytes, 8)
  thai_test_push_u16(bytes, 4)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 0xffff)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_feature_list(tag : @common.Tag) -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 1)
  thai_test_push_tag(bytes, tag)
  thai_test_push_u16(bytes, 8)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_lookup_list(lookup : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 4)
  for b in lookup {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_layout_table_with_script(
  lookup : Bytes,
  feature_tag : @common.Tag,
  script_tag : @common.Tag,
) -> Bytes {
  let script = thai_test_build_script_list_for(script_tag)
  let feature = thai_test_build_feature_list(feature_tag)
  let lookup_list = thai_test_build_lookup_list(lookup)
  let bytes : Array[Byte] = []
  thai_test_push_u32(bytes, 0x00010000)
  let script_offset = 10
  let feature_offset = script_offset + script.length()
  let lookup_offset = feature_offset + feature.length()
  thai_test_push_u16(bytes, script_offset)
  thai_test_push_u16(bytes, feature_offset)
  thai_test_push_u16(bytes, lookup_offset)
  for b in script {
    bytes.push(b)
  }
  for b in feature {
    bytes.push(b)
  }
  for b in lookup_list {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_gsub_subtable(target : Int, substitute : Int) -> Bytes {
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 2)
  thai_test_push_u16(bytes, 8)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, substitute)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, target)
  Bytes::from_array(bytes)
}

///|
fn thai_test_build_gsub_lookup() -> Bytes {
  let subtable = thai_test_build_gsub_subtable(1, 1)
  let bytes : Array[Byte] = []
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 0)
  thai_test_push_u16(bytes, 1)
  thai_test_push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_thai_pua() -> Bytes {
  let cmap = thai_test_build_cmap_table(
    thai_test_build_cmap_format12_groups([
      (0x0E01U, 0x0E01U, 1U),
      (0x0E48U, 0x0E48U, 2U),
      (0xF70AU, 0xF70AU, 3U),
    ]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), thai_test_build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), thai_test_build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), thai_test_build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), thai_test_build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  thai_test_build_sfnt(tables)
}

///|
test "thai fallback pua snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_thai_pua())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_thai)
  buffer.add_codepoint(0x0E01U)
  buffer.add_codepoint(0x0E48U)
  let result = buffer.shape_thai(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  let snapshot : Array[(UInt, Int, Int, Int, Int)] = []
  for i in 0..<infos.length() {
    snapshot.push(
      (
        infos[i].codepoint,
        infos[i].cluster,
        positions[i].x_advance,
        positions[i].x_offset,
        positions[i].y_offset,
      ),
    )
  }
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0], [3, 1, 500, 0, 0]])
}

///|
fn build_font_bytes_thai_pua_rd() -> Bytes {
  let cmap = thai_test_build_cmap_table(
    thai_test_build_cmap_format12_groups([
      (0x0E0DU, 0x0E0DU, 1U),
      (0x0E38U, 0x0E38U, 2U),
      (0xF70FU, 0xF70FU, 3U),
    ]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), thai_test_build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), thai_test_build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), thai_test_build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), thai_test_build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  thai_test_build_sfnt(tables)
}

///|
test "thai fallback pua base replacement snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_thai_pua_rd())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_thai)
  buffer.add_codepoint(0x0E0DU)
  buffer.add_codepoint(0x0E38U)
  let result = buffer.shape_thai(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  let snapshot : Array[(UInt, Int, Int, Int, Int)] = []
  for i in 0..<infos.length() {
    snapshot.push(
      (
        infos[i].codepoint,
        infos[i].cluster,
        positions[i].x_advance,
        positions[i].x_offset,
        positions[i].y_offset,
      ),
    )
  }
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0], [2, 1, 0, -400, 0]])
}

///|
fn build_font_bytes_thai_pua_gsub() -> Bytes {
  let cmap = thai_test_build_cmap_table(
    thai_test_build_cmap_format12_groups([
      (0x0E01U, 0x0E01U, 1U),
      (0x0E48U, 0x0E48U, 2U),
      (0xF70AU, 0xF70AU, 3U),
    ]),
  )
  let gsub = thai_test_build_layout_table_with_script(
    thai_test_build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
    @common.Tag::from_chars('t', 'h', 'a', 'i'),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), thai_test_build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), thai_test_build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), thai_test_build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), thai_test_build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
    (@common.Tag::from_chars('G', 'S', 'U', 'B'), gsub),
  ]
  thai_test_build_sfnt(tables)
}

///|
test "thai fallback skipped with gsub snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_thai_pua_gsub())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_thai)
  buffer.add_codepoint(0x0E01U)
  buffer.add_codepoint(0x0E48U)
  let result = buffer.shape_thai(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  let snapshot : Array[(UInt, Int, Int, Int, Int)] = []
  for i in 0..<infos.length() {
    snapshot.push(
      (
        infos[i].codepoint,
        infos[i].cluster,
        positions[i].x_advance,
        positions[i].x_offset,
        positions[i].y_offset,
      ),
    )
  }
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0], [2, 1, 0, -400, 0]])
}
