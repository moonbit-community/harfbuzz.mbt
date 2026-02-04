///|
/// Shape a buffer using AAT tables (morx, kerx, trak).
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
  match buffer.apply_morx(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  buffer.merge_combining_mark_clusters()
  let has_kerx = match buffer.has_kerx(font) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if has_kerx {
    match buffer.apply_kerx(font) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  } else {
    match buffer.apply_gpos(
      font,
      include_all_features=true,
      adjust_mark_offsets=false,
    ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  buffer.apply_trak(font)
}
