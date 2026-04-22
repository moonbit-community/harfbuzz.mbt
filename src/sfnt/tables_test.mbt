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
fn build_bytes(len : Int) -> Array[Byte] {
  let bytes : Array[Byte] = []
  for _ in 0..<len {
    bytes.push(0x00)
  }
  bytes
}

///|
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u8(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, adjusted)
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_tag(bytes : Array[Byte], tag : @common.Tag) -> Unit {
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
}

///|

///|
fn write_u16_at(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  bytes[offset] = ((value >> 8) & 0xff).to_byte()
  bytes[offset + 1] = (value & 0xff).to_byte()
}

///|
fn write_i16_at(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  write_u16_at(bytes, offset, adjusted)
}

///|
fn write_u32_at(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  bytes[offset] = ((value >> 24) & 0xff).to_byte()
  bytes[offset + 1] = ((value >> 16) & 0xff).to_byte()
  bytes[offset + 2] = ((value >> 8) & 0xff).to_byte()
  bytes[offset + 3] = (value & 0xff).to_byte()
}

///|
fn build_cmap_table(
  subtable : Bytes,
  platform_id : Int,
  encoding_id : Int,
) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(((platform_id >> 8) & 0xff).to_byte())
  bytes.push((platform_id & 0xff).to_byte())
  bytes.push(((encoding_id >> 8) & 0xff).to_byte())
  bytes.push((encoding_id & 0xff).to_byte())
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x0c)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format12(start : UInt, end : UInt, start_gid : UInt) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x0c)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x1c)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  let start_arr = [
    (start >> 24).to_byte(),
    (start >> 16).to_byte(),
    (start >> 8).to_byte(),
    start.to_byte(),
  ]
  let end_arr = [
    (end >> 24).to_byte(),
    (end >> 16).to_byte(),
    (end >> 8).to_byte(),
    end.to_byte(),
  ]
  let gid_arr = [
    (start_gid >> 24).to_byte(),
    (start_gid >> 16).to_byte(),
    (start_gid >> 8).to_byte(),
    start_gid.to_byte(),
  ]
  for b in start_arr {
    bytes.push(b)
  }
  for b in end_arr {
    bytes.push(b)
  }
  for b in gid_arr {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format4() -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x04)
  bytes.push(0x00)
  bytes.push(0x20)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x04)
  bytes.push(0x00)
  bytes.push(0x04)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x41)
  bytes.push(0xff)
  bytes.push(0xff)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x41)
  bytes.push(0xff)
  bytes.push(0xff)
  bytes.push(0xff)
  bytes.push(0xc4)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  Bytes::from_array(bytes)
}

///|
fn build_kern_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 20)
  push_u16(bytes, 0x0001)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_i16(bytes, -50)
  Bytes::from_array(bytes)
}

///|
fn build_kern_table_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 38)
  push_u16(bytes, 0x0201)
  push_u16(bytes, 4)
  push_u16(bytes, 14)
  push_u16(bytes, 22)
  push_u16(bytes, 30)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, -30)
  Bytes::from_array(bytes)
}

///|
fn build_kern_table_format3() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 26)
  push_u16(bytes, 0x0301)
  push_u16(bytes, 3)
  push_u8(bytes, 2)
  push_u8(bytes, 2)
  push_u8(bytes, 2)
  push_u8(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, -40)
  push_u8(bytes, 0)
  push_u8(bytes, 1)
  push_u8(bytes, 0)
  push_u8(bytes, 0)
  push_u8(bytes, 1)
  push_u8(bytes, 0)
  push_u8(bytes, 0)
  push_u8(bytes, 0)
  push_u8(bytes, 0)
  push_u8(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_vhea_table() -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = 0x00
  bytes[35] = 0x02
  Bytes::from_array(bytes)
}

