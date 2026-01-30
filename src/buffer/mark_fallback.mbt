fn is_zero_width_mark(u : UInt) -> Bool {
  let cat = @unicode.general_category(u)
  cat == @unicode.gc_non_spacing_mark || cat == @unicode.gc_enclosing_mark
}

fn mark_flags_from_infos(infos : Array[GlyphInfo]) -> Array[Bool] {
  let flags : Array[Bool] = []
  for info in infos {
    flags.push(is_zero_width_mark(info.codepoint))
  }
  flags
}

fn mark_flags_from_gdef(
  gdef : @ot_tables.GdefTable,
  infos : Array[GlyphInfo],
) -> Result[Array[Bool], ShapeError] {
  let flags : Array[Bool] = []
  for info in infos {
    let glyph_class = match gdef.glyph_class(info.codepoint) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
    flags.push(glyph_class == 3)
  }
  Ok(flags)
}

fn zero_mark_advances_with_flags(
  buffer : Buffer,
  marks : Array[Bool],
  adjust_offsets? : Bool = false,
) -> Unit {
  if buffer.infos.length() != buffer.positions.length() ||
    buffer.infos.length() != marks.length() {
    return ()
  }
  for i in 0..<buffer.infos.length() {
    if marks[i] {
      let pos = buffer.positions[i]
      let x_offset = if adjust_offsets { pos.x_offset - pos.x_advance } else { pos.x_offset }
      let y_offset = if adjust_offsets { pos.y_offset - pos.y_advance } else { pos.y_offset }
      buffer.positions[i] = GlyphPosition::{
        x_advance: 0,
        y_advance: 0,
        x_offset,
        y_offset,
      }
    }
  }
}
