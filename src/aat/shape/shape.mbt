///|
/// Shape a buffer using AAT tables (currently trak only).
pub fn shape(
  font : @font.Font,
  buffer : @buffer.Buffer,
) -> Result[Unit, @buffer.ShapeError] {
  buffer.guess_segment_properties()
  buffer.normalize()
  match buffer.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  buffer.apply_trak(font)
}
