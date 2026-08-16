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
pub extend AvarMapping with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AvarMapping with Eq::{not_equal, equal}

///|
pub extend AvarMapping with ToJson::{to_json}

///|
pub extend AvarSegmentMap with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AvarSegmentMap with Eq::{not_equal, equal}

///|
pub extend AvarSegmentMap with ToJson::{to_json}

///|
pub extend AvarTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AvarTable with Eq::{not_equal, equal}

///|
pub extend AvarTable with ToJson::{to_json}

///|
pub extend AxisCoord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AxisCoord with Eq::{not_equal, equal}

///|
pub extend AxisCoord with ToJson::{to_json}

///|
pub extend AxisRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AxisRecord with Eq::{not_equal, equal}

///|
pub extend AxisRecord with ToJson::{to_json}

///|
pub extend CffIndex with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CffIndex with ToJson::{to_json}

///|
pub extend CvarTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CvarTable with ToJson::{to_json}

///|
pub extend DeltaSetIndexMap with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DeltaSetIndexMap with Eq::{not_equal, equal}

///|
pub extend DeltaSetIndexMap with ToJson::{to_json}

///|
pub extend FvarTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FvarTable with Eq::{not_equal, equal}

///|
pub extend FvarTable with ToJson::{to_json}

///|
pub extend GvarTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GvarTable with ToJson::{to_json}

///|
pub extend HvarTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HvarTable with ToJson::{to_json}

///|
pub extend InstanceRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend InstanceRecord with Eq::{not_equal, equal}

///|
pub extend InstanceRecord with ToJson::{to_json}

///|
pub extend ItemVariationStore with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ItemVariationStore with Eq::{not_equal, equal}

///|
pub extend ItemVariationStore with ToJson::{to_json}

///|
pub extend MultiItemVariationStore with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MultiItemVariationStore with ToJson::{to_json}

///|
pub extend MultiVarData with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MultiVarData with ToJson::{to_json}

///|
pub extend MvarRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MvarRecord with Eq::{not_equal, equal}

///|
pub extend MvarRecord with ToJson::{to_json}

///|
pub extend MvarTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MvarTable with ToJson::{to_json}

///|
pub extend SparseVariationRegion with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SparseVariationRegion with Eq::{not_equal, equal}

///|
pub extend SparseVariationRegion with ToJson::{to_json}

///|
pub extend SparseVarRegionAxis with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SparseVarRegionAxis with Eq::{not_equal, equal}

///|
pub extend SparseVarRegionAxis with ToJson::{to_json}

///|
pub extend SparseVarRegionList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SparseVarRegionList with Eq::{not_equal, equal}

///|
pub extend SparseVarRegionList with ToJson::{to_json}

///|
pub extend TupleHeader with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TupleHeader with ToJson::{to_json}

///|
pub extend TupleVariation with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TupleVariation with ToJson::{to_json}

///|
pub extend TupleVariationData with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TupleVariationData with ToJson::{to_json}

///|
pub extend VarcComponent with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarcComponent with ToJson::{to_json}

///|
pub extend VarcCondition with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarcCondition with ToJson::{to_json}

///|
pub extend VarcTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarcTable with ToJson::{to_json}

///|
pub extend VarcTransform with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarcTransform with ToJson::{to_json}

///|
pub extend VarData with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarData with Eq::{not_equal, equal}

///|
pub extend VarData with ToJson::{to_json}

///|
pub extend VarError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarError with Eq::{not_equal, equal}

///|
pub extend VarError with ToJson::{to_json}

///|
pub extend VarRegionAxis with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarRegionAxis with Eq::{not_equal, equal}

///|
pub extend VarRegionAxis with ToJson::{to_json}

///|
pub extend VarRegionList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VarRegionList with Eq::{not_equal, equal}

///|
pub extend VarRegionList with ToJson::{to_json}
