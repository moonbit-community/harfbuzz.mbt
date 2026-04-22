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
fn has_tag(tags : ArrayView[@common.Tag], tag : @common.Tag) -> Bool {
  for entry in tags {
    if entry == tag {
      return true
    }
  }
  false
}

///|
test "buffer basics" {
  let buffer = Buffer::new()
  assert_true(buffer.is_empty())
  buffer.add_codepoint(65U)
  buffer.add_codepoint(66U, cluster=10)
  @debug.debug_inspect(buffer.len(), content="2")
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="65")
  @debug.debug_inspect(infos[1].cluster, content="10")
}

///|
test "buffer add string" {
  let buffer = Buffer::new()
  buffer.add_string("ab")
  let infos = buffer.infos()
  @debug.debug_inspect(buffer.len(), content="2")
  @debug.debug_inspect(infos[0].cluster, content="0")
  @debug.debug_inspect(infos[1].cluster, content="1")
}

///|
test "buffer properties" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ltr)
  buffer.set_script(@common.script_latin)
  buffer.set_language(@common.Language::from_string("en"))
  @debug.debug_inspect(buffer.get_direction().to_string(), content="ltr")
  @debug.debug_inspect(buffer.get_script().to_tag().to_string(), content="Latn")
  @debug.debug_inspect(
    buffer.get_language().to_string(),
    content="Some(\"en\")",
  )
}

///|
test "buffer default feature list horizontal" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ltr)
  let tags = buffer.gsub_features()
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('c', 'c', 'm', 'p')),
    content="true",
  )
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('k', 'e', 'r', 'n')),
    content="true",
  )
}

///|
test "buffer default feature list vertical" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ttb)
  let tags = buffer.gsub_features()
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('v', 'e', 'r', 't')),
    content="true",
  )
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('k', 'e', 'r', 'n')),
    content="false",
  )
}

///|
test "buffer default feature list rtl" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_rtl)
  let tags = buffer.gsub_features()
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('r', 't', 'l', 'a')),
    content="true",
  )
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('r', 't', 'l', 'm')),
    content="true",
  )
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('l', 't', 'r', 'a')),
    content="false",
  )
  @debug.debug_inspect(
    has_tag(tags, @common.Tag::from_chars('r', 'c', 'l', 't')),
    content="true",
  )
}

///|
test "buffer feature list honors manual override" {
  let buffer = Buffer::new()
  let custom = @common.Tag::from_chars('a', 'b', 'c', 'd')
  let custom_gpos = @common.Tag::from_chars('w', 'x', 'y', 'z')
  buffer.set_gsub_features([custom])
  buffer.set_gpos_features([custom_gpos])
  buffer.set_direction(@common.direction_ttb)
  let gsub_tags = buffer.gsub_features()
  @debug.debug_inspect(gsub_tags.length(), content="1")
  @debug.debug_inspect(gsub_tags[0].to_string(), content="abcd")
  let gpos_tags = buffer.gpos_features()
  @debug.debug_inspect(gpos_tags.length(), content="1")
  @debug.debug_inspect(gpos_tags[0].to_string(), content="wxyz")
}

///|
test "buffer variation selector fallback" {
  let buffer = Buffer::new()
  @debug.debug_inspect(
    buffer.get_not_found_variation_selector(),
    content="None",
  )
  buffer.set_not_found_variation_selector(Some(5U))
  @debug.debug_inspect(
    buffer.get_not_found_variation_selector(),
    content="Some(5)",
  )
  buffer.set_not_found_variation_selector(None)
  @debug.debug_inspect(
    buffer.get_not_found_variation_selector(),
    content="None",
  )
}

