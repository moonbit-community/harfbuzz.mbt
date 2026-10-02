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
pub type VarIdx = UInt

///|
/// Special value indicating no variation.
pub let var_idx_none : VarIdx = 0xFFFFFFFFU

///|
/// RGBA color (0..255 per channel).
pub struct Color {
  r : Int
  g : Int
  b : Int
  a : Int
} derive(Eq, Debug, ToJson)

///|
pub extend Color with Eq::{not_equal, equal}

///|
pub extend Color with @debug.Debug::{to_repr}

///|
pub extend Color with ToJson::{to_json}

///|
/// Helper to build a color from BGRA bytes.
pub fn Color::from_bgra(b : Int, g : Int, r : Int, a : Int) -> Color {
  { r, g, b, a, }
}

///|
/// Color stop for gradients. Offset/alpha are raw F2DOT14 values.
pub(all) struct ColorStop {
  offset : Int
  palette_index : Int
  alpha : Int
  var_idx_base : VarIdx?
} derive(Eq, Debug, ToJson)

///|
pub extend ColorStop with Eq::{not_equal, equal}

///|
pub extend ColorStop with @debug.Debug::{to_repr}

///|
pub extend ColorStop with ToJson::{to_json}

///|
/// Color line for gradients. `extend_mode` is the raw `Extend` enum value
/// (0..2). It was named `extend`, which is now a reserved word.
pub(all) struct ColorLine {
  extend_mode : Int
  stops : Array[ColorStop]
} derive(Eq, Debug, ToJson)

///|
pub extend ColorLine with Eq::{not_equal, equal}

///|
pub extend ColorLine with @debug.Debug::{to_repr}

///|
pub extend ColorLine with ToJson::{to_json}

///|
/// Affine transform (F16DOT16 values), with optional VarIdx base for variation.
pub(all) struct Affine2x3 {
  xx : Int
  yx : Int
  xy : Int
  yy : Int
  dx : Int
  dy : Int
  var_idx_base : VarIdx?
} derive(Eq, Debug, ToJson)

///|
pub extend Affine2x3 with Eq::{not_equal, equal}

///|
pub extend Affine2x3 with @debug.Debug::{to_repr}

///|
pub extend Affine2x3 with ToJson::{to_json}
