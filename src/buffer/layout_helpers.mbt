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
fn buffer_ascii_lowercase_byte(b : Byte) -> Byte {
  let v = b.to_uint()
  if v >= 0x41U && v <= 0x5AU {
    (v + 0x20U).to_byte()
  } else {
    b
  }
}

///|
fn buffer_lowercase_tag(tag : @common.Tag) -> @common.Tag {
  let (b1, b2, b3, b4) = tag.bytes()
  @common.Tag::from_bytes(
    buffer_ascii_lowercase_byte(b1),
    buffer_ascii_lowercase_byte(b2),
    buffer_ascii_lowercase_byte(b3),
    buffer_ascii_lowercase_byte(b4),
  )
}

///|
fn buffer_layout_has_script(
  layout : @ot_tables.LayoutTable,
  tag : @common.Tag,
) -> Bool {
  let lower = buffer_lowercase_tag(tag)
  for record in layout.script_list().records() {
    if record.tag == tag || record.tag == lower {
      return true
    }
  }
  false
}
