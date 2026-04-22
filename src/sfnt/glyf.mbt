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
/// Glyph bounding box from glyf header.
pub struct GlyphBounds {
  contours : Int
  x_min : Int
  y_min : Int
  x_max : Int
  y_max : Int
} derive(Eq, Debug, ToJson)

///|
/// Outline point from glyf data.
pub struct GlyphPoint {
  mut x : Double
  mut y : Double
  flag : Int
  mut is_end_point : Bool
} derive(Debug, ToJson)

///|
pub fn GlyphPoint::new(
  x : Double,
  y : Double,
  flag : Int,
  is_end_point : Bool,
) -> GlyphPoint {
  GlyphPoint::{ x, y, flag, is_end_point }
}

///|
pub fn GlyphPoint::translate(
  self : GlyphPoint,
  dx : Double,
  dy : Double,
) -> Unit {
  self.x = self.x + dx
  self.y = self.y + dy
}

///|
pub fn GlyphPoint::set(self : GlyphPoint, x : Double, y : Double) -> Unit {
  self.x = x
  self.y = y
}

///|
pub fn GlyphPoint::transform(
  self : GlyphPoint,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
) -> Unit {
  let nx = self.x * a + self.y * c
  let ny = self.x * b + self.y * d
  self.x = nx
  self.y = ny
}

///|
pub fn GlyphBounds::new(
  contours : Int,
  x_min : Int,
  y_min : Int,
  x_max : Int,
  y_max : Int,
) -> GlyphBounds {
  GlyphBounds::{ contours, x_min, y_min, x_max, y_max }
}

///|
/// Parsed glyf table (raw view).
pub struct GlyfTable {
  data : BytesView
} derive(Debug, ToJson)

///|
pub struct CompositeComponent {
  glyph : Int
  flags : Int
  arg1 : Int
  arg2 : Int
  a : Double
  b : Double
  c : Double
  d : Double
  tx : Double
  ty : Double
  is_anchored : Bool
  use_my_metrics : Bool
  scaled_offset : Bool
} derive(Debug, ToJson)

///|
/// Parse glyf table from its blob.
pub fn GlyfTable::parse(blob : @blob.Blob) -> Result[GlyfTable, SfntError] {
  Ok(GlyfTable::{ data: blob.as_view() })
}

///|
/// Read glyph bounds at a given offset/length.
pub fn GlyfTable::glyph_bounds(
  self : GlyfTable,
  offset : Int,
  length : Int,
) -> Result[GlyphBounds?, SfntError] {
  if offset < 0 || length < 0 {
    return Err(InvalidFormat)
  }
  let data_len = self.data.length()
  if offset > data_len {
    return Err(UnexpectedEof)
  }
  if length == 0 {
    return Ok(None)
  }
  if length < 10 || offset + length > data_len || offset + 10 > data_len {
    return Err(UnexpectedEof)
  }
  let contours = read_i16(self.data, offset)
  let x_min = read_i16(self.data, offset + 2)
  let y_min = read_i16(self.data, offset + 4)
  let x_max = read_i16(self.data, offset + 6)
  let y_max = read_i16(self.data, offset + 8)
  match (contours, x_min, y_min, x_max, y_max) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (Ok(contours), Ok(x_min), Ok(y_min), Ok(x_max), Ok(y_max)) =>
      Ok(Some(GlyphBounds::{ contours, x_min, y_min, x_max, y_max }))
  }
}

///|
fn read_simple_flags(
  data : BytesView,
  offset : Int,
  end : Int,
  count : Int,
) -> Result[(Array[Int], Int), SfntError] {
  if count < 0 {
    return Err(InvalidFormat)
  }
  let flags : Array[Int] = []
  let mut pos = offset
  let mut i = 0
  while i < count {
    if pos >= end {
      return Err(UnexpectedEof)
    }
    let flag = data[pos].to_int()
    pos = pos + 1
    let mut repeat = 1
    if (flag & 0x08) != 0 {
      if pos >= end {
        return Err(UnexpectedEof)
      }
      repeat = data[pos].to_int() + 1
      pos = pos + 1
    }
    if i + repeat > count {
      return Err(InvalidFormat)
    }
    for _ in 0..<repeat {
      flags.push(flag)
      i = i + 1
    }
  }
  Ok((flags, pos))
}

