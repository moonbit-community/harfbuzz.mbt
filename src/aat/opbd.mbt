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
/// Optical bounds record.
pub struct OpticalBounds {
  left : Int32
  top : Int32
  right : Int32
  bottom : Int32
} derive(Eq, Debug, ToJson)

///|
/// Parsed opbd table.
pub struct OpbdTable {
  version : Int32
  format : Int32
  lookup : LookupTable
  data : BytesView
} derive(Debug, ToJson)

///|
pub fn OpbdTable::has_data(self : OpbdTable) -> Bool {
  self.version != 0
}

///|
fn read_bounds(
  data : BytesView,
  offset : Int32,
) -> Result[OpticalBounds, AatError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let left = read_i16(data, offset)
  let top = read_i16(data, offset + 2)
  let right = read_i16(data, offset + 4)
  let bottom = read_i16(data, offset + 6)
  match (left, top, right, bottom) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(left), Ok(top), Ok(right), Ok(bottom)) =>
      Ok({ left, top, right, bottom, })
  }
}

///|
/// Parse an opbd table.
pub fn OpbdTable::parse(
  data : BytesView,
  num_glyphs : Int32,
) -> Result[OpbdTable, AatError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let version = read_i32(data, 0)
  let format = read_u16_int(data, 4)
  match (version, format) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(format)) => {
      if format != 0 && format != 1 {
        return Err(InvalidFormat)
      }
      let lookup_offset = 6
      let lookup = match parse_lookup(data, lookup_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok({ version, format, lookup, data, })
    }
  }
}

///|
/// Resolve optical bounds for a glyph.
pub fn OpbdTable::bounds(
  self : OpbdTable,
  glyph : UInt32,
  contour_point~ : (UInt32, Int32) -> (Int32, Int32)? = (_, _) => None,
) -> Result[OpticalBounds?, AatError] {
  let offset = match self.lookup.value_for(glyph) {
    None => return Ok(None)
    Some(value) => value.reinterpret_as_int()
  }
  if offset <= 0 {
    return Ok(None)
  }
  let bounds = match read_bounds(self.data, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if self.format == 0 {
    return Ok(Some(bounds))
  }
  if self.format == 1 {
    let contour_point = contour_point
    if bounds.left < 0 ||
      bounds.top < 0 ||
      bounds.right < 0 ||
      bounds.bottom < 0 {
      return Ok(None)
    }
    let left = contour_point(glyph, bounds.left)
    let top = contour_point(glyph, bounds.top)
    let right = contour_point(glyph, bounds.right)
    let bottom = contour_point(glyph, bounds.bottom)
    match (left, top, right, bottom) {
      (Some((left, _)), Some((_, top)), Some((right, _)), Some((_, bottom))) =>
        Ok(Some({ left, top, right, bottom, }))
      _ => Ok(None)
    }
  } else {
    Ok(None)
  }
}
