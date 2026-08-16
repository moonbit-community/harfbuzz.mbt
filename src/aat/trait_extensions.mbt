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
pub extend AatError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AatError with Eq::{not_equal, equal}

///|
pub extend AatError with ToJson::{to_json}

///|
pub extend Anchor with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Anchor with Eq::{not_equal, equal}

///|
pub extend Anchor with ToJson::{to_json}

///|
pub extend AnkrTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AnkrTable with ToJson::{to_json}

///|
pub extend BslnData with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BslnData with ToJson::{to_json}

///|
pub extend BslnTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BslnTable with ToJson::{to_json}

///|
pub extend ClassTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ClassTable with Eq::{not_equal, equal}

///|
pub extend ClassTable with ToJson::{to_json}

///|
pub extend ContextualSubstitutions with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ContextualSubstitutions with Eq::{not_equal, equal}

///|
pub extend ContextualSubstitutions with ToJson::{to_json}

///|
pub extend ContextualSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ContextualSubtable with Eq::{not_equal, equal}

///|
pub extend ContextualSubtable with ToJson::{to_json}

///|
pub extend FeatFeatureName with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FeatFeatureName with Eq::{not_equal, equal}

///|
pub extend FeatFeatureName with ToJson::{to_json}

///|
pub extend FeatSettingName with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FeatSettingName with Eq::{not_equal, equal}

///|
pub extend FeatSettingName with ToJson::{to_json}

///|
pub extend FeatTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FeatTable with ToJson::{to_json}

///|
pub extend InsertionSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend InsertionSubtable with Eq::{not_equal, equal}

///|
pub extend InsertionSubtable with ToJson::{to_json}

///|
pub extend JustificationHeader with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JustificationHeader with ToJson::{to_json}

///|
pub extend JustTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JustTable with ToJson::{to_json}

///|
pub extend KerxAdjustment with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxAdjustment with Eq::{not_equal, equal}

///|
pub extend KerxAdjustment with ToJson::{to_json}

///|
pub extend KerxFormat1 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxFormat1 with ToJson::{to_json}

///|
pub extend KerxFormat2 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxFormat2 with ToJson::{to_json}

///|
pub extend KerxFormat4 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxFormat4 with ToJson::{to_json}

///|
pub extend KerxFormat6 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxFormat6 with ToJson::{to_json}

///|
pub extend KerxPair with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxPair with Eq::{not_equal, equal}

///|
pub extend KerxPair with ToJson::{to_json}

///|
pub extend KerxSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxSubtable with ToJson::{to_json}

///|
pub extend KerxSubtableHeader with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxSubtableHeader with Eq::{not_equal, equal}

///|
pub extend KerxSubtableHeader with ToJson::{to_json}

///|
pub extend KerxTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KerxTable with ToJson::{to_json}

///|
pub extend LigatureSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LigatureSubtable with Eq::{not_equal, equal}

///|
pub extend LigatureSubtable with ToJson::{to_json}

///|
pub extend LookupSegmentArray with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LookupSegmentArray with Eq::{not_equal, equal}

///|
pub extend LookupSegmentArray with ToJson::{to_json}

///|
pub extend LookupSegmentSingle with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LookupSegmentSingle with Eq::{not_equal, equal}

///|
pub extend LookupSegmentSingle with ToJson::{to_json}

///|
pub extend LookupSingle with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LookupSingle with Eq::{not_equal, equal}

///|
pub extend LookupSingle with ToJson::{to_json}

///|
pub extend LookupTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LookupTable with Eq::{not_equal, equal}

///|
pub extend LookupTable with ToJson::{to_json}

///|
pub extend LtagTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LtagTable with ToJson::{to_json}

///|
pub extend MortTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MortTable with Eq::{not_equal, equal}

///|
pub extend MortTable with ToJson::{to_json}

///|
pub extend MorxSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MorxSubtable with Eq::{not_equal, equal}

///|
pub extend MorxSubtable with ToJson::{to_json}

///|
pub extend MorxTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MorxTable with Eq::{not_equal, equal}

///|
pub extend MorxTable with ToJson::{to_json}

///|
pub extend NoncontextualSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend NoncontextualSubtable with Eq::{not_equal, equal}

///|
pub extend NoncontextualSubtable with ToJson::{to_json}

///|
pub extend OpbdTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend OpbdTable with ToJson::{to_json}

///|
pub extend OpticalBounds with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend OpticalBounds with Eq::{not_equal, equal}

///|
pub extend OpticalBounds with ToJson::{to_json}

///|
pub extend RearrangementSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend RearrangementSubtable with Eq::{not_equal, equal}

///|
pub extend RearrangementSubtable with ToJson::{to_json}

///|
pub extend StateEntry with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend StateEntry with Eq::{not_equal, equal}

///|
pub extend StateEntry with ToJson::{to_json}

///|
pub extend StateTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend StateTable with Eq::{not_equal, equal}

///|
pub extend StateTable with ToJson::{to_json}

///|
pub extend TrackData with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TrackData with Eq::{not_equal, equal}

///|
pub extend TrackData with ToJson::{to_json}

///|
pub extend TrackTableEntry with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TrackTableEntry with Eq::{not_equal, equal}

///|
pub extend TrackTableEntry with ToJson::{to_json}

///|
pub extend TrakTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TrakTable with Eq::{not_equal, equal}

///|
pub extend TrakTable with ToJson::{to_json}