///|
test "buffer clear preserves properties" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_rtl)
  buffer.set_script(@common.script_arabic)
  buffer.set_language(@common.Language::from_string("fa"))
  buffer.add_codepoint(0x41U)
  buffer.clear()
  @debug.debug_inspect(buffer.len(), content="0")
  @debug.debug_inspect(buffer.get_direction().to_string(), content="rtl")
  @debug.debug_inspect(buffer.get_script().to_tag().to_string(), content="Arab")
  @debug.debug_inspect(
    buffer.get_language().to_string(),
    content="Some(\"fa\")",
  )
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
  @debug.debug_inspect(clusters, content="[3, 3, 3]")
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
  @debug.debug_inspect(buffer.replace_glyphs(infos0), content="true")
  @debug.debug_inspect(buffer.len(), content="1")
  let infos1 : Array[GlyphInfo] = []
  for info in buffer.infos() {
    infos1.push(info)
    infos1.push(info)
  }
  let positions1 : Array[GlyphPosition] = []
  for pos in positions0 {
    positions1.push(pos)
  }
  @debug.debug_inspect(
    buffer.replace_glyphs(infos1, positions=positions1),
    content="false",
  )
  @debug.debug_inspect(buffer.len(), content="1")
}

///|
test "buffer verify monotone clusters" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ltr)
  buffer.add_codepoint(0x41U, cluster=0)
  buffer.add_codepoint(0x42U, cluster=2)
  @debug.debug_inspect(buffer.verify(), content="true")
}

///|
test "buffer verify non-monotone clusters" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ltr)
  buffer.add_codepoint(0x41U, cluster=3)
  buffer.add_codepoint(0x42U, cluster=1)
  @debug.debug_inspect(buffer.verify(), content="false")
}

///|
test "buffer guess segment properties" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_arabic)
  buffer.guess_segment_properties()
  @debug.debug_inspect(buffer.get_direction().to_string(), content="rtl")
  @debug.debug_inspect(
    buffer.get_language().to_string(),
    content="Some(\"und\")",
  )
}

///|
test "buffer guess segment properties script detection" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x05D0U)
  buffer.guess_segment_properties()
  @debug.debug_inspect(buffer.get_script().to_tag().to_string(), content="Hebr")
  @debug.debug_inspect(buffer.get_direction().to_string(), content="rtl")
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
  @debug.debug_inspect(cps, content="[225, 807]")
}

///|
test "buffer normalize compose" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x0301U)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[193]")
}

///|
test "buffer normalize skips variation selectors" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x0301U)
  buffer.add_codepoint(0xFE0FU)
  buffer.normalize()
  let cps : Array[UInt] = []
  let clusters : Array[Int] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
    clusters.push(info.cluster)
  }
  @debug.debug_inspect(cps, content="[65, 769, 65039]")
  @debug.debug_inspect(clusters, content="[0, 1, 1]")
}

///|
test "buffer normalize indic compose exception" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_bengali)
  buffer.add_codepoint(0x09AFU)
  buffer.add_codepoint(0x09BCU)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[2527]")
}

///|
test "buffer normalize indic skip mark-base compose" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0308U)
  buffer.add_codepoint(0x0301U)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[776, 769]")
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
  @debug.debug_inspect(cps, content="[64302, 1469, 1456]")
}

///|
test "buffer normalize hebrew compose" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hebrew)
  buffer.add_codepoint(0x05D0U)
  buffer.add_codepoint(0x05BCU)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[64304]")
}

///|
test "buffer normalize arabic reorder" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_arabic)
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x0652U)
  buffer.add_codepoint(0x0655U)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[1576, 1621, 1618]")
}

///|
test "buffer normalize hangul compose" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hangul)
  buffer.add_codepoint(0x1100U)
  buffer.add_codepoint(0x1161U)
  buffer.add_codepoint(0x11A8U)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[44033]")
}

