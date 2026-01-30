///|
/// Glyph info entry.
pub struct GlyphInfo {
  codepoint : UInt
  cluster : Int
} derive(Eq, Show, ToJson)

///|
/// Glyph positioning data.
pub struct GlyphPosition {
  x_advance : Int
  y_advance : Int
  x_offset : Int
  y_offset : Int
} derive(Eq, Show, ToJson)

///|
suberror ShapeError {
  Font(@font.FontError)
  Layout(@ot_tables.OtLayoutError)
} derive(Eq, Show, ToJson)

///|
/// Text buffer for shaping.
pub struct Buffer {
  mut infos : Array[GlyphInfo]
  mut positions : Array[GlyphPosition]
  mut direction : @common.Direction
  mut script : @common.Script
  mut language : @common.Language
  mut gsub_features : Array[@common.Tag]
  mut gpos_features : Array[@common.Tag]
} derive(Show, ToJson)

///|
/// Create an empty buffer.
pub fn Buffer::new() -> Buffer {
  Buffer::{
    infos: [],
    positions: [],
    direction: @common.direction_invalid,
    script: @common.script_invalid,
    language: @common.language_invalid,
    gsub_features: default_gsub_features(),
    gpos_features: default_gpos_features(),
  }
}

///|
/// Clear all glyph data.
pub fn Buffer::clear(self : Buffer) -> Unit {
  self.infos = []
  self.positions = []
}

///|
/// Number of glyphs in the buffer.
pub fn Buffer::len(self : Buffer) -> Int {
  self.infos.length()
}

///|
/// Return true when empty.
pub fn Buffer::is_empty(self : Buffer) -> Bool {
  self.infos.is_empty()
}

///|
/// Append a codepoint with cluster.
pub fn Buffer::add_codepoint(
  self : Buffer,
  codepoint : UInt,
  cluster? : Int = -1,
) -> Unit {
  let actual_cluster = if cluster < 0 { self.infos.length() } else { cluster }
  self.infos.push(GlyphInfo::{ codepoint, cluster: actual_cluster })
  self.positions.push(GlyphPosition::{
    x_advance: 0,
    y_advance: 0,
    x_offset: 0,
    y_offset: 0,
  })
}

///|
/// Append a character with cluster.
pub fn Buffer::add_char(self : Buffer, ch : Char, cluster? : Int = -1) -> Unit {
  self.add_codepoint(ch.to_uint(), cluster~)
}

///|
/// Append all characters from a string.
pub fn Buffer::add_string(self : Buffer, text : String) -> Unit {
  let mut cluster = 0
  for ch in text {
    self.add_char(ch, cluster~)
    cluster = cluster + 1
  }
}

///|
/// Access glyph infos.
pub fn Buffer::infos(self : Buffer) -> ArrayView[GlyphInfo] {
  self.infos[:]
}

///|
/// Access glyph positions.
pub fn Buffer::positions(self : Buffer) -> ArrayView[GlyphPosition] {
  self.positions[:]
}

///|
/// Replace glyph infos and positions. Returns false if lengths mismatch.
pub fn Buffer::replace_glyphs(
  self : Buffer,
  infos : Array[GlyphInfo],
  positions? : Array[GlyphPosition] = [],
) -> Bool {
  let mut next_positions = positions
  if next_positions.is_empty() {
    let filled : Array[GlyphPosition] = []
    for _ in 0..<infos.length() {
      filled.push(GlyphPosition::{ x_advance: 0, y_advance: 0, x_offset: 0, y_offset: 0 })
    }
    next_positions = filled
  }
  if infos.length() != next_positions.length() {
    return false
  }
  self.infos = infos
  self.positions = next_positions
  true
}

///|
/// Merge clusters in the range [start, end).
pub fn Buffer::merge_clusters(self : Buffer, start : Int, end : Int) -> Unit {
  if start < 0 || end > self.infos.length() || start >= end {
    return ()
  }
  let mut min_cluster = self.infos[start].cluster
  for i in (start + 1)..<end {
    let value = self.infos[i].cluster
    if value < min_cluster {
      min_cluster = value
    }
  }
  for i in start..<end {
    let info = self.infos[i]
    self.infos[i] = GlyphInfo::{ codepoint: info.codepoint, cluster: min_cluster }
  }
}

