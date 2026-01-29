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
    self.script = @common.script_common
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
  let len = self.infos.length()
  if len <= 1 {
    return ()
  }
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
        let mut j = i
        while j > mark_start {
          let prev = self.infos[j - 1]
          let prev_cc = @unicode.modified_combining_class(prev.codepoint).reinterpret_as_int()
          if prev_cc <= current_cc {
            break
          }
          self.infos[j] = prev
          j = j - 1
        }
        self.infos[j] = current
        i = i + 1
      }
    }
    start = end
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
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let gpos = match font.gpos() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
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