///|
test "buffer normalize hangul tone mark" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hangul)
  buffer.add_codepoint(0xAC00U)
  buffer.add_codepoint(0x302EU)
  buffer.normalize()
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  @debug.debug_inspect(cps, content="[12334, 44032]")
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
fn push_u24(bytes : Array[Byte], value : Int) -> Unit {
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
fn build_loca_short(offsets : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for offset in offsets {
    push_u16(bytes, offset / 2)
  }
  Bytes::from_array(bytes)
}

///|
fn build_glyf_mark_fallback() -> Bytes {
  let bytes : Array[Byte] = []
  push_i16(bytes, 1)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 100)
  push_i16(bytes, 100)
  push_i16(bytes, 1)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 20)
  push_i16(bytes, 20)
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
fn build_script_list_for(tag : @common.Tag) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_tag(bytes, tag)
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
fn build_script_table(feature_indices : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0xffff)
  push_u16(bytes, feature_indices.length())
  for idx in feature_indices {
    push_u16(bytes, idx)
  }
  Bytes::from_array(bytes)
}

///|
fn build_script_list_two(
  tag1 : @common.Tag,
  table1 : Bytes,
  tag2 : @common.Tag,
  table2 : Bytes,
) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_tag(bytes, tag1)
  let first_offset = 2 + 2 * 6
  push_u16(bytes, first_offset)
  push_tag(bytes, tag2)
  let second_offset = first_offset + table1.length()
  push_u16(bytes, second_offset)
  for b in table1 {
    bytes.push(b)
  }
  for b in table2 {
    bytes.push(b)
  }
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
fn build_layout_table_with_script(
  lookup : Bytes,
  feature_tag : @common.Tag,
  script_tag : @common.Tag,
) -> Bytes {
  let script = build_script_list_for(script_tag)
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
fn build_layout_table_with_script_list(
  lookup : Bytes,
  feature_tag : @common.Tag,
  script_list : Bytes,
) -> Bytes {
  let feature = build_feature_list(feature_tag)
  let lookup_list = build_lookup_list(lookup)
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  let script_offset = 10
  let feature_offset = script_offset + script_list.length()
  let lookup_offset = feature_offset + feature.length()
  push_u16(bytes, script_offset)
  push_u16(bytes, feature_offset)
  push_u16(bytes, lookup_offset)
  for b in script_list {
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
fn build_ot_table_with_script(
  tag : @common.Tag,
  lookup : Bytes,
  feature_tag : @common.Tag,
  script_tag : @common.Tag,
) -> (@common.Tag, Bytes) {
  (tag, build_layout_table_with_script(lookup, feature_tag, script_tag))
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
fn build_cmap_format12_groups(groups : Array[(UInt, UInt, UInt)]) -> Bytes {
  let bytes : Array[Byte] = []
  let length = 16 + groups.length() * 12
  push_u16(bytes, 12)
  push_u16(bytes, 0)
  push_u32(bytes, length)
  push_u32(bytes, 0)
  push_u32(bytes, groups.length())
  for group in groups {
    let (start, end, start_gid) = group
    push_u32(bytes, start.reinterpret_as_int())
    push_u32(bytes, end.reinterpret_as_int())
    push_u32(bytes, start_gid.reinterpret_as_int())
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format14_non_default(
  selector : UInt,
  mappings : Array[(UInt, UInt)],
) -> Bytes {
  let bytes : Array[Byte] = []
  let non_default_offset = 21
  let length = non_default_offset + 4 + mappings.length() * 5
  push_u16(bytes, 14)
  push_u32(bytes, length)
  push_u32(bytes, 1)
  push_u24(bytes, selector.reinterpret_as_int())
  push_u32(bytes, 0)
  push_u32(bytes, non_default_offset)
  push_u32(bytes, mappings.length())
  for mapping in mappings {
    let (value, glyph) = mapping
    push_u24(bytes, value.reinterpret_as_int())
    push_u16(bytes, glyph.reinterpret_as_int())
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format14_default(
  selector : UInt,
  ranges : Array[(UInt, UInt)],
) -> Bytes {
  let bytes : Array[Byte] = []
  let default_offset = 21
  let length = default_offset + 4 + ranges.length() * 4
  push_u16(bytes, 14)
  push_u32(bytes, length)
  push_u32(bytes, 1)
  push_u24(bytes, selector.reinterpret_as_int())
  push_u32(bytes, default_offset)
  push_u32(bytes, 0)
  push_u32(bytes, ranges.length())
  for range in ranges {
    let (start, count) = range
    push_u24(bytes, start.reinterpret_as_int())
    push_u8(bytes, count.reinterpret_as_int())
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_table_with_variation(
  subtable : Bytes,
  variation : Bytes,
) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 2)
  let first_offset = 4 + 2 * 8
  push_u16(bytes, 3)
  push_u16(bytes, 10)
  push_u32(bytes, first_offset)
  push_u16(bytes, 0)
  push_u16(bytes, 5)
  let second_offset = first_offset + subtable.length()
  push_u32(bytes, second_offset)
  for b in subtable {
    bytes.push(b)
  }
  for b in variation {
    bytes.push(b)
  }
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
fn build_font_bytes_space_fallback() -> Bytes {
  let cmap = build_cmap_table(
    build_cmap_format12_groups([(0x0020U, 0x0020U, 1U), (0x2010U, 0x2010U, 2U)]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_default_ignorables() -> Bytes {
  let cmap = build_cmap_table(
    build_cmap_format12_groups([(0x200DU, 0x200DU, 1U)]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_variation_selector() -> Bytes {
  let cmap = build_cmap_table_with_variation(
    build_cmap_format12(0x41U, 0x41U, 1U),
    build_cmap_format14_non_default(0xFE0FU, [(0x41U, 3U)]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_variation_selector_default() -> Bytes {
  let cmap = build_cmap_table_with_variation(
    build_cmap_format12(0x41U, 0x41U, 1U),
    build_cmap_format14_default(0xFE0FU, [(0x41U, 0U)]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
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
fn build_font_bytes_ot_single_hebr() -> Bytes {
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
    build_ot_table_with_script(
      @common.Tag::from_chars('G', 'P', 'O', 'S'),
      build_gpos_single_lookup(),
      @common.Tag::from_chars('k', 'e', 'r', 'n'),
      @common.Tag::from_chars('h', 'e', 'b', 'r'),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_indic3() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x0915U, 0x0915U, 1U)),
    ),
    build_ot_table_with_script(
      @common.Tag::from_chars('G', 'S', 'U', 'B'),
      build_gsub_lookup(),
      @common.Tag::from_chars('i', 's', 'o', 'l'),
      @common.Tag::from_chars('d', 'e', 'v', '3'),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_indic_dev2_dflt() -> Bytes {
  let dflt_table = build_script_table([])
  let dev2_table = build_script_table([0])
  let script_list = build_script_list_two(
    @common.Tag::from_chars('D', 'F', 'L', 'T'),
    dflt_table,
    @common.Tag::from_chars('d', 'e', 'v', '2'),
    dev2_table,
  )
  let gsub_table = build_layout_table_with_script_list(
    build_gsub_lookup(),
    @common.Tag::from_chars('r', 'p', 'h', 'f'),
    script_list,
  )
  let cmap = build_cmap_table(
    build_cmap_format12_groups([
      (0x0930U, 0x0930U, 1U),
      (0x094DU, 0x094DU, 2U),
      (0x0915U, 0x0915U, 3U),
    ]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
    (@common.Tag::from_chars('G', 'S', 'U', 'B'), gsub_table),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_myanmar_mym2_dflt() -> Bytes {
  let dflt_table = build_script_table([])
  let mym2_table = build_script_table([0])
  let script_list = build_script_list_two(
    @common.Tag::from_chars('D', 'F', 'L', 'T'),
    dflt_table,
    @common.Tag::from_chars('m', 'y', 'm', '2'),
    mym2_table,
  )
  let gsub_table = build_layout_table_with_script_list(
    build_gsub_lookup(),
    @common.Tag::from_chars('r', 'p', 'h', 'f'),
    script_list,
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x1000U, 0x1000U, 1U)),
    ),
    (@common.Tag::from_chars('G', 'S', 'U', 'B'), gsub_table),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_syrc_gsub() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x0628U, 0x0628U, 1U)),
    ),
    build_ot_table_with_script(
      @common.Tag::from_chars('G', 'S', 'U', 'B'),
      build_gsub_lookup(),
      @common.Tag::from_chars('i', 's', 'o', 'l'),
      @common.Tag::from_chars('s', 'y', 'r', 'c'),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_dflt_gsub() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x0628U, 0x0628U, 1U)),
    ),
    build_ot_table_with_script(
      @common.Tag::from_chars('G', 'S', 'U', 'B'),
      build_gsub_lookup(),
      @common.Tag::from_chars('l', 'i', 'g', 'a'),
      @common.Tag::from_chars('D', 'F', 'L', 'T'),
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
fn build_font_bytes_kern_with_gpos() -> Bytes {
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
    build_ot_table(
      @common.Tag::from_chars('G', 'P', 'O', 'S'),
      build_gpos_lookup(),
      @common.Tag::from_chars('m', 'a', 'r', 'k'),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_mark_fallback() -> Bytes {
  let cmap = build_cmap_table(
    build_cmap_format12_groups([(0x41U, 0x41U, 1U), (0x0301U, 0x0301U, 2U)]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  build_sfnt(tables)
}

///|
fn build_gdef_mark_class_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 12)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  // glyph class def (glyph 2 -> class 3)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_mark_fallback_gdef() -> Bytes {
  let cmap = build_cmap_table(
    build_cmap_format12_groups([(0x41U, 0x41U, 1U), (0x42U, 0x42U, 2U)]),
  )
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
    (@common.Tag::from_chars('G', 'D', 'E', 'F'), build_gdef_mark_class_table()),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_mark_fallback_position() -> Bytes {
  let cmap = build_cmap_table(
    build_cmap_format12_groups([(0x41U, 0x41U, 1U), (0x0301U, 0x0301U, 2U)]),
  )
  let glyf = build_glyf_mark_fallback()
  let loca = build_loca_short([
    0,
    0,
    glyf.length() / 2,
    glyf.length(),
    glyf.length(),
  ])
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_ot()),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
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
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="1")
  @debug.debug_inspect(positions[0].x_advance, content="300")
}

///|
test "buffer shape basic fallback for space and hyphen" {
  let font = @font.Font::from_bytes(build_font_bytes_space_fallback())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x00A0U)
  buffer.add_codepoint(0x2011U)
  let result = buffer.shape_basic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="1")
  @debug.debug_inspect(infos[1].codepoint, content="2")
}

///|
test "buffer shape basic fallback space advances" {
  let font = @font.Font::from_bytes(build_font_bytes_space_fallback())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x2003U)
  buffer.add_codepoint(0x202FU)
  let result = buffer.shape_basic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="1000")
  @debug.debug_inspect(positions[1].x_advance, content="150")
}

///|
test "buffer shape basic vertical advances" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ttb)
  buffer.add_string("A")
  let result = buffer.shape_basic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="0")
  @debug.debug_inspect(positions[0].y_advance, content="-800")
}

///|
test "buffer shape ot default ignorable zeroed" {
  let font = @font.Font::from_bytes(build_font_bytes_default_ignorables())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x200DU)
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="1")
  @debug.debug_inspect(positions[0].x_advance, content="0")
}

///|
test "buffer shape ot default ignorable zeroed snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_default_ignorables())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x200DU)
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 0, 0, 0]])
}

///|
test "buffer shape ot preserve default ignorable" {
  let font = @font.Font::from_bytes(build_font_bytes_default_ignorables())
  let buffer = Buffer::new()
  buffer.set_preserve_default_ignorables(true)
  buffer.add_codepoint(0x200DU)
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="300")
}

///|
test "buffer shape ot preserve default ignorable snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_default_ignorables())
  let buffer = Buffer::new()
  buffer.set_preserve_default_ignorables(true)
  buffer.add_codepoint(0x200DU)
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0]])
}

///|
test "buffer shape ot variation selector fallback" {
  let font = @font.Font::from_bytes(build_font_bytes_default_ignorables())
  let buffer = Buffer::new()
  buffer.set_remove_default_ignorables(true)
  buffer.set_not_found_variation_selector(Some(3U))
  buffer.add_codepoint(0xFE0FU)
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  @debug.debug_inspect(buffer.len(), content="1")
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="3")
  @debug.debug_inspect(positions[0].x_advance, content="0")
}

///|
test "buffer shape ot variation selector fallback snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_default_ignorables())
  let buffer = Buffer::new()
  buffer.set_remove_default_ignorables(true)
  buffer.set_not_found_variation_selector(Some(3U))
  buffer.add_codepoint(0xFE0FU)
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[3, 0, 0, 0, 0]])
}

