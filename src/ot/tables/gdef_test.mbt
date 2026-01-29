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
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let class3 = match gdef.glyph_class(3U) {
    Err(err) => fail("glyph class error: \{err}")
    Ok(value) => value
  }
  let class4 = match gdef.glyph_class(4U) {
    Err(err) => fail("glyph class error: \{err}")
    Ok(value) => value
  }
  let class2 = match gdef.glyph_class(2U) {
    Err(err) => fail("glyph class error: \{err}")
    Ok(value) => value
  }
  inspect(class3, content="1")
  inspect(class4, content="2")
  inspect(class2, content="0")
  let mark_class5 = match gdef.mark_attach_class(5U) {
    Err(err) => fail("mark class error: \{err}")
    Ok(value) => value
  }
  let mark_class4 = match gdef.mark_attach_class(4U) {
    Err(err) => fail("mark class error: \{err}")
    Ok(value) => value
  }
  inspect(mark_class5, content="3")
  inspect(mark_class4, content="0")
  let in_set = match gdef.mark_glyph_set_contains(0, 5U) {
    Err(err) => fail("mark set error: \{err}")
    Ok(value) => value
  }
  let not_in_set = match gdef.mark_glyph_set_contains(0, 3U) {
    Err(err) => fail("mark set error: \{err}")
    Ok(value) => value
  }
  inspect(in_set, content="true")
  inspect(not_in_set, content="false")
}
