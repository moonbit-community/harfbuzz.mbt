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
pub(all) struct VarRegionAxis {
  start_coord : Int
  peak_coord : Int
  end_coord : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct VarRegionList {
  axis_count : Int
  region_count : Int
  axes : Array[VarRegionAxis]
} derive(Eq, Debug, ToJson)

///|
pub(all) struct VarData {
  item_count : Int
  word_count : Int
  long_words : Bool
  region_indices : Array[Int]
  deltas : Bytes
} derive(Eq, Debug, ToJson)

///|
pub struct ItemVariationStore {
  region_list : VarRegionList
  data_sets : Array[VarData]
} derive(Eq, Debug, ToJson)

fn VarRegionAxis::evaluate(self : VarRegionAxis, coord : Int) -> Double {
  let peak = self.peak_coord
  if peak == 0 || coord == peak {
    return 1.0
  }
  if coord == 0 {
    return 0.0
  }
  let start = self.start_coord
  let end = self.end_coord
  if start > peak || peak > end {
    return 1.0
  }
  if start < 0 && end > 0 && peak != 0 {
    return 1.0
  }
  if coord <= start || end <= coord {
    return 0.0
  }
  if coord < peak {
    (coord - start).to_double() / (peak - start).to_double()
  } else {
    (end - coord).to_double() / (end - peak).to_double()
  }
}

fn VarRegionList::evaluate(self : VarRegionList, region_index : Int, coords : ArrayView[Int]) -> Double {
  if region_index < 0 || region_index >= self.region_count {
    return 0.0
  }
  let base = region_index * self.axis_count
  let mut scalar = 1.0
  for axis in 0..<self.axis_count {
    let coord = if axis < coords.length() { coords[axis] } else { 0 }
    let axis_record = self.axes[base + axis]
    let factor = axis_record.evaluate(coord)
    if factor == 0.0 {
      return 0.0
    }
    scalar = scalar * factor
  }
  scalar
}

fn VarData::row_size(self : VarData) -> Int {
  let count = self.region_indices.length()
  (self.word_count + count) * (if self.long_words { 2 } else { 1 })
}

fn read_i8(bytes : BytesView, offset : Int) -> Result[Int, VarError] {
  if offset < 0 || offset + 1 > bytes.length() {
    return Err(UnexpectedEof)
  }
  let v = bytes[offset].to_int()
  if v >= 0x80 { Ok(v - 0x100) } else { Ok(v) }
}

fn read_i16_be(bytes : BytesView, offset : Int) -> Result[Int, VarError] {
  let hi = read_u16(bytes, offset)
  match hi {
    Err(err) => Err(err)
    Ok(value) => {
      let v = value.reinterpret_as_int()
      if v >= 0x8000 { Ok(v - 0x10000) } else { Ok(v) }
    }
  }
}

fn read_i32_be(bytes : BytesView, offset : Int) -> Result[Int, VarError] {
  match read_u32(bytes, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

fn VarData::get_delta(
  self : VarData,
  inner : Int,
  coords : ArrayView[Int],
  regions : VarRegionList,
) -> Double {
  if inner < 0 || inner >= self.item_count {
    return 0.0
  }
  let count = self.region_indices.length()
  if count == 0 {
    return 0.0
  }
  let row_size = self.row_size()
  let row_offset = inner * row_size
  if row_offset < 0 || row_offset + row_size > self.deltas.length() {
    return 0.0
  }
  let row = self.deltas[row_offset:row_offset + row_size]
  let mut delta = 0.0
  let mut offset = 0
  if self.long_words {
    for i in 0..<self.word_count {
      let value = match read_i32_be(row, offset) {
        Err(_) => return delta
        Ok(v) => v
      }
      let scalar = regions.evaluate(self.region_indices[i], coords)
      if scalar != 0.0 {
        delta = delta + scalar * value.to_double()
      }
      offset = offset + 4
    }
    for i in self.word_count..<count {
      let value = match read_i16_be(row, offset) {
        Err(_) => return delta
        Ok(v) => v
      }
      let scalar = regions.evaluate(self.region_indices[i], coords)
      if scalar != 0.0 {
        delta = delta + scalar * value.to_double()
      }
      offset = offset + 2
    }
    return delta
  }

  for i in 0..<self.word_count {
    let value = match read_i16_be(row, offset) {
      Err(_) => return delta
      Ok(v) => v
    }
    let scalar = regions.evaluate(self.region_indices[i], coords)
    if scalar != 0.0 {
      delta = delta + scalar * value.to_double()
    }
    offset = offset + 2
  }
  for i in self.word_count..<count {
    let value = match read_i8(row, offset) {
      Err(_) => return delta
      Ok(v) => v
    }
    let scalar = regions.evaluate(self.region_indices[i], coords)
    if scalar != 0.0 {
      delta = delta + scalar * value.to_double()
    }
    offset = offset + 1
  }
  delta
}

fn parse_region_list(data : BytesView, offset : Int) -> Result[VarRegionList, VarError] {
  let axis_count = read_u16_int(data, offset)
  let region_count = read_u16_int(data, offset + 2)
  match (axis_count, region_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(axis_count), Ok(region_count)) => {
      if axis_count < 0 || region_count < 0 {
        return Err(InvalidFormat)
      }
      let total_axes = axis_count * region_count
      let mut axis_offset = offset + 4
      let axes : Array[VarRegionAxis] = []
      for _ in 0..<total_axes {
        let start = read_i16(data, axis_offset)
        let peak = read_i16(data, axis_offset + 2)
        let end = read_i16(data, axis_offset + 4)
        match (start, peak, end) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start_coord), Ok(peak_coord), Ok(end_coord)) => axes.push(VarRegionAxis::{
            start_coord,
            peak_coord,
            end_coord,
          })
        }
        axis_offset = axis_offset + 6
      }
      Ok(VarRegionList::{ axis_count, region_count, axes })
    }
  }
}