///|
test "buffer shape ot variation selector mapping snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_variation_selector())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0xFE0FU)
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0]])
}

///|
test "buffer shape ot variation selector default snapshot" {
  let font = @font.Font::from_bytes(
    build_font_bytes_variation_selector_default(),
  )
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0xFE0FU)
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0]])
}

///|
test "buffer serialize glyphs json" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let output = buffer.serialize(format=BufferSerializeFormat::Json)
  @debug.debug_inspect(
    output,
    content="[{\"g\":3,\"cl\":0,\"dx\":5,\"dy\":0,\"ax\":480,\"ay\":0},{\"g\":2,\"cl\":1,\"dx\":0,\"dy\":0,\"ax\":410,\"ay\":0}]",
  )
}

///|
test "buffer serialize unicode text" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let output = buffer.serialize(
    format=BufferSerializeFormat::Text,
    mode=BufferSerializeMode::Unicode,
    no_positions=true,
  )
  @debug.debug_inspect(output, content="<U+0041=0|U+0042=1>")
}

///|
test "buffer shape ot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="3")
  @debug.debug_inspect(infos[1].codepoint, content="2")
  @debug.debug_inspect(positions[0].x_advance, content="480")
  @debug.debug_inspect(positions[0].x_offset, content="5")
  @debug.debug_inspect(positions[1].x_advance, content="410")
}

