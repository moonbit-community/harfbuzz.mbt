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
fn build_vhea(number_of_vmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_vmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_vmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_hmtx() -> Bytes {
  let bytes : Array[Byte] = []
  // glyph 0 advance 200, lsb 0
  push_u16(bytes, 200)
  push_u16(bytes, 0)
  // glyph 1 advance 300, lsb 0
  push_u16(bytes, 300)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_vmtx() -> Bytes {
  let bytes : Array[Byte] = []
  // glyph 0 advance 700, tsb 0
  push_u16(bytes, 700)
  push_u16(bytes, 0)
  // glyph 1 advance 800, tsb 0
  push_u16(bytes, 800)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_loca_short(offsets : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for offset in offsets {
    push_u16(bytes, offset / 2)
  }
  Bytes::from_array(bytes)
}

///|
fn build_glyf_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_i16(bytes, 1)
  push_i16(bytes, 5)
  push_i16(bytes, -2)
  push_i16(bytes, 50)
  push_i16(bytes, 100)
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
fn build_font_bytes() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_short([0, 0, glyf.length()])
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(2)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx()),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(2)),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx()),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x41U, 1U)),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_fvar_table() -> Bytes {
  Bytes::from_array([
    0x00, 0x01, 0x00, 0x00, // version 1.0
    0x00, 0x10, // axis offset
    0x00, 0x02, // reserved
    0x00, 0x01, // axis count
    0x00, 0x14, // axis size
    0x00, 0x00, // instance count
    0x00, 0x08, // instance size
    0x77, 0x67, 0x68, 0x74, // 'wght'
    0xFF, 0xFF, 0x00, 0x00, // min -1.0
    0x00, 0x00, 0x00, 0x00, // default 0.0
    0x00, 0x01, 0x00, 0x00, // max 1.0
    0x00, 0x00, // flags
    0x01, 0x00, // name id
  ])
}

///|
fn build_avar_table() -> Bytes {
  Bytes::from_array([
    0x00, 0x01, 0x00, 0x00, // version 1.0
    0x00, 0x00, // reserved
    0x00, 0x01, // axis count
    0x00, 0x04, // segment count
    0xC0, 0x00, 0xC0, 0x00, // -1.0 -> -1.0
    0x00, 0x00, 0x00, 0x00, // 0.0 -> 0.0
    0x20, 0x00, 0x30, 0x00, // 0.5 -> 0.75
    0x40, 0x00, 0x40, 0x00, // 1.0 -> 1.0
  ])
}

///|
fn build_font_bytes_variations() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('a', 'v', 'a', 'r'), build_avar_table()),
  ]
  build_sfnt(tables)
}

///|
test "font basics" {
  let font = Font::from_bytes([0x00, 0x01])
  let (sx, sy) = font.get_scale()
  inspect((sx, sy), content="(0, 0)")
  font.set_scale(1000, 2000)
  inspect(font.get_scale(), content="(1000, 2000)")
  font.set_ppem(12, 14)
  inspect(font.get_ppem(), content="(12, 14)")
}

///|
test "font face access" {
  let font = Font::from_bytes([0x00])
  let face = font.get_face()
  inspect(face.get_index(), content="0")
}

///|
test "font variation coords" {
  let font = Font::from_bytes(build_font_bytes_variations())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 0.5),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  inspect(font.variation_coords(), content="[12288]")
}

///|
test "font cmap mapping and advances" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let gid = match font.glyph_for_codepoint(0x41U) {
    Err(err) => fail("lookup error: \{err}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  inspect(gid, content="1")
  let advance = match font.glyph_h_advance(gid) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="300")
}

///|
test "font vmtx advances" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let advance = match font.glyph_v_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="-800")
}

///|
test "font scale applies to advances" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  font.set_scale(2000, 2000)
  let advance = match font.glyph_h_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="600")
}

///|
test "font scale defaults to upem" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let _ = font.glyph_h_advance(1U)
  inspect(font.get_scale(), content="(1000, 1000)")
}

///|
test "font glyph bounds" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let bounds0 = match font.glyph_bounds(0U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(value) => value
  }
  inspect(bounds0, content="None")
  let bounds1 = match font.glyph_bounds(1U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(None) => fail("missing bounds")
    Ok(Some(value)) => value
  }
  inspect(bounds1.contours, content="1")
  inspect(bounds1.x_min, content="5")
  inspect(bounds1.y_min, content="-2")
  inspect(bounds1.x_max, content="50")
  inspect(bounds1.y_max, content="100")
}