///|
fn build_vmtx_table() -> Bytes {
  let bytes : Array[Byte] = [
    0x02, 0xbc, 0x00, 0x05, 0x03, 0x20, 0x00, 0x06, 0x00, 0x07,
  ]
  Bytes::from_array(bytes)
}

///|
fn build_os2_table_v0() -> Bytes {
  let bytes : Array[Byte] = Array::make(78, b'\x00')
  write_u16_at(bytes, 4, 400)
  write_u16_at(bytes, 6, 5)
  write_u16_at(bytes, 8, 0)
  write_i16_at(bytes, 68, 800)
  write_i16_at(bytes, 70, -200)
  write_i16_at(bytes, 72, 100)
  write_u16_at(bytes, 74, 900)
  write_u16_at(bytes, 76, 200)
  Bytes::from_array(bytes)
}

///|
fn build_os2_table_v2() -> Bytes {
  let bytes : Array[Byte] = Array::make(96, b'\x00')
  write_u16_at(bytes, 0, 2)
  write_u16_at(bytes, 4, 500)
  write_u16_at(bytes, 6, 7)
  write_u16_at(bytes, 8, 1)
  write_i16_at(bytes, 68, 700)
  write_i16_at(bytes, 70, -150)
  write_i16_at(bytes, 72, 50)
  write_u16_at(bytes, 74, 800)
  write_u16_at(bytes, 76, 180)
  write_u32_at(bytes, 78, 1)
  write_u32_at(bytes, 82, 2)
  write_i16_at(bytes, 86, 500)
  write_i16_at(bytes, 88, 700)
  write_u16_at(bytes, 90, 0)
  write_u16_at(bytes, 92, 32)
  write_u16_at(bytes, 94, 4)
  Bytes::from_array(bytes)
}

///|
fn build_name_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 18)
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 0x0409)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 'T'.to_int())
  push_u16(bytes, 'e'.to_int())
  Bytes::from_array(bytes)
}

///|
fn build_post_table_v2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00020000)
  push_u32(bytes, 0)
  push_i16(bytes, -50)
  push_i16(bytes, 20)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 258)
  bytes.push(3)
  bytes.push(b'f')
  bytes.push(b'o')
  bytes.push(b'o')
  Bytes::from_array(bytes)
}

///|
fn build_gasp_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 16)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_meta_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u32(bytes, 0)
  push_u32(bytes, 16)
  push_u32(bytes, 1)
  push_u32(bytes, 0x64657363)
  push_u32(bytes, 28)
  push_u32(bytes, 3)
  bytes.push(b'f')
  bytes.push(b'o')
  bytes.push(b'o')
  Bytes::from_array(bytes)
}

///|
fn build_vorg_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_i16(bytes, 800)
  push_u16(bytes, 2)
  push_u16(bytes, 3)
  push_i16(bytes, 750)
  push_u16(bytes, 4)
  push_i16(bytes, 700)
  Bytes::from_array(bytes)
}

///|
fn build_hdmx_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u32(bytes, 6)
  bytes.push(12)
  bytes.push(8)
  bytes.push(3)
  bytes.push(4)
  bytes.push(5)
  bytes.push(6)
  Bytes::from_array(bytes)
}

///|
fn build_stat_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010001)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u32(bytes, 20)
  push_u16(bytes, 1)
  push_u32(bytes, 28)
  push_u16(bytes, 2)
  push_tag(bytes, @common.Tag::from_chars('w', 'g', 'h', 't'))
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 3)
  push_u32(bytes, 0x00010000)
  Bytes::from_array(bytes)
}

///|
fn build_base_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 8)
  push_u16(bytes, 0)
  push_u16(bytes, 4)
  push_u16(bytes, 10)
  push_u16(bytes, 1)
  push_tag(bytes, @common.Tag::from_chars('r', 'o', 'm', 'n'))
  push_u16(bytes, 1)
  push_tag(bytes, @common.Tag::from_chars('l', 'a', 't', 'n'))
  push_u16(bytes, 8)
  push_u16(bytes, 6)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 6)
  push_u16(bytes, 1)
  push_i16(bytes, 100)
  Bytes::from_array(bytes)
}