///|
test "buffer shape ot snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[3, 0, 480, 5, 0], [2, 1, 410, 0, 0]])
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
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="1")
  @debug.debug_inspect(infos[1].codepoint, content="2")
  @debug.debug_inspect(positions[0].x_advance, content="300")
  @debug.debug_inspect(positions[1].x_advance, content="400")
  @debug.debug_inspect(positions[0].x_offset, content="0")
}

///|
test "buffer shape ot feature filter snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.set_gsub_features([@common.Tag::from_chars('k', 'e', 'r', 'n')])
  buffer.set_gpos_features([@common.Tag::from_chars('l', 'i', 'g', 'a')])
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0], [2, 1, 400, 0, 0]])
}

///|
test "buffer shape ot single pos" {
  let font = @font.Font::from_bytes(build_font_bytes_ot_single())
  let buffer = Buffer::new()
  buffer.add_string("A")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="3")
  @debug.debug_inspect(positions[0].x_advance, content="520")
  @debug.debug_inspect(positions[0].x_offset, content="6")
}

///|
test "buffer shape ot single pos snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot_single())
  let buffer = Buffer::new()
  buffer.add_string("A")
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[3, 0, 520, 6, 0]])
}

///|
test "buffer shape ot kern fallback" {
  let font = @font.Font::from_bytes(build_font_bytes_kern())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="250")
  @debug.debug_inspect(positions[1].x_advance, content="400")
  @debug.debug_inspect(positions[0].x_offset, content="0")
}

