///|
/// Shape a buffer with OT GSUB/GPOS lookups.
pub fn shape(font : @font.Font, buffer : @buffer.Buffer) -> Result[Unit, @buffer.ShapeError] {
  buffer.guess_segment_properties()
  buffer.normalize()
  buffer.shape_ot(font)
}

///|
/// Fallback shaping using cmap + advances only.
pub fn shape_basic(font : @font.Font, buffer : @buffer.Buffer) -> Result[Unit, @buffer.ShapeError] {
  buffer.shape_basic(font)
}
