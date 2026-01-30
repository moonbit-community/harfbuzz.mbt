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

fn zero_mark_advances_with_flags(buffer : Buffer, marks : Array[Bool]) -> Unit {
  if buffer.infos.length() != buffer.positions.length() ||
    buffer.infos.length() != marks.length() {
    return ()
  }
  for i in 0..<buffer.infos.length() {
    if marks[i] {
      let pos = buffer.positions[i]
      buffer.positions[i] = GlyphPosition::{
        x_advance: 0,
        y_advance: 0,
        x_offset: pos.x_offset,
        y_offset: pos.y_offset,
      }
    }
  }
}