///|
test "buffer shape ot kern fallback snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_kern())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 250, 0, 0], [2, 1, 400, 0, 0]])
}

///|
test "buffer shape ot kern fallback with non-kern gpos" {
  let font = @font.Font::from_bytes(build_font_bytes_kern_with_gpos())
  let buffer = Buffer::new()
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="250")
  @debug.debug_inspect(positions[1].x_advance, content="400")
  @debug.debug_inspect(positions[0].x_offset, content="0")
}

///|
test "buffer shape ot zeroes mark advances without gpos" {
  let font = @font.Font::from_bytes(build_font_bytes_mark_fallback())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x0301U)
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="300")
  @debug.debug_inspect(positions[1].x_advance, content="0")
}

///|
test "buffer shape ot zeroes mark advances using gdef mark class" {
  let font = @font.Font::from_bytes(build_font_bytes_mark_fallback_gdef())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x42U)
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="300")
  @debug.debug_inspect(positions[1].x_advance, content="0")
}

///|
test "buffer shape ot gdef mark class snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_mark_fallback_gdef())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x42U)
  let result = buffer.shape_ot(font)
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

///|
test "buffer shape ot fallback mark positioning without gpos" {
  let font = @font.Font::from_bytes(build_font_bytes_mark_fallback_position())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x0301U)
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[1].x_advance, content="0")
  @debug.debug_inspect(positions[1].x_offset, content="140")
  @debug.debug_inspect(positions[1].y_offset, content="122")
}

