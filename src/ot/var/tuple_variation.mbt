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
struct TupleHeader {
  data_size : Int
  tuple_index : Int
  peak : Array[Int]
  start : Array[Int]?
  end : Array[Int]?
} derive(Show, ToJson)

///|
fn TupleHeader::has_private_points(self : TupleHeader) -> Bool {
  (self.tuple_index & 0x2000) != 0
}

///|
pub struct TupleVariation {
  peak : Array[Int]
  start : Array[Int]?
  end : Array[Int]?
  indices : Array[Int]?
  deltas_x : Array[Int]
  deltas_y : Array[Int]?
} derive(Show, ToJson)

///|
fn coord_at(coords : Array[Int], index : Int) -> Int {
  if index < 0 || index >= coords.length() { 0 } else { coords[index] }
}

///|
pub fn TupleVariation::scalar(self : TupleVariation, coords : Array[Int]) -> Double {
  let axis_count = self.peak.length()
  let mut scalar = 1.0
  let has_interm = self.start is Some(_) && self.end is Some(_)
  let start_tuple = match self.start {
    None => []
    Some(value) => value
  }
  let end_tuple = match self.end {
    None => []
    Some(value) => value
  }
  for i in 0..<axis_count {
    let peak = self.peak[i]
    if peak == 0 {
      continue
    }
    let v = coord_at(coords, i)
    if v == 0 {
      return 0.0
    }
    if v == peak {
      continue
    }
    if has_interm {
      let start = start_tuple[i]
      let end = end_tuple[i]
      if start > peak || peak > end || (start < 0 && end > 0 && peak != 0) {
        continue
      }
      if v < start || v > end {
        return 0.0
      }
      if v < peak {
        if peak != start {
          scalar = scalar * (v - start).to_double() / (peak - start).to_double()
        }
      } else if peak != end {
        scalar = scalar * (end - v).to_double() / (end - peak).to_double()
      }
    } else {
      let minv = if peak < 0 { peak } else { 0 }
      let maxv = if peak > 0 { peak } else { 0 }
      if v < minv || v > maxv {
        return 0.0
      }
      scalar = scalar * v.to_double() / peak.to_double()
    }
  }
  scalar
}

///|
pub struct TupleVariationData {
  axis_count : Int
  tuple_headers : Array[TupleHeader]
  shared_points : Array[Int]?
  shared_points_size : Int
  data_offset : Int
  data : Bytes
} derive(Show, ToJson)

///|
fn clone_int_array(values : Array[Int]) -> Array[Int] {
  let out : Array[Int] = []
  for v in values {
    out.push(v)
  }
  out
}

///|
fn read_f2dot14_array(
  data : BytesView,
  offset : Int,
  axis_count : Int,
) -> Result[(Array[Int], Int), VarError] {
  let values : Array[Int] = []
  let mut pos = offset
  for _ in 0..<axis_count {
    let value = read_i16(data, pos)
    match value {
      Err(err) => return Err(err)
      Ok(v) => values.push(v)
    }
    pos = pos + 2
  }
  Ok((values, pos))
}

///|
fn slice_shared_tuple(
  shared_tuples : Array[Int],
  index : Int,
  axis_count : Int,
) -> Result[Array[Int], VarError] {
  let start = index * axis_count
  if start < 0 || start + axis_count > shared_tuples.length() {
    return Err(InvalidFormat)
  }
  let out : Array[Int] = []
  for i in 0..<axis_count {
    out.push(shared_tuples[start + i])
  }
  Ok(out)
}

///|
fn parse_tuple_header(
  data : BytesView,
  offset : Int,
  axis_count : Int,
  shared_tuples : Array[Int],
) -> Result[(TupleHeader, Int), VarError] {
  let data_size = read_u16_int(data, offset)
  let tuple_index = read_u16_int(data, offset + 2)
  match (data_size, tuple_index) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(data_size), Ok(tuple_index)) => {
      let mut pos = offset + 4
      let has_peak = (tuple_index & 0x8000) != 0
      let has_intermediate = (tuple_index & 0x4000) != 0
      let peak = if has_peak {
        match read_f2dot14_array(data, pos, axis_count) {
          Err(err) => return Err(err)
          Ok((values, next)) => {
            pos = next
            values
          }
        }
      } else {
        let index = tuple_index & 0x0FFF
        match slice_shared_tuple(shared_tuples, index, axis_count) {
          Err(err) => return Err(err)
          Ok(values) => values
        }
      }
      let start_tuple = if has_intermediate {
        match read_f2dot14_array(data, pos, axis_count) {
          Err(err) => return Err(err)
          Ok((values, next)) => {
            pos = next
            Some(values)
          }
        }
      } else {
        None
      }
      let end_tuple = if has_intermediate {
        match read_f2dot14_array(data, pos, axis_count) {
          Err(err) => return Err(err)
          Ok((values, next)) => {
            pos = next
            Some(values)
          }
        }
      } else {
        None
      }
      Ok((TupleHeader::{ data_size, tuple_index, peak, start: start_tuple, end: end_tuple }, pos))
    }
  }
}