///|
fn read_simple_coords(
  data : BytesView,
  offset : Int,
  end : Int,
  flags : Array[Int],
  short_flag : Int,
  same_flag : Int,
) -> Result[(Array[Int], Int), SfntError] {
  let coords : Array[Int] = []
  let mut pos = offset
  let mut value = 0
  for flag in flags {
    if (flag & short_flag) != 0 {
      if pos >= end {
        return Err(UnexpectedEof)
      }
      let delta = data[pos].to_int()
      pos = pos + 1
      if (flag & same_flag) != 0 {
        value = value + delta
      } else {
        value = value - delta
      }
    } else if (flag & same_flag) == 0 {
      if pos + 2 > end {
        return Err(UnexpectedEof)
      }
      let delta = read_i16(data, pos)
      match delta {
        Err(err) => return Err(err)
        Ok(v) => value = value + v
      }
      pos = pos + 2
    }
    coords.push(value)
  }
  Ok((coords, pos))
}

///|
fn read_i8(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  if offset < 0 || offset >= data.length() {
    return Err(UnexpectedEof)
  }
  let v = data[offset].to_int()
  Ok(if v >= 0x80 { v - 0x100 } else { v })
}

///|
fn f2dot14_to_double(value : Int) -> Double {
  value.to_double() / 16384.0
}

