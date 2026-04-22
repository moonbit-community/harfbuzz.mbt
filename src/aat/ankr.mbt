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
pub struct Anchor {
  x : Int
  y : Int
} derive(Eq, Debug, ToJson)

///|
pub struct AnkrTable {
  version : Int
  lookup : LookupTable
  anchor_offset : Int
  data : Bytes
} derive(Debug, ToJson)

///|
pub fn AnkrTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[AnkrTable, AatError] {
  let version = read_u16_int(data, 0)
  let flags = read_u16_int(data, 2)
  let lookup_offset = read_u32_non_negative(data, 4)
  let anchor_offset = read_u32_non_negative(data, 8)
  match (version, flags, lookup_offset, anchor_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(_), Ok(lookup_offset), Ok(anchor_offset)) => {
      if lookup_offset < 0 || anchor_offset < 0 {
        return Err(InvalidFormat)
      }
      if lookup_offset >= data.length() || anchor_offset >= data.length() {
        return Err(UnexpectedEof)
      }
      let lookup = match parse_lookup(data, lookup_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(AnkrTable::{ version, lookup, anchor_offset, data: data.to_bytes() })
    }
  }
}

///|
pub fn AnkrTable::has_data(self : AnkrTable) -> Bool {
  self.version == 0
}

///|
pub fn AnkrTable::get_anchor(
  self : AnkrTable,
  glyph : UInt,
  index : Int,
) -> Anchor? {
  if index < 0 {
    return None
  }
  let offset = match self.lookup.value_for(glyph) {
    None => return None
    Some(value) => value.reinterpret_as_int()
  }
  if offset < 0 {
    return None
  }
  let base = self.anchor_offset + offset
  if base < 0 || base + 4 > self.data.length() {
    return None
  }
  let count = match read_u32_non_negative(self.data[:], base) {
    Err(_) => return None
    Ok(value) => value
  }
  if index >= count {
    return None
  }
  let anchor_base = base + 4 + index * 4
  if anchor_base < 0 || anchor_base + 4 > self.data.length() {
    return None
  }
  let x = match read_i16(self.data[:], anchor_base) {
    Err(_) => return None
    Ok(value) => value
  }
  let y = match read_i16(self.data[:], anchor_base + 2) {
    Err(_) => return None
    Ok(value) => value
  }
  Some(Anchor::{ x, y })
}
