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
fn build_gpos_subtable_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 32)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 38)
  push_u16(bytes, 46)
  push_u16(bytes, 2)
  push_u16(bytes, 2)
  // class1 records (class2Count=2, recordSize=4)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 30)
  push_i16(bytes, -10)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // classDef1 format1
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // classDef2 format1
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_lookup_format2() -> Bytes {
  let subtable = build_gpos_subtable_format2()
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
fn build_gpos_single_subtable_format1() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0x0005)
  push_i16(bytes, 7)
  push_i16(bytes, 15)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_single_lookup_format1() -> Bytes {
  let subtable = build_gpos_single_subtable_format1()
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
fn build_gpos_single_subtable_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 12)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 2)
  push_i16(bytes, 10)
  push_i16(bytes, -5)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 3)
  push_u16(bytes, 4)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_single_lookup_format2() -> Bytes {
  let subtable = build_gpos_single_subtable_format2()
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
fn build_gsub_ligature_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // ligature set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // ligature table
  push_u16(bytes, 6)
  push_u16(bytes, 2)
  push_u16(bytes, 4)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_ligature_lookup() -> Bytes {
  let subtable = build_gsub_ligature_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_multiple_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // sequence table
  push_u16(bytes, 2)
  push_u16(bytes, 6)
  push_u16(bytes, 7)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_multiple_lookup() -> Bytes {
  let subtable = build_gsub_multiple_subtable()
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
fn build_gsub_alternate_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  // alternate set
  push_u16(bytes, 2)
  push_u16(bytes, 6)
  push_u16(bytes, 7)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_alternate_lookup() -> Bytes {
  let subtable = build_gsub_alternate_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_extension_subtable() -> Bytes {
  let inner = build_gsub_subtable(1, 3)
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u32(bytes, 8)
  for b in inner {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_extension_lookup() -> Bytes {
  let subtable = build_gsub_extension_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 7)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_extension_subtable() -> Bytes {
  let inner = build_gpos_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u32(bytes, 8)
  for b in inner {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_extension_lookup() -> Bytes {
  let subtable = build_gpos_extension_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 9)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
test "gsub single substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let changed = match gsub.apply_single(glyphs) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(changed, content="true")
  inspect(glyphs, content="[3, 2]")
}

///|
test "gpos pair adjust deltas" {
  let gpos_bytes = build_layout_table(
    build_gpos_lookup(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 2U]
  let deltas = match gpos.pair_adjust_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(deltas.length(), content="2")
  inspect(deltas[0].x_placement, content="5")
  inspect(deltas[0].x_advance, content="-20")
  inspect(deltas[1].x_advance, content="10")
}

///|
test "gpos pair adjust format2" {
  let gpos_bytes = build_layout_table(
    build_gpos_lookup_format2(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.pair_adjust_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(deltas.length(), content="2")
  inspect(deltas[0].x_advance, content="30")
  inspect(deltas[1].x_advance, content="-10")
}

///|
test "gpos single adjust format1" {
  let gpos_bytes = build_layout_table(
    build_gpos_single_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(deltas.length(), content="2")
  inspect(deltas[0].x_placement, content="7")
  inspect(deltas[0].x_advance, content="15")
  inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos single adjust format2" {
  let gpos_bytes = build_layout_table(
    build_gpos_single_lookup_format2(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(deltas.length(), content="2")
  inspect(deltas[0].x_advance, content="10")
  inspect(deltas[1].x_advance, content="-5")
}

///|
test "gsub ligature substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_ligature_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U, 5U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  inspect(changed, content="true")
  inspect(new_glyphs, content="[6, 5]")
  inspect(new_clusters, content="[0, 2]")
}

///|
test "gsub multiple substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_multiple_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let clusters : Array[Int] = [0, 1]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  inspect(changed, content="true")
  inspect(new_glyphs, content="[6, 7, 4]")
  inspect(new_clusters, content="[0, 0, 1]")
}

///|
test "gsub alternate substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_alternate_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let clusters : Array[Int] = [0, 1]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  inspect(changed, content="true")
  inspect(new_glyphs, content="[6, 4]")
  inspect(new_clusters, content="[0, 1]")
}

///|
test "gsub extension lookup apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_extension_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let changed = match gsub.apply_single(glyphs) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(changed, content="true")
  inspect(glyphs, content="[3, 2]")
}

///|
test "gpos extension lookup apply" {
  let gpos_bytes = build_layout_table(
    build_gpos_extension_lookup(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 2U]
  let deltas = match gpos.pair_adjust_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{err}")
    Ok(value) => value
  }
  inspect(deltas.length(), content="2")
  inspect(deltas[0].x_placement, content="5")
  inspect(deltas[0].x_advance, content="-20")
  inspect(deltas[1].x_advance, content="10")
}
