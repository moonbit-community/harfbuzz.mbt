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
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_sfnt(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, tables.length())
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
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
    push_u32(bytes, 0)
    push_u32(bytes, table_offset)
    push_u32(bytes, length)
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
fn build_head(upem : Int, loc_format : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(54, b'\x00')
  bytes[18] = ((upem >> 8) & 0xff).to_byte()
  bytes[19] = (upem & 0xff).to_byte()
  bytes[50] = ((loc_format >> 8) & 0xff).to_byte()
  bytes[51] = (loc_format & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_maxp(num_glyphs : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(6, b'\x00')
  bytes[4] = ((num_glyphs >> 8) & 0xff).to_byte()
  bytes[5] = (num_glyphs & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_hhea(number_of_hmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_hmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_hmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_hmtx(advances : Array[Int], lsbs : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for i in 0..<advances.length() {
    push_u16(bytes, advances[i])
    push_i16(bytes, lsbs[i])
  }
  Bytes::from_array(bytes)
}

///|
fn build_loca_long(offsets : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for offset in offsets {
    push_u32(bytes, offset)
  }
  Bytes::from_array(bytes)
}

///|
fn build_simple_glyph() -> Array[Byte] {
  let bytes : Array[Byte] = []
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_u16(bytes, 0)
  bytes
}

///|
fn build_composite_glyph(component_gid : Int) -> Array[Byte] {
  let bytes : Array[Byte] = []
  push_i16(bytes, -1)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_u16(bytes, 0x0003)
  push_u16(bytes, component_gid)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  bytes
}

///|
fn build_glyf_table() -> Bytes {
  let bytes : Array[Byte] = []
  let glyph1 = build_simple_glyph()
  let glyph2 = build_composite_glyph(3)
  let glyph3 = build_simple_glyph()
  for b in glyph1 {
    bytes.push(b)
  }
  for b in glyph2 {
    bytes.push(b)
  }
  for b in glyph3 {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
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
fn build_font_bytes_subset_fixture() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_long([0, 0, 12, 30, 42])
  let cmap = build_cmap_table(build_cmap_format12(0x41U, 0x42U, 1U))
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 1)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx([500, 600, 700, 800], [0, 10, 20, 30])),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  build_sfnt(tables)
}

///|
test "subset drops unused glyphs" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gid = match subset_font.glyph_for_codepoint(0x41U) {
    Err(err) => fail("glyph lookup failed: \{err}")
    Ok(value) => value
  }
  assert_true(gid is Some(1U))
  let missing = match subset_font.glyph_for_codepoint(0x42U) {
    Err(err) => fail("glyph lookup failed: \{err}")
    Ok(value) => value
  }
  assert_true(missing is None)
  let maxp = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('m', 'a', 'x', 'p'),
  ) {
    Err(err) => fail("maxp table missing: \{err}")
    Ok(None) => fail("maxp table missing")
    Ok(Some(blob)) =>
      match @sfnt.MaxpTable::parse(blob.as_view()) {
        Err(err) => fail("maxp parse failed: \{err}")
        Ok(value) => value
      }
  }
  inspect(maxp.num_glyphs, content="2")
}

///|
test "subset remaps composite components" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gid = match subset_font.glyph_for_codepoint(0x42U) {
    Err(err) => fail("glyph lookup failed: \{err}")
    Ok(value) => value
  }
  assert_true(gid is Some(1U))
  let face = subset_font.get_face()
  let head = match face.reference_table_optional(@common.Tag::from_chars('h', 'e', 'a', 'd')) {
    Err(err) => fail("head table missing: \{err}")
    Ok(None) => fail("head table missing")
    Ok(Some(blob)) =>
      match @sfnt.HeadTable::parse(blob.as_view()) {
        Err(err) => fail("head parse failed: \{err}")
        Ok(value) => value
      }
  }
  let loca = match face.reference_table_optional(@common.Tag::from_chars('l', 'o', 'c', 'a')) {
    Err(err) => fail("loca table missing: \{err}")
    Ok(None) => fail("loca table missing")
    Ok(Some(blob)) =>
      match @sfnt.LocaTable::parse(blob.as_view(), 3, head.index_to_loc_format) {
        Err(err) => fail("loca parse failed: \{err}")
        Ok(value) => value
      }
  }
  let glyf = match face.reference_table_optional(@common.Tag::from_chars('g', 'l', 'y', 'f')) {
    Err(err) => fail("glyf table missing: \{err}")
    Ok(None) => fail("glyf table missing")
    Ok(Some(blob)) =>
      match @sfnt.GlyfTable::parse(blob) {
        Err(err) => fail("glyf parse failed: \{err}")
        Ok(value) => value
      }
  }
  let start = loca.offsets[1]
  let end = loca.offsets[2]
  let comps = match glyf.glyph_composite_components(start, end - start) {
    Err(err) => fail("composite parse failed: \{err}")
    Ok(value) => value
  }
  match comps {
    None => fail("expected composite glyph")
    Some(components) => inspect(components[0].glyph, content="2")
  }
}
