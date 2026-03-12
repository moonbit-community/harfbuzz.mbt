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
/// Parsed justification header (shallow).
pub struct JustificationHeader {
  class_table_offset : Int
  wdc_table_offset : Int
  pc_table_offset : Int
  lookup : LookupTable?
} derive(Show, ToJson)

///|
/// Parsed just table (shallow).
pub struct JustTable {
  version : Int
  format : Int
  horiz : JustificationHeader?
  vert : JustificationHeader?
} derive(Show, ToJson)

///|
pub fn JustTable::has_data(self : JustTable) -> Bool {
  self.version != 0
}

fn parse_justification_header(
  data : BytesView,
  offset : Int,
  num_glyphs : Int,
) -> Result[JustificationHeader, AatError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let class_offset = read_u16_int(data, offset)
  let wdc_offset = read_u16_int(data, offset + 2)
  let pc_offset = read_u16_int(data, offset + 4)
  let lookup_offset = read_u16_int(data, offset + 6)
  match (class_offset, wdc_offset, pc_offset, lookup_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(class_offset), Ok(wdc_offset), Ok(pc_offset), Ok(lookup_offset)) => {
      if class_offset < 0 || wdc_offset < 0 || pc_offset < 0 || lookup_offset < 0 {
        return Err(InvalidFormat)
      }
      if class_offset != 0 && class_offset > data.length() {
        return Err(UnexpectedEof)
      }
      if wdc_offset != 0 && wdc_offset > data.length() {
        return Err(UnexpectedEof)
      }
      if pc_offset != 0 && pc_offset > data.length() {
        return Err(UnexpectedEof)
      }
      let lookup = if lookup_offset == 0 {
        None
      } else {
        if lookup_offset > data.length() {
          return Err(UnexpectedEof)
        }
        match parse_lookup(data, lookup_offset, num_glyphs) {
          Err(err) => return Err(err)
          Ok(value) => Some(value)
        }
      }
      Ok(
        JustificationHeader::{
          class_table_offset: class_offset,
          wdc_table_offset: wdc_offset,
          pc_table_offset: pc_offset,
          lookup,
        },
      )
    }
  }
}

///|
/// Parse a just table (shallow).
pub fn JustTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[JustTable, AatError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let version = read_i32(data, 0)
  let format = read_u16_int(data, 4)
  let horiz_offset = read_u16_int(data, 6)
  let vert_offset = read_u16_int(data, 8)
  match (version, format, horiz_offset, vert_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(format), Ok(horiz_offset), Ok(vert_offset)) => {
      if format != 0 {
        return Err(InvalidFormat)
      }
      let horiz = if horiz_offset == 0 {
        None
      } else {
        Some(match parse_justification_header(data, horiz_offset, num_glyphs) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let vert = if vert_offset == 0 {
        None
      } else {
        Some(match parse_justification_header(data, vert_offset, num_glyphs) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      Ok(JustTable::{ version, format, horiz, vert })
    }
  }
}
