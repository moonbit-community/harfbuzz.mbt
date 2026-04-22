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
pub(all) struct LookupSegmentSingle {
  first : UInt
  last : UInt
  value : UInt
} derive(Eq, Debug, ToJson)

///|
pub(all) struct LookupSegmentArray {
  first : UInt
  last : UInt
  values : Array[UInt]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct LookupSingle {
  glyph : UInt
  value : UInt
} derive(Eq, Debug, ToJson)

///|
pub(all) enum LookupTable {
  Format0(Array[UInt])
  Format2(Array[LookupSegmentSingle])
  Format4(Array[LookupSegmentArray])
  Format6(Array[LookupSingle])
  Format8(UInt, Array[UInt])
  Format10(Int, UInt, Array[UInt])
} derive(Eq, Debug, ToJson)

///|
fn within_range(glyph : UInt, first : UInt, last : UInt) -> Bool {
  glyph >= first && glyph <= last
}

///|
fn LookupTable::value_for(self : LookupTable, glyph : UInt) -> UInt? {
  match self {
    Format0(values) => {
      let idx = glyph.reinterpret_as_int()
      if idx < 0 || idx >= values.length() {
        None
      } else {
        Some(values[idx])
      }
    }
    Format2(segments) => {
      for seg in segments {
        if within_range(glyph, seg.first, seg.last) {
          return Some(seg.value)
        }
      }
      None
    }
    Format4(segments) => {
      for seg in segments {
        if within_range(glyph, seg.first, seg.last) {
          let idx = (glyph - seg.first).reinterpret_as_int()
          if idx >= 0 && idx < seg.values.length() {
            return Some(seg.values[idx])
          }
        }
      }
      None
    }
    Format6(entries) => {
      for entry in entries {
        if entry.glyph == glyph {
          return Some(entry.value)
        }
      }
      None
    }
    Format8(first, values) => {
      if glyph < first {
        return None
      }
      let idx = (glyph - first).reinterpret_as_int()
      if idx < 0 || idx >= values.length() {
        None
      } else {
        Some(values[idx])
      }
    }
    Format10(_, first, values) => {
      if glyph < first {
        return None
      }
      let idx = (glyph - first).reinterpret_as_int()
      if idx < 0 || idx >= values.length() {
        None
      } else {
        Some(values[idx])
      }
    }
  }
}

///|
fn read_lookup_value(
  data : BytesView,
  offset : Int,
  value_size : Int,
) -> Result[UInt, AatError] {
  if value_size == 2 {
    read_u16(data, offset)
  } else if value_size == 4 {
    read_u32(data, offset)
  } else {
    Err(InvalidFormat)
  }
}

///|
fn parse_format0(
  data : BytesView,
  offset : Int,
  num_glyphs : Int,
  value_size : Int,
) -> Result[LookupTable, AatError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let start = offset + 2
  if start < 0 || start + num_glyphs * value_size > data.length() {
    return Err(UnexpectedEof)
  }
  let values : Array[UInt] = []
  for i in 0..<num_glyphs {
    let value = read_lookup_value(data, start + i * value_size, value_size)
    match value {
      Err(err) => return Err(err)
      Ok(value) => values.push(value)
    }
  }
  Ok(Format0(values))
}

///|
fn parse_binsearch_header(
  data : BytesView,
  offset : Int,
) -> Result[(Int, Int, Int), AatError] {
  let unit_size = read_u16_int(data, offset)
  let n_units = read_u16_int(data, offset + 2)
  let search_range = read_u16_int(data, offset + 4)
  let entry_selector = read_u16_int(data, offset + 6)
  let range_shift = read_u16_int(data, offset + 8)
  match (unit_size, n_units, search_range, entry_selector, range_shift) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (Ok(unit_size), Ok(n_units), Ok(_), Ok(_), Ok(_)) => {
      if unit_size < 0 || n_units < 0 {
        return Err(InvalidFormat)
      }
      Ok((unit_size, n_units, offset + 10))
    }
  }
}

///|
fn parse_format2(
  data : BytesView,
  offset : Int,
  value_size : Int,
) -> Result[LookupTable, AatError] {
  let header = parse_binsearch_header(data, offset + 2)
  match header {
    Err(err) => Err(err)
    Ok((unit_size, n_units, array_offset)) => {
      if unit_size < 4 + value_size {
        return Err(InvalidFormat)
      }
      if array_offset < 0 || array_offset + n_units * unit_size > data.length() {
        return Err(UnexpectedEof)
      }
      let segments : Array[LookupSegmentSingle] = []
      for i in 0..<n_units {
        let entry_offset = array_offset + i * unit_size
        let last = read_u16(data, entry_offset)
        let first = read_u16(data, entry_offset + 2)
        let value = read_lookup_value(data, entry_offset + 4, value_size)
        match (last, first, value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(last), Ok(first), Ok(value)) => {
            if last == 0xffffU && first == 0xffffU {
              continue
            }
            segments.push(LookupSegmentSingle::{ first, last, value })
          }
        }
      }
      Ok(Format2(segments))
    }
  }
}

