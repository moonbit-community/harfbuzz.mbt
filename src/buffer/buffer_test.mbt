///|
test "buffer basics" {
  let buffer = Buffer::new()
  assert_true(buffer.is_empty())
  buffer.add_codepoint(65U)
  buffer.add_codepoint(66U, cluster=10)
  inspect(buffer.len(), content="2")
  let infos = buffer.infos()
  inspect(infos[0].codepoint, content="65")
  inspect(infos[1].cluster, content="10")
}

///|
test "buffer add string" {
  let buffer = Buffer::new()
  buffer.add_string("ab")
  let infos = buffer.infos()
  inspect(buffer.len(), content="2")
  inspect(infos[0].cluster, content="0")
  inspect(infos[1].cluster, content="1")
}

///|
test "buffer properties" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ltr)
  buffer.set_script(@common.script_latin)
  buffer.set_language(@common.Language::from_string("en"))
  inspect(buffer.get_direction().to_string(), content="ltr")
  inspect(buffer.get_script().to_tag().to_string(), content="Latn")
  inspect(buffer.get_language().to_string(), content="Some(\"en\")")
}

///|
test "buffer merge clusters" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x61U, cluster=5)
  buffer.add_codepoint(0x62U, cluster=3)
  buffer.add_codepoint(0x63U, cluster=7)
  buffer.merge_clusters(0, 3)
  let clusters : Array[Int] = []
  for info in buffer.infos() {
    clusters.push(info.cluster)
  }
  inspect(clusters, content="[3, 3, 3]")
}

///|
test "buffer replace glyphs" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U, cluster=2)
  let infos0 : Array[GlyphInfo] = []
  let positions0 : Array[GlyphPosition] = []
  for info in buffer.infos() {
    infos0.push(info)
  }
  for pos in buffer.positions() {
    positions0.push(pos)
  }
  inspect(buffer.replace_glyphs(infos0), content="true")
  inspect(buffer.len(), content="1")
  let infos1 : Array[GlyphInfo] = []
  for info in buffer.infos() {
    infos1.push(info)
    infos1.push(info)
  }
  let positions1 : Array[GlyphPosition] = []
  for pos in positions0 {
    positions1.push(pos)
  }
  inspect(buffer.replace_glyphs(infos1, positions=positions1), content="false")
  inspect(buffer.len(), content="1")
}

///|
test "buffer guess segment properties" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_arabic)
  buffer.guess_segment_properties()
  inspect(buffer.get_direction().to_string(), content="rtl")
  inspect(buffer.get_language().to_string(), content="Some(\"und\")")
}

///|
test "buffer normalize combining marks" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x61U)
  buffer.add_codepoint(0x0301U)
  buffer.add_codepoint(0x0327U)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  inspect(cps, content="[97, 807, 769]")
}

