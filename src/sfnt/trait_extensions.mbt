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
pub extend Axis with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Axis with ToJson::{to_json}

///|
pub extend AxisValue with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AxisValue with ToJson::{to_json}

///|
pub extend AxisValueRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AxisValueRecord with Eq::{not_equal, equal}

///|
pub extend AxisValueRecord with ToJson::{to_json}

///|
pub extend BaseCoord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseCoord with ToJson::{to_json}

///|
pub extend BaseLangSysRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseLangSysRecord with ToJson::{to_json}

///|
pub extend BaseScript with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseScript with ToJson::{to_json}

///|
pub extend BaseScriptList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseScriptList with ToJson::{to_json}

///|
pub extend BaseScriptRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseScriptRecord with ToJson::{to_json}

///|
pub extend BaseTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseTable with ToJson::{to_json}

///|
pub extend BaseTagList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseTagList with ToJson::{to_json}

///|
pub extend BaseValues with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BaseValues with ToJson::{to_json}

///|
pub extend CmapTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CmapTable with ToJson::{to_json}

///|
pub extend CompositeComponent with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CompositeComponent with ToJson::{to_json}

///|
pub extend CvtTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CvtTable with ToJson::{to_json}

///|
pub extend FeatMinMaxRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FeatMinMaxRecord with ToJson::{to_json}

///|
pub extend GaspRange with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GaspRange with Eq::{not_equal, equal}

///|
pub extend GaspRange with ToJson::{to_json}

///|
pub extend GaspTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GaspTable with ToJson::{to_json}

///|
pub extend GlyfTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GlyfTable with ToJson::{to_json}

///|
pub extend GlyphBounds with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GlyphBounds with Eq::{not_equal, equal}

///|
pub extend GlyphBounds with ToJson::{to_json}

///|
pub extend GlyphPoint with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend GlyphPoint with ToJson::{to_json}

///|
pub extend HdmxRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HdmxRecord with ToJson::{to_json}

///|
pub extend HdmxTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HdmxTable with ToJson::{to_json}

///|
pub extend HeadTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HeadTable with Eq::{not_equal, equal}

///|
pub extend HeadTable with ToJson::{to_json}

///|
pub extend HheaTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HheaTable with Eq::{not_equal, equal}

///|
pub extend HheaTable with ToJson::{to_json}

///|
pub extend HmtxTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HmtxTable with ToJson::{to_json}

///|
pub extend JstfLangSys with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfLangSys with ToJson::{to_json}

///|
pub extend JstfLangSysRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfLangSysRecord with ToJson::{to_json}

///|
pub extend JstfMax with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfMax with ToJson::{to_json}

///|
pub extend JstfModList with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfModList with ToJson::{to_json}

///|
pub extend JstfPriority with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfPriority with ToJson::{to_json}

///|
pub extend JstfScript with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfScript with ToJson::{to_json}

///|
pub extend JstfScriptRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfScriptRecord with ToJson::{to_json}

///|
pub extend JstfTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend JstfTable with ToJson::{to_json}

///|
pub extend KernClassTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KernClassTable with ToJson::{to_json}

///|
pub extend KernPair with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KernPair with Eq::{not_equal, equal}

///|
pub extend KernPair with ToJson::{to_json}

///|
pub extend KernSubtable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KernSubtable with ToJson::{to_json}

///|
pub extend KernSubtableFormat2 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KernSubtableFormat2 with ToJson::{to_json}

///|
pub extend KernSubtableFormat3 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KernSubtableFormat3 with ToJson::{to_json}

///|
pub extend KernTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KernTable with ToJson::{to_json}

///|
pub extend LocaTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend LocaTable with Eq::{not_equal, equal}

///|
pub extend LocaTable with ToJson::{to_json}

///|
pub extend MathConstants with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathConstants with ToJson::{to_json}

///|
pub extend MathGlyphAssembly with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathGlyphAssembly with ToJson::{to_json}

///|
pub extend MathGlyphConstruction with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathGlyphConstruction with ToJson::{to_json}

///|
pub extend MathGlyphInfo with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathGlyphInfo with ToJson::{to_json}

///|
pub extend MathGlyphPartRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathGlyphPartRecord with ToJson::{to_json}

///|
pub extend MathGlyphVariantRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathGlyphVariantRecord with ToJson::{to_json}

///|
pub extend MathItalicsCorrectionInfo with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend MathItalicsCorrectionInfo with ToJson::{to_json}

///|
pub extend MathKern with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathKern with ToJson::{to_json}

///|
pub extend MathKernInfo with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathKernInfo with ToJson::{to_json}

///|
pub extend MathKernInfoRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathKernInfoRecord with ToJson::{to_json}

///|
pub extend MathTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathTable with ToJson::{to_json}

///|
pub extend MathTopAccentAttachment with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathTopAccentAttachment with ToJson::{to_json}

///|
pub extend MathValueRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathValueRecord with Eq::{not_equal, equal}

///|
pub extend MathValueRecord with ToJson::{to_json}

///|
pub extend MathVariants with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MathVariants with ToJson::{to_json}

///|
pub extend MaxpTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MaxpTable with Eq::{not_equal, equal}

///|
pub extend MaxpTable with ToJson::{to_json}

///|
pub extend MetaRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MetaRecord with ToJson::{to_json}

///|
pub extend MetaTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MetaTable with ToJson::{to_json}

///|
pub extend MinMax with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MinMax with ToJson::{to_json}

///|
pub extend NameRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend NameRecord with ToJson::{to_json}

///|
pub extend NameTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend NameTable with ToJson::{to_json}

///|
pub extend Os2Table with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Os2Table with ToJson::{to_json}

///|
pub extend PostTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PostTable with ToJson::{to_json}

///|
pub extend Sfnt with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Sfnt with ToJson::{to_json}

///|
pub extend SfntError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SfntError with Eq::{not_equal, equal}

///|
pub extend SfntError with ToJson::{to_json}

///|
pub extend StatAxisRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend StatAxisRecord with Eq::{not_equal, equal}

///|
pub extend StatAxisRecord with ToJson::{to_json}

///|
pub extend StatTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend StatTable with ToJson::{to_json}

///|
pub extend TableRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TableRecord with Eq::{not_equal, equal}

///|
pub extend TableRecord with ToJson::{to_json}

///|
pub extend VheaTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VheaTable with Eq::{not_equal, equal}

///|
pub extend VheaTable with ToJson::{to_json}

///|
pub extend VmtxTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VmtxTable with ToJson::{to_json}

///|
pub extend VorgMetric with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VorgMetric with Eq::{not_equal, equal}

///|
pub extend VorgMetric with ToJson::{to_json}

///|
pub extend VorgTable with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VorgTable with ToJson::{to_json}
