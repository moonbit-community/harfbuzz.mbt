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
let hangul_action_ljmo : Int = 0

///|
let hangul_action_vjmo : Int = 1

///|
let hangul_action_tjmo : Int = 2

///|
let hangul_action_none : Int = 3

///|
let hangul_feature_tags : Array[@common.Tag] = [
  @common.Tag::from_chars('l', 'j', 'm', 'o'),
  @common.Tag::from_chars('v', 'j', 'm', 'o'),
  @common.Tag::from_chars('t', 'j', 'm', 'o'),
]

///|
fn hangul_actions(buffer : Buffer) -> Array[Int] {
  let actions : Array[Int] = Array::make(
    buffer.infos.length(),
    hangul_action_none,
  )
  for i in 0..<buffer.infos.length() {
    let value = buffer.infos[i].codepoint
    if is_hangul_l(value) {
      actions[i] = hangul_action_ljmo
    } else if is_hangul_v(value) {
      actions[i] = hangul_action_vjmo
    } else if is_hangul_t(value) {
      actions[i] = hangul_action_tjmo
    }
  }
  actions
}

///|
fn decompose_hangul_syllable(u : UInt) -> Array[UInt] {
  if !is_hangul_lv(u) {
    return [u]
  }
  match @unicode.decompose(u) {
    None => [u]
    Some((a, b)) => {
      if b == 0U {
        return [a]
      }
      if is_hangul_lv(a) {
        match @unicode.decompose(a) {
          None => [a, b]
          Some((l, v)) => if v == 0U { [a, b] } else { [l, v, b] }
        }
      } else {
        [a, b]
      }
    }
  }
}

///|
fn hangul_components_available(
  font : @font.Font,
  components : Array[UInt],
) -> Result[Bool, ShapeError] {
  for component in components {
    match font.glyph_for_codepoint(component) {
      Err(err) => return Err(Font(err))
      Ok(None) => return Ok(false)
      Ok(Some(_)) => ()
    }
  }
  Ok(true)
}

///|
fn preprocess_hangul_for_font(
  buffer : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  if buffer.infos.is_empty() {
    return Ok(())
  }
  let mut changed = false
  let next_infos : Array[GlyphInfo] = []
  for info in buffer.infos {
    let codepoint = info.codepoint
    if is_hangul_lv(codepoint) {
      let has_glyph = match font.glyph_for_codepoint(codepoint) {
        Err(err) => return Err(Font(err))
        Ok(None) => false
        Ok(Some(_)) => true
      }
      if !has_glyph {
        let components = decompose_hangul_syllable(codepoint)
        if components.length() > 1 {
          match hangul_components_available(font, components) {
            Err(err) => return Err(err)
            Ok(false) => ()
            Ok(true) => {
              changed = true
              for component in components {
                next_infos.push(GlyphInfo::{
                  codepoint: component,
                  cluster: info.cluster,
                  unicode: component,
                })
              }
              continue
            }
          }
        }
      }
    }
    next_infos.push(info)
  }
  if changed {
    ignore(buffer.replace_glyphs(next_infos))
  }
  Ok(())
}

///|
pub fn Buffer::shape_hangul(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  match preprocess_hangul_for_font(self, font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let (unicode_mark_flags, combining_classes) = collect_mark_fallback_data(
    self.infos,
  )
  let actions = hangul_actions(self)
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let mut current_glyphs : Array[UInt] = []
  let mut current_clusters : Array[Int] = []
  let mut current_unicodes : Array[UInt] = []
  for info in self.infos {
    current_glyphs.push(info.codepoint)
    current_clusters.push(info.cluster)
    current_unicodes.push(info.unicode)
  }
  let mut changed = false
  if gsub is Some(gsub) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let script_tag = self.script.to_tag()
    let lang_tag = language_to_ot_tag(self.language)
    for feature_index in 0..<hangul_feature_tags.length() {
      let feature_tag = hangul_feature_tags[feature_index]
      let lookup_offsets = match
        gsub
        .layout()
        .select_lookup_offsets_for_feature(
          script_tag,
          feature_tag,
          language_tag=lang_tag,
          include_required=false,
        ) {
        Err(err) => return Err(Layout(err))
        Ok(value) => value
      }
      if lookup_offsets.is_empty() {
        continue
      }
      let masks = build_action_mask(actions, feature_index)
      let result = match gdef {
        None =>
          match
            gsub.apply_with_lookups(
              current_glyphs,
              current_clusters,
              lookup_offsets[:],
              masks~,
              lookup_mask=1U,
            ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
        Some(gdef) =>
          match
            gsub.apply_with_lookups(
              current_glyphs,
              current_clusters,
              lookup_offsets[:],
              gdef~,
              masks~,
              lookup_mask=1U,
            ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
      }
      let (next_glyphs, next_clusters, did_change) = result
      if next_glyphs.length() != current_unicodes.length() {
        current_unicodes = Array::make(next_glyphs.length(), 0U)
      }
      current_glyphs = next_glyphs
      current_clusters = next_clusters
      if did_change {
        changed = true
      }
    }
  }
  if changed || current_glyphs.length() != self.infos.length() {
    let infos : Array[GlyphInfo] = []
    let positions : Array[GlyphPosition] = []
    for i in 0..<current_glyphs.length() {
      let glyph = current_glyphs[i]
      let pos = match default_position(self, font, glyph) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let unicode = if current_unicodes.length() == current_glyphs.length() {
        current_unicodes[i]
      } else {
        0U
      }
      infos.push(GlyphInfo::{
        codepoint: glyph,
        cluster: current_clusters[i],
        unicode,
      })
      positions.push(pos)
    }
    self.infos = infos
    self.positions = positions
  }
  apply_gpos(
    font,
    self,
    zero_width_marks=ZeroWidthMarks::Disabled,
    fallback_position=true,
    unicode_mark_flags~,
    combining_classes~,
  )
}
