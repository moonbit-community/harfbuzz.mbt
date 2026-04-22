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
fn build_sfnt_with_table(tag : @common.Tag, table_bytes : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  // Offset table
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  // numTables = 1
  bytes.push(0x00)
  bytes.push(0x01)
  // searchRange, entrySelector, rangeShift
  bytes.push(0x00)
  bytes.push(0x10)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  // Table record
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
  // checksum (ignored)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  // offset (immediately after header + record = 12 + 16 = 28)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x1c)
  // length
  let len = table_bytes.length()
  bytes.push(((len >> 24) & 0xff).to_byte())
  bytes.push(((len >> 16) & 0xff).to_byte())
  bytes.push(((len >> 8) & 0xff).to_byte())
  bytes.push((len & 0xff).to_byte())
  // table data
  for b in table_bytes {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
test "sfnt parse single table" {
  let tag = @common.Tag::from_chars('t', 'e', 's', 't')
  let table_bytes : Bytes = [0x01, 0x02, 0x03]
  let sfnt_bytes = build_sfnt_with_table(tag, table_bytes)
  let blob = @blob.Blob::from_bytes(sfnt_bytes)
  let sfnt = match @sfnt.Sfnt::parse(blob) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(sfnt.tables().length(), content="1")
  let table = match sfnt.table(tag) {
    Err(err) => fail("missing table: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(table.to_bytes(), content="b\"\\x01\\x02\\x03\"")
}

///|
test "sfnt table not found" {
  let tag = @common.Tag::from_chars('t', 'e', 's', 't')
  let sfnt_bytes = build_sfnt_with_table(tag, [0x00])
  let blob = @blob.Blob::from_bytes(sfnt_bytes)
  let sfnt = match @sfnt.Sfnt::parse(blob) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let res : Result[@blob.Blob, @sfnt.SfntError] = sfnt.table(@common.tag_none)
  @debug.debug_inspect(res, content="Err(TableNotFound)")
}