///|
fn decode_point_numbers(
  data : BytesView,
  offset : Int,
  end : Int,
) -> Result[(Array[Int], Int), VarError] {
  if offset < 0 || offset >= end {
    return Err(UnexpectedEof)
  }
  let mut pos = offset
  let mut count = data[pos].to_int()
  pos = pos + 1
  if (count & 0x80) != 0 {
    if pos >= end {
      return Err(UnexpectedEof)
    }
    count = ((count & 0x7F) << 8) | data[pos].to_int()
    pos = pos + 1
  }
  let points : Array[Int] = []
  let mut n = 0
  let mut i = 0
  while i < count {
    if pos >= end {
      return Err(UnexpectedEof)
    }
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x7F) + 1
    let stop = i + run_count
    if stop > count {
      return Err(InvalidFormat)
    }
    if (control & 0x80) != 0 {
      let needed = run_count * 2
      if pos + needed > end {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let delta = read_u16_int(data, pos)
        match delta {
          Err(err) => return Err(err)
          Ok(value) => {
            n = n + value
            points.push(n)
          }
        }
        pos = pos + 2
      }
    } else {
      if pos + run_count > end {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let delta = data[pos].to_int()
        pos = pos + 1
        n = n + delta
        points.push(n)
      }
    }
    i = stop
  }
  Ok((points, pos))
}

///|
fn int8_from_byte(value : Byte) -> Int {
  let v = value.to_int()
  if v >= 0x80 { v - 0x100 } else { v }
}

///|
fn decode_values(
  data : BytesView,
  offset : Int,
  end : Int,
  count : Int,
) -> Result[(Array[Int], Int), VarError] {
  if count < 0 {
    return Err(InvalidFormat)
  }
  if count == 0 {
    return Ok(([], offset))
  }
  if offset < 0 || offset > end {
    return Err(UnexpectedEof)
  }
  let mut pos = offset
  let values : Array[Int] = []
  let mut i = 0
  while i < count {
    if pos >= end {
      return Err(UnexpectedEof)
    }
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x3F) + 1
    let stop = i + run_count
    if stop > count {
      return Err(InvalidFormat)
    }
    let mode = control & 0xC0
    if mode == 0x80 {
      for _ in 0..<run_count {
        values.push(0)
      }
    } else if mode == 0x40 {
      let needed = run_count * 2
      if pos + needed > end {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i16(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => values.push(v)
        }
        pos = pos + 2
      }
    } else if mode == 0xC0 {
      let needed = run_count * 4
      if pos + needed > end {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i32(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => values.push(v)
        }
        pos = pos + 4
      }
    } else {
      if pos + run_count > end {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        values.push(int8_from_byte(data[pos]))
        pos = pos + 1
      }
    }
    i = stop
  }
  Ok((values, pos))
}

///|
pub fn TupleVariationData::parse(
  data : BytesView,
  axis_count : Int,
  shared_tuples : Array[Int],
) -> Result[TupleVariationData, VarError] {
  let tuple_var_count = read_u16_int(data, 0)
  let data_offset = read_u16_int(data, 2)
  match (tuple_var_count, data_offset) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(tuple_var_count), Ok(data_offset)) => {
      let tuple_count = tuple_var_count & 0x0FFF
      let has_shared_points = (tuple_var_count & 0x8000) != 0
      if data_offset < 0 || data_offset > data.length() {
        return Err(UnexpectedEof)
      }
      let mut pos = 4
      let tuple_headers : Array[TupleHeader] = []
      for _ in 0..<tuple_count {
        let parsed = parse_tuple_header(data, pos, axis_count, shared_tuples)
        match parsed {
          Err(err) => return Err(err)
          Ok((header, next_pos)) => {
            tuple_headers.push(header)
            pos = next_pos
          }
        }
      }
      let mut shared_points : Array[Int]? = None
      let mut shared_points_size = 0
      if has_shared_points {
        let decoded = decode_point_numbers(data, data_offset, data.length())
        match decoded {
          Err(err) => return Err(err)
          Ok((points, next_pos)) => {
            shared_points = Some(points)
            shared_points_size = next_pos - data_offset
          }
        }
      }
      Ok(TupleVariationData::{
        axis_count,
        tuple_headers,
        shared_points,
        shared_points_size,
        data_offset,
        data: data.to_bytes(),
      })
    }
  }
}