///|
test "buffer shape ot fallback mark positioning snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_mark_fallback_position())
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x0301U)
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0], [2, 1, 0, 140, 122]])
}

///|
test "buffer shape ot skips kern for vertical" {
  let font = @font.Font::from_bytes(build_font_bytes_kern())
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ttb)
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let positions = buffer.positions()
  @debug.debug_inspect(positions[0].x_advance, content="0")
}

///|
test "buffer shape ot skips kern for vertical snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_kern())
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ttb)
  buffer.add_string("AB")
  let result = buffer.shape_ot(font)
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
  json_inspect(snapshot, content=[[1, 0, 0, 0, 0], [2, 1, 0, 0, 0]])
}

///|
test "buffer shape myanmar fallback" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_myanmar)
  buffer.add_string("A")
  let result = buffer.shape_myanmar(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="1")
}

///|
test "buffer shape myanmar fallback snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_myanmar)
  buffer.add_string("A")
  let result = buffer.shape_myanmar(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0]])
}

///|
test "buffer shape myanmar prefers mym2 over dflt" {
  let font = @font.Font::from_bytes(build_font_bytes_myanmar_mym2_dflt())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_myanmar)
  buffer.add_codepoint(0x1000U)
  let result = buffer.shape_myanmar(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="3")
}

///|
test "buffer shape myanmar prefers mym2 over dflt snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_myanmar_mym2_dflt())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_myanmar)
  buffer.add_codepoint(0x1000U)
  let result = buffer.shape_myanmar(font)
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
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0]])
}

///|
test "buffer shape indic fallback" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_string("A")
  let result = buffer.shape_indic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="1")
}

///|
test "buffer shape indic fallback snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_string("A")
  let result = buffer.shape_indic(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0]])
}

///|
test "buffer shape indic routes to use for dev3 gsub" {
  let font = @font.Font::from_bytes(build_font_bytes_indic3())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0915U)
  let result = buffer.shape_indic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="3")
}

///|
test "buffer shape indic routes to use for dev3 gsub snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_indic3())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0915U)
  let result = buffer.shape_indic(font)
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
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0]])
}

