///|
let dotted_circle_codepoint : UInt = 0x25CCU

fn insert_dotted_circle_for_syllables(
  font : @font.Font,
  buffer : Buffer,
  syllables : Array[Int],
  broken_type : Int,
) -> Result[Bool, ShapeError] {
  if buffer.infos.length() != syllables.length() || buffer.infos.is_empty() {
    return Ok(false)
  }
  let has_dotted_circle = match font.glyph_for_codepoint(dotted_circle_codepoint) {
    Err(err) => return Err(Font(err))
    Ok(None) => false
    Ok(Some(_)) => true
  }
  if !has_dotted_circle {
    return Ok(false)
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let mut inserted = false
  let mut last_syllable = -1
  for i in 0..<buffer.infos.length() {
    let syllable = syllables[i]
    if syllable != last_syllable && (syllable & 0x0f) == broken_type {
      inserted = true
      let info = buffer.infos[i]
      next_infos.push(GlyphInfo::{ codepoint: dotted_circle_codepoint, cluster: info.cluster })
      next_positions.push(GlyphPosition::{ x_advance: 0, y_advance: 0, x_offset: 0, y_offset: 0 })
    }
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    last_syllable = syllable
  }
  if inserted {
    buffer.infos = next_infos
    buffer.positions = next_positions
  }
  Ok(inserted)
}