///|
fn build_jstf_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 1)
  push_tag(bytes, @common.Tag::from_chars('l', 'a', 't', 'n'))
  push_u16(bytes, 12)
  push_u16(bytes, 6)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  for _ in 0..<10 {
    push_u16(bytes, 0)
  }
  Bytes::from_array(bytes)
}

///|
fn build_math_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 10)
  push_u16(bytes, 224)
  push_u16(bytes, 248)
  let constants : Array[Byte] = Array::make(214, b'\x00')
  write_i16_at(constants, 0, 80)
  write_i16_at(constants, 2, 60)
  write_u16_at(constants, 4, 500)
  write_u16_at(constants, 6, 700)
  write_i16_at(constants, 8, 12)
  write_u16_at(constants, 10, 0)
  write_i16_at(constants, 212, 45)
  for b in constants {
    bytes.push(b)
  }
  push_u16(bytes, 8)
  push_u16(bytes, 16)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_i16(bytes, 10)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_i16(bytes, 20)
  push_u16(bytes, 0)
  push_u16(bytes, 3)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
test "head table parse" {
  let bytes = build_bytes(54)
  bytes[18] = 0x03
  bytes[19] = 0xe8
  bytes[50] = 0x00
  bytes[51] = 0x01
  let head = match HeadTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(head.units_per_em, content="1000")
  @debug.debug_inspect(head.index_to_loc_format, content="1")
}

///|
test "maxp table parse" {
  let bytes = build_bytes(6)
  bytes[4] = 0x00
  bytes[5] = 0x0a
  let maxp = match MaxpTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(maxp.num_glyphs, content="10")
}

///|
test "hhea table parse" {
  let bytes = build_bytes(36)
  bytes[34] = 0x00
  bytes[35] = 0x05
  let hhea = match HheaTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(hhea.number_of_hmetrics, content="5")
}

///|
test "hmtx table parse" {
  let bytes : Array[Byte] = [
    0x00, 0xc8, 0x00, 0x0a, 0x01, 0x2c, 0x00, 0x14, 0x00, 0x1e,
  ]
  let hmtx = match HmtxTable::parse(Bytes::from_array(bytes)[:], 3, 2) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(hmtx.advances, content="[200, 300, 300]")
  @debug.debug_inspect(hmtx.lsbs, content="[10, 20, 30]")
}

