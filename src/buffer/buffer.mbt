///|
/// Glyph info entry.
pub struct GlyphInfo {
  codepoint : UInt
  cluster : Int
  unicode : UInt
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
pub suberror ShapeError {
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
  mut gsub_features_default : Bool
  mut gpos_features_default : Bool
  mut preserve_default_ignorables : Bool
  mut remove_default_ignorables : Bool
  mut not_found_variation_selector : UInt?
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
    gsub_features: default_feature_tags(@common.direction_ltr),
    gpos_features: default_feature_tags(@common.direction_ltr),
    gsub_features_default: true,
    gpos_features_default: true,
    preserve_default_ignorables: false,
    remove_default_ignorables: false,
    not_found_variation_selector: None,
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
  self.infos.push(GlyphInfo::{ codepoint, cluster: actual_cluster, unicode: codepoint })
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
/// Add tracking adjustment to advances.
pub fn Buffer::add_tracking(
  self : Buffer,
  adjustment : Int,
  horizontal : Bool,
) -> Unit {
  if adjustment == 0 {
    return ()
  }
  if horizontal {
    for i in 0..<self.positions.length() {
      let pos = self.positions[i]
      self.positions[i] = GlyphPosition::{
        x_advance: pos.x_advance + adjustment,
        y_advance: pos.y_advance,
        x_offset: pos.x_offset,
        y_offset: pos.y_offset,
      }
    }
  } else {
    for i in 0..<self.positions.length() {
      let pos = self.positions[i]
      self.positions[i] = GlyphPosition::{
        x_advance: pos.x_advance,
        y_advance: pos.y_advance + adjustment,
        x_offset: pos.x_offset,
        y_offset: pos.y_offset,
      }
    }
  }
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
    self.infos[i] = GlyphInfo::{ codepoint: info.codepoint, cluster: min_cluster, unicode: info.unicode }
  }
}

///|
/// Merge clusters for base + combining-mark sequences.
pub fn Buffer::merge_combining_mark_clusters(self : Buffer) -> Unit {
  let len = self.infos.length()
  if len <= 1 {
    return ()
  }
  let mut start = 0
  while start < len {
    let mut end = start + 1
    while end < len {
      let klass = @unicode.combining_class(self.infos[end].unicode)
      if klass == 0U {
        break
      }
      end = end + 1
    }
    if end - start > 1 {
      self.merge_clusters(start, end)
    }
    start = end
  }
}

///|
/// Set direction.
pub fn Buffer::set_direction(
  self : Buffer,
  direction : @common.Direction,
) -> Unit {
  self.direction = direction
  update_default_features(self)
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
  self.gsub_features_default = false
}

///|
pub fn Buffer::set_gpos_features(
  self : Buffer,
  features : Array[@common.Tag],
) -> Unit {
  self.gpos_features = features
  self.gpos_features_default = false
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
/// Preserve default-ignorable codepoints (do not hide/zero).
pub fn Buffer::set_preserve_default_ignorables(self : Buffer, preserve : Bool) -> Unit {
  self.preserve_default_ignorables = preserve
}

///|
/// Remove default-ignorable glyphs instead of zeroing advances.
pub fn Buffer::set_remove_default_ignorables(self : Buffer, remove : Bool) -> Unit {
  self.remove_default_ignorables = remove
}

///|
/// Set the fallback glyph for not-found variation selectors.
pub fn Buffer::set_not_found_variation_selector(self : Buffer, glyph : UInt?) -> Unit {
  self.not_found_variation_selector = glyph
}

///|
/// Get the fallback glyph for not-found variation selectors.
pub fn Buffer::get_not_found_variation_selector(self : Buffer) -> UInt? {
  self.not_found_variation_selector
}

///|
fn default_feature_tags(direction : @common.Direction) -> Array[@common.Tag] {
  let tags : Array[@common.Tag] = []
  let dir = if direction.is_valid() { direction } else { @common.direction_ltr }
  tags.push(@common.Tag::from_chars('r', 'v', 'r', 'n'))
  if dir == @common.direction_ltr {
    tags.push(@common.Tag::from_chars('l', 't', 'r', 'a'))
    tags.push(@common.Tag::from_chars('l', 't', 'r', 'm'))
  } else if dir == @common.direction_rtl {
    tags.push(@common.Tag::from_chars('r', 't', 'l', 'a'))
    tags.push(@common.Tag::from_chars('r', 't', 'l', 'm'))
  }
  tags.push(@common.Tag::from_chars('f', 'r', 'a', 'c'))
  tags.push(@common.Tag::from_chars('n', 'u', 'm', 'r'))
  tags.push(@common.Tag::from_chars('d', 'n', 'o', 'm'))
  tags.push(@common.Tag::from_chars('r', 'a', 'n', 'd'))
  tags.push(@common.Tag::from_chars('H', 'a', 'r', 'f'))
  tags.push(@common.Tag::from_chars('H', 'A', 'R', 'F'))
  tags.push(@common.Tag::from_chars('B', 'u', 'z', 'z'))
  tags.push(@common.Tag::from_chars('B', 'U', 'Z', 'Z'))
  tags.push(@common.Tag::from_chars('c', 'c', 'm', 'p'))
  tags.push(@common.Tag::from_chars('l', 'o', 'c', 'l'))
  tags.push(@common.Tag::from_chars('m', 'a', 'r', 'k'))
  tags.push(@common.Tag::from_chars('m', 'k', 'm', 'k'))
  tags.push(@common.Tag::from_chars('r', 'l', 'i', 'g'))
  if dir.is_horizontal() {
    tags.push(@common.Tag::from_chars('c', 'a', 'l', 't'))
    tags.push(@common.Tag::from_chars('c', 'l', 'i', 'g'))
    tags.push(@common.Tag::from_chars('c', 'u', 'r', 's'))
    tags.push(@common.Tag::from_chars('d', 'i', 's', 't'))
    tags.push(@common.Tag::from_chars('k', 'e', 'r', 'n'))
    tags.push(@common.Tag::from_chars('l', 'i', 'g', 'a'))
    tags.push(@common.Tag::from_chars('r', 'c', 'l', 't'))
  } else {
    tags.push(@common.Tag::from_chars('v', 'e', 'r', 't'))
  }
  tags
}

fn tag_in_list(tags : Array[@common.Tag], tag : @common.Tag) -> Bool {
  for entry in tags {
    if entry == tag {
      return true
    }
  }
  false
}

fn update_default_features(buffer : Buffer) -> Unit {
  if buffer.gsub_features_default {
    buffer.gsub_features = default_feature_tags(buffer.direction)
  }
  if buffer.gpos_features_default {
    buffer.gpos_features = default_feature_tags(buffer.direction)
  }
}

fn fallback_glyph_for_codepoint(
  font : @font.Font,
  codepoint : UInt,
) -> Result[(UInt?, @unicode.SpaceFallbackType?), ShapeError] {
  if codepoint == 0x2011U {
    return match font.glyph_for_codepoint(0x2010U) {
      Err(err) => Err(Font(err))
      Ok(value) => Ok((value, None))
    }
  }
  let space_type = @unicode.space_fallback_type(codepoint)
  match space_type {
    @unicode.SpaceFallbackType::NotSpace => ()
    _ =>
      return match font.glyph_for_codepoint(0x0020U) {
        Err(err) => Err(Font(err))
        Ok(None) => Ok((None, None))
        Ok(Some(value)) => Ok((Some(value), Some(space_type)))
      }
  }
  Ok((None, None))
}

fn space_fallback_divisor(space_type : @unicode.SpaceFallbackType) -> Int? {
  match space_type {
    @unicode.SpaceFallbackType::SpaceEm => Some(1)
    @unicode.SpaceFallbackType::SpaceEm2 => Some(2)
    @unicode.SpaceFallbackType::SpaceEm3 => Some(3)
    @unicode.SpaceFallbackType::SpaceEm4 => Some(4)
    @unicode.SpaceFallbackType::SpaceEm5 => Some(5)
    @unicode.SpaceFallbackType::SpaceEm6 => Some(6)
    @unicode.SpaceFallbackType::SpaceEm16 => Some(16)
    _ => None
  }
}

fn advance_for_codepoint(
  font : @font.Font,
  codepoint : UInt,
  horizontal : Bool,
) -> Result[Int?, ShapeError] {
  match font.glyph_for_codepoint(codepoint) {
    Err(err) => Err(Font(err))
    Ok(None) => Ok(None)
    Ok(Some(glyph)) =>
      if horizontal {
        match font.glyph_h_advance(glyph) {
          Ok(value) => Ok(Some(value))
          Err(err) => {
            let glyph_count = font.get_face().get_glyph_count()
            if glyph_count > 0 && glyph.reinterpret_as_int() >= glyph_count {
              Ok(Some(0))
            } else {
              Err(Font(err))
            }
          }
        }
      } else {
        match font.glyph_v_advance(glyph) {
          Ok(value) => Ok(Some(value))
          Err(err) => {
            let glyph_count = font.get_face().get_glyph_count()
            if glyph_count > 0 && glyph.reinterpret_as_int() >= glyph_count {
              Ok(Some(0))
            } else {
              Err(Font(err))
            }
          }
        }
      }
  }
}

fn adjust_space_fallback_position(
  font : @font.Font,
  direction : @common.Direction,
  space_type : @unicode.SpaceFallbackType,
  pos : GlyphPosition,
) -> Result[GlyphPosition, ShapeError] {
  let horizontal = !direction.is_vertical()
  match space_type {
    @unicode.SpaceFallbackType::NotSpace => Ok(pos)
    @unicode.SpaceFallbackType::Space => Ok(pos)
    @unicode.SpaceFallbackType::SpaceNarrow => {
      if horizontal {
        Ok(GlyphPosition::{
          x_advance: pos.x_advance / 2,
          y_advance: pos.y_advance,
          x_offset: pos.x_offset,
          y_offset: pos.y_offset,
        })
      } else {
        Ok(GlyphPosition::{
          x_advance: pos.x_advance,
          y_advance: pos.y_advance / 2,
          x_offset: pos.x_offset,
          y_offset: pos.y_offset,
        })
      }
    }
    @unicode.SpaceFallbackType::Space4Em18 => {
      let (scale_x, scale_y) = font.get_scale()
      let scale = if horizontal { scale_x } else { scale_y }
      let advance = scale * 4 / 18
      if horizontal {
        Ok(GlyphPosition::{
          x_advance: advance,
          y_advance: pos.y_advance,
          x_offset: pos.x_offset,
          y_offset: pos.y_offset,
        })
      } else {
        Ok(GlyphPosition::{
          x_advance: pos.x_advance,
          y_advance: -advance,
          x_offset: pos.x_offset,
          y_offset: pos.y_offset,
        })
      }
    }
    @unicode.SpaceFallbackType::SpaceFigure => {
      let mut value : Int? = None
      let mut digit = 0x30
      while digit <= 0x39 {
        match advance_for_codepoint(font, digit.reinterpret_as_uint(), horizontal) {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(advance)) => {
            value = Some(advance)
            break
          }
        }
        digit = digit + 1
      }
      match value {
        None => Ok(pos)
        Some(advance) =>
          if horizontal {
            Ok(GlyphPosition::{
              x_advance: advance,
              y_advance: pos.y_advance,
              x_offset: pos.x_offset,
              y_offset: pos.y_offset,
            })
          } else {
            Ok(GlyphPosition::{
              x_advance: pos.x_advance,
              y_advance: advance,
              x_offset: pos.x_offset,
              y_offset: pos.y_offset,
            })
          }
      }
    }
    @unicode.SpaceFallbackType::SpacePunctuation => {
      let mut value = match advance_for_codepoint(font, 0x2EU, horizontal) {
        Err(err) => return Err(err)
        Ok(advance) => advance
      }
      if value is None {
        value = match advance_for_codepoint(font, 0x2CU, horizontal) {
          Err(err) => return Err(err)
          Ok(advance) => advance
        }
      }
      match value {
        None => Ok(pos)
        Some(advance) =>
          if horizontal {
            Ok(GlyphPosition::{
              x_advance: advance,
              y_advance: pos.y_advance,
              x_offset: pos.x_offset,
              y_offset: pos.y_offset,
            })
          } else {
            Ok(GlyphPosition::{
              x_advance: pos.x_advance,
              y_advance: advance,
              x_offset: pos.x_offset,
              y_offset: pos.y_offset,
            })
          }
      }
    }
    _ =>
      match space_fallback_divisor(space_type) {
        None => Ok(pos)
        Some(divisor) => {
          let (scale_x, scale_y) = font.get_scale()
          let scale = if horizontal { scale_x } else { scale_y }
          let base = (scale + divisor / 2) / divisor
          if horizontal {
            Ok(GlyphPosition::{
              x_advance: base,
              y_advance: pos.y_advance,
              x_offset: pos.x_offset,
              y_offset: pos.y_offset,
            })
          } else {
            Ok(GlyphPosition::{
              x_advance: pos.x_advance,
              y_advance: -base,
              x_offset: pos.x_offset,
              y_offset: pos.y_offset,
            })
          }
        }
      }
  }
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
  update_default_features(self)
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
  let mut has_vs = false
  for info in self.infos {
    if @unicode.is_variation_selector(info.codepoint) {
      has_vs = true
      break
    }
  }
  let vs_clusters : Map[Int, Bool] = {}
  if has_vs {
    merge_variation_selector_clusters(self)
    for info in self.infos {
      if @unicode.is_variation_selector(info.codepoint) {
        vs_clusters[info.cluster] = true
      }
    }
  }
  let is_hebrew = self.script == @common.script_hebrew
  let is_arabic = self.script == @common.script_arabic
  let is_hangul = self.script == @common.script_hangul
  let mut start = 0
  while start < len {
    let mut end = start + 1
    let mut cluster_has_vs = @unicode.is_variation_selector(self.infos[start].codepoint)
    while end < len {
      let codepoint = self.infos[end].codepoint
      if @unicode.is_variation_selector(codepoint) {
        cluster_has_vs = true
        end = end + 1
        continue
      }
      let cc = @unicode.combining_class(codepoint)
      if cc == 0U {
        break
      }
      end = end + 1
    }
    if cluster_has_vs {
      start = end
      continue
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
          self.infos[start] = GlyphInfo::{ codepoint: composed, cluster: base.cluster, unicode: composed }
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
    normalize_hangul(self, vs_clusters)
  }
}

///|
fn merge_variation_selector_clusters(buffer : Buffer) -> Unit {
  let mut last_non_vs = -1
  for i in 0..<buffer.infos.length() {
    let codepoint = buffer.infos[i].codepoint
    if @unicode.is_variation_selector(codepoint) {
      if last_non_vs >= 0 {
        buffer.merge_clusters(last_non_vs, i + 1)
      }
    } else {
      last_non_vs = i
    }
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
fn normalize_hangul(buffer : Buffer, vs_clusters : Map[Int, Bool]) -> Unit {
  let mut i = 0
  let mut len = buffer.infos.length()
  while i + 1 < len {
    if vs_clusters.contains(buffer.infos[i].cluster) ||
      vs_clusters.contains(buffer.infos[i + 1].cluster) {
      i = i + 1
      continue
    }
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
        buffer.infos[i] = GlyphInfo::{ codepoint: value, cluster: base.cluster, unicode: value }
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
                buffer.infos[i] = GlyphInfo::{ codepoint: composed, cluster: base.cluster, unicode: composed }
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
  let mut i = 0
  while i < self.infos.length() {
    let info = self.infos[i]
    let mut skip_next = false
    let mut use_variation_glyph = None
    if i + 1 < self.infos.length() {
      let next = self.infos[i + 1]
      if @unicode.is_variation_selector(next.codepoint) {
        let mapping = match font.variation_glyph_for(info.codepoint, next.codepoint) {
          Err(err) => return Err(Font(err))
          Ok(value) => value
        }
        let (supported, glyph) = mapping
        if supported {
          skip_next = true
          use_variation_glyph = glyph
        }
      }
    }
    let mut space_type : @unicode.SpaceFallbackType? = None
    let glyph = match use_variation_glyph {
      Some(value) => value
      None =>
        match font.glyph_for_codepoint(info.codepoint) {
          Err(err) => return Err(Font(err))
          Ok(Some(value)) => value
          Ok(None) =>
            match fallback_glyph_for_codepoint(font, info.codepoint) {
              Err(err) => return Err(err)
              Ok((None, _)) => 0U
              Ok((Some(value), fallback_space_type)) => {
                space_type = fallback_space_type
                value
              }
            }
        }
    }
    let mut pos = match default_position(self, font, glyph) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    match space_type {
      None => ()
      Some(space_type) =>
        pos = match adjust_space_fallback_position(font, self.direction, space_type, pos) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
    }
    new_infos.push(GlyphInfo::{ codepoint: glyph, cluster: info.cluster, unicode: info.unicode })
    new_positions.push(pos)
    if skip_next {
      i = i + 2
    } else {
      i = i + 1
    }
  }
  self.infos = new_infos
  self.positions = new_positions
  Ok(())
}

///|
/// Apply AAT trak tracking adjustments if present.
pub fn Buffer::apply_trak(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let trak = match font.trak() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  match trak {
    None => Ok(())
    Some(trak) => {
      if !trak.has_data() {
        return Ok(())
      }
      let horizontal = self.direction.is_horizontal()
      let (ppem_x, ppem_y) = font.get_ppem()
      let ptem = if horizontal {
        if ppem_x > 0 { ppem_x.to_double() } else { 12.0 }
      } else {
        if ppem_y > 0 { ppem_y.to_double() } else { 12.0 }
      }
      let tracking = trak.tracking(ptem, horizontal)
      let (scale_x, scale_y) = font.get_scale()
      let scale = if horizontal { scale_x } else { scale_y }
      let upem = font.get_face().get_upem()
      let adjustment = if upem == 0 {
        tracking.round().to_int()
      } else {
        (tracking * scale.to_double() / upem.to_double()).round().to_int()
      }
      self.add_tracking(adjustment, horizontal)
      Ok(())
    }
  }
}

///|
/// Apply AAT morx/mort substitutions and rearrangements if present.
pub fn Buffer::apply_morx(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let morx = match font.morx() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let use_morx = match morx {
    Some(morx) => morx.has_data()
    None => false
  }
  let mort = if use_morx {
    None
  } else {
    match font.mort() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
  }
  let use_mort = match mort {
    Some(mort) => mort.has_data()
    None => false
  }
  if !use_morx && !use_mort {
    return Ok(())
  }
  let horizontal = self.direction.is_horizontal()
  let cluster_unicode : Map[Int, UInt] = {}
  for info in self.infos {
    if !cluster_unicode.contains(info.cluster) {
      cluster_unicode[info.cluster] = info.unicode
    }
  }
  let glyphs : Array[UInt] = []
  let clusters : Array[Int] = []
  for info in self.infos {
    glyphs.push(info.codepoint)
    clusters.push(info.cluster)
  }
  let changed = if use_morx {
    let morx = match morx {
      Some(morx) => morx
      None => return Ok(())
    }
    morx.apply(glyphs, clusters, horizontal)
  } else {
    let mort = match mort {
      Some(mort) => mort
      None => return Ok(())
    }
    mort.apply(glyphs, clusters, horizontal)
  }
  if !changed {
    return Ok(())
  }
  let new_infos : Array[GlyphInfo] = []
  let new_positions : Array[GlyphPosition] = []
  for i in 0..<glyphs.length() {
    let glyph = glyphs[i]
    let cluster = clusters[i]
    let pos = match default_position(self, font, glyph) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let unicode = match cluster_unicode.get(cluster) {
      None => 0U
      Some(value) => value
    }
    new_infos.push(GlyphInfo::{ codepoint: glyph, cluster, unicode })
    new_positions.push(pos)
  }
  self.infos = new_infos
  self.positions = new_positions
  Ok(())
}

///|
/// Apply AAT kerx kerning adjustments if present.
pub fn Buffer::apply_kerx(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let kerx = match font.kerx() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let kerx = match kerx {
    None => return Ok(())
    Some(kerx) => kerx
  }
  if !kerx.has_data() {
    return Ok(())
  }
  if self.infos.length() < 2 {
    return Ok(())
  }
  let horizontal = self.direction.is_horizontal()
  let (scale_x, scale_y) = font.get_scale()
  let upem = font.get_face().get_upem()
  let ankr = match font.ankr() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let glyphs : Array[UInt] = []
  let clusters : Array[Int] = []
  for info in self.infos {
    glyphs.push(info.codepoint)
    clusters.push(info.cluster)
  }
  let contour_point = (glyph, point_index) => {
    match font.glyph_contour_point_for_origin(glyph, point_index) {
      Err(_) => None
      Ok(value) => value
    }
  }
  let adjustments = kerx.apply_scaled(
    glyphs,
    horizontal,
    scale_x,
    scale_y,
    upem,
    ankr,
    contour_point=contour_point,
  )
  if adjustments.length() != self.positions.length() {
    return Ok(())
  }
  let positions : Array[GlyphPosition] = []
  for i in 0..<self.positions.length() {
    let pos = self.positions[i]
    let adj = adjustments[i]
    if adj.x_advance == 0 &&
      adj.y_advance == 0 &&
      adj.x_offset == 0 &&
      adj.y_offset == 0 {
      positions.push(pos)
    } else {
      positions.push(
        GlyphPosition::{
          x_advance: pos.x_advance + adj.x_advance,
          y_advance: pos.y_advance + adj.y_advance,
          x_offset: pos.x_offset + adj.x_offset,
          y_offset: pos.y_offset + adj.y_offset,
        },
      )
    }
  }
  self.positions = positions
  Ok(())
}

///|
/// Return true if kerx data is present.
pub fn Buffer::has_kerx(self : Buffer, font : @font.Font) -> Result[Bool, ShapeError] {
  ignore(self)
  let kerx = match font.kerx() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  Ok(
    match kerx {
      None => false
      Some(value) => value.has_data()
    },
  )
}

///|
/// Apply GPOS positioning to the current glyph sequence. Returns true when GPOS was present.
pub fn Buffer::apply_gpos(
  self : Buffer,
  font : @font.Font,
  include_all_features? : Bool = false,
) -> Result[Bool, ShapeError] {
  let gpos = match font.gpos() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let gpos = match gpos {
    None => return Ok(false)
    Some(value) => value
  }
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
  let script_tag = self.script.to_tag()
  let lang_tag = language_to_ot_tag(self.language)
  let feature_tags : Array[@common.Tag] =
    if include_all_features {
      [
        @common.Tag::from_chars('a', 'b', 'v', 'm'),
        @common.Tag::from_chars('b', 'l', 'w', 'm'),
        @common.Tag::from_chars('c', 'c', 'm', 'p'),
        @common.Tag::from_chars('l', 'o', 'c', 'l'),
        @common.Tag::from_chars('m', 'a', 'r', 'k'),
        @common.Tag::from_chars('m', 'k', 'm', 'k'),
        @common.Tag::from_chars('r', 'l', 'i', 'g'),
        @common.Tag::from_chars('c', 'a', 'l', 't'),
        @common.Tag::from_chars('c', 'l', 'i', 'g'),
        @common.Tag::from_chars('c', 'u', 'r', 's'),
        @common.Tag::from_chars('d', 'i', 's', 't'),
        @common.Tag::from_chars('k', 'e', 'r', 'n'),
        @common.Tag::from_chars('l', 'i', 'g', 'a'),
        @common.Tag::from_chars('r', 'c', 'l', 't'),
      ]
    } else {
      self.gpos_features
    }
  let lookup_offsets = match gpos.layout().select_lookup_offsets_with_features(
    script_tag,
    language_tag=lang_tag,
    feature_tags=feature_tags,
  ) {
    Err(err) => return Err(Layout(err))
    Ok(value) => value
  }
  let advances_x : Array[Int] = []
  let advances_y : Array[Int] = []
  for pos in self.positions {
    advances_x.push(pos.x_advance)
    advances_y.push(pos.y_advance)
  }
  let deltas = match gdef {
    None =>
      match gpos.position_deltas_with_lookups(
        glyphs[:],
        lookup_offsets[:],
        clusters=clusters[:],
        advances_x=advances_x[:],
        advances_y=advances_y[:],
      ) {
        Err(err) => return Err(Layout(err))
        Ok(value) => value
      }
    Some(gdef) =>
      match gpos.position_deltas_with_lookups(
        glyphs[:],
        lookup_offsets[:],
        gdef=gdef,
        clusters=clusters[:],
        advances_x=advances_x[:],
        advances_y=advances_y[:],
      ) {
        Err(err) => return Err(Layout(err))
        Ok(value) => value
      }
  }
  if deltas.length() != self.positions.length() {
    return Ok(true)
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
  let unicode_mark_flags : Array[Bool] = []
  for info in self.infos {
    unicode_mark_flags.push(is_zero_width_mark(info.unicode))
  }
  match zero_marks_by_gdef_or_unicode(font, self, unicode_mark_flags, true) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if include_all_features && unicode_mark_flags.length() == self.positions.length() {
    let mut advance_since_base = 0
    let mut has_base = false
    for i in 0..<self.positions.length() {
      if !unicode_mark_flags[i] {
        has_base = true
        advance_since_base = self.positions[i].x_advance
      } else if has_base {
        let pos = self.positions[i]
        self.positions[i] = GlyphPosition::{
          x_advance: pos.x_advance,
          y_advance: pos.y_advance,
          x_offset: pos.x_offset - advance_since_base,
          y_offset: pos.y_offset,
        }
        advance_since_base = advance_since_base + pos.x_advance
      }
    }
  }
  Ok(true)
}

///|
/// Shape with GSUB single substitution and GPOS pair adjustment.
pub fn Buffer::shape_ot(
  self : Buffer,
  font : @font.Font,
  fallback_position? : Bool = true,
) -> Result[Unit, ShapeError] {
  self.shape_ot_with_options(
    font,
    fallback_position=fallback_position,
    zero_width_marks=ZeroWidthMarks::ByGdefLate,
  )
}

///|
fn Buffer::shape_ot_with_options(
  self : Buffer,
  font : @font.Font,
  fallback_position? : Bool = true,
  zero_width_marks? : ZeroWidthMarks = ZeroWidthMarks::ByGdefLate,
) -> Result[Unit, ShapeError] {
  self.guess_segment_properties()
  let (unicode_mark_flags, combining_classes) = collect_mark_fallback_data(self.infos)
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
  let gpos_lookups = map.gpos_lookups()
  let gpos_present = gpos is Some(_) && !gpos_lookups.is_empty()
  let kern_tag =
    if self.direction.is_horizontal() {
      @common.Tag::from_chars('k', 'e', 'r', 'n')
    } else {
      @common.Tag::from_chars('v', 'k', 'r', 'n')
    }
  let wants_kern = tag_in_list(self.gpos_features, kern_tag)
  let mut has_gpos_kern = false
  if wants_kern && gpos is Some(gpos) {
    let kern_lookups = match gpos.layout().select_lookup_offsets_for_feature(
      script_tag,
      kern_tag,
      language_tag=lang_tag,
      include_required=false,
    ) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
    has_gpos_kern = !kern_lookups.is_empty()
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
      let same_len = next_glyphs.length() == self.infos.length()
      let new_infos : Array[GlyphInfo] = []
      let new_positions : Array[GlyphPosition] = []
      for i in 0..<next_glyphs.length() {
        let glyph = next_glyphs[i]
        let cluster = next_clusters[i]
        let pos = match default_position(self, font, glyph) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let unicode = if same_len { self.infos[i].unicode } else { 0U }
        new_infos.push(GlyphInfo::{ codepoint: glyph, cluster, unicode })
        new_positions.push(pos)
      }
      self.infos = new_infos
      self.positions = new_positions
    }
  }
  match zero_width_marks {
    ZeroWidthMarks::ByGdefEarly =>
      match zero_marks_by_gdef_or_unicode(font, self, unicode_mark_flags, gpos_present) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
    _ => ()
  }
  if gpos_present && gpos is Some(gpos) {
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
    let advances_x : Array[Int] = []
    let advances_y : Array[Int] = []
    for pos in self.positions {
      advances_x.push(pos.x_advance)
      advances_y.push(pos.y_advance)
    }
    let deltas = match gdef {
      None =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          gpos_lookups,
          clusters=clusters[:],
          advances_x=advances_x[:],
          advances_y=advances_y[:],
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          gpos_lookups,
          gdef=gdef,
          clusters=clusters[:],
          advances_x=advances_x[:],
          advances_y=advances_y[:],
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
  }
  if self.direction.is_horizontal() && wants_kern && !has_gpos_kern {
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
  match zero_width_marks {
    ZeroWidthMarks::ByGdefLate =>
      match zero_marks_by_gdef_or_unicode(font, self, unicode_mark_flags, gpos_present) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
    _ => ()
  }
  if fallback_position && !gpos_present {
    match fallback_mark_position(font, self, unicode_mark_flags, combining_classes) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  finalize_default_ignorables_and_variation_selectors(self)
  Ok(())
}

///|
fn is_effective_default_ignorable(buffer : Buffer, info : GlyphInfo) -> Bool {
  if !@unicode.is_default_ignorable(info.unicode) {
    return false
  }
  match buffer.not_found_variation_selector {
    None => true
    Some(_) => !@unicode.is_variation_selector(info.unicode)
  }
}

///|
fn apply_default_ignorables(buffer : Buffer) -> Unit {
  if buffer.preserve_default_ignorables {
    return ()
  }
  if buffer.remove_default_ignorables {
    let new_infos : Array[GlyphInfo] = []
    let new_positions : Array[GlyphPosition] = []
    for i in 0..<buffer.infos.length() {
      if is_effective_default_ignorable(buffer, buffer.infos[i]) {
        continue
      }
      new_infos.push(buffer.infos[i])
      new_positions.push(buffer.positions[i])
    }
    buffer.infos = new_infos
    buffer.positions = new_positions
    return ()
  }
  for i in 0..<buffer.infos.length() {
    if !is_effective_default_ignorable(buffer, buffer.infos[i]) {
      continue
    }
    let pos = buffer.positions[i]
    let next_pos =
      if buffer.direction.is_vertical() {
        GlyphPosition::{
          x_advance: 0,
          y_advance: 0,
          x_offset: pos.x_offset,
          y_offset: 0,
        }
      } else {
        GlyphPosition::{
          x_advance: 0,
          y_advance: 0,
          x_offset: 0,
          y_offset: pos.y_offset,
        }
      }
    buffer.positions[i] = next_pos
  }
}

///|
fn apply_variation_selector_fallback(buffer : Buffer) -> Unit {
  match buffer.not_found_variation_selector {
    None => ()
    Some(glyph) => {
      for i in 0..<buffer.infos.length() {
        let info = buffer.infos[i]
        if @unicode.is_variation_selector(info.unicode) {
          buffer.infos[i] = GlyphInfo::{ codepoint: glyph, cluster: info.cluster, unicode: info.unicode }
          buffer.positions[i] = GlyphPosition::{
            x_advance: 0,
            y_advance: 0,
            x_offset: 0,
            y_offset: 0,
          }
        }
      }
    }
  }
}

///|
fn finalize_default_ignorables_and_variation_selectors(buffer : Buffer) -> Unit {
  apply_default_ignorables(buffer)
  apply_variation_selector_fallback(buffer)
}

///|
fn default_position(
  buffer : Buffer,
  font : @font.Font,
  glyph : UInt,
) -> Result[GlyphPosition, ShapeError] {
  if buffer.direction.is_vertical() {
    let advance = match font.glyph_v_advance(glyph) {
      Ok(value) => value
      Err(err) => {
        let glyph_count = font.get_face().get_glyph_count()
        if glyph_count > 0 && glyph.reinterpret_as_int() >= glyph_count {
          0
        } else {
          return Err(Font(err))
        }
      }
    }
    Ok(GlyphPosition::{
      x_advance: 0,
      y_advance: advance,
      x_offset: 0,
      y_offset: 0,
    })
  } else {
    let advance = match font.glyph_h_advance(glyph) {
      Ok(value) => value
      Err(err) => {
        let glyph_count = font.get_face().get_glyph_count()
        if glyph_count > 0 && glyph.reinterpret_as_int() >= glyph_count {
          0
        } else {
          return Err(Font(err))
        }
      }
    }
    Ok(GlyphPosition::{
      x_advance: advance,
      y_advance: 0,
      x_offset: 0,
      y_offset: 0,
    })
  }
}
