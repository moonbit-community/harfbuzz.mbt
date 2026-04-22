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
fn build_lookup_list_with_lookups(lookups : Array[Bytes]) -> Bytes {
  let bytes : Array[Byte] = []
  let count = lookups.length()
  push_u16(bytes, count)
  let header_len = 2 + count * 2
  let mut cursor = header_len
  for lookup in lookups {
    push_u16(bytes, cursor)
    cursor = cursor + lookup.length()
  }
  for lookup in lookups {
    for b in lookup {
      bytes.push(b)
    }
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
fn build_layout_table_with_lookups(
  lookups : Array[Bytes],
  feature_tag : @common.Tag,
) -> Bytes {
  let script = build_script_list()
  let feature = build_feature_list(feature_tag)
  let lookup_list = build_lookup_list_with_lookups(lookups)
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
fn build_gsub_single_lookup(target : Int, substitute : Int) -> Bytes {
  let subtable = build_gsub_subtable(target, substitute)
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
fn build_gsub_single_subtable_format2_two() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 10)
  push_u16(bytes, 2)
  push_u16(bytes, 9)
  push_u16(bytes, 10)
  // coverage table (glyphs 5, 6)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 5)
  push_u16(bytes, 6)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_single_lookup_mark_filter() -> Bytes {
  let subtable = build_gsub_single_subtable_format2_two()
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_single_lookup_mark_attach_type() -> Bytes {
  let subtable = build_gsub_single_subtable_format2_two()
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0x0100)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_single_lookup_ignore_base() -> Bytes {
  let subtable = build_gsub_subtable(3, 9)
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0x0002)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_single_lookup_ignore_ligature() -> Bytes {
  let subtable = build_gsub_subtable(4, 9)
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0x0004)
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
fn build_gpos_pair_subtable_format1(first : Int, second : Int) -> Bytes {
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
  push_u16(bytes, first)
  // pair set table
  push_u16(bytes, 1)
  push_u16(bytes, second)
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
fn build_gpos_pair_lookup_ignore_marks() -> Bytes {
  let subtable = build_gpos_pair_subtable_format1(5, 2)
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 0x0008)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_pair_lookup_ignore_ligature() -> Bytes {
  let subtable = build_gpos_pair_subtable_format1(4, 2)
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_pair_lookup_ignore_base() -> Bytes {
  let subtable = build_gpos_pair_subtable_format1(3, 2)
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 0x0002)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_lookup_mark_filter() -> Bytes {
  let subtable = build_gpos_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
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
fn build_gpos_single_subtable_format1_mark() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0x0005)
  push_i16(bytes, 7)
  push_i16(bytes, 15)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
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
fn build_gpos_single_lookup_format1_ignore_marks() -> Bytes {
  let subtable = build_gpos_single_subtable_format1_mark()
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0x0008)
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
fn build_gpos_cursive_subtable_format1() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  push_u16(bytes, 2)
  // entry/exit records
  push_u16(bytes, 0)
  push_u16(bytes, 22)
  push_u16(bytes, 28)
  push_u16(bytes, 0)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 9)
  push_u16(bytes, 10)
  // exit anchor (glyph 9)
  push_u16(bytes, 1)
  push_i16(bytes, 20)
  push_i16(bytes, 5)
  // entry anchor (glyph 10)
  push_u16(bytes, 1)
  push_i16(bytes, 7)
  push_i16(bytes, 2)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_cursive_subtable_format1_mark() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  push_u16(bytes, 2)
  // entry/exit records
  push_u16(bytes, 0)
  push_u16(bytes, 22)
  push_u16(bytes, 28)
  push_u16(bytes, 0)
  // coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 5)
  push_u16(bytes, 10)
  // exit anchor (glyph 5)
  push_u16(bytes, 1)
  push_i16(bytes, 20)
  push_i16(bytes, 5)
  // entry anchor (glyph 10)
  push_u16(bytes, 1)
  push_i16(bytes, 7)
  push_i16(bytes, 2)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_cursive_lookup_format1() -> Bytes {
  let subtable = build_gpos_cursive_subtable_format1()
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
fn build_gpos_cursive_lookup_format1_ignore_marks() -> Bytes {
  let subtable = build_gpos_cursive_subtable_format1_mark()
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 0x0008)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_context_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // rule: [3, 4] -> apply lookup 1 at index 0
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_context_subtable_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 26)
  push_u16(bytes, 32)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 12)
  // class rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // class rule: [class1, class1] -> apply lookup 1 at index 0
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // class def (glyphs 3..4 -> class 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_context_lookup_format2() -> Bytes {
  let subtable = build_gpos_context_subtable_format2()
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
fn build_gpos_context_subtable_format3() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  push_u16(bytes, 20)
  // pos lookup record (seq index 0, lookup index 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  // coverage table 1 (glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // coverage table 2 (glyph 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_context_lookup_format3() -> Bytes {
  let subtable = build_gpos_context_subtable_format3()
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
fn build_gpos_context_lookup() -> Bytes {
  let subtable = build_gpos_context_subtable()
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
fn build_gpos_context_lookup_ignore_base() -> Bytes {
  let subtable = build_gpos_context_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 7)
  push_u16(bytes, 0x0002)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_context_mark_to_base_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // rule: [3, 5] -> apply lookup 1 at index 1
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_context_mark_to_base_lookup() -> Bytes {
  let subtable = build_gpos_context_mark_to_base_subtable()
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
fn build_gpos_chain_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 32)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  // chain rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // chain rule
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 4)
  push_u16(bytes, 5)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_chain_subtable_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 38)
  push_u16(bytes, 44)
  push_u16(bytes, 44)
  push_u16(bytes, 44)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 16)
  // chain class rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // chain class rule: backtrack class 1, input class 1, lookahead class 1
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // class def (glyphs 1..4 -> class 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_chain_lookup_format2() -> Bytes {
  let subtable = build_gpos_chain_subtable_format2()
  let bytes : Array[Byte] = []
  push_u16(bytes, 8)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_chain_subtable_format3() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 22)
  push_u16(bytes, 2)
  push_u16(bytes, 28)
  push_u16(bytes, 34)
  push_u16(bytes, 1)
  push_u16(bytes, 40)
  push_u16(bytes, 1)
  // pos lookup record (seq index 0, lookup index 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  // backtrack coverage (glyph 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // input coverage 1 (glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // input coverage 2 (glyph 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // lookahead coverage (glyph 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_chain_lookup_format3() -> Bytes {
  let subtable = build_gpos_chain_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 8)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_chain_lookup_format3_mark_filter() -> Bytes {
  let subtable = build_gpos_chain_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 8)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_chain_lookup() -> Bytes {
  let subtable = build_gpos_chain_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 8)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_base_subtable_format1() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 18)
  push_u16(bytes, 1)
  push_u16(bytes, 24)
  push_u16(bytes, 30)
  // mark coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  // base coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // mark array
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 10)
  // base array
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  // mark anchor
  push_u16(bytes, 1)
  push_i16(bytes, 10)
  push_i16(bytes, 5)
  // base anchor
  push_u16(bytes, 1)
  push_i16(bytes, 15)
  push_i16(bytes, 20)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_base_subtable_format1_two_marks() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 20)
  push_u16(bytes, 1)
  push_u16(bytes, 26)
  push_u16(bytes, 36)
  // mark coverage table (glyphs 5, 6)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 5)
  push_u16(bytes, 6)
  // base coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // mark array (2 records, anchors at 14 and 20 from mark array base)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 14)
  push_u16(bytes, 0)
  push_u16(bytes, 20)
  // base array
  push_u16(bytes, 1)
  push_u16(bytes, 16)
  // mark anchor 1
  push_u16(bytes, 1)
  push_i16(bytes, 10)
  push_i16(bytes, 5)
  // mark anchor 2
  push_u16(bytes, 1)
  push_i16(bytes, 10)
  push_i16(bytes, 5)
  // base anchor
  push_u16(bytes, 1)
  push_i16(bytes, 15)
  push_i16(bytes, 20)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_base_lookup_format1() -> Bytes {
  let subtable = build_gpos_mark_to_base_subtable_format1()
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
fn build_gpos_mark_to_base_lookup_format1_mark_filter() -> Bytes {
  let subtable = build_gpos_mark_to_base_subtable_format1_two_marks()
  let bytes : Array[Byte] = []
  push_u16(bytes, 4)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_base_lookup_format1_mark_attach_type() -> Bytes {
  let subtable = build_gpos_mark_to_base_subtable_format1_two_marks()
  let bytes : Array[Byte] = []
  push_u16(bytes, 4)
  push_u16(bytes, 0x0100)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_mark_subtable_format1() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 18)
  push_u16(bytes, 1)
  push_u16(bytes, 24)
  push_u16(bytes, 36)
  // mark1 coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  // mark2 coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 7)
  // mark1 array
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 6)
  // mark1 anchor
  push_u16(bytes, 1)
  push_i16(bytes, 3)
  push_i16(bytes, 4)
  // mark2 array
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // mark2 anchor
  push_u16(bytes, 1)
  push_i16(bytes, 8)
  push_i16(bytes, 10)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_mark_subtable_format1_two_marks() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 20)
  push_u16(bytes, 1)
  push_u16(bytes, 28)
  push_u16(bytes, 50)
  // mark1 coverage table (glyphs 5, 6)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 5)
  push_u16(bytes, 6)
  // mark2 coverage table (glyphs 5, 6)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 5)
  push_u16(bytes, 6)
  // mark1 array (2 records, anchors at 10 and 16 from mark1 array base)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  push_u16(bytes, 16)
  // mark1 anchor 1
  push_u16(bytes, 1)
  push_i16(bytes, 3)
  push_i16(bytes, 4)
  // mark1 anchor 2
  push_u16(bytes, 1)
  push_i16(bytes, 3)
  push_i16(bytes, 4)
  // mark2 array (2 records, anchors at 6 and 12 from mark2 array base)
  push_u16(bytes, 2)
  push_u16(bytes, 6)
  push_u16(bytes, 12)
  // mark2 anchor 1
  push_u16(bytes, 1)
  push_i16(bytes, 8)
  push_i16(bytes, 10)
  // mark2 anchor 2
  push_u16(bytes, 1)
  push_i16(bytes, 8)
  push_i16(bytes, 10)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_mark_lookup_format1() -> Bytes {
  let subtable = build_gpos_mark_to_mark_subtable_format1()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_mark_lookup_format1_mark_filter() -> Bytes {
  let subtable = build_gpos_mark_to_mark_subtable_format1_two_marks()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_mark_lookup_format1_mark_attach_type() -> Bytes {
  let subtable = build_gpos_mark_to_mark_subtable_format1_two_marks()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0100)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_ligature_subtable_format1() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 18)
  push_u16(bytes, 1)
  push_u16(bytes, 24)
  push_u16(bytes, 30)
  // mark coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  // ligature coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  // mark array
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 20)
  // ligature array
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // ligature attach
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // ligature anchor
  push_u16(bytes, 1)
  push_i16(bytes, 12)
  push_i16(bytes, 15)
  // mark anchor
  push_u16(bytes, 1)
  push_i16(bytes, 3)
  push_i16(bytes, 4)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_ligature_subtable_format1_two_marks() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 12)
  push_u16(bytes, 20)
  push_u16(bytes, 1)
  push_u16(bytes, 26)
  push_u16(bytes, 36)
  // mark coverage table (glyphs 5, 6)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 5)
  push_u16(bytes, 6)
  // ligature coverage table
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  // mark array (2 records, anchors at 24 and 30 from mark array base)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 24)
  push_u16(bytes, 0)
  push_u16(bytes, 30)
  // ligature array
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // ligature attach
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // ligature anchor
  push_u16(bytes, 1)
  push_i16(bytes, 12)
  push_i16(bytes, 15)
  // mark anchor 1
  push_u16(bytes, 1)
  push_i16(bytes, 3)
  push_i16(bytes, 4)
  // mark anchor 2
  push_u16(bytes, 1)
  push_i16(bytes, 3)
  push_i16(bytes, 4)
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_ligature_lookup_format1() -> Bytes {
  let subtable = build_gpos_mark_to_ligature_subtable_format1()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_ligature_lookup_format1_mark_filter() -> Bytes {
  let subtable = build_gpos_mark_to_ligature_subtable_format1_two_marks()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gpos_mark_to_ligature_lookup_format1_mark_attach_type() -> Bytes {
  let subtable = build_gpos_mark_to_ligature_subtable_format1_two_marks()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0x0100)
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
fn build_gsub_reverse_chain_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 16)
  push_u16(bytes, 1)
  push_u16(bytes, 22)
  push_u16(bytes, 1)
  push_u16(bytes, 28)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // backtrack coverage (glyph 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // lookahead coverage (glyph 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_reverse_chain_lookup() -> Bytes {
  let subtable = build_gsub_reverse_chain_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 8)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_reverse_chain_lookup_mark_filter() -> Bytes {
  let subtable = build_gsub_reverse_chain_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 8)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // subrule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // subrule: [3, 4] -> apply lookup 1 at index 1
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_subtable_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 26)
  push_u16(bytes, 32)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 12)
  // class rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // class rule: [class1, class1] -> apply lookup 1 at index 1
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // class def (glyphs 3..4 -> class 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_lookup_format2() -> Bytes {
  let subtable = build_gsub_context_subtable_format2()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_subtable_format3() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  push_u16(bytes, 20)
  // subst lookup record (seq index 1, lookup index 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // coverage table 1 (glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // coverage table 2 (glyph 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_lookup_format3() -> Bytes {
  let subtable = build_gsub_context_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_subtable_format3_input(first : Int, second : Int) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 14)
  push_u16(bytes, 20)
  // subst lookup record (seq index 1, lookup index 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // coverage table 1
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, first)
  // coverage table 2
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, second)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_lookup_format3_mark_filter(
  first : Int,
  second : Int,
) -> Bytes {
  let subtable = build_gsub_context_subtable_format3_input(first, second)
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0x0010)
  push_u16(bytes, 1)
  push_u16(bytes, 10)
  push_u16(bytes, 0)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gdef_mark_filter_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010002)
  push_u16(bytes, 14)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 24)
  push_u16(bytes, 34)
  // glyph class def (glyphs 5..6 -> class 3)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  push_u16(bytes, 2)
  push_u16(bytes, 3)
  push_u16(bytes, 3)
  // mark attach class def (glyph 5 -> class 1, glyph 6 -> class 2)
  push_u16(bytes, 1)
  push_u16(bytes, 5)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  // mark glyph sets def (format 1, 1 set)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 6)
  // coverage table (glyph 6)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 6)
  Bytes::from_array(bytes)
}

