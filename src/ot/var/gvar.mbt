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
pub struct GvarTable {
  axis_count : Int
  shared_tuple_count : Int
  shared_tuples_offset : Int
  glyph_count : Int
  flags : Int
  data_offset : Int
  offsets : Array[Int]
  data : Bytes
} derive(Debug, ToJson)

fn parse_offsets(
  data : BytesView,
  offset : Int,
  glyph_count : Int,
  long_offsets : Bool,
) -> Result[Array[Int], VarError] {
  let count = glyph_count + 1
  let offsets : Array[Int] = []
  if long_offsets {
    let total = count * 4
    if offset < 0 || offset + total > data.length() {
      return Err(UnexpectedEof)
    }
    let mut pos = offset
    for _ in 0..<count {
      let value = read_u32_int(data, pos)
      match value {
        Err(err) => return Err(err)
        Ok(v) => offsets.push(v)
      }
      pos = pos + 4
    }
  } else {
    let total = count * 2
    if offset < 0 || offset + total > data.length() {
      return Err(UnexpectedEof)
    }
    let mut pos = offset
    for _ in 0..<count {
      let value = read_u16_int(data, pos)
      match value {
        Err(err) => return Err(err)
        Ok(v) => offsets.push(v * 2)
      }
      pos = pos + 2
    }
  }
  Ok(offsets)
}

///|
pub fn GvarTable::parse(data : BytesView) -> Result[GvarTable, VarError] {
  let version = read_u32(data, 0)
  let axis_count = read_u16_int(data, 4)
  let shared_tuple_count = read_u16_int(data, 6)
  let shared_tuples_offset = read_u32_int(data, 8)
  let glyph_count = read_u16_int(data, 12)
  let flags = read_u16_int(data, 14)
  let data_offset = read_u32_int(data, 16)
  match (
    version,
    axis_count,
    shared_tuple_count,
    shared_tuples_offset,
    glyph_count,
    flags,
    data_offset,
  ) {
    (Err(err), _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(axis_count), Ok(shared_tuple_count), Ok(shared_tuples_offset), Ok(glyph_count), Ok(flags), Ok(data_offset)) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if glyph_count < 0 {
        return Err(InvalidFormat)
      }
      let long_offsets = (flags & 1) != 0
      let offsets = match parse_offsets(data, 20, glyph_count, long_offsets) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(GvarTable::{
        axis_count,
        shared_tuple_count,
        shared_tuples_offset,
        glyph_count,
        flags,
        data_offset,
        offsets,
        data: data.to_bytes(),
      })
    }
  }
}

///|
pub fn GvarTable::glyph_variation_data(self : GvarTable, glyph : Int) -> Bytes? {
  if glyph < 0 || glyph >= self.glyph_count {
    return None
  }
  let start = self.offsets[glyph]
  let end = self.offsets[glyph + 1]
  if end < start {
    return None
  }
  let base = self.data_offset
  let length = end - start
  if length == 0 {
    return None
  }
  if base < 0 || base + end > self.data.length() {
    return None
  }
  Some(self.data[base + start:base + start + length].to_bytes())
}

///|
pub fn GvarTable::shared_tuples(self : GvarTable) -> Result[Array[Int], VarError] {
  if self.shared_tuple_count <= 0 {
    return Ok([])
  }
  if self.shared_tuples_offset <= 0 || self.shared_tuples_offset >= self.data.length() {
    return Err(UnexpectedEof)
  }
  let total = self.shared_tuple_count * self.axis_count
  let tuples : Array[Int] = []
  let mut pos = self.shared_tuples_offset
  for _ in 0..<total {
    let value = read_i16(self.data, pos)
    match value {
      Err(err) => return Err(err)
      Ok(v) => tuples.push(v)
    }
    pos = pos + 2
  }
  Ok(tuples)
}

///|
pub fn GvarTable::glyph_tuple_variations(
  self : GvarTable,
  glyph : Int,
) -> Result[TupleVariationData?, VarError] {
  let data = self.glyph_variation_data(glyph)
  match data {
    None => Ok(None)
    Some(bytes) => {
      let shared = match self.shared_tuples() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let parsed = TupleVariationData::parse(bytes[:], self.axis_count, shared)
      match parsed {
        Err(err) => Err(err)
        Ok(value) => Ok(Some(value))
      }
    }
  }
}

///|
pub fn GvarTable::glyph_deltas(
  self : GvarTable,
  glyph : Int,
  coords : Array[Int],
  point_count : Int,
) -> Result[(Array[Double], Array[Double]?), VarError] {
  let tuple_data = match self.glyph_tuple_variations(glyph) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match tuple_data {
    Some(value) => value.apply(coords, point_count, true)
    None => {
      let deltas_x : Array[Double] = []
      let deltas_y : Array[Double] = []
      for _ in 0..<point_count {
        deltas_x.push(0.0)
        deltas_y.push(0.0)
      }
      Ok((deltas_x, Some(deltas_y)))
    }
  }
}
