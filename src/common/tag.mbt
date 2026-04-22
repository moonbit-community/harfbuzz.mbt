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
/// Tag identifier (four bytes).
pub struct Tag {
  value : UInt
} derive(Eq, Debug, ToJson, Hash)

///|
/// Construct a tag from four bytes.
pub fn Tag::from_bytes(b1 : Byte, b2 : Byte, b3 : Byte, b4 : Byte) -> Tag {
  let value = (b1.to_uint() << 24) |
    (b2.to_uint() << 16) |
    (b3.to_uint() << 8) |
    b4.to_uint()
  Tag::{ value, }
}

///|
/// Construct a tag from four characters.
pub fn Tag::from_chars(c1 : Char, c2 : Char, c3 : Char, c4 : Char) -> Tag {
  Tag::from_bytes(
    c1.to_uint().to_byte(),
    c2.to_uint().to_byte(),
    c3.to_uint().to_byte(),
    c4.to_uint().to_byte(),
  )
}

///|
/// Construct a tag from a string, padding with spaces when shorter than 4.
pub fn Tag::from_string(s : String, len? : Int = -1) -> Tag {
  if s is "" || len == 0 {
    return tag_none
  }
  let max_len = if len < 0 || len > 4 { 4 } else { len }
  let bytes : Array[Byte] = []
  let mut count = 0
  for c in s {
    if count >= max_len {
      break
    }
    bytes.push(c.to_uint().to_byte())
    count = count + 1
  }
  for _ in bytes.length()..<4 {
    bytes.push(b' ')
  }
  Tag::from_bytes(bytes[0], bytes[1], bytes[2], bytes[3])
}

///|
/// Extract the four bytes of the tag, in big-endian order.
pub fn Tag::bytes(self : Tag) -> (Byte, Byte, Byte, Byte) {
  let value = self.value
  (
    ((value >> 24) & 0xffU).to_byte(),
    ((value >> 16) & 0xffU).to_byte(),
    ((value >> 8) & 0xffU).to_byte(),
    (value & 0xffU).to_byte(),
  )
}

///|
/// Convert a tag to a four-character string.
pub fn Tag::to_string(self : Tag) -> String {
  let (b1, b2, b3, b4) = self.bytes()
  let sb = StringBuilder::new(size_hint=4)
  sb
  ..write_char(b1.to_int().unsafe_to_char())
  ..write_char(b2.to_int().unsafe_to_char())
  ..write_char(b3.to_int().unsafe_to_char())
  .write_char(b4.to_int().unsafe_to_char())
  sb.to_string()
}

///|
pub impl Show for Tag with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Return the raw 32-bit value of the tag.
pub fn Tag::to_uint(self : Tag) -> UInt {
  self.value
}

///|
/// Unset tag.
pub let tag_none : Tag = Tag::from_bytes(b'\x00', b'\x00', b'\x00', b'\x00')

///|
/// Maximum possible unsigned tag.
pub let tag_max : Tag = Tag::from_bytes(b'\xFF', b'\xFF', b'\xFF', b'\xFF')

///|
/// Maximum possible signed tag.
pub let tag_max_signed : Tag = Tag::from_bytes(
  b'\x7F', b'\xFF', b'\xFF', b'\xFF',
)
