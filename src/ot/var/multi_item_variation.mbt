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
pub struct SparseVarRegionAxis {
  axis_index : Int
  axis : VarRegionAxis
} derive(Eq, Debug, ToJson)

///|
pub struct SparseVariationRegion {
  axes : Array[SparseVarRegionAxis]
} derive(Eq, Debug, ToJson)

///|
pub struct SparseVarRegionList {
  regions : Array[SparseVariationRegion]
} derive(Eq, Debug, ToJson)

///|
pub struct MultiVarData {
  region_indices : Array[Int]
  delta_sets : CffIndex
} derive(Debug, ToJson)

///|
pub struct MultiItemVariationStore {
  region_list : SparseVarRegionList
  data_sets : Array[MultiVarData]
} derive(Debug, ToJson)

fn SparseVariationRegion::evaluate(self : SparseVariationRegion, coords : ArrayView[Int]) -> Double {
  let mut scalar = 1.0
  for axis in self.axes {
    let coord = if axis.axis_index >= 0 && axis.axis_index < coords.length() {
      coords[axis.axis_index]
    } else {
      0
    }
    let factor = axis.axis.evaluate(coord)
    if factor == 0.0 {
      return 0.0
    }
    scalar = scalar * factor
  }
  scalar
}

fn SparseVarRegionList::evaluate(
  self : SparseVarRegionList,
  region_index : Int,
  coords : ArrayView[Int],
) -> Double {
  if region_index < 0 || region_index >= self.regions.length() {
    return 0.0
  }
  self.regions[region_index].evaluate(coords)
}

fn parse_sparse_variation_region(
  data : BytesView,
  offset : Int,
) -> Result[SparseVariationRegion, VarError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let base = offset + 2
      let record_size = 8
      let total = count * record_size
      if base < 0 || base + total > data.length() {
        return Err(UnexpectedEof)
      }
      let axes : Array[SparseVarRegionAxis] = []
      let mut pos = base
      for _ in 0..<count {
        let axis_index = read_u16_int(data, pos)
        let start = read_i16(data, pos + 2)
        let peak = read_i16(data, pos + 4)
        let end = read_i16(data, pos + 6)
        match (axis_index, start, peak, end) {
          (Err(err), _, _, _) => return Err(err)
          (_, Err(err), _, _) => return Err(err)
          (_, _, Err(err), _) => return Err(err)
          (_, _, _, Err(err)) => return Err(err)
          (Ok(axis_index), Ok(start_coord), Ok(peak_coord), Ok(end_coord)) => {
            let axis = VarRegionAxis::{
              start_coord,
              peak_coord,
              end_coord,
            }
            axes.push(SparseVarRegionAxis::{ axis_index, axis })
          }
        }
        pos = pos + record_size
      }
      Ok(SparseVariationRegion::{ axes })
    }
  }
}

fn parse_sparse_var_region_list(
  data : BytesView,
  offset : Int,
) -> Result[SparseVarRegionList, VarError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let offsets_base = offset + 2
      let total = count * 4
      if offsets_base < 0 || offsets_base + total > data.length() {
        return Err(UnexpectedEof)
      }
      let regions : Array[SparseVariationRegion] = []
      for i in 0..<count {
        let entry = read_u32_int(data, offsets_base + i * 4)
        match entry {
          Err(err) => return Err(err)
          Ok(entry_offset) => {
            let region_offset = offset + entry_offset
            if region_offset < 0 || region_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            let region = match parse_sparse_variation_region(data, region_offset) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            regions.push(region)
          }
        }
      }
      Ok(SparseVarRegionList::{ regions })
    }
  }
}

fn parse_multi_var_data(data : BytesView, offset : Int) -> Result[MultiVarData, VarError] {
  let format = read_u8_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      let count = read_u16_int(data, offset + 1)
      match count {
        Err(err) => Err(err)
        Ok(count) => {
          if count < 0 {
            return Err(InvalidFormat)
          }
          let indices_base = offset + 3
          let total = count * 2
          if indices_base < 0 || indices_base + total > data.length() {
            return Err(UnexpectedEof)
          }
          let region_indices : Array[Int] = []
          let mut pos = indices_base
          for _ in 0..<count {
            let value = read_u16_int(data, pos)
            match value {
              Err(err) => return Err(err)
              Ok(v) => region_indices.push(v)
            }
            pos = pos + 2
          }
          let delta_sets = match parse_cff2_index(data, pos) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          Ok(MultiVarData::{ region_indices, delta_sets })
        }
      }
    }
  }
}

fn MultiVarData::add_delta(
  self : MultiVarData,
  inner : Int,
  coords : ArrayView[Int],
  regions : SparseVarRegionList,
  out : Array[Double],
) -> Unit {
  if inner < 0 || inner >= self.delta_sets.count {
    return
  }
  let bytes = match self.delta_sets.item_bytes(inner) {
    Err(_) => return
    Ok(value) => value
  }
  let values = match decode_tuple_values(bytes[:]) {
    Err(_) => return
    Ok(value) => value
  }
  let out_len = out.length()
  let region_count = self.region_indices.length()
  let mut index = 0
  for region_index in 0..<region_count {
    let scalar = regions.evaluate(self.region_indices[region_index], coords)
    for i in 0..<out_len {
      let value = if index < values.length() { values[index] } else { 0 }
      if scalar != 0.0 && value != 0 {
        out[i] = out[i] + scalar * value.to_double()
      }
      index = index + 1
    }
  }
}

///|
pub fn MultiItemVariationStore::parse(
  data : BytesView,
) -> Result[MultiItemVariationStore, VarError] {
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
      let region_list = match parse_sparse_var_region_list(data, region_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let data_sets : Array[MultiVarData] = []
      let mut pos = 8
      for _ in 0..<data_count {
        let entry = read_u32_int(data, pos)
        match entry {
          Err(err) => return Err(err)
          Ok(entry_offset) => {
            if entry_offset < 0 || entry_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            let data_set = match parse_multi_var_data(data, entry_offset) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            data_sets.push(data_set)
          }
        }
        pos = pos + 4
      }
      Ok(MultiItemVariationStore::{ region_list, data_sets })
    }
  }
}

///|
pub fn MultiItemVariationStore::get_delta(
  self : MultiItemVariationStore,
  var_idx : UInt,
  coords : Array[Int],
  out : Array[Double],
) -> Unit {
  let outer = ((var_idx >> 16) & 0xFFFFU).reinterpret_as_int()
  let inner = (var_idx & 0xFFFFU).reinterpret_as_int()
  if outer < 0 || outer >= self.data_sets.length() {
    return
  }
  self.data_sets[outer].add_delta(inner, coords[:], self.region_list, out)
}