///|
/// Set direction.
pub fn Buffer::set_direction(
  self : Buffer,
  direction : @common.Direction,
) -> Unit {
  self.direction = direction
}

///|
/// Get direction.
pub fn Buffer::get_direction(self : Buffer) -> @common.Direction {
  self.direction
}

///|
/// Set script.
pub fn Buffer::set_script(self : Buffer, script : @common.Script) -> Unit {
  self.script = script
}

///|
/// Get script.
pub fn Buffer::get_script(self : Buffer) -> @common.Script {
  self.script
}

///|
/// Set language.
pub fn Buffer::set_language(self : Buffer, language : @common.Language) -> Unit {
  self.language = language
}

///|
pub fn Buffer::set_gsub_features(
  self : Buffer,
  features : Array[@common.Tag],
) -> Unit {
  self.gsub_features = features
}

///|
pub fn Buffer::set_gpos_features(
  self : Buffer,
  features : Array[@common.Tag],
) -> Unit {
  self.gpos_features = features
}

///|
pub fn Buffer::gsub_features(self : Buffer) -> ArrayView[@common.Tag] {
  self.gsub_features[:]
}

///|
pub fn Buffer::gpos_features(self : Buffer) -> ArrayView[@common.Tag] {
  self.gpos_features[:]
}

///|
fn default_gsub_features() -> Array[@common.Tag] {
  [@common.Tag::from_chars('l', 'i', 'g', 'a')]
}

///|
fn default_gpos_features() -> Array[@common.Tag] {
  [@common.Tag::from_chars('k', 'e', 'r', 'n')]
}

///|
/// Get language.
pub fn Buffer::get_language(self : Buffer) -> @common.Language {
  self.language
}

///|
/// Fill missing segment properties with defaults.
pub fn Buffer::guess_segment_properties(self : Buffer) -> Unit {
  if self.script == @common.script_invalid {
    let first_codepoint = match self.infos {
      [] => None
      [first, ..] => Some(first.codepoint)
    }
    match first_codepoint {
      None => self.script = @common.script_common
      Some(value) => self.script = @unicode.script(value)
    }
  }
  if !self.direction.is_valid() {
    let dir = self.script.horizontal_direction()
    self.direction = if dir.is_valid() { dir } else { @common.direction_ltr }
  }
  if !self.language.is_valid() {
    self.language = @common.Language::from_string("und")
  }
}

///|
/// Normalize buffer codepoints by reordering combining marks.
pub fn Buffer::normalize(self : Buffer) -> Unit {
  let mut len = self.infos.length()
  if len <= 1 {
    return ()
  }
  let is_hebrew = self.script == @common.script_hebrew
  let is_arabic = self.script == @common.script_arabic
  let is_hangul = self.script == @common.script_hangul
  let mut start = 0
  while start < len {
    let mut end = start + 1
    while end < len {
      let cc = @unicode.combining_class(self.infos[end].codepoint)
      if cc == 0U {
        break
      }
      end = end + 1
    }
    let mark_start = start + 1
    if end - mark_start > 1 {
      let mut i = mark_start + 1
      while i < end {
        let current = self.infos[i]
        let current_cc = @unicode.modified_combining_class(current.codepoint).reinterpret_as_int()
        let current_pos = self.positions[i]
        let mut j = i
        while j > mark_start {
          let prev = self.infos[j - 1]
          let prev_cc = @unicode.modified_combining_class(prev.codepoint).reinterpret_as_int()
          if prev_cc <= current_cc {
            break
          }
          self.infos[j] = prev
          self.positions[j] = self.positions[j - 1]
          j = j - 1
        }
        self.infos[j] = current
        self.positions[j] = current_pos
        i = i + 1
      }
    }
    if end > mark_start {
      if is_hebrew {
        reorder_marks_hebrew(self, mark_start, end)
      }
      if is_arabic {
        reorder_marks_arabic(self, mark_start, end)
      }
    }
    let mut i = start + 1
    while i < end {
      let base = self.infos[start].codepoint
      let mark = self.infos[i].codepoint
      let composed = match compose_for_script(self.script, base, mark) {
        None => if is_hebrew { compose_hebrew(base, mark) } else { None }
        Some(value) => Some(value)
      }
      match composed {
        None => i = i + 1
        Some(composed) => {
          self.merge_clusters(start, i + 1)
          let base = self.infos[start]
          self.infos[start] = GlyphInfo::{ codepoint: composed, cluster: base.cluster }
          ignore(self.infos.remove(i))
          ignore(self.positions.remove(i))
          len = len - 1
          end = end - 1
        }
      }
    }
    start = end
  }
  if is_hangul {
    normalize_hangul(self)
  }
}

