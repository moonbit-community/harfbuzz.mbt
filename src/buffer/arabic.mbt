///|
let arabic_action_isol : Int = 0

///|
let arabic_action_fina : Int = 1

///|
let arabic_action_fin2 : Int = 2

///|
let arabic_action_fin3 : Int = 3

///|
let arabic_action_medi : Int = 4

///|
let arabic_action_med2 : Int = 5

///|
let arabic_action_init : Int = 6

///|
let arabic_action_none : Int = 7

///|
let arabic_feature_tags : Array[@common.Tag] = [
  @common.Tag::from_chars('i', 's', 'o', 'l'),
  @common.Tag::from_chars('f', 'i', 'n', 'a'),
  @common.Tag::from_chars('f', 'i', 'n', '2'),
  @common.Tag::from_chars('f', 'i', 'n', '3'),
  @common.Tag::from_chars('m', 'e', 'd', 'i'),
  @common.Tag::from_chars('m', 'e', 'd', '2'),
  @common.Tag::from_chars('i', 'n', 'i', 't'),
]

///|
priv struct ArabicStateEntry {
  prev_action : Int
  curr_action : Int
  next_state : Int
}

///|
let arabic_state_table : Array[Array[ArabicStateEntry]] = [
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 6 },
  ],
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_fin2, next_state: 5 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 6 },
  ],
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_init, curr_action: arabic_action_fina, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_init, curr_action: arabic_action_fina, next_state: 3 },
    ArabicStateEntry::{ prev_action: arabic_action_init, curr_action: arabic_action_fina, next_state: 4 },
    ArabicStateEntry::{ prev_action: arabic_action_init, curr_action: arabic_action_fina, next_state: 6 },
  ],
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_medi, curr_action: arabic_action_fina, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_medi, curr_action: arabic_action_fina, next_state: 3 },
    ArabicStateEntry::{ prev_action: arabic_action_medi, curr_action: arabic_action_fina, next_state: 4 },
    ArabicStateEntry::{ prev_action: arabic_action_medi, curr_action: arabic_action_fina, next_state: 6 },
  ],
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_med2, curr_action: arabic_action_isol, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_med2, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_med2, curr_action: arabic_action_fin2, next_state: 5 },
    ArabicStateEntry::{ prev_action: arabic_action_med2, curr_action: arabic_action_isol, next_state: 6 },
  ],
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_isol, curr_action: arabic_action_isol, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_isol, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_isol, curr_action: arabic_action_fin2, next_state: 5 },
    ArabicStateEntry::{ prev_action: arabic_action_isol, curr_action: arabic_action_isol, next_state: 6 },
  ],
  [
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_none, next_state: 0 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 1 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 2 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_fin3, next_state: 5 },
    ArabicStateEntry::{ prev_action: arabic_action_none, curr_action: arabic_action_isol, next_state: 6 },
  ],
]

///|
fn arabic_joining_actions(buffer : Buffer) -> Array[Int] {
  let infos = buffer.infos
  let actions : Array[Int] = Array::make(infos.length(), arabic_action_none)
  let mut state = 0
  let mut prev = -1
  for i in 0..<infos.length() {
    let join_type = @unicode.arabic_joining_type(infos[i].codepoint)
    if join_type == @unicode.arabic_joining_type_t {
      actions[i] = arabic_action_none
      continue
    }
    let col = join_type.reinterpret_as_int()
    if col < 0 || col >= 6 {
      actions[i] = arabic_action_none
      continue
    }
    let entry = arabic_state_table[state][col]
    if entry.prev_action != arabic_action_none && prev >= 0 {
      actions[prev] = entry.prev_action
    }
    actions[i] = entry.curr_action
    prev = i
    state = entry.next_state
  }
  actions
}

///|
fn is_mongolian_variation_selector(u : UInt) -> Bool {
  (u >= 0x180BU && u <= 0x180DU) || u == 0x180FU
}

///|
fn apply_mongolian_variation_selectors(
  actions : Array[Int],
  infos : Array[GlyphInfo],
) -> Unit {
  if actions.length() != infos.length() {
    return ()
  }
  if infos.length() <= 1 {
    return ()
  }
  for i in 1..<infos.length() {
    if is_mongolian_variation_selector(infos[i].codepoint) {
      actions[i] = actions[i - 1]
    }
  }
}

///|
fn build_action_mask(actions : Array[Int], target : Int) -> Array[UInt] {
  let masks : Array[UInt] = Array::make(actions.length(), 0U)
  for i in 0..<actions.length() {
    if actions[i] == target {
      masks[i] = 1U
    }
  }
  masks
}

///|
fn arabic_action_column(action : Int) -> Int? {
  if action == arabic_action_init {
    return Some(0)
  }
  if action == arabic_action_medi {
    return Some(1)
  }
  if action == arabic_action_fina || action == arabic_action_fin2 || action == arabic_action_fin3 {
    return Some(2)
  }
  if action == arabic_action_isol {
    return Some(3)
  }
  None
}

///|
fn apply_arabic_fallback(buffer : Buffer, actions : Array[Int]) -> Unit {
  if actions.length() != buffer.infos.length() {
    return ()
  }
  for i in 0..<actions.length() {
    let action = actions[i]
    let column = arabic_action_column(action)
    match column {
      None => ()
      Some(column) => {
        let codepoint = buffer.infos[i].codepoint
        match @unicode.arabic_shaping_form(codepoint, column) {
          None => ()
          Some(value) => {
            let info = buffer.infos[i]
            buffer.infos[i] = GlyphInfo::{ codepoint: value, cluster: info.cluster }
          }
        }
      }
    }
  }
}

