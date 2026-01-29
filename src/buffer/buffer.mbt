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
    script: @common.script_unknown,
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
    let advance = match font.glyph_h_advance(glyph) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    new_infos.push(GlyphInfo::{ codepoint: glyph, cluster: info.cluster })
    new_positions.push(GlyphPosition::{
      x_advance: advance,
      y_advance: 0,
      x_offset: 0,
      y_offset: 0,
    })
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
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if gsub is Some(gsub) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let script_tag = self.script.to_tag()
    let lang_tag = language_to_ot_tag(self.language)
    let lookup_offsets = match gsub.layout().select_lookup_offsets_with_features(
      script_tag,
      language_tag=lang_tag,
      feature_tags=self.gsub_features,
    ) {
      Err(err) => return Err(Layout(err))
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
          lookup_offsets[:],
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gsub.apply_with_lookups(
          glyphs,
          clusters,
          lookup_offsets[:],
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
        let advance = match font.glyph_h_advance(glyph) {
          Err(err) => return Err(Font(err))
          Ok(value) => value
        }
        new_infos.push(GlyphInfo::{ codepoint: glyph, cluster })
        new_positions.push(GlyphPosition::{
          x_advance: advance,
          y_advance: 0,
          x_offset: 0,
          y_offset: 0,
        })
      }
      self.infos = new_infos
      self.positions = new_positions
    }
  }
  let gpos = match font.gpos() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if gpos is Some(gpos) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let script_tag = self.script.to_tag()
    let lang_tag = language_to_ot_tag(self.language)
    let lookup_offsets = match gpos.layout().select_lookup_offsets_with_features(
      script_tag,
      language_tag=lang_tag,
      feature_tags=self.gpos_features,
    ) {
      Err(err) => return Err(Layout(err))
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
  Ok(())
}