fn parse_var_data(data : BytesView, offset : Int) -> Result[VarData, VarError] {
  let item_count = read_u16_int(data, offset)
  let word_size_count = read_u16_int(data, offset + 2)
  let region_index_count = read_u16_int(data, offset + 4)
  match (item_count, word_size_count, region_index_count) {
    (Err(err), _, _) => return Err(err)
    (_, Err(err), _) => return Err(err)
    (_, _, Err(err)) => return Err(err)
    (Ok(item_count), Ok(word_size_count), Ok(region_index_count)) => {
      let long_words = (word_size_count & 0x8000) != 0
      let word_count = word_size_count & 0x7FFF
      if region_index_count < 0 || word_count < 0 || word_count > region_index_count {
        return Err(InvalidFormat)
      }
      let region_indices : Array[Int] = []
      let mut region_offset = offset + 6
      for _ in 0..<region_index_count {
        let value = read_u16_int(data, region_offset)
        match value {
          Err(err) => return Err(err)
          Ok(v) => region_indices.push(v)
        }
        region_offset = region_offset + 2
      }
      let row_size = (word_count + region_indices.length()) * (if long_words { 2 } else { 1 })
      let total_bytes = item_count * row_size
      let data_offset = region_offset
      if data_offset < 0 || data_offset + total_bytes > data.length() {
        return Err(UnexpectedEof)
      }
      let deltas = data[data_offset:data_offset + total_bytes].to_bytes()
      Ok(VarData::{
        item_count,
        word_count,
        long_words,
        region_indices,
        deltas,
      })
    }
  }
}

///|
pub fn ItemVariationStore::parse(data : BytesView) -> Result[ItemVariationStore, VarError] {
  let format = read_u16_int(data, 0)
  let region_offset = read_u32_int(data, 2)
  let data_count = read_u16_int(data, 6)
  match (format, region_offset, data_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(region_offset), Ok(data_count)) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      if region_offset < 0 || region_offset >= data.length() {
        return Err(UnexpectedEof)
      }
      let region_list = match parse_region_list(data, region_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let data_sets : Array[VarData] = []
      let mut offset = 8
      for _ in 0..<data_count {
        let entry = read_u32_int(data, offset)
        match entry {
          Err(err) => return Err(err)
          Ok(entry_offset) => {
            if entry_offset < 0 || entry_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            let var_data = match parse_var_data(data, entry_offset) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            data_sets.push(var_data)
          }
        }
        offset = offset + 4
      }
      Ok(ItemVariationStore::{ region_list, data_sets })
    }
  }
}

///|
pub fn ItemVariationStore::get_delta(
  self : ItemVariationStore,
  var_idx : UInt,
  coords : Array[Int],
) -> Double {
  let outer = ((var_idx >> 16) & 0xFFFFU).reinterpret_as_int()
  let inner = (var_idx & 0xFFFFU).reinterpret_as_int()
  if outer < 0 || outer >= self.data_sets.length() {
    return 0.0
  }
  self.data_sets[outer].get_delta(inner, coords[:], self.region_list)
}

///|
pub fn ItemVariationStore::region_count(
  self : ItemVariationStore,
  outer : Int,
) -> Int? {
  if outer < 0 || outer >= self.data_sets.length() {
    return None
  }
  Some(self.data_sets[outer].region_indices.length())
}

///|
pub fn ItemVariationStore::region_scalars(
  self : ItemVariationStore,
  outer : Int,
  coords : Array[Int],
) -> Array[Double]? {
  if outer < 0 || outer >= self.data_sets.length() {
    return None
  }
  let var_data = self.data_sets[outer]
  let count = var_data.region_indices.length()
  let scalars : Array[Double] = Array::make(count, 0.0)
  for i in 0..<count {
    scalars[i] = self.region_list.evaluate(var_data.region_indices[i], coords[:])
  }
  Some(scalars)
}
