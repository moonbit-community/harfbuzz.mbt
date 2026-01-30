///|
let dotted_circle_codepoint : UInt = 0x25CCU

///|
fn is_syllabic_joiner(u : UInt) -> Bool {
  u == 0x200CU || u == 0x200DU
}

///|
fn is_syllabic_base(u : UInt) -> Bool {
  let cat = @unicode.general_category(u)
  cat == @unicode.gc_lowercase_letter ||
    cat == @unicode.gc_uppercase_letter ||
    cat == @unicode.gc_titlecase_letter ||
    cat == @unicode.gc_modifier_letter ||
    cat == @unicode.gc_other_letter ||
    cat == @unicode.gc_decimal_number ||
    cat == @unicode.gc_letter_number ||
    cat == @unicode.gc_other_number
}

///|
fn insert_dotted_circle_for_broken_syllables(buffer : Buffer) -> Bool {
  if buffer.infos.is_empty() {
    return false
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let mut seen_base = false
  let mut inserted = false
  for i in 0..<buffer.infos.length() {
    let info = buffer.infos[i]
    let pos = buffer.positions[i]
    let codepoint = info.codepoint
    if is_syllabic_joiner(codepoint) {
      next_infos.push(info)
      next_positions.push(pos)
      continue
    }
    if @unicode.is_mark(codepoint) {
      if !seen_base {
        inserted = true
        next_infos.push(GlyphInfo::{ codepoint: dotted_circle_codepoint, cluster: info.cluster })
        next_positions.push(GlyphPosition::{ x_advance: 0, y_advance: 0, x_offset: 0, y_offset: 0 })
        seen_base = true
      }
      next_infos.push(info)
      next_positions.push(pos)
      continue
    }
    if is_syllabic_base(codepoint) {
      seen_base = true
    } else {
      seen_base = false
    }
    next_infos.push(info)
    next_positions.push(pos)
  }
  if inserted {
    buffer.infos = next_infos
    buffer.positions = next_positions
  }
  inserted
}

///|
fn insert_dotted_circle_if_supported(
  font : @font.Font,
  buffer : Buffer,
) -> Result[Bool, ShapeError] {
  let has_dotted_circle = match font.glyph_for_codepoint(dotted_circle_codepoint) {
    Err(err) => return Err(Font(err))
    Ok(None) => false
    Ok(Some(_)) => true
  }
  if !has_dotted_circle {
    return Ok(false)
  }
  Ok(insert_dotted_circle_for_broken_syllables(buffer))
}