///|
fn reorder_marks_arabic(buffer : Buffer, start : Int, end : Int) -> Unit {
  let mut i = start
  let mut cc = 220
  while cc <= 230 {
    while i < end {
      let value = @unicode.modified_combining_class(buffer.infos[i].codepoint).reinterpret_as_int()
      if value >= cc {
        break
      }
      i = i + 1
    }
    if i >= end {
      break
    }
    let current_cc = @unicode.modified_combining_class(buffer.infos[i].codepoint).reinterpret_as_int()
    if current_cc > cc {
      cc = cc + 10
      continue
    }
    let mut j = i
    while j < end {
      let value = @unicode.modified_combining_class(buffer.infos[j].codepoint).reinterpret_as_int()
      if value != cc || !is_modifier_combining_mark(buffer.infos[j].codepoint) {
        break
      }
      j = j + 1
    }
    if i == j {
      cc = cc + 10
      continue
    }
    buffer.merge_clusters(start, j)
    let moved_len = j - i
    let shift_len = i - start
    let moved_infos : Array[GlyphInfo] = []
    let moved_positions : Array[GlyphPosition] = []
    for k in i..<j {
      moved_infos.push(buffer.infos[k])
      moved_positions.push(buffer.positions[k])
    }
    let shift_infos : Array[GlyphInfo] = []
    let shift_positions : Array[GlyphPosition] = []
    for k in start..<i {
      shift_infos.push(buffer.infos[k])
      shift_positions.push(buffer.positions[k])
    }
    for idx in 0..<moved_len {
      buffer.infos[start + idx] = moved_infos[idx]
      buffer.positions[start + idx] = moved_positions[idx]
    }
    for idx in 0..<shift_len {
      buffer.infos[start + moved_len + idx] = shift_infos[idx]
      buffer.positions[start + moved_len + idx] = shift_positions[idx]
    }
    i = j
    cc = cc + 10
  }
}

///|
fn normalize_hangul(buffer : Buffer) -> Unit {
  let mut i = 0
  let mut len = buffer.infos.length()
  while i + 1 < len {
    let a = buffer.infos[i].codepoint
    let b = buffer.infos[i + 1].codepoint
    let composed = if is_hangul_l(a) && is_hangul_v(b) {
      @unicode.compose(a, b)
    } else if is_hangul_lv(a) && is_hangul_t(b) {
      @unicode.compose(a, b)
    } else {
      None
    }
    match composed {
      None => i = i + 1
      Some(value) => {
        buffer.merge_clusters(i, i + 2)
        let base = buffer.infos[i]
        buffer.infos[i] = GlyphInfo::{ codepoint: value, cluster: base.cluster }
        ignore(buffer.infos.remove(i + 1))
        ignore(buffer.positions.remove(i + 1))
        len = len - 1
        if i + 1 < len {
          let next = buffer.infos[i + 1].codepoint
          if is_hangul_t(next) && is_hangul_lv(value) {
            match @unicode.compose(value, next) {
              None => ()
              Some(composed) => {
                buffer.merge_clusters(i, i + 2)
                let base = buffer.infos[i]
                buffer.infos[i] = GlyphInfo::{ codepoint: composed, cluster: base.cluster }
                ignore(buffer.infos.remove(i + 1))
                ignore(buffer.positions.remove(i + 1))
                len = len - 1
              }
            }
          }
        }
        i = i + 1
      }
    }
  }
  reorder_hangul_tone_marks(buffer)
}

