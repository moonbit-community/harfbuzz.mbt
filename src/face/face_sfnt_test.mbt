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
fn build_sfnt_with_table(tag : @common.Tag, table_bytes : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x10)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x1c)
  let len = table_bytes.length()
  bytes.push(((len >> 24) & 0xff).to_byte())
  bytes.push(((len >> 16) & 0xff).to_byte())
  bytes.push(((len >> 8) & 0xff).to_byte())
  bytes.push((len & 0xff).to_byte())
  for b in table_bytes {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_sfnt_with_tables(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, tables.length())
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  let mut offset = 12 + tables.length() * 16
  for entry in tables {
    let (tag, table_bytes) = entry
    let (b1, b2, b3, b4) = tag.bytes()
    bytes.push(b1)
    bytes.push(b2)
    bytes.push(b3)
    bytes.push(b4)
    push_u32(bytes, 0)
    push_u32(bytes, offset)
    push_u32(bytes, table_bytes.length())
    offset = offset + table_bytes.length()
  }
  for entry in tables {
    let (_, table_bytes) = entry
    for b in table_bytes {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

///|
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, adjusted)
}

///|
fn build_cmap_table(subtable : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 10)
  push_u32(bytes, 12)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format12(start : UInt, end : UInt, start_gid : UInt) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 12)
  push_u16(bytes, 0)
  push_u32(bytes, 28)
  push_u32(bytes, 0)
  push_u32(bytes, 1)
  push_u32(bytes, start.reinterpret_as_int())
  push_u32(bytes, end.reinterpret_as_int())
  push_u32(bytes, start_gid.reinterpret_as_int())
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format4_simple(start : Int, end : Int, start_gid : Int) -> Bytes {
  let seg_count = 2
  let length = 16 + 8 * seg_count
  let id_delta = start_gid - start
  let bytes : Array[Byte] = []
  push_u16(bytes, 4)
  push_u16(bytes, length)
  push_u16(bytes, 0)
  push_u16(bytes, seg_count * 2)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, end)
  push_u16(bytes, 0xFFFF)
  push_u16(bytes, 0)
  push_u16(bytes, start)
  push_u16(bytes, 0xFFFF)
  push_i16(bytes, id_delta)
  push_i16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_ttc(fonts : Array[Bytes]) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x74)
  bytes.push(0x74)
  bytes.push(0x63)
  bytes.push(0x66)
  push_u32(bytes, 0x00010000)
  push_u32(bytes, fonts.length())
  let mut offset = 12 + fonts.length() * 4
  for font in fonts {
    push_u32(bytes, offset)
    offset = offset + font.length()
  }
  for font in fonts {
    for b in font {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

///|
test "face references sfnt table" {
  let tag = @common.Tag::from_chars('n', 'a', 'm', 'e')
  let table_bytes : Bytes = [0x0a, 0x0b]
  let sfnt_bytes = build_sfnt_with_table(tag, table_bytes)
  let face = Face::from_bytes(sfnt_bytes)
  let table = match face.reference_table(tag) {
    Err(err) => fail("missing table: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(table.to_bytes(), content="b\"\\x0a\\x0b\"")
}

///|
test "face references ttc tables by index" {
  let tag = @common.Tag::from_chars('n', 'a', 'm', 'e')
  let font0 = build_sfnt_with_table(tag, [0x0a])
  let font1 = build_sfnt_with_table(tag, [0x0b, 0x0c])
  let ttc = build_ttc([font0, font1])
  let face0 = Face::from_bytes(ttc, index=0)
  let face1 = Face::from_bytes(ttc, index=1)
  let table0 = match face0.reference_table(tag) {
    Err(err) => fail("missing table: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let table1 = match face1.reference_table(tag) {
    Err(err) => fail("missing table: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(table0.to_bytes(), content="b\"\\x0a\"")
  inspect(table1.to_bytes(), content="b\"\\x0b\\x0c\"")
}

///|
test "face set_index resets cached tables" {
  let tag = @common.Tag::from_chars('n', 'a', 'm', 'e')
  let font0 = build_sfnt_with_table(tag, [0x01])
  let font1 = build_sfnt_with_table(tag, [0x02])
  let ttc = build_ttc([font0, font1])
  let face = Face::from_bytes(ttc, index=0)
  let table0 = match face.reference_table(tag) {
    Err(err) => fail("missing table: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  face.set_index(1)
  let table1 = match face.reference_table(tag) {
    Err(err) => fail("missing table: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(table0.to_bytes(), content="b\"\\x01\"")
  inspect(table1.to_bytes(), content="b\"\\x02\"")
}

///|
test "face table tags listing" {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('c', 'v', 't', ' '), [0x01]),
    (@common.Tag::from_chars('f', 'p', 'g', 'm'), [0x02, 0x03]),
    (@common.Tag::from_chars('g', 'a', 's', 'p'), []),
  ]
  let sfnt = build_sfnt_with_tables(tables)
  let face = Face::from_bytes(sfnt)
  let (total0, tags0) = match face.table_tags() {
    Err(err) => fail("table tags error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(total0, content="3")
  let names0 : Array[String] = []
  for tag in tags0 {
    names0.push(tag.to_string())
  }
  inspect(names0, content="[cvt , fpgm, gasp]")
  let (total1, tags1) = match face.table_tags(start_offset=1, count=1) {
    Err(err) => fail("table tags error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(total1, content="3")
  let names1 : Array[String] = []
  for tag in tags1 {
    names1.push(tag.to_string())
  }
  inspect(names1, content="[fpgm]")
  let (total2, tags2) = match face.table_tags(start_offset=3, count=2) {
    Err(err) => fail("table tags error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(total2, content="3")
  inspect(tags2.length(), content="0")
}

///|
test "face collect unicodes format12" {
  let cmap = build_cmap_table(build_cmap_format12(0x61U, 0x63U, 1U))
  let sfnt = build_sfnt_with_tables([
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ])
  let face = Face::from_bytes(sfnt)
  let set = match face.collect_unicodes() {
    Err(err) => fail("collect unicodes error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(set.to_sorted_array(), content="[97, 98, 99]")
  let map = match face.collect_nominal_glyph_mapping() {
    Err(err) => fail("collect mapping error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(map.population(), content="3")
  inspect(map.get(0x61U), content="1")
  inspect(map.get(0x62U), content="2")
  inspect(map.get(0x63U), content="3")
}

///|
test "face collect unicodes format4" {
  let subtable = build_cmap_format4_simple(0x61, 0x63, 1)
  let cmap = build_cmap_table(subtable)
  let sfnt = build_sfnt_with_tables([
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ])
  let face = Face::from_bytes(sfnt)
  let set = match face.collect_unicodes() {
    Err(err) => fail("collect unicodes error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  inspect(set.to_sorted_array(), content="[97, 98, 99]")
}
