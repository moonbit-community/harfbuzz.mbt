///|
/// Shape a buffer with OT GSUB/GPOS lookups.
pub fn shape(font : @font.Font, buffer : @buffer.Buffer) -> Result[Unit, @buffer.ShapeError] {
  buffer.guess_segment_properties()
  buffer.normalize()
  let script = buffer.get_script()
  if script == @common.script_arabic || script == @common.script_mongolian {
    return buffer.shape_arabic(font)
  }
  if script == @common.script_thai || script == @common.script_lao {
    return buffer.shape_thai(font)
  }
  if script == @common.script_khmer {
    return buffer.shape_khmer(font)
  }
  if script == @common.script_myanmar {
    return buffer.shape_myanmar(font)
  }
  if is_indic_script(script) {
    return buffer.shape_indic(font)
  }
  if is_use_script(script) {
    return buffer.shape_use(font)
  }
  if script == @common.script_hangul {
    return buffer.shape_hangul(font)
  }
  buffer.shape_ot(font)
}

///|
fn is_indic_script(script : @common.Script) -> Bool {
  script == @common.script_devanagari ||
    script == @common.script_bengali ||
    script == @common.script_gurmukhi ||
    script == @common.script_gujarati ||
    script == @common.script_oriya ||
    script == @common.script_tamil ||
    script == @common.script_telugu ||
    script == @common.script_kannada ||
    script == @common.script_malayalam
}

///|
fn is_use_script(script : @common.Script) -> Bool {
  script == @common.script_sinhala ||
    script == @common.script_tibetan
}

///|
/// Fallback shaping using cmap + advances only.
pub fn shape_basic(font : @font.Font, buffer : @buffer.Buffer) -> Result[Unit, @buffer.ShapeError] {
  buffer.shape_basic(font)
}