///|
fn build_gdef_class_def_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 12)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  // glyph class def (glyphs 3..5 -> class 1,2,3)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_lookup() -> Bytes {
  let subtable = build_gsub_context_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_context_lookup_ignore_marks() -> Bytes {
  let subtable = build_gsub_context_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 5)
  push_u16(bytes, 0x0008)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_subtable() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 32)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  // chain sub rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // chain sub rule
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 4)
  push_u16(bytes, 5)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_subtable_format2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, 38)
  push_u16(bytes, 44)
  push_u16(bytes, 44)
  push_u16(bytes, 44)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 16)
  // chain class rule set
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // chain class rule: backtrack class 1, input class 1, lookahead class 1
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // coverage table (input glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // class def (glyphs 1..4 -> class 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format2() -> Bytes {
  let subtable = build_gsub_chain_subtable_format2()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format2_ignore_marks() -> Bytes {
  let subtable = build_gsub_chain_subtable_format2()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0008)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format2_ignore_base() -> Bytes {
  let subtable = build_gsub_chain_subtable_format2()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0002)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format2_ignore_ligature() -> Bytes {
  let subtable = build_gsub_chain_subtable_format2()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_subtable_format3() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 22)
  push_u16(bytes, 2)
  push_u16(bytes, 28)
  push_u16(bytes, 34)
  push_u16(bytes, 1)
  push_u16(bytes, 40)
  push_u16(bytes, 1)
  // subst lookup record (seq index 1, lookup index 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // backtrack coverage (glyph 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  // input coverage 1 (glyph 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  // input coverage 2 (glyph 4)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // lookahead coverage (glyph 2)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format3() -> Bytes {
  let subtable = build_gsub_chain_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format3_ignore_marks() -> Bytes {
  let subtable = build_gsub_chain_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0008)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format3_ignore_base() -> Bytes {
  let subtable = build_gsub_chain_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0002)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_format3_ignore_ligature() -> Bytes {
  let subtable = build_gsub_chain_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0004)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup() -> Bytes {
  let subtable = build_gsub_chain_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 8)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_chain_lookup_ignore_marks() -> Bytes {
  let subtable = build_gsub_chain_subtable()
  let bytes : Array[Byte] = []
  push_u16(bytes, 6)
  push_u16(bytes, 0x0008)
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
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let changed = match gsub.apply_single(glyphs) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(glyphs, content="[3, 2]")
}

