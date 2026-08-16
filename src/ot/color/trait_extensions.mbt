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
/// Keeps trait methods available through dot syntax.
pub extend BaseGlyphPaintRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseGlyphPaintRecord with Eq::{not_equal, equal}

///|
pub extend BaseGlyphPaintRecord with ToJson::{to_json}

///|
pub extend ClipBox with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ClipBox with Eq::{not_equal, equal}

///|
pub extend ClipBox with ToJson::{to_json}

///|
pub extend ClipExtents with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ClipExtents with Eq::{not_equal, equal}

///|
pub extend ClipExtents with ToJson::{to_json}

///|
pub extend ClipList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ClipList with Eq::{not_equal, equal}

///|
pub extend ClipList with ToJson::{to_json}

///|
pub extend ClipRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ClipRecord with Eq::{not_equal, equal}

///|
pub extend ClipRecord with ToJson::{to_json}

///|
pub extend ColorError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ColorError with Eq::{not_equal, equal}

///|
pub extend ColorError with ToJson::{to_json}

///|
pub extend ColrBaseGlyph with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ColrBaseGlyph with Eq::{not_equal, equal}

///|
pub extend ColrBaseGlyph with ToJson::{to_json}

///|
pub extend ColrLayer with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ColrLayer with Eq::{not_equal, equal}

///|
pub extend ColrLayer with ToJson::{to_json}

///|
pub extend ColrTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ColrTable with ToJson::{to_json}

///|
pub extend CpalTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CpalTable with ToJson::{to_json}