///|
fn reorder_hangul_tone_marks(buffer : Buffer) -> Unit {
  let mut i = 1
  while i < buffer.infos.length() {
    let current = buffer.infos[i].codepoint
    if is_hangul_tone(current) &&
      is_hangul_syllable(buffer.infos[i - 1].codepoint) {
      buffer.merge_clusters(i - 1, i + 1)
      let info = buffer.infos[i]
      let pos = buffer.positions[i]
      buffer.infos[i] = buffer.infos[i - 1]
      buffer.positions[i] = buffer.positions[i - 1]
      buffer.infos[i - 1] = info
      buffer.positions[i - 1] = pos
      if i > 1 {
        i = i - 1
      } else {
        i = i + 1
      }
    } else {
      i = i + 1
    }
  }
}

///|
fn is_hangul_l(u : UInt) -> Bool {
  u >= 0x1100U && u <= 0x1112U
}

///|
fn is_hangul_v(u : UInt) -> Bool {
  u >= 0x1161U && u <= 0x1175U
}

///|
fn is_hangul_t(u : UInt) -> Bool {
  u >= 0x11A8U && u <= 0x11C2U
}

///|
fn is_hangul_lv(u : UInt) -> Bool {
  u >= 0xAC00U && u <= 0xD7A3U
}

///|
fn is_hangul_tone(u : UInt) -> Bool {
  u == 0x302EU || u == 0x302FU
}

///|
fn is_hangul_syllable(u : UInt) -> Bool {
  is_hangul_lv(u) || is_hangul_l(u) || is_hangul_v(u) || is_hangul_t(u)
}

///|
fn is_modifier_combining_mark(u : UInt) -> Bool {
  let marks : Array[UInt] = [
    0x0654U, 0x0655U, 0x0658U, 0x06DCU, 0x06E3U, 0x06E7U, 0x06E8U,
    0x08CAU, 0x08CBU, 0x08CDU, 0x08CEU, 0x08CFU, 0x08D3U, 0x08F3U,
  ]
  for mark in marks {
    if mark == u {
      return true
    }
  }
  false
}

///|
fn compose_hebrew(a : UInt, b : UInt) -> UInt? {
  let dagesh_forms : Array[UInt] = [
    0xFB30U, 0xFB31U, 0xFB32U, 0xFB33U, 0xFB34U, 0xFB35U, 0xFB36U, 0U,
    0xFB38U, 0xFB39U, 0xFB3AU, 0xFB3BU, 0xFB3CU, 0U, 0xFB3EU, 0U,
    0xFB40U, 0xFB41U, 0U, 0xFB43U, 0xFB44U, 0U, 0xFB46U, 0xFB47U,
    0xFB48U, 0xFB49U, 0xFB4AU,
  ]
  match b {
    0x05B4U => if a == 0x05D9U { Some(0xFB1DU) } else { None }
    0x05B7U =>
      if a == 0x05F2U {
        Some(0xFB1FU)
      } else if a == 0x05D0U {
        Some(0xFB2EU)
      } else {
        None
      }
    0x05B8U => if a == 0x05D0U { Some(0xFB2FU) } else { None }
    0x05B9U => if a == 0x05D5U { Some(0xFB4BU) } else { None }
    0x05BCU => if a >= 0x05D0U && a <= 0x05EAU {
        let form = dagesh_forms[(a - 0x05D0U).reinterpret_as_int()]
        if form == 0U { None } else { Some(form) }
      } else if a == 0xFB2AU {
        Some(0xFB2CU)
      } else if a == 0xFB2BU {
        Some(0xFB2DU)
      } else {
        None
      }
    0x05BFU => if a == 0x05D1U {
        Some(0xFB4CU)
      } else if a == 0x05DBU {
        Some(0xFB4DU)
      } else if a == 0x05E4U {
        Some(0xFB4EU)
      } else {
        None
      }
    0x05C1U => if a == 0x05E9U {
        Some(0xFB2AU)
      } else if a == 0xFB49U {
        Some(0xFB2CU)
      } else {
        None
      }
    0x05C2U => if a == 0x05E9U {
        Some(0xFB2BU)
      } else if a == 0xFB49U {
        Some(0xFB2DU)
      } else {
        None
      }
    _ => None
  }
}