///|
test "vhea table parse" {
  let vhea = match VheaTable::parse(build_vhea_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(vhea.number_of_vmetrics, content="2")
}

///|
test "vmtx table parse" {
  let vmtx = match VmtxTable::parse(build_vmtx_table()[:], 3, 2) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(vmtx.advances, content="[700, 800, 800]")
  @debug.debug_inspect(vmtx.tsbs, content="[5, 6, 7]")
}

///|
test "cmap format 12" {
  let subtable = build_cmap_format12(0x41U, 0x41U, 5U)
  let cmap_bytes = build_cmap_table(subtable, 3, 10)
  let cmap = match CmapTable::parse(@blob.Blob::from_bytes(cmap_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gid = match cmap.glyph_for(0x41U) {
    Err(err) => fail("lookup error: \{@debug.to_string(err)}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  @debug.debug_inspect(gid, content="5")
}

///|
test "cmap format 4" {
  let subtable = build_cmap_format4()
  let cmap_bytes = build_cmap_table(subtable, 3, 1)
  let cmap = match CmapTable::parse(@blob.Blob::from_bytes(cmap_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gid = match cmap.glyph_for(0x41U) {
    Err(err) => fail("lookup error: \{@debug.to_string(err)}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  @debug.debug_inspect(gid, content="5")
}

///|
test "kern table parse" {
  let kern = match KernTable::parse(build_kern_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(kern.kern_value(1U, 2U), content="Some(-50)")
  @debug.debug_inspect(kern.kern_value(2U, 1U), content="None")
}

///|
test "kern table format2 parse" {
  let kern = match KernTable::parse(build_kern_table_format2()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(kern.kern_value(1U, 1U), content="Some(-30)")
  @debug.debug_inspect(kern.kern_value(2U, 2U), content="Some(0)")
}

///|
test "kern table format3 parse" {
  let kern = match KernTable::parse(build_kern_table_format3()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(kern.kern_value(1U, 1U), content="Some(-40)")
  @debug.debug_inspect(kern.kern_value(0U, 1U), content="Some(0)")
}

///|
test "os2 table parse v0" {
  let os2 = match Os2Table::parse(build_os2_table_v0()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(os2.version, content="0")
  @debug.debug_inspect(os2.weight_class, content="400")
  @debug.debug_inspect(os2.width_class, content="5")
  @debug.debug_inspect(os2.typo_ascender, content="800")
  @debug.debug_inspect(os2.typo_descender, content="-200")
  @debug.debug_inspect(os2.win_ascent, content="900")
  @debug.debug_inspect(os2.win_descent, content="200")
}

///|
test "os2 table parse v2" {
  let os2 = match Os2Table::parse(build_os2_table_v2()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(os2.version, content="2")
  @debug.debug_inspect(os2.code_page_range_1, content="Some(1)")
  @debug.debug_inspect(os2.code_page_range_2, content="Some(2)")
  @debug.debug_inspect(os2.x_height, content="Some(500)")
  @debug.debug_inspect(os2.cap_height, content="Some(700)")
  @debug.debug_inspect(os2.break_char, content="Some(32)")
  @debug.debug_inspect(os2.max_context, content="Some(4)")
}

///|
test "name table parse" {
  let name = match NameTable::parse(build_name_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(name.records.length(), content="1")
  let record = match name.find_name(3, 1, 0x0409, 1) {
    None => fail("missing name record")
    Some(value) => value
  }
  @debug.debug_inspect(record.value, content="b\"\\x00T\\x00e\"")
}

///|
test "post table parse v2" {
  let post = match PostTable::parse(build_post_table_v2()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(post.version, content="131072")
  @debug.debug_inspect(post.underline_position, content="-50")
  @debug.debug_inspect(post.underline_thickness, content="20")
  let indices = match post.glyph_name_indices {
    None => fail("missing name indices")
    Some(value) => value
  }
  let names = match post.custom_names {
    None => fail("missing custom names")
    Some(value) => value
  }
  @debug.debug_inspect(indices, content="[258]")
  @debug.debug_inspect(names, content="[b\"foo\"]")
}

///|
test "gasp table parse" {
  let gasp = match GaspTable::parse(build_gasp_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(gasp.version, content="1")
  @debug.debug_inspect(gasp.behavior_for_ppem(7), content="Some(1)")
  @debug.debug_inspect(gasp.behavior_for_ppem(16), content="Some(3)")
  @debug.debug_inspect(gasp.behavior_for_ppem(20), content="None")
}

///|
test "meta table parse" {
  let meta = match MetaTable::parse(build_meta_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(meta.records.length(), content="1")
  let data = match meta.find(@common.Tag::from_chars('d', 'e', 's', 'c')) {
    None => fail("missing meta record")
    Some(value) => value
  }
  @debug.debug_inspect(data, content="b\"foo\"")
}

///|
test "vorg table parse" {
  let vorg = match VorgTable::parse(build_vorg_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(vorg.major_version, content="1")
  @debug.debug_inspect(vorg.default_origin_y, content="800")
  @debug.debug_inspect(vorg.origin_y_for(3), content="750")
  @debug.debug_inspect(vorg.origin_y_for(10), content="800")
}

///|
test "hdmx table parse" {
  let hdmx = match HdmxTable::parse(build_hdmx_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(hdmx.records.length(), content="1")
  let record = hdmx.records[0]
  @debug.debug_inspect(record.pixel_size, content="12")
  @debug.debug_inspect(record.max_width, content="8")
  @debug.debug_inspect(record.widths, content="[3, 4, 5, 6]")
}

///|
test "stat table parse" {
  let stat = match StatTable::parse(build_stat_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(stat.design_axes.length(), content="1")
  @debug.debug_inspect(stat.design_axes[0].tag.to_string(), content="wght")
  @debug.debug_inspect(stat.elided_fallback_name_id, content="2")
  @debug.debug_inspect(stat.axis_values.length(), content="1")
  match stat.axis_values[0] {
    Format1(axis_index, flags, value_name_id, value) => {
      @debug.debug_inspect(axis_index, content="0")
      @debug.debug_inspect(flags, content="0")
      @debug.debug_inspect(value_name_id, content="3")
      @debug.debug_inspect(value, content="65536")
    }
    _ => fail("unexpected axis value format")
  }
}

///|
test "base table parse" {
  let base = match BaseTable::parse(build_base_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(base.major_version, content="1")
  let axis = match base.h_axis {
    None => fail("missing hAxis")
    Some(value) => value
  }
  let tags = match axis.base_tags {
    None => fail("missing base tag list")
    Some(value) => value
  }
  @debug.debug_inspect(tags.tags.length(), content="1")
  @debug.debug_inspect(tags.tags[0].to_string(), content="romn")
  let scripts = match axis.base_scripts {
    None => fail("missing base script list")
    Some(value) => value
  }
  @debug.debug_inspect(scripts.records.length(), content="1")
  @debug.debug_inspect(scripts.records[0].tag.to_string(), content="latn")
  let script = match scripts.records[0].base_script {
    None => fail("missing base script")
    Some(value) => value
  }
  let values = match script.base_values {
    None => fail("missing base values")
    Some(value) => value
  }
  @debug.debug_inspect(values.base_coords.length(), content="1")
  match values.base_coords[0] {
    None => fail("missing base coord")
    Some(Format1(value)) => @debug.debug_inspect(value, content="100")
    _ => fail("unexpected base coord")
  }
}

///|
test "jstf table parse" {
  let jstf = match JstfTable::parse(build_jstf_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(jstf.major_version, content="1")
  @debug.debug_inspect(jstf.scripts.length(), content="1")
  @debug.debug_inspect(jstf.scripts[0].tag.to_string(), content="latn")
  let script = match jstf.scripts[0].script {
    None => fail("missing script")
    Some(value) => value
  }
  @debug.debug_inspect(script.extender_glyphs, content="[3]")
  let lang_sys = match script.default_lang_sys {
    None => fail("missing default lang sys")
    Some(value) => value
  }
  @debug.debug_inspect(lang_sys.priorities.length(), content="1")
}

///|
test "math table parse" {
  let math = match MathTable::parse(build_math_table()[:]) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(math.major_version, content="1")
  let constants = match math.constants {
    None => fail("missing constants")
    Some(value) => value
  }
  @debug.debug_inspect(constants.percent_scale_down, content="[80, 60]")
  @debug.debug_inspect(constants.min_height, content="[500, 700]")
  @debug.debug_inspect(
    constants.radical_degree_bottom_raise_percent,
    content="45",
  )
  let info = match math.glyph_info {
    None => fail("missing glyph info")
    Some(value) => value
  }
  let italics = match info.italics_correction {
    None => fail("missing italics correction")
    Some(value) => value
  }
  @debug.debug_inspect(italics.records.length(), content="1")
  let top = match info.top_accent_attachment {
    None => fail("missing top accent attachment")
    Some(value) => value
  }
  @debug.debug_inspect(top.records.length(), content="1")
  let variants = match math.variants {
    None => fail("missing variants")
    Some(value) => value
  }
  @debug.debug_inspect(variants.min_connector_overlap, content="3")
}