///|
/// Read simple glyph outline points. Returns None for composite glyphs.
pub fn GlyfTable::glyph_simple_points(
  self : GlyfTable,
  offset : Int,
  length : Int,
) -> Result[Array[GlyphPoint]?, SfntError] {
  if offset < 0 || length < 0 {
    return Err(InvalidFormat)
  }
  let data_len = self.data.length()
  if offset > data_len {
    return Err(UnexpectedEof)
  }
  if length == 0 {
    return Ok(Some([]))
  }
  if length < 10 || offset + length > data_len {
    return Err(UnexpectedEof)
  }
  let contours = read_i16(self.data, offset)
  let num_contours = match contours {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if num_contours < 0 {
    return Ok(None)
  }
  if num_contours == 0 {
    return Ok(Some([]))
  }
  let end_pts_offset = offset + 10
  let end_pts_total = num_contours * 2
  if end_pts_offset + end_pts_total > offset + length {
    return Err(UnexpectedEof)
  }
  let end_points : Array[Int] = []
  let mut pos = end_pts_offset
  for _ in 0..<num_contours {
    let value = read_u16_int(self.data, pos)
    match value {
      Err(err) => return Err(err)
      Ok(v) => end_points.push(v)
    }
    pos = pos + 2
  }
  if end_points.is_empty() {
    return Ok(Some([]))
  }
  let last_end = end_points[end_points.length() - 1]
  if last_end < 0 {
    return Err(InvalidFormat)
  }
  let point_count = last_end + 1
  if pos + 2 > offset + length {
    return Err(UnexpectedEof)
  }
  let instruction_len = read_u16_int(self.data, pos)
  let instr_len = match instruction_len {
    Err(err) => return Err(err)
    Ok(v) => v
  }
  if instr_len < 0 {
    return Err(InvalidFormat)
  }
  pos = pos + 2 + instr_len
  if pos > offset + length {
    return Err(UnexpectedEof)
  }
  let (flags, after_flags) = match
    read_simple_flags(self.data, pos, offset + length, point_count) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  pos = after_flags
  let (x_coords, after_x) = match
    read_simple_coords(self.data, pos, offset + length, flags, 0x02, 0x10) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  pos = after_x
  let (y_coords, _) = match
    read_simple_coords(self.data, pos, offset + length, flags, 0x04, 0x20) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let points : Array[GlyphPoint] = []
  for i in 0..<point_count {
    let flag = if i < flags.length() { flags[i] } else { 0 }
    let x = if i < x_coords.length() { x_coords[i].to_double() } else { 0.0 }
    let y = if i < y_coords.length() { y_coords[i].to_double() } else { 0.0 }
    points.push(GlyphPoint::{ x, y, flag, is_end_point: false })
  }
  for end_point in end_points {
    if end_point < 0 || end_point >= point_count {
      return Err(InvalidFormat)
    }
    points[end_point].is_end_point = true
  }
  Ok(Some(points))
}

///|
/// Read composite glyph component records. Returns None for non-composite glyphs.
pub fn GlyfTable::glyph_composite_components(
  self : GlyfTable,
  offset : Int,
  length : Int,
) -> Result[Array[CompositeComponent]?, SfntError] {
  if offset < 0 || length < 0 {
    return Err(InvalidFormat)
  }
  let data_len = self.data.length()
  if offset > data_len {
    return Err(UnexpectedEof)
  }
  if length == 0 {
    return Ok(Some([]))
  }
  if length < 10 || offset + length > data_len {
    return Err(UnexpectedEof)
  }
  let contours = read_i16(self.data, offset)
  let num_contours = match contours {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if num_contours >= 0 {
    return Ok(None)
  }
  let mut pos = offset + 10
  let end = offset + length
  let components : Array[CompositeComponent] = []
  let mut last_flags = 0
  while true {
    if pos + 4 > end {
      return Err(UnexpectedEof)
    }
    let flags = read_u16_int(self.data, pos)
    let glyph_index = read_u16_int(self.data, pos + 2)
    let flags = match flags {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mut glyph = match glyph_index {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 4
    if (flags & 0x2000) != 0 {
      let gid24 = read_u24(self.data, pos)
      match gid24 {
        Err(err) => return Err(err)
        Ok(value) => glyph = value.reinterpret_as_int()
      }
      pos = pos + 3
    }
    let args_are_words = (flags & 0x0001) != 0
    let args_are_xy = (flags & 0x0002) != 0
    let mut arg1 = 0
    let mut arg2 = 0
    if args_are_words {
      if args_are_xy {
        let a1 = read_i16(self.data, pos)
        let a2 = read_i16(self.data, pos + 2)
        match (a1, a2) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(v1), Ok(v2)) => {
            arg1 = v1
            arg2 = v2
          }
        }
      } else {
        let a1 = read_u16_int(self.data, pos)
        let a2 = read_u16_int(self.data, pos + 2)
        match (a1, a2) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(v1), Ok(v2)) => {
            arg1 = v1
            arg2 = v2
          }
        }
      }
      pos = pos + 4
    } else {
      if args_are_xy {
        let a1 = read_i8(self.data, pos)
        let a2 = read_i8(self.data, pos + 1)
        match (a1, a2) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(v1), Ok(v2)) => {
            arg1 = v1
            arg2 = v2
          }
        }
      } else {
        let a1 = read_u8_int(self.data, pos)
        let a2 = read_u8_int(self.data, pos + 1)
        match (a1, a2) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(v1), Ok(v2)) => {
            arg1 = v1
            arg2 = v2
          }
        }
      }
      pos = pos + 2
    }
    let mut a = 1.0
    let mut b = 0.0
    let mut c = 0.0
    let mut d = 1.0
    if (flags & 0x0008) != 0 {
      let scale = read_i16(self.data, pos)
      match scale {
        Err(err) => return Err(err)
        Ok(value) => {
          let s = f2dot14_to_double(value)
          a = s
          d = s
        }
      }
      pos = pos + 2
    } else if (flags & 0x0040) != 0 {
      let xscale = read_i16(self.data, pos)
      let yscale = read_i16(self.data, pos + 2)
      match (xscale, yscale) {
        (Err(err), _) => return Err(err)
        (_, Err(err)) => return Err(err)
        (Ok(v1), Ok(v2)) => {
          a = f2dot14_to_double(v1)
          d = f2dot14_to_double(v2)
        }
      }
      pos = pos + 4
    } else if (flags & 0x0080) != 0 {
      let v0 = read_i16(self.data, pos)
      let v1 = read_i16(self.data, pos + 2)
      let v2 = read_i16(self.data, pos + 4)
      let v3 = read_i16(self.data, pos + 6)
      match (v0, v1, v2, v3) {
        (Err(err), _, _, _) => return Err(err)
        (_, Err(err), _, _) => return Err(err)
        (_, _, Err(err), _) => return Err(err)
        (_, _, _, Err(err)) => return Err(err)
        (Ok(v0), Ok(v1), Ok(v2), Ok(v3)) => {
          a = f2dot14_to_double(v0)
          b = f2dot14_to_double(v1)
          c = f2dot14_to_double(v2)
          d = f2dot14_to_double(v3)
        }
      }
      pos = pos + 8
    }
    let is_anchored = !args_are_xy
    let use_my_metrics = (flags & 0x0200) != 0
    let scaled_offset = (flags & 0x0800) != 0 && (flags & 0x1000) == 0
    let tx = if is_anchored { 0.0 } else { arg1.to_double() }
    let ty = if is_anchored { 0.0 } else { arg2.to_double() }
    components.push(CompositeComponent::{
      glyph,
      flags,
      arg1,
      arg2,
      a,
      b,
      c,
      d,
      tx,
      ty,
      is_anchored,
      use_my_metrics,
      scaled_offset,
    })
    last_flags = flags
    if (flags & 0x0020) == 0 {
      break
    }
  }
  if (last_flags & 0x0100) != 0 {
    if pos + 2 > end {
      return Err(UnexpectedEof)
    }
    let instr_len = read_u16_int(self.data, pos)
    let instr_len = match instr_len {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2 + instr_len
    if pos > end {
      return Err(UnexpectedEof)
    }
  }
  Ok(Some(components))
}