///|
fn reorder_marks_hebrew(buffer : Buffer, start : Int, end : Int) -> Unit {
  if end - start < 3 {
    return ()
  }
  for i in (start + 2)..<end {
    let c0 = @unicode.modified_combining_class(buffer.infos[i - 2].codepoint).reinterpret_as_int()
    let c1 = @unicode.modified_combining_class(buffer.infos[i - 1].codepoint).reinterpret_as_int()
    let c2 = @unicode.modified_combining_class(buffer.infos[i].codepoint).reinterpret_as_int()
    if (c0 == 20 || c0 == 21) &&
      (c1 == 22 || c1 == 23) &&
      (c2 == 25 || c2 == 220) {
      buffer.merge_clusters(i - 1, i + 1)
      let tmp = buffer.infos[i - 1]
      buffer.infos[i - 1] = buffer.infos[i]
      buffer.infos[i] = tmp
      let tmp_pos = buffer.positions[i - 1]
      buffer.positions[i - 1] = buffer.positions[i]
      buffer.positions[i] = tmp_pos
      break
    }
  }
}

///|
fn language_to_ot_tag(lang : @common.Language) -> @common.Tag {
  match lang.to_string() {
    None => @common.tag_none
    Some(value) => {
      let bytes : Array[Byte] = []
      for c in value {
        if c == '-' || c == '_' {
          break
        }
        if c.is_ascii_alphabetic() {
          bytes.push(c.to_ascii_uppercase().to_uint().to_byte())
        } else if c.is_ascii_digit() {
          bytes.push(c.to_uint().to_byte())
        } else {
          break
        }
        if bytes.length() == 4 {
          break
        }
      }
      if bytes.is_empty() {
        @common.tag_none
      } else {
        for _ in bytes.length()..<4 {
          bytes.push(b' ')
        }
        @common.Tag::from_bytes(bytes[0], bytes[1], bytes[2], bytes[3])
      }
    }
  }
}

///|
/// Populate glyph IDs and advances using cmap + hmtx.
pub fn Buffer::shape_basic(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let new_infos : Array[GlyphInfo] = []
  let new_positions : Array[GlyphPosition] = []
  for info in self.infos {
    let glyph = match font.glyph_for_codepoint(info.codepoint) {
      Err(err) => return Err(Font(err))
      Ok(None) => 0U
      Ok(Some(value)) => value
    }
    let pos = match default_position(self, font, glyph) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    new_infos.push(GlyphInfo::{ codepoint: glyph, cluster: info.cluster })
    new_positions.push(pos)
  }
  self.infos = new_infos
  self.positions = new_positions
  Ok(())
}

