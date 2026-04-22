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
/// OT feature lookup selections for GSUB/GPOS.
pub struct OtMap {
  gsub_lookups : Array[Int]
  gpos_lookups : Array[Int]
}

///|
/// Build lookup selections for a script/language and feature allowlists.
pub fn OtMap::new(
  gsub : @ot_tables.GsubTable?,
  gpos : @ot_tables.GposTable?,
  script_tag : @common.Tag,
  language_tag? : @common.Tag = @common.tag_none,
  gsub_features? : Array[@common.Tag] = [],
  gpos_features? : Array[@common.Tag] = [],
) -> Result[OtMap, @ot_tables.OtLayoutError] {
  let gsub_lookups = match gsub {
    None => []
    Some(gsub) =>
      match
        gsub
        .layout()
        .select_lookup_offsets_with_features(
          script_tag,
          language_tag~,
          feature_tags=gsub_features,
        ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
  }
  let gpos_lookups = match gpos {
    None => []
    Some(gpos) =>
      match
        gpos
        .layout()
        .select_lookup_offsets_with_features(
          script_tag,
          language_tag~,
          feature_tags=gpos_features,
        ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
  }
  Ok(OtMap::{ gsub_lookups, gpos_lookups })
}

///|
/// Access GSUB lookup offsets.
pub fn OtMap::gsub_lookups(self : OtMap) -> ArrayView[Int] {
  self.gsub_lookups[:]
}

///|
/// Access GPOS lookup offsets.
pub fn OtMap::gpos_lookups(self : OtMap) -> ArrayView[Int] {
  self.gpos_lookups[:]
}
