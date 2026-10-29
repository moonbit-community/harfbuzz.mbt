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
/// VarIdx points into an ItemVariationStore (outer:high 16 bits, inner:low 16 bits).
pub type VarIdx = UInt32

///|
/// Special value indicating no variation.
pub let var_idx_none : VarIdx = 0xFFFFFFFFU

///|
/// RGBA color (0..255 per channel).
pub struct Color {
  r : Int32
  g : Int32
  b : Int32
  a : Int32
} derive(Eq, Debug, ToJson)

///|
/// Helper to build a color from BGRA bytes.
pub fn Color::from_bgra(b : Int32, g : Int32, r : Int32, a : Int32) -> Color {
  { r, g, b, a, }
}

///|
/// Color stop for gradients. Offset/alpha are raw F2DOT14 values.
pub(all) struct ColorStop {
  offset : Int32
  palette_index : Int32
  alpha : Int32
  var_idx_base : VarIdx?
} derive(Eq, Debug, ToJson)

///|
/// Color line for gradients. Extend is raw enum value (0..2).
pub(all) struct ColorLine {
  extend_mode : Int32
  stops : Array[ColorStop]
} derive(Eq, Debug)

///|
/// Preserve the COLR JSON key after `extend` became a language keyword.
pub impl ToJson for ColorLine with fn to_json(self) {
  { "extend": Json(self.extend_mode), "stops": Json(self.stops) }
}

///|
/// Affine transform (F16DOT16 values), with optional VarIdx base for variation.
pub(all) struct Affine2x3 {
  xx : Int32
  yx : Int32
  xy : Int32
  yy : Int32
  dx : Int32
  dy : Int32
  var_idx_base : VarIdx?
} derive(Eq, Debug, ToJson)