///|
/// Shape with GSUB single substitution and GPOS pair adjustment.
pub fn Buffer::shape_ot(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  self.guess_segment_properties()
  let unicode_mark_flags = mark_flags_from_infos(self.infos)
  let combining_classes : Array[Int] = []
  for info in self.infos {
    let klass = @unicode.modified_combining_class(info.codepoint).reinterpret_as_int()
    combining_classes.push(recategorize_combining_class(info.codepoint, klass))
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let gpos = match font.gpos() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let script_tag = self.script.to_tag()
  let lang_tag = language_to_ot_tag(self.language)
  let map = match @ot_map.OtMap::new(
    gsub,
    gpos,
    script_tag,
    language_tag=lang_tag,
    gsub_features=self.gsub_features,
    gpos_features=self.gpos_features,
  ) {
    Err(err) => return Err(Layout(err))
    Ok(value) => value
  }
  if gsub is Some(gsub) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let glyphs : Array[UInt] = []
    let clusters : Array[Int] = []
    for info in self.infos {
      glyphs.push(info.codepoint)
      clusters.push(info.cluster)
    }
    let result = match gdef {
      None =>
        match gsub.apply_with_lookups(
          glyphs,
          clusters,
          map.gsub_lookups(),
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gsub.apply_with_lookups(
          glyphs,
          clusters,
          map.gsub_lookups(),
          gdef=gdef,
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
    }
    let (next_glyphs, next_clusters, changed) = result
    if changed || next_glyphs.length() != self.infos.length() {
      let new_infos : Array[GlyphInfo] = []
      let new_positions : Array[GlyphPosition] = []
      for i in 0..<next_glyphs.length() {
        let glyph = next_glyphs[i]
        let cluster = next_clusters[i]
        let pos = match default_position(self, font, glyph) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        new_infos.push(GlyphInfo::{ codepoint: glyph, cluster })
        new_positions.push(pos)
      }
      self.infos = new_infos
      self.positions = new_positions
    }
  }
  if gpos is Some(gpos) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let glyphs : Array[UInt] = []
    for info in self.infos {
      glyphs.push(info.codepoint)
    }
    let deltas = match gdef {
      None =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          map.gpos_lookups(),
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          map.gpos_lookups(),
          gdef=gdef,
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
    }
    let new_positions : Array[GlyphPosition] = []
    for i in 0..<self.positions.length() {
      let pos = self.positions[i]
      let delta = deltas[i]
      new_positions.push(GlyphPosition::{
        x_advance: pos.x_advance + delta.x_advance,
        y_advance: pos.y_advance + delta.y_advance,
        x_offset: pos.x_offset + delta.x_placement,
        y_offset: pos.y_offset + delta.y_placement,
      })
    }
    self.positions = new_positions
  } else if self.direction.is_horizontal() {
    let kern = match font.kern() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    if kern is Some(kern) {
      let new_positions : Array[GlyphPosition] = []
      for pos in self.positions {
        new_positions.push(pos)
      }
      if new_positions.length() >= 2 {
        for i in 0..<(new_positions.length() - 1) {
          let left = self.infos[i].codepoint
          let right = self.infos[i + 1].codepoint
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
      self.positions = new_positions
    }
  }
  let adjust_offsets = gpos is None && self.direction.is_forward()
  let gdef_for_marks = match font.gdef() {
    Err(_) => None
    Ok(value) => value
  }
  let mut used_flags : Array[Bool] = []
  let mut zero_marks = false
  match gdef_for_marks {
    None => ()
    Some(gdef) => {
      if gdef.header().glyph_class_def_offset is Some(_) {
        match mark_flags_from_gdef(gdef, self.infos) {
          Err(err) => return Err(err)
          Ok(value) => {
            used_flags = value
            zero_marks = true
          }
        }
      }
    }
  }
  if !zero_marks && gpos is None && unicode_mark_flags.length() == self.infos.length() {
    used_flags = unicode_mark_flags
    zero_marks = true
  }
  if zero_marks {
    zero_mark_advances_with_flags(self, used_flags, adjust_offsets=adjust_offsets)
  }
  if gpos is None {
    match fallback_mark_position(font, self, unicode_mark_flags, combining_classes) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  Ok(())
}

///|
fn default_position(
  buffer : Buffer,
  font : @font.Font,
  glyph : UInt,
) -> Result[GlyphPosition, ShapeError] {
  if buffer.direction.is_vertical() {
    let advance = match font.glyph_v_advance(glyph) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    Ok(GlyphPosition::{
      x_advance: 0,
      y_advance: advance,
      x_offset: 0,
      y_offset: 0,
    })
  } else {
    let advance = match font.glyph_h_advance(glyph) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    Ok(GlyphPosition::{
      x_advance: advance,
      y_advance: 0,
      x_offset: 0,
      y_offset: 0,
    })
  }
}
