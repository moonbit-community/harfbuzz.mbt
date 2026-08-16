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
pub extend FeatureList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FeatureList with Eq::{not_equal, equal}

///|
pub extend FeatureList with ToJson::{to_json}

///|
pub extend FeatureRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FeatureRecord with Eq::{not_equal, equal}

///|
pub extend FeatureRecord with ToJson::{to_json}

///|
pub extend GdefHeader with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GdefHeader with ToJson::{to_json}

///|
pub extend GdefTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GdefTable with ToJson::{to_json}

///|
pub extend GposTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GposTable with ToJson::{to_json}

///|
pub extend GsubTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GsubTable with ToJson::{to_json}

///|
pub extend LayoutHeader with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LayoutHeader with Eq::{not_equal, equal}

///|
pub extend LayoutHeader with ToJson::{to_json}

///|
pub extend LayoutTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LayoutTable with ToJson::{to_json}

///|
pub extend LookupList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LookupList with Eq::{not_equal, equal}

///|
pub extend LookupList with ToJson::{to_json}

///|
pub extend OtLayoutError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend OtLayoutError with Eq::{not_equal, equal}

///|
pub extend OtLayoutError with ToJson::{to_json}

///|
pub extend PairAdjust with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PairAdjust with Eq::{not_equal, equal}

///|
pub extend PairAdjust with ToJson::{to_json}

///|
pub extend ScriptList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ScriptList with Eq::{not_equal, equal}

///|
pub extend ScriptList with ToJson::{to_json}

///|
pub extend ScriptRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ScriptRecord with Eq::{not_equal, equal}

///|
pub extend ScriptRecord with ToJson::{to_json}

///|
pub extend ValueRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ValueRecord with Eq::{not_equal, equal}

///|
pub extend ValueRecord with ToJson::{to_json}