///|
fn apply_gpos(font : @font.Font, buffer : Buffer) -> Result[Unit, ShapeError] {
  let gpos = match font.gpos() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if gpos is Some(gpos) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let glyphs : Array[UInt] = []
    for info in buffer.infos {
      glyphs.push(info.codepoint)
    }
    let script_tag = buffer.script.to_tag()
    let lang_tag = language_to_ot_tag(buffer.language)
    let lookup_offsets = match gpos.layout().select_lookup_offsets_with_features(
      script_tag,
      language_tag=lang_tag,
      feature_tags=buffer.gpos_features,
    ) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
    let deltas = match gdef {
      None =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          lookup_offsets[:],
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          lookup_offsets[:],
          gdef=gdef,
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
    }
    let new_positions : Array[GlyphPosition] = []
    for i in 0..<buffer.positions.length() {
      let pos = buffer.positions[i]
      let delta = deltas[i]
      new_positions.push(GlyphPosition::{
        x_advance: pos.x_advance + delta.x_advance,
        y_advance: pos.y_advance + delta.y_advance,
        x_offset: pos.x_offset + delta.x_placement,
        y_offset: pos.y_offset + delta.y_placement,
      })
    }
    buffer.positions = new_positions
  } else if buffer.direction.is_horizontal() {
    let kern = match font.kern() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    if kern is Some(kern) {
      let new_positions : Array[GlyphPosition] = []
      for pos in buffer.positions {
        new_positions.push(pos)
      }
      if new_positions.length() >= 2 {
        for i in 0..<(new_positions.length() - 1) {
          let left = buffer.infos[i].codepoint
          let right = buffer.infos[i + 1].codepoint
          match kern.kern_value(left, right) {
            None => ()
            Some(value) => {
              let pos = new_positions[i]
              new_positions[i] = GlyphPosition::{
                x_advance: pos.x_advance + value,
                y_advance: pos.y_advance,
                x_offset: pos.x_offset,
                y_offset: pos.y_offset,
              }
            }
          }
        }
      }
      buffer.positions = new_positions
    }
  }
  Ok(())
}

///|
pub fn Buffer::shape_arabic(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let actions = arabic_joining_actions(self)
  if self.script == @common.script_mongolian {
    apply_mongolian_variation_selectors(actions, self.infos)
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if self.script == @common.script_syriac {
    let mut has_syrc = false
    if gsub is Some(gsub) {
      let script_tag = self.script.to_tag()
      if buffer_layout_has_script(gsub.layout(), script_tag) {
        has_syrc = true
      }
    }
    if !has_syrc {
      return self.shape_ot(font)
    }
  }
  if actions.is_empty() {
    match self.shape_basic(font) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    return apply_gpos(font, self)
  }
  let mut current_glyphs : Array[UInt] = []
  let mut current_clusters : Array[Int] = []
  let mut changed = false
  let mut has_gsub_features = false
  if gsub is Some(gsub) {
    let script_tag = self.script.to_tag()
    let lang_tag = language_to_ot_tag(self.language)
    for feature_tag in arabic_feature_tags {
      let lookup_offsets = match gsub.layout().select_lookup_offsets_for_feature(
        script_tag,
        feature_tag,
        language_tag=lang_tag,
        include_required=false,
      ) {
        Err(err) => return Err(Layout(err))
        Ok(value) => value
      }
      if !lookup_offsets.is_empty() {
        has_gsub_features = true
        break
      }
    }
  }
  if !has_gsub_features {
    if self.script == @common.script_arabic {
      apply_arabic_fallback(self, actions)
    }
    match self.shape_basic(font) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    return apply_gpos(font, self)
  }
  if gsub is Some(gsub) {
    match self.shape_basic(font) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    for info in self.infos {
      current_glyphs.push(info.codepoint)
      current_clusters.push(info.cluster)
    }
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let script_tag = self.script.to_tag()
    let lang_tag = language_to_ot_tag(self.language)
    for feature_index in 0..<arabic_feature_tags.length() {
      let feature_tag = arabic_feature_tags[feature_index]
      let lookup_offsets = match gsub.layout().select_lookup_offsets_for_feature(
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
          match gsub.apply_with_lookups(
            current_glyphs,
            current_clusters,
            lookup_offsets[:],
            masks=masks,
            lookup_mask=1U,
          ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
        Some(gdef) =>
          match gsub.apply_with_lookups(
            current_glyphs,
            current_clusters,
            lookup_offsets[:],
            gdef=gdef,
            masks=masks,
            lookup_mask=1U,
          ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
      }
      let (next_glyphs, next_clusters, did_change) = result
      current_glyphs = next_glyphs
      current_clusters = next_clusters
      if did_change {
        changed = true
      }
    }
  }
  if changed {
    let infos : Array[GlyphInfo] = []
    let positions : Array[GlyphPosition] = []
    for i in 0..<current_glyphs.length() {
      let glyph = current_glyphs[i]
      let pos = match default_position(self, font, glyph) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      infos.push(GlyphInfo::{ codepoint: glyph, cluster: current_clusters[i] })
      positions.push(pos)
    }
    self.infos = infos
    self.positions = positions
  }
  apply_gpos(font, self)
}
