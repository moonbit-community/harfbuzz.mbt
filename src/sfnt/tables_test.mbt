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
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, adjusted)
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
test "head table parse" {
  let bytes = build_bytes(54)
  bytes[18] = 0x03
  bytes[19] = 0xe8
  bytes[50] = 0x00
  bytes[51] = 0x01
  let head = match HeadTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(head.units_per_em, content="1000")
  inspect(head.index_to_loc_format, content="1")
}

///|
test "maxp table parse" {
  let bytes = build_bytes(6)
  bytes[4] = 0x00
  bytes[5] = 0x0a
  let maxp = match MaxpTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(maxp.num_glyphs, content="10")
}

///|
test "hhea table parse" {
  let bytes = build_bytes(36)
  bytes[34] = 0x00
  bytes[35] = 0x05
  let hhea = match HheaTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(hhea.number_of_hmetrics, content="5")
}

///|
test "hmtx table parse" {
  let bytes : Array[Byte] = [
    0x00, 0xc8, 0x00, 0x0a, 0x01, 0x2c, 0x00, 0x14, 0x00, 0x1e,
  ]
  let hmtx = match HmtxTable::parse(Bytes::from_array(bytes)[:], 3, 2) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(hmtx.advances, content="[200, 300, 300]")
  inspect(hmtx.lsbs, content="[10, 20, 30]")
}

///|
test "cmap format 12" {
  let subtable = build_cmap_format12(0x41U, 0x41U, 5U)
  let cmap_bytes = build_cmap_table(subtable, 3, 10)
  let cmap = match CmapTable::parse(@blob.Blob::from_bytes(cmap_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let gid = match cmap.glyph_for(0x41U) {
    Err(err) => fail("lookup error: \{err}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  inspect(gid, content="5")
}

///|
test "cmap format 4" {
  let subtable = build_cmap_format4()
  let cmap_bytes = build_cmap_table(subtable, 3, 1)
  let cmap = match CmapTable::parse(@blob.Blob::from_bytes(cmap_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let gid = match cmap.glyph_for(0x41U) {
    Err(err) => fail("lookup error: \{err}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  inspect(gid, content="5")
}

///|
test "kern table parse" {
  let kern = match KernTable::parse(build_kern_table()[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(kern.kern_value(1U, 2U), content="Some(-50)")
  inspect(kern.kern_value(2U, 1U), content="None")
}

///|
test "os2 table parse v0" {
  let os2 = match Os2Table::parse(build_os2_table_v0()[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(os2.version, content="0")
  inspect(os2.weight_class, content="400")
  inspect(os2.width_class, content="5")
  inspect(os2.typo_ascender, content="800")
  inspect(os2.typo_descender, content="-200")
  inspect(os2.win_ascent, content="900")
  inspect(os2.win_descent, content="200")
}

///|
test "os2 table parse v2" {
  let os2 = match Os2Table::parse(build_os2_table_v2()[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(os2.version, content="2")
  inspect(os2.code_page_range_1, content="Some(1)")
  inspect(os2.code_page_range_2, content="Some(2)")
  inspect(os2.x_height, content="Some(500)")
  inspect(os2.cap_height, content="Some(700)")
  inspect(os2.break_char, content="Some(32)")
  inspect(os2.max_context, content="Some(4)")
}

///|
test "name table parse" {
  let name = match NameTable::parse(build_name_table()[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(name.records.length(), content="1")
  let record = match name.find_name(3, 1, 0x0409, 1) {
    None => fail("missing name record")
    Some(value) => value
  }
  inspect(record.value, content="b\"\\x00T\\x00e\"")
}
