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
/// COLRv0 layer record.
pub struct ColrLayer {
  glyph_id : Int
  color_index : Int
} derive(Eq, Debug, ToJson)

///|
pub extend ColrLayer with Eq::{not_equal, equal}

///|
pub extend ColrLayer with @debug.Debug::{to_repr}

///|
pub extend ColrLayer with ToJson::{to_json}

///|
/// COLRv0 base glyph record.
pub struct ColrBaseGlyph {
  glyph_id : Int
  first_layer_index : Int
  num_layers : Int
} derive(Eq, Debug, ToJson)

///|
pub extend ColrBaseGlyph with Eq::{not_equal, equal}

///|
pub extend ColrBaseGlyph with @debug.Debug::{to_repr}

///|
pub extend ColrBaseGlyph with ToJson::{to_json}

///|
/// COLRv1 base glyph -> paint record.
pub struct BaseGlyphPaintRecord {
  glyph_id : Int
  paint_offset : Int
} derive(Eq, Debug, ToJson)

///|
pub extend BaseGlyphPaintRecord with Eq::{not_equal, equal}

///|
pub extend BaseGlyphPaintRecord with @debug.Debug::{to_repr}

///|
pub extend BaseGlyphPaintRecord with ToJson::{to_json}

///|
/// Clip box data (format 1 or 2).
pub struct ClipBox {
  format : Int
  x_min : Int
  y_min : Int
  x_max : Int
  y_max : Int
  var_idx_base : @paint.VarIdx?
} derive(Eq, Debug, ToJson)

///|
pub extend ClipBox with Eq::{not_equal, equal}

///|
pub extend ClipBox with @debug.Debug::{to_repr}

///|
pub extend ClipBox with ToJson::{to_json}

///|
/// Clip record for a glyph range.
pub struct ClipRecord {
  start_glyph_id : Int
  end_glyph_id : Int
  clip_box : ClipBox
} derive(Eq, Debug, ToJson)

///|
pub extend ClipRecord with Eq::{not_equal, equal}

///|
pub extend ClipRecord with @debug.Debug::{to_repr}

///|
pub extend ClipRecord with ToJson::{to_json}

///|
/// Clip list (format 1) for COLRv1.
pub struct ClipList {
  format : Int
  records : Array[ClipRecord]
} derive(Eq, Debug, ToJson)

///|
pub extend ClipList with Eq::{not_equal, equal}

///|
pub extend ClipList with @debug.Debug::{to_repr}

///|
pub extend ClipList with ToJson::{to_json}

///|
/// Clip extents for a glyph (y-bearing is y_max).
pub struct ClipExtents {
  x_bearing : Int
  y_bearing : Int
  width : Int
  height : Int
} derive(Eq, Debug, ToJson)

///|
pub extend ClipExtents with Eq::{not_equal, equal}

///|
pub extend ClipExtents with @debug.Debug::{to_repr}

///|
pub extend ClipExtents with ToJson::{to_json}
