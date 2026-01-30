///|
test "arabic joining actions pair" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x0628U)
  let actions = arabic_joining_actions(buffer)
  inspect(actions, content="[6, 1]")
}

///|
test "arabic joining actions with transparent mark" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x064BU)
  buffer.add_codepoint(0x0628U)
  let actions = arabic_joining_actions(buffer)
  inspect(actions, content="[6, 7, 1]")
}

///|
test "arabic joining actions mongolian variation selector" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x180BU)
  let actions = arabic_joining_actions(buffer)
  apply_mongolian_variation_selectors(actions, buffer.infos)
  inspect(actions, content="[0, 0]")
}

///|
fn arabic_test_push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn arabic_test_push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn arabic_test_build_sfnt(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  arabic_test_push_u32(bytes, 0x00010000)
  arabic_test_push_u16(bytes, tables.length())
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u16(bytes, 0)
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
    arabic_test_push_u32(bytes, 0)
    arabic_test_push_u32(bytes, table_offset)
    arabic_test_push_u32(bytes, length)
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
fn arabic_test_build_head(upem : Int, loc_format : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(54, b'\x00')
  bytes[18] = ((upem >> 8) & 0xff).to_byte()
  bytes[19] = (upem & 0xff).to_byte()
  bytes[50] = ((loc_format >> 8) & 0xff).to_byte()
  bytes[51] = (loc_format & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_maxp(num_glyphs : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(6, b'\x00')
  bytes[4] = ((num_glyphs >> 8) & 0xff).to_byte()
  bytes[5] = (num_glyphs & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_hhea(number_of_hmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_hmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_hmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_vhea(number_of_vmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_vmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_vmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_hmtx() -> Bytes {
  let bytes : Array[Byte] = []
  arabic_test_push_u16(bytes, 200)
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u16(bytes, 300)
  arabic_test_push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

fn arabic_test_build_hmtx_n(count : Int, advance : Int) -> Bytes {
  let bytes : Array[Byte] = []
  let mut i = 0
  while i < count {
    arabic_test_push_u16(bytes, advance)
    arabic_test_push_u16(bytes, 0)
    i = i + 1
  }
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_vmtx() -> Bytes {
  let bytes : Array[Byte] = []
  arabic_test_push_u16(bytes, 700)
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u16(bytes, 800)
  arabic_test_push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_cmap_table(subtable : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u16(bytes, 1)
  arabic_test_push_u16(bytes, 3)
  arabic_test_push_u16(bytes, 10)
  arabic_test_push_u32(bytes, 12)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn arabic_test_build_cmap_format12(start : UInt, end : UInt, start_gid : UInt) -> Bytes {
  let bytes : Array[Byte] = []
  arabic_test_push_u16(bytes, 12)
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u32(bytes, 28)
  arabic_test_push_u32(bytes, 0)
  arabic_test_push_u32(bytes, 1)
  arabic_test_push_u32(bytes, start.reinterpret_as_int())
  arabic_test_push_u32(bytes, end.reinterpret_as_int())
  arabic_test_push_u32(bytes, start_gid.reinterpret_as_int())
  Bytes::from_array(bytes)
}

fn arabic_test_build_cmap_format12_groups(groups : Array[(UInt, UInt, UInt)]) -> Bytes {
  let bytes : Array[Byte] = []
  let length = 16 + groups.length() * 12
  arabic_test_push_u16(bytes, 12)
  arabic_test_push_u16(bytes, 0)
  arabic_test_push_u32(bytes, length)
  arabic_test_push_u32(bytes, 0)
  arabic_test_push_u32(bytes, groups.length())
  for group in groups {
    let (start, end, start_gid) = group
    arabic_test_push_u32(bytes, start.reinterpret_as_int())
    arabic_test_push_u32(bytes, end.reinterpret_as_int())
    arabic_test_push_u32(bytes, start_gid.reinterpret_as_int())
  }
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_arabic_base() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), arabic_test_build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), arabic_test_build_maxp(2)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), arabic_test_build_hhea(2)),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), arabic_test_build_vhea(2)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), arabic_test_build_hmtx()),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), arabic_test_build_vmtx()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      arabic_test_build_cmap_table(
        arabic_test_build_cmap_format12(0x0628U, 0x0628U, 1U),
      ),
    ),
  ]
  arabic_test_build_sfnt(tables)
}

fn build_font_bytes_arabic_fallback() -> Bytes {
  let base = 0x0628U
  let init = match @unicode.arabic_shaping_form(base, 0) {
    None => base
    Some(value) => value
  }
  let medi = match @unicode.arabic_shaping_form(base, 1) {
    None => base
    Some(value) => value
  }
  let fina = match @unicode.arabic_shaping_form(base, 2) {
    None => base
    Some(value) => value
  }
  let isol = match @unicode.arabic_shaping_form(base, 3) {
    None => base
    Some(value) => value
  }
  let cmap = arabic_test_build_cmap_table(
    arabic_test_build_cmap_format12_groups([
      (base, base, 1U),
      (init, init, 2U),
      (medi, medi, 3U),
      (fina, fina, 4U),
      (isol, isol, 5U),
    ]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), arabic_test_build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), arabic_test_build_maxp(6)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), arabic_test_build_hhea(6)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), arabic_test_build_hmtx_n(6, 500)),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  arabic_test_build_sfnt(tables)
}

///|
test "arabic fallback skipped for non-arabic script" {
  let font = @font.Font::from_bytes(build_font_bytes_arabic_base())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_syriac)
  buffer.add_codepoint(0x0628U)
  let result = buffer.shape_arabic(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  inspect(infos[0].codepoint, content="1")
}

///|
test "arabic fallback snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_arabic_fallback())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_arabic)
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x0628U)
  let result = buffer.shape_arabic(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  let snapshot : Array[(UInt, Int, Int, Int, Int)] = []
  for i in 0..<infos.length() {
    snapshot.push((
      infos[i].codepoint,
      infos[i].cluster,
      positions[i].x_advance,
      positions[i].x_offset,
      positions[i].y_offset,
    ))
  }
  json_inspect(snapshot, content=[[2,0,500,0,0],[4,1,500,0,0]])
}