///|
pub fn TupleVariationData::decode(
  self : TupleVariationData,
  point_count : Int,
  is_gvar : Bool,
) -> Result[Array[TupleVariation], VarError] {
  if point_count < 0 {
    return Err(InvalidFormat)
  }
  let data = self.data[:]
  let mut pos = self.data_offset + self.shared_points_size
  if pos < 0 || pos > data.length() {
    return Err(UnexpectedEof)
  }
  let tuples : Array[TupleVariation] = []
  for header in self.tuple_headers {
    let end = pos + header.data_size
    if end < pos || end > data.length() {
      return Err(UnexpectedEof)
    }
    let mut points : Array[Int] = []
    if header.has_private_points() {
      let decoded = decode_point_numbers(data, pos, end)
      match decoded {
        Err(err) => return Err(err)
        Ok((values, next_pos)) => {
          points = values
          pos = next_pos
        }
      }
    } else {
      points = match self.shared_points {
        None => []
        Some(values) => clone_int_array(values)
      }
    }
    let apply_to_all = points.length() == 0
    let num_deltas = if apply_to_all { point_count } else { points.length() }
    let decoded_x = decode_values(data, pos, end, num_deltas)
    let deltas_x = match decoded_x {
      Err(err) => return Err(err)
      Ok((values, next_pos)) => {
        pos = next_pos
        values
      }
    }
    let mut deltas_y : Array[Int]? = None
    if is_gvar {
      let decoded_y = decode_values(data, pos, end, num_deltas)
      match decoded_y {
        Err(err) => return Err(err)
        Ok((values, next_pos)) => {
          pos = next_pos
          deltas_y = Some(values)
        }
      }
    }
    if pos > end {
      return Err(UnexpectedEof)
    }
    if pos < end {
      pos = end
    }
    let indices = if apply_to_all { None } else { Some(points) }
    tuples.push(TupleVariation::{
      peak: header.peak,
      start: header.start,
      end: header.end,
      indices,
      deltas_x,
      deltas_y,
    })
  }
  Ok(tuples)
}

///|
pub fn TupleVariationData::apply(
  self : TupleVariationData,
  coords : Array[Int],
  point_count : Int,
  is_gvar : Bool,
) -> Result[(Array[Double], Array[Double]?), VarError] {
  let tuples = match self.decode(point_count, is_gvar) {
    Err(err) => return Err(err)
    Ok(values) => values
  }
  let deltas_x : Array[Double] = []
  let deltas_y : Array[Double] = []
  for _ in 0..<point_count {
    deltas_x.push(0.0)
    deltas_y.push(0.0)
  }
  for tuple in tuples {
    let scalar = tuple.scalar(coords)
    if scalar == 0.0 {
      continue
    }
    let indices = tuple.indices
    if indices is None {
      for i in 0..<point_count {
        deltas_x[i] = deltas_x[i] + tuple.deltas_x[i].to_double() * scalar
      }
      if is_gvar {
        match tuple.deltas_y {
          None => ()
          Some(values) => {
            for i in 0..<point_count {
              deltas_y[i] = deltas_y[i] + values[i].to_double() * scalar
            }
          }
        }
      }
    } else {
      let values = indices.unwrap()
      for i in 0..<values.length() {
        let idx = values[i]
        if idx < 0 || idx >= point_count {
          continue
        }
        deltas_x[idx] = deltas_x[idx] + tuple.deltas_x[i].to_double() * scalar
        if is_gvar {
          match tuple.deltas_y {
            None => ()
            Some(deltas) => {
              deltas_y[idx] = deltas_y[idx] + deltas[i].to_double() * scalar
            }
          }
        }
      }
    }
  }
  let out_y = if is_gvar { Some(deltas_y) } else { None }
  Ok((deltas_x, out_y))
}
