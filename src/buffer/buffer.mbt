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
/// Text buffer for shaping.
pub struct Buffer {
  mut infos : Array[GlyphInfo]
  mut positions : Array[GlyphPosition]
  mut direction : @common.Direction
  mut script : @common.Script
  mut language : @common.Language
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
/// Get language.
pub fn Buffer::get_language(self : Buffer) -> @common.Language {
  self.language
}