///|
test "buffer normalize hebrew reorder" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hebrew)
  buffer.add_codepoint(0x05D0U)
  buffer.add_codepoint(0x05B7U)
  buffer.add_codepoint(0x05B0U)
  buffer.add_codepoint(0x05BDU)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  inspect(cps, content="[1488, 1463, 1469, 1456]")
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
  push_u16(bytes, 200)
  push_u16(bytes, 0)
  push_u16(bytes, 300)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_vmtx() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 700)
  push_u16(bytes, 0)
  push_u16(bytes, 800)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_hmtx_ot() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 200)
  push_u16(bytes, 0)
  push_u16(bytes, 300)
  push_u16(bytes, 0)
  push_u16(bytes, 400)
  push_u16(bytes, 0)
  push_u16(bytes, 500)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
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
fn build_script_list() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_tag(bytes, @common.Tag::from_chars('l', 'a', 't', 'n'))
  push_u16(bytes, 8)
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0xffff)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_feature_list(tag : @common.Tag) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_tag(bytes, tag)
  push_u16(bytes, 8)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_lookup_list(lookup : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  for b in lookup {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_layout_table(lookup : Bytes, feature_tag : @common.Tag) -> Bytes {
  let script = build_script_list()
  let feature = build_feature_list(feature_tag)
  let lookup_list = build_lookup_list(lookup)
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  let script_offset = 10
  let feature_offset = script_offset + script.length()
  let lookup_offset = feature_offset + feature.length()
  push_u16(bytes, script_offset)
  push_u16(bytes, feature_offset)
  push_u16(bytes, lookup_offset)
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
fn build_gsub_subtable(target : Int, substitute : Int) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, substitute)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, target)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_lookup() -> Bytes {
  let subtable = build_gsub_subtable(1, 3)
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 0x0005)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 1)
  push_u16(bytes, 18)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // pair set table
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_i16(bytes, 5)
  push_i16(bytes, -20)
  push_i16(bytes, 10)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_lookup() -> Bytes {
  let subtable = build_gpos_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_single_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0x0005)
  push_i16(bytes, 6)
  push_i16(bytes, 20)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_single_lookup() -> Bytes {
  let subtable = build_gpos_single_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_ot_table(
  tag : @common.Tag,
  lookup : Bytes,
  feature_tag : @common.Tag,
) -> (@common.Tag, Bytes) {
  (tag, build_layout_table(lookup, feature_tag))
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
fn build_font_bytes() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(2)),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(2)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx()),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x41U, 1U)),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_ot() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x42U, 1U)),
    ),
    build_ot_table(
      @common.Tag::from_chars('G', 'S', 'U', 'B'),
      build_gsub_lookup(),
      @common.Tag::from_chars('l', 'i', 'g', 'a'),
    ),
    build_ot_table(
      @common.Tag::from_chars('G', 'P', 'O', 'S'),
      build_gpos_lookup(),
      @common.Tag::from_chars('k', 'e', 'r', 'n'),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_ot_single() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x41U, 1U)),
    ),
    build_ot_table(
      @common.Tag::from_chars('G', 'S', 'U', 'B'),
      build_gsub_lookup(),
      @common.Tag::from_chars('l', 'i', 'g', 'a'),
    ),
    build_ot_table(
      @common.Tag::from_chars('G', 'P', 'O', 'S'),
      build_gpos_single_lookup(),
      @common.Tag::from_chars('k', 'e', 'r', 'n'),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_kern() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x42U, 1U)),
    ),
    (@common.Tag::from_chars('k', 'e', 'r', 'n'), build_kern_table()),
  ]
  build_sfnt(tables)
}

///|
test "buffer shape basic" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.add_string("A")
  let result = buffer.shape_basic(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  inspect(infos[0].codepoint, content="1")
  inspect(positions[0].x_advance, content="300")
}

///|
test "buffer shape basic vertical advances" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ttb)
  buffer.add_string("A")
  let result = buffer.shape_basic(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  inspect(positions[0].x_advance, content="0")
  inspect(positions[0].y_advance, content="-800")
}

///|
test "buffer shape ot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  inspect(infos[0].codepoint, content="3")
  inspect(infos[1].codepoint, content="2")
  inspect(positions[0].x_advance, content="480")
  inspect(positions[0].x_offset, content="5")
  inspect(positions[1].x_advance, content="410")
}

///|
test "buffer shape ot feature filter" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.set_gsub_features([@common.Tag::from_chars('k', 'e', 'r', 'n')])
  buffer.set_gpos_features([@common.Tag::from_chars('l', 'i', 'g', 'a')])
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  inspect(infos[0].codepoint, content="1")
  inspect(infos[1].codepoint, content="2")
  inspect(positions[0].x_advance, content="300")
  inspect(positions[1].x_advance, content="400")
  inspect(positions[0].x_offset, content="0")
}

///|
test "buffer shape ot single pos" {
  let font = @font.Font::from_bytes(build_font_bytes_ot_single())
  let buffer = Buffer::new()
  buffer.add_string("A")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  inspect(infos[0].codepoint, content="3")
  inspect(positions[0].x_advance, content="520")
  inspect(positions[0].x_offset, content="6")
}

///|
test "buffer shape ot kern fallback" {
  let font = @font.Font::from_bytes(build_font_bytes_kern())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  inspect(positions[0].x_advance, content="250")
  inspect(positions[1].x_advance, content="400")
  inspect(positions[0].x_offset, content="0")
}

///|
test "buffer shape ot skips kern for vertical" {
  let font = @font.Font::from_bytes(build_font_bytes_kern())
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ttb)
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{err}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  inspect(positions[0].x_advance, content="0")
}
