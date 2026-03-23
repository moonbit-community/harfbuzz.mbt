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

fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

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

fn build_sfnt_with_table(tag : @common.Tag, table_bytes : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x10)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x1c)
  let len = table_bytes.length()
  bytes.push(((len >> 24) & 0xff).to_byte())
  bytes.push(((len >> 16) & 0xff).to_byte())
  bytes.push(((len >> 8) & 0xff).to_byte())
  bytes.push((len & 0xff).to_byte())
  for b in table_bytes {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

fn build_font_bytes_cmap(start : UInt, end : UInt, start_gid : UInt) -> Bytes {
  let cmap = build_cmap_table(build_cmap_format12(start, end, start_gid))
  build_sfnt_with_table(@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap)
}

test "syllabic dotted circle requires font mapping" {
  let font = @font.Font::from_bytes(build_font_bytes_cmap(0x41U, 0x41U, 1U))
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0301U)
  let syllables : Array[Int] = [1]
  let inserted = match insert_dotted_circle_for_syllables(
    font,
    buffer,
    syllables,
    1,
  ) {
    Err(err) => fail("shape error: \{err}")
    Ok(value) => value
  }
  inspect(inserted, content="false")
  let infos = buffer.infos()
  inspect(infos.length(), content="1")
  inspect(infos[0].codepoint, content="769")
}

test "syllabic dotted circle uses font mapping" {
  let font = @font.Font::from_bytes(build_font_bytes_cmap(0x25CCU, 0x25CCU, 1U))
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0301U)
  let syllables : Array[Int] = [1]
  let inserted = match insert_dotted_circle_for_syllables(
    font,
    buffer,
    syllables,
    1,
  ) {
    Err(err) => fail("shape error: \{err}")
    Ok(value) => value
  }
  inspect(inserted, content="true")
  let infos = buffer.infos()
  inspect(infos.length(), content="2")
  inspect(infos[0].codepoint, content="9676")
  inspect(infos[1].codepoint, content="769")
}

test "syllabic dotted circle for broken syllable list" {
  let font = @font.Font::from_bytes(build_font_bytes_cmap(0x25CCU, 0x25CCU, 1U))
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0301U)
  let syllables : Array[Int] = [1]
  let inserted = match insert_dotted_circle_for_syllables(
    font,
    buffer,
    syllables,
    1,
  ) {
    Err(err) => fail("shape error: \{err}")
    Ok(value) => value
  }
  inspect(inserted, content="true")
  let infos = buffer.infos()
  inspect(infos.length(), content="2")
  inspect(infos[0].codepoint, content="9676")
  inspect(infos[1].codepoint, content="769")
}

test "syllabic dotted circle once per broken syllable" {
  let font = @font.Font::from_bytes(build_font_bytes_cmap(0x25CCU, 0x25CCU, 1U))
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0301U)
  buffer.add_codepoint(0x0301U)
  let syllables : Array[Int] = [1, 1]
  let inserted = match insert_dotted_circle_for_syllables(
    font,
    buffer,
    syllables,
    1,
  ) {
    Err(err) => fail("shape error: \{err}")
    Ok(value) => value
  }
  inspect(inserted, content="true")
  let infos = buffer.infos()
  inspect(infos.length(), content="3")
  inspect(infos[0].codepoint, content="9676")
  inspect(infos[1].codepoint, content="769")
  inspect(infos[2].codepoint, content="769")
}

test "syllabic dotted circle inserts after repha in broken syllable" {
  let font = @font.Font::from_bytes(build_font_bytes_cmap(0x25CCU, 0x25CCU, 1U))
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x42U)
  let syllables : Array[Int] = [1, 1]
  let categories : Array[Int] = [indic_cat_repha, 0]
  let inserted = match insert_dotted_circle_for_syllables_with_repha(
    font,
    buffer,
    syllables,
    1,
    categories,
    indic_cat_repha,
  ) {
    Err(err) => fail("shape error: \{err}")
    Ok(value) => value
  }
  inspect(inserted, content="true")
  let infos = buffer.infos()
  inspect(infos.length(), content="3")
  inspect(infos[0].codepoint, content="65")
  inspect(infos[1].codepoint, content="9676")
  inspect(infos[2].codepoint, content="66")
}