///|
test "buffer shape indic prefers dev2 over dflt" {
  let font = @font.Font::from_bytes(build_font_bytes_indic_dev2_dflt())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0930U)
  buffer.add_codepoint(0x094DU)
  buffer.add_codepoint(0x0915U)
  let result = buffer.shape_indic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let mut has_ra = false
  for info in buffer.infos() {
    if info.codepoint == 1U {
      has_ra = true
    }
  }
  @debug.debug_inspect(has_ra, content="false")
}

///|
test "buffer shape indic prefers dev2 over dflt snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_indic_dev2_dflt())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0930U)
  buffer.add_codepoint(0x094DU)
  buffer.add_codepoint(0x0915U)
  let result = buffer.shape_indic(font)
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
  json_inspect(snapshot, content=[
    [3, 0, 500, 0, 0],
    [2, 0, 400, 0, 0],
    [3, 0, 500, 0, 0],
  ])
}

///|
test "buffer shape arabic syriac uses gsub when syrc present" {
  let font = @font.Font::from_bytes(build_font_bytes_syrc_gsub())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_syriac)
  buffer.add_codepoint(0x0628U)
  let result = buffer.shape_arabic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="3")
}

///|
test "buffer shape arabic syriac uses gsub snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_syrc_gsub())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_syriac)
  buffer.add_codepoint(0x0628U)
  let result = buffer.shape_arabic(font)
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
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0]])
}

///|
test "buffer shape arabic syriac falls back to dflt gsub" {
  let font = @font.Font::from_bytes(build_font_bytes_dflt_gsub())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_syriac)
  buffer.add_codepoint(0x0628U)
  let result = buffer.shape_arabic(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="3")
}

///|
test "buffer shape arabic syriac dflt gsub snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_dflt_gsub())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_syriac)
  buffer.add_codepoint(0x0628U)
  let result = buffer.shape_arabic(font)
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
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0]])
}

///|
test "buffer shape use fallback" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_sinhala)
  buffer.add_string("A")
  let result = buffer.shape_use(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  @debug.debug_inspect(infos[0].codepoint, content="1")
}

///|
test "buffer shape use fallback snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_sinhala)
  buffer.add_string("A")
  let result = buffer.shape_use(font)
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
  json_inspect(snapshot, content=[[1, 0, 300, 0, 0]])
}

///|
test "buffer shape hebrew skips gpos without hebr" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hebrew)
  buffer.add_string("AB")
  let result = buffer.shape_hebrew(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="3")
  @debug.debug_inspect(infos[1].codepoint, content="2")
  @debug.debug_inspect(positions[0].x_advance, content="500")
  @debug.debug_inspect(positions[1].x_advance, content="400")
  @debug.debug_inspect(positions[0].x_offset, content="0")
}

///|
test "buffer shape hebrew skips gpos without hebr snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hebrew)
  buffer.add_string("AB")
  let result = buffer.shape_hebrew(font)
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
  json_inspect(snapshot, content=[[3, 0, 500, 0, 0], [2, 1, 400, 0, 0]])
}

///|
test "buffer shape hebrew applies hebr gpos" {
  let font = @font.Font::from_bytes(build_font_bytes_ot_single_hebr())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hebrew)
  buffer.add_string("A")
  let result = buffer.shape_hebrew(font)
  match result {
    Err(err) => fail("shape error: \{@debug.to_string(err)}")
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  @debug.debug_inspect(infos[0].codepoint, content="3")
  @debug.debug_inspect(positions[0].x_advance, content="520")
  @debug.debug_inspect(positions[0].x_offset, content="6")
}

///|
test "buffer shape hebrew applies hebr gpos snapshot" {
  let font = @font.Font::from_bytes(build_font_bytes_ot_single_hebr())
  let buffer = Buffer::new()
  buffer.set_script(@common.script_hebrew)
  buffer.add_string("A")
  let result = buffer.shape_hebrew(font)
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
  json_inspect(snapshot, content=[[3, 0, 520, 6, 0]])
}