///|
test "gsub single substitution apply mask" {
  let gsub_bytes = build_layout_table(
    build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = gsub.layout().lookup_list().offsets()
  let glyphs : Array[UInt] = [1U, 1U]
  let masks : Array[UInt] = [0U, 1U]
  let changed = match gsub.apply_single_with_lookups(
    glyphs,
    lookup_offsets,
    masks=masks,
    lookup_mask=1U,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(glyphs, content="[1, 3]")
}

///|
test "gsub single lookup mark filtering set" {
  let gsub_bytes = build_layout_table(
    build_gsub_single_lookup_mark_filter(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gsub.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [5U]
  let clusters1 : Array[Int] = [0]
  let result1 = match gsub.apply_with_lookups(
    glyphs1,
    clusters1,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs1, _, changed1) = result1
  @debug.debug_inspect(changed1, content="false")
  @debug.debug_inspect(new_glyphs1, content="[5]")
  let glyphs2 : Array[UInt] = [6U]
  let clusters2 : Array[Int] = [0]
  let result2 = match gsub.apply_with_lookups(
    glyphs2,
    clusters2,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs2, _, changed2) = result2
  @debug.debug_inspect(changed2, content="true")
  @debug.debug_inspect(new_glyphs2, content="[10]")
}

///|
test "gsub single lookup mark attachment type" {
  let gsub_bytes = build_layout_table(
    build_gsub_single_lookup_mark_attach_type(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gsub.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [5U]
  let clusters1 : Array[Int] = [0]
  let result1 = match gsub.apply_with_lookups(
    glyphs1,
    clusters1,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs1, _, changed1) = result1
  @debug.debug_inspect(changed1, content="true")
  @debug.debug_inspect(new_glyphs1, content="[9]")
  let glyphs2 : Array[UInt] = [6U]
  let clusters2 : Array[Int] = [0]
  let result2 = match gsub.apply_with_lookups(
    glyphs2,
    clusters2,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs2, _, changed2) = result2
  @debug.debug_inspect(changed2, content="false")
  @debug.debug_inspect(new_glyphs2, content="[6]")
}

///|
test "gsub lookup ignore base glyphs" {
  let gsub_bytes = build_layout_table(
    build_gsub_single_lookup_ignore_base(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gsub.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U]
  let clusters : Array[Int] = [0]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, _, changed) = result
  @debug.debug_inspect(changed, content="false")
  @debug.debug_inspect(new_glyphs, content="[3]")
}

///|
test "gsub lookup ignore ligature glyphs" {
  let gsub_bytes = build_layout_table(
    build_gsub_single_lookup_ignore_ligature(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gsub.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [4U]
  let clusters : Array[Int] = [0]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, _, changed) = result
  @debug.debug_inspect(changed, content="false")
  @debug.debug_inspect(new_glyphs, content="[4]")
}

///|
test "gpos pair adjust deltas" {
  let gpos_bytes = build_layout_table(
    build_gpos_lookup(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 2U]
  let deltas = match gpos.pair_adjust_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="5")
  @debug.debug_inspect(deltas[0].x_advance, content="-20")
  @debug.debug_inspect(deltas[1].x_advance, content="10")
}

///|
test "gpos pair lookup ignore marks" {
  let gpos_bytes = build_layout_table(
    build_gpos_pair_lookup_ignore_marks(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [5U, 2U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[0].x_advance, content="0")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos pair lookup ignore ligatures" {
  let gpos_bytes = build_layout_table(
    build_gpos_pair_lookup_ignore_ligature(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [4U, 2U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[0].x_advance, content="0")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos pair lookup ignore base glyphs" {
  let gpos_bytes = build_layout_table(
    build_gpos_pair_lookup_ignore_base(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 2U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[0].x_advance, content="0")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos pair lookup mark filtering set" {
  let gpos_bytes = build_layout_table(
    build_gpos_lookup_mark_filter(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [3U, 5U, 2U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="3")
  @debug.debug_inspect(deltas1[0].x_placement, content="5")
  @debug.debug_inspect(deltas1[0].x_advance, content="-20")
  @debug.debug_inspect(deltas1[2].x_advance, content="10")
  let glyphs2 : Array[UInt] = [3U, 6U, 2U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="3")
  @debug.debug_inspect(deltas2[0].x_placement, content="0")
  @debug.debug_inspect(deltas2[0].x_advance, content="0")
  @debug.debug_inspect(deltas2[2].x_advance, content="0")
}

///|
test "gpos pair adjust format2" {
  let gpos_bytes = build_layout_table(
    build_gpos_lookup_format2(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.pair_adjust_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_advance, content="30")
  @debug.debug_inspect(deltas[1].x_advance, content="-10")
}

///|
test "gpos single adjust format1" {
  let gpos_bytes = build_layout_table(
    build_gpos_single_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="7")
  @debug.debug_inspect(deltas[0].x_advance, content="15")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos single lookup ignore marks" {
  let gpos_bytes = build_layout_table(
    build_gpos_single_lookup_format1_ignore_marks(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [5U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="1")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[0].x_advance, content="0")
}

///|
test "gpos single adjust format2" {
  let gpos_bytes = build_layout_table(
    build_gpos_single_lookup_format2(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_advance, content="10")
  @debug.debug_inspect(deltas[1].x_advance, content="-5")
}

///|
test "gpos cursive format1" {
  let gpos_bytes = build_layout_table(
    build_gpos_cursive_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [9U, 10U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="13")
  @debug.debug_inspect(deltas[1].y_placement, content="3")
}

///|
test "gpos cursive lookup ignore marks" {
  let gpos_bytes = build_layout_table(
    build_gpos_cursive_lookup_format1_ignore_marks(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [5U, 10U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="0")
}

///|
test "gpos context format1" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_context_lookup(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="7")
  @debug.debug_inspect(deltas[0].x_advance, content="15")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos context ignore base glyphs" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_context_lookup_ignore_base(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[0].x_advance, content="0")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos context mark to base format1" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_context_mark_to_base_lookup(), build_gpos_mark_to_base_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 5U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="5")
  @debug.debug_inspect(deltas[1].y_placement, content="15")
}

///|
test "gpos chain format1" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_chain_lookup(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [1U, 3U, 4U, 5U, 2U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="5")
  @debug.debug_inspect(deltas[1].x_placement, content="7")
  @debug.debug_inspect(deltas[1].x_advance, content="15")
  @debug.debug_inspect(deltas[2].x_advance, content="0")
}

///|
test "gpos context format2" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_context_lookup_format2(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="7")
  @debug.debug_inspect(deltas[0].x_advance, content="15")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos context format3" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_context_lookup_format3(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [3U, 4U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="7")
  @debug.debug_inspect(deltas[0].x_advance, content="15")
  @debug.debug_inspect(deltas[1].x_advance, content="0")
}

///|
test "gpos chain format2" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_chain_lookup_format2(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="4")
  @debug.debug_inspect(deltas[1].x_placement, content="7")
  @debug.debug_inspect(deltas[1].x_advance, content="15")
  @debug.debug_inspect(deltas[2].x_advance, content="0")
}

///|
test "gpos chain format3" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_chain_lookup_format3(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let deltas = match gpos.position_deltas_with_lookups(
    glyphs[:],
    lookup_offsets[:],
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="4")
  @debug.debug_inspect(deltas[1].x_placement, content="7")
  @debug.debug_inspect(deltas[1].x_advance, content="15")
  @debug.debug_inspect(deltas[2].x_advance, content="0")
}

///|
test "gpos chain format3 mark filtering set" {
  let gpos_bytes = build_layout_table_with_lookups(
    [build_gpos_chain_lookup_format3_mark_filter(), build_gpos_single_lookup_format1()],
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [1U, 3U, 5U, 4U, 2U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="5")
  @debug.debug_inspect(deltas1[1].x_placement, content="7")
  @debug.debug_inspect(deltas1[1].x_advance, content="15")
  let glyphs2 : Array[UInt] = [1U, 3U, 6U, 4U, 2U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="5")
  @debug.debug_inspect(deltas2[1].x_placement, content="0")
  @debug.debug_inspect(deltas2[1].x_advance, content="0")
}

///|
test "gpos mark to base format1" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_base_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 5U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="5")
  @debug.debug_inspect(deltas[1].y_placement, content="15")
}

///|
test "gpos mark to base skips intervening marks" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_base_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 5U, 5U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="3")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="5")
  @debug.debug_inspect(deltas[1].y_placement, content="15")
  @debug.debug_inspect(deltas[2].x_placement, content="5")
  @debug.debug_inspect(deltas[2].y_placement, content="15")
}

///|
test "gpos mark to base mark filtering set" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_base_lookup_format1_mark_filter(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [3U, 5U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="2")
  @debug.debug_inspect(deltas1[1].x_placement, content="0")
  @debug.debug_inspect(deltas1[1].y_placement, content="0")
  let glyphs2 : Array[UInt] = [3U, 6U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="2")
  @debug.debug_inspect(deltas2[1].x_placement, content="5")
  @debug.debug_inspect(deltas2[1].y_placement, content="15")
}

///|
test "gpos mark to base mark attachment type" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_base_lookup_format1_mark_attach_type(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [3U, 5U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="2")
  @debug.debug_inspect(deltas1[1].x_placement, content="5")
  @debug.debug_inspect(deltas1[1].y_placement, content="15")
  let glyphs2 : Array[UInt] = [3U, 6U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="2")
  @debug.debug_inspect(deltas2[1].x_placement, content="0")
  @debug.debug_inspect(deltas2[1].y_placement, content="0")
}

///|
test "gpos mark to mark format1" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_mark_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [7U, 5U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="5")
  @debug.debug_inspect(deltas[1].y_placement, content="6")
}

///|
test "gpos mark to mark mark filtering set" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_mark_lookup_format1_mark_filter(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [6U, 5U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="2")
  @debug.debug_inspect(deltas1[1].x_placement, content="0")
  @debug.debug_inspect(deltas1[1].y_placement, content="0")
  let glyphs2 : Array[UInt] = [6U, 6U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="2")
  @debug.debug_inspect(deltas2[1].x_placement, content="5")
  @debug.debug_inspect(deltas2[1].y_placement, content="6")
}

///|
test "gpos mark to mark mark attachment type" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_mark_lookup_format1_mark_attach_type(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [5U, 5U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="2")
  @debug.debug_inspect(deltas1[1].x_placement, content="5")
  @debug.debug_inspect(deltas1[1].y_placement, content="6")
  let glyphs2 : Array[UInt] = [5U, 6U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="2")
  @debug.debug_inspect(deltas2[1].x_placement, content="0")
  @debug.debug_inspect(deltas2[1].y_placement, content="0")
}

///|
test "gpos mark to ligature format1" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_ligature_lookup_format1(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [8U, 5U]
  let deltas = match gpos.position_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="0")
  @debug.debug_inspect(deltas[1].x_placement, content="9")
  @debug.debug_inspect(deltas[1].y_placement, content="11")
}

///|
test "gpos mark to ligature mark filtering set" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_ligature_lookup_format1_mark_filter(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [8U, 5U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="2")
  @debug.debug_inspect(deltas1[1].x_placement, content="0")
  @debug.debug_inspect(deltas1[1].y_placement, content="0")
  let glyphs2 : Array[UInt] = [8U, 6U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="2")
  @debug.debug_inspect(deltas2[1].x_placement, content="9")
  @debug.debug_inspect(deltas2[1].y_placement, content="11")
}

///|
test "gpos mark to ligature mark attachment type" {
  let gpos_bytes = build_layout_table(
    build_gpos_mark_to_ligature_lookup_format1_mark_attach_type(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gpos.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [8U, 5U]
  let deltas1 = match gpos.position_deltas_with_lookups(
    glyphs1[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas1.length(), content="2")
  @debug.debug_inspect(deltas1[1].x_placement, content="9")
  @debug.debug_inspect(deltas1[1].y_placement, content="11")
  let glyphs2 : Array[UInt] = [8U, 6U]
  let deltas2 = match gpos.position_deltas_with_lookups(
    glyphs2[:],
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas2.length(), content="2")
  @debug.debug_inspect(deltas2[1].x_placement, content="0")
  @debug.debug_inspect(deltas2[1].y_placement, content="0")
}

///|
test "gsub ligature substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_ligature_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U, 5U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[6, 5]")
  @debug.debug_inspect(new_clusters, content="[0, 2]")
}

///|
test "gsub ligature substitution apply mask" {
  let gsub_bytes = build_layout_table(
    build_gsub_ligature_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U, 5U]
  let clusters : Array[Int] = [0, 1, 2]
  let masks : Array[UInt] = [1U, 0U, 1U]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    masks=masks,
    lookup_mask=1U,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="false")
  @debug.debug_inspect(new_glyphs, content="[3, 4, 5]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2]")
}

///|
test "gsub ligature substitution mask propagation" {
  let gsub_bytes = build_layout_table_with_lookups(
    [build_gsub_ligature_lookup(), build_gsub_single_lookup(6, 9)],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let clusters : Array[Int] = [0, 1]
  let masks : Array[UInt] = [1U, 1U]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    masks=masks,
    lookup_mask=1U,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[9]")
  @debug.debug_inspect(new_clusters, content="[0]")
}

///|
test "gsub multiple substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_multiple_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let clusters : Array[Int] = [0, 1]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[6, 7, 4]")
  @debug.debug_inspect(new_clusters, content="[0, 0, 1]")
}

///|
test "gsub multiple substitution mask propagation" {
  let gsub_bytes = build_layout_table_with_lookups(
    [build_gsub_multiple_lookup(), build_gsub_single_lookup(6, 9)],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U]
  let clusters : Array[Int] = [0]
  let masks : Array[UInt] = [1U]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    masks=masks,
    lookup_mask=1U,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[9, 7]")
  @debug.debug_inspect(new_clusters, content="[0, 0]")
}

///|
test "gsub alternate substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_alternate_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U]
  let clusters : Array[Int] = [0, 1]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[6, 4]")
  @debug.debug_inspect(new_clusters, content="[0, 1]")
}

///|
test "gsub extension lookup apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_extension_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let changed = match gsub.apply_single(glyphs) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(glyphs, content="[3, 2]")
}

///|
test "gpos extension lookup apply" {
  let gpos_bytes = build_layout_table(
    build_gpos_extension_lookup(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  )
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(gpos_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 2U]
  let deltas = match gpos.pair_adjust_deltas(glyphs[:]) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(deltas.length(), content="2")
  @debug.debug_inspect(deltas[0].x_placement, content="5")
  @debug.debug_inspect(deltas[0].x_advance, content="-20")
  @debug.debug_inspect(deltas[1].x_advance, content="10")
}

///|
test "gsub reverse chain substitution apply" {
  let gsub_bytes = build_layout_table(
    build_gsub_reverse_chain_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 2U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 5, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2]")
}

///|
test "gsub reverse chain lookup mark filtering set" {
  let gsub_bytes = build_layout_table(
    build_gsub_reverse_chain_lookup_mark_filter(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gsub.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [1U, 5U, 3U, 2U]
  let clusters1 : Array[Int] = [0, 1, 2, 3]
  let result1 = match gsub.apply_with_lookups(
    glyphs1,
    clusters1,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs1, new_clusters1, changed1) = result1
  @debug.debug_inspect(changed1, content="true")
  @debug.debug_inspect(new_glyphs1, content="[1, 5, 5, 2]")
  @debug.debug_inspect(new_clusters1, content="[0, 1, 2, 3]")
  let glyphs2 : Array[UInt] = [1U, 6U, 3U, 2U]
  let clusters2 : Array[Int] = [0, 1, 2, 3]
  let result2 = match gsub.apply_with_lookups(
    glyphs2,
    clusters2,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs2, new_clusters2, changed2) = result2
  @debug.debug_inspect(changed2, content="false")
  @debug.debug_inspect(new_glyphs2, content="[1, 6, 3, 2]")
  @debug.debug_inspect(new_clusters2, content="[0, 1, 2, 3]")
}

///|
test "gsub contextual substitution apply" {
  let context_lookup = build_gsub_context_lookup()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [context_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U, 5U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[3, 6, 5]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2]")
}

///|
test "gsub contextual ignore marks" {
  let context_lookup = build_gsub_context_lookup_ignore_marks()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [context_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 5U, 4U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[3, 5, 6]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2]")
}

///|
test "gsub chaining substitution apply" {
  let chain_lookup = build_gsub_chain_lookup()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 5U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3, 4]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 5, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3, 4]")
}

///|
test "gsub chaining ignore marks" {
  let chain_lookup = build_gsub_chain_lookup_ignore_marks()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 5U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3, 4]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 5, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3, 4]")
}

///|
test "gsub contextual substitution format2" {
  let context_lookup = build_gsub_context_lookup_format2()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [context_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U, 5U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[3, 6, 5]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2]")
}

///|
test "gsub chaining substitution format2" {
  let chain_lookup = build_gsub_chain_lookup_format2()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3]")
}

///|
test "gsub chaining format2 ignore marks" {
  let chain_lookup = build_gsub_chain_lookup_format2_ignore_marks()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 5U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3, 4]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 5, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3, 4]")
}

///|
test "gsub chaining format2 ignore base glyphs" {
  let chain_lookup = build_gsub_chain_lookup_format2_ignore_base()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3]")
}

///|
test "gsub chaining format2 ignore ligature glyphs" {
  let chain_lookup = build_gsub_chain_lookup_format2_ignore_ligature()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3]")
}

///|
test "gsub contextual substitution format3" {
  let context_lookup = build_gsub_context_lookup_format3()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [context_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [3U, 4U, 5U]
  let clusters : Array[Int] = [0, 1, 2]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[3, 6, 5]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2]")
}

///|
test "gsub lookup flags mark filtering set" {
  let context_lookup = build_gsub_context_lookup_format3_mark_filter(1, 2)
  let single_lookup = build_gsub_single_lookup(2, 9)
  let gsub_bytes = build_layout_table_with_lookups(
    [context_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let lookup_offsets = [gsub.layout().lookup_list().offsets()[0]]
  let glyphs1 : Array[UInt] = [1U, 5U, 2U]
  let clusters1 : Array[Int] = [0, 1, 2]
  let result1 = match gsub.apply_with_lookups(
    glyphs1,
    clusters1,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs1, new_clusters1, changed1) = result1
  @debug.debug_inspect(changed1, content="true")
  @debug.debug_inspect(new_glyphs1, content="[1, 5, 9]")
  @debug.debug_inspect(new_clusters1, content="[0, 1, 2]")
  let glyphs2 : Array[UInt] = [1U, 6U, 2U]
  let clusters2 : Array[Int] = [0, 1, 2]
  let result2 = match gsub.apply_with_lookups(
    glyphs2,
    clusters2,
    lookup_offsets[:],
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs2, new_clusters2, changed2) = result2
  @debug.debug_inspect(changed2, content="false")
  @debug.debug_inspect(new_glyphs2, content="[1, 6, 2]")
  @debug.debug_inspect(new_clusters2, content="[0, 1, 2]")
}

///|
test "gsub chaining substitution format3" {
  let chain_lookup = build_gsub_chain_lookup_format3()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3]")
}

///|
test "gsub chaining format3 ignore marks" {
  let chain_lookup = build_gsub_chain_lookup_format3_ignore_marks()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_mark_filter_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 5U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3, 4]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 5, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3, 4]")
}

///|
test "gsub chaining format3 ignore base glyphs" {
  let chain_lookup = build_gsub_chain_lookup_format3_ignore_base()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3]")
}

///|
test "gsub chaining format3 ignore ligature glyphs" {
  let chain_lookup = build_gsub_chain_lookup_format3_ignore_ligature()
  let single_lookup = build_gsub_single_lookup(4, 6)
  let gsub_bytes = build_layout_table_with_lookups(
    [chain_lookup, single_lookup],
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(gsub_bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gdef = match GdefTable::parse(
    @blob.Blob::from_bytes(build_gdef_class_def_table()),
  ) {
    Err(err) => fail("gdef parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 3U, 4U, 2U]
  let clusters : Array[Int] = [0, 1, 2, 3]
  let result = match gsub.apply_with_lookups(
    glyphs,
    clusters,
    gsub.layout().lookup_list().offsets(),
    gdef=gdef,
  ) {
    Err(err) => fail("apply error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let (new_glyphs, new_clusters, changed) = result
  @debug.debug_inspect(changed, content="true")
  @debug.debug_inspect(new_glyphs, content="[1, 3, 6, 2]")
  @debug.debug_inspect(new_clusters, content="[0, 1, 2, 3]")
}
