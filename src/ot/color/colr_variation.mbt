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
let f2dot14_scale : Double = 1.0 / 16384.0

///|
let f16dot16_scale : Double = 1.0 / 65536.0

///|
/// COLRv1 variation instancer.
pub struct ColrVarInstancer {
  coords : Array[Int]
  var_store : @ot_var.ItemVariationStore?
  var_idx_map : @ot_var.DeltaSetIndexMap?
}

///|
/// Build a variation instancer for COLRv1 data.
pub fn ColrTable::var_instancer(
  self : ColrTable,
  coords : Array[Int],
) -> ColrVarInstancer {
  ColrVarInstancer::{
    coords,
    var_store: self.var_store,
    var_idx_map: self.var_idx_map,
  }
}

///|
/// Resolve a variation delta for a varIdxBase + offset.
pub fn ColrVarInstancer::delta(
  self : ColrVarInstancer,
  var_idx_base : @paint.VarIdx?,
  offset : Int,
) -> Double {
  if offset < 0 {
    return 0.0
  }
  if self.coords.length() == 0 {
    return 0.0
  }
  let store = match self.var_store {
    None => return 0.0
    Some(store) => store
  }
  let base = match var_idx_base {
    None => return 0.0
    Some(base) => base
  }
  if base == @paint.var_idx_none {
    return 0.0
  }
  let mut var_idx = base + offset.reinterpret_as_uint()
  match self.var_idx_map {
    None => ()
    Some(map) => var_idx = map.map(var_idx)
  }
  store.get_delta(var_idx, self.coords)
}

///|
/// Apply a variation delta to an FWORD value (returns float).
pub fn ColrVarInstancer::fword(
  self : ColrVarInstancer,
  value : Int,
  var_idx_base : @paint.VarIdx?,
  offset : Int,
) -> Double {
  value.to_double() + self.delta(var_idx_base, offset)
}

///|
/// Apply a variation delta to an F2DOT14 value (returns float).
pub fn ColrVarInstancer::f2dot14(
  self : ColrVarInstancer,
  value : Int,
  var_idx_base : @paint.VarIdx?,
  offset : Int,
) -> Double {
  (value.to_double() + self.delta(var_idx_base, offset)) * f2dot14_scale
}

///|
/// Apply a variation delta to an F16DOT16 value (returns float).
pub fn ColrVarInstancer::f16dot16(
  self : ColrVarInstancer,
  value : Int,
  var_idx_base : @paint.VarIdx?,
  offset : Int,
) -> Double {
  (value.to_double() + self.delta(var_idx_base, offset)) * f16dot16_scale
}