///|
fn parse_format4(
  data : BytesView,
  offset : Int,
  value_size : Int,
) -> Result[LookupTable, AatError] {
  let header = parse_binsearch_header(data, offset + 2)
  match header {
    Err(err) => Err(err)
    Ok((unit_size, n_units, array_offset)) => {
      if unit_size < 6 {
        return Err(InvalidFormat)
      }
      if array_offset < 0 || array_offset + n_units * unit_size > data.length() {
        return Err(UnexpectedEof)
      }
      let segments : Array[LookupSegmentArray] = []
      for i in 0..<n_units {
        let entry_offset = array_offset + i * unit_size
        let last = read_u16(data, entry_offset)
        let first = read_u16(data, entry_offset + 2)
        let values_offset = read_u16_int(data, entry_offset + 4)
        match (last, first, values_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(last), Ok(first), Ok(values_offset)) => {
            if last == 0xffffU && first == 0xffffU {
              continue
            }
            let count = (last - first).reinterpret_as_int() + 1
            if count < 0 {
              return Err(InvalidFormat)
            }
            let values_start = offset + values_offset
            if values_start < 0 ||
              values_start + count * value_size > data.length() {
              return Err(UnexpectedEof)
            }
            let values : Array[UInt] = []
            for j in 0..<count {
              let value = read_lookup_value(
                data,
                values_start + j * value_size,
                value_size,
              )
              match value {
                Err(err) => return Err(err)
                Ok(value) => values.push(value)
              }
            }
            segments.push(LookupSegmentArray::{ first, last, values })
          }
        }
      }
      Ok(Format4(segments))
    }
  }
}

///|
fn parse_format6(
  data : BytesView,
  offset : Int,
  value_size : Int,
) -> Result[LookupTable, AatError] {
  let header = parse_binsearch_header(data, offset + 2)
  match header {
    Err(err) => Err(err)
    Ok((unit_size, n_units, array_offset)) => {
      if unit_size < 2 + value_size {
        return Err(InvalidFormat)
      }
      if array_offset < 0 || array_offset + n_units * unit_size > data.length() {
        return Err(UnexpectedEof)
      }
      let entries : Array[LookupSingle] = []
      for i in 0..<n_units {
        let entry_offset = array_offset + i * unit_size
        let glyph = read_u16(data, entry_offset)
        let value = read_lookup_value(data, entry_offset + 2, value_size)
        match (glyph, value) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(glyph), Ok(value)) => {
            if glyph == 0xffffU {
              continue
            }
            entries.push(LookupSingle::{ glyph, value })
          }
        }
      }
      Ok(Format6(entries))
    }
  }
}

///|
fn parse_format8(
  data : BytesView,
  offset : Int,
  value_size : Int,
) -> Result[LookupTable, AatError] {
  let first = read_u16(data, offset + 2)
  let glyph_count = read_u16_int(data, offset + 4)
  match (first, glyph_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(first), Ok(glyph_count)) => {
      if glyph_count < 0 {
        return Err(InvalidFormat)
      }
      let start = offset + 6
      if start < 0 || start + glyph_count * value_size > data.length() {
        return Err(UnexpectedEof)
      }
      let values : Array[UInt] = []
      for i in 0..<glyph_count {
        let value = read_lookup_value(data, start + i * value_size, value_size)
        match value {
          Err(err) => return Err(err)
          Ok(value) => values.push(value)
        }
      }
      Ok(Format8(first, values))
    }
  }
}

///|
fn parse_format10(
  data : BytesView,
  offset : Int,
) -> Result[LookupTable, AatError] {
  let value_size = read_u16_int(data, offset + 2)
  let first = read_u16(data, offset + 4)
  let glyph_count = read_u16_int(data, offset + 6)
  match (value_size, first, glyph_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(value_size), Ok(first), Ok(glyph_count)) => {
      if value_size <= 0 || value_size > 4 || glyph_count < 0 {
        return Err(InvalidFormat)
      }
      let start = offset + 8
      if start < 0 || start + glyph_count * value_size > data.length() {
        return Err(UnexpectedEof)
      }
      let values : Array[UInt] = []
      for i in 0..<glyph_count {
        let mut value = 0U
        let base = start + i * value_size
        for j in 0..<value_size {
          value = (value << 8) | data[base + j].to_uint()
        }
        values.push(value)
      }
      Ok(Format10(value_size, first, values))
    }
  }
}

///|
fn parse_lookup_with_value_size(
  data : BytesView,
  offset : Int,
  num_glyphs : Int,
  value_size : Int,
) -> Result[LookupTable, AatError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      match format {
        0 => parse_format0(data, offset, num_glyphs, value_size)
        2 => parse_format2(data, offset, value_size)
        4 => parse_format4(data, offset, value_size)
        6 => parse_format6(data, offset, value_size)
        8 => parse_format8(data, offset, value_size)
        10 => parse_format10(data, offset)
        _ => Err(InvalidFormat)
      }
  }
}

///|
fn parse_lookup(
  data : BytesView,
  offset : Int,
  num_glyphs : Int,
) -> Result[LookupTable, AatError] {
  parse_lookup_with_value_size(data, offset, num_glyphs, 2)
}
