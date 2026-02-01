///|
/// Glyph bounding box from glyf header.
pub struct GlyphBounds {
  contours : Int
  x_min : Int
  y_min : Int
  x_max : Int
  y_max : Int
} derive(Eq, Show, ToJson)

///|
pub fn GlyphBounds::new(
  contours : Int,
  x_min : Int,
  y_min : Int,
  x_max : Int,
  y_max : Int,
) -> GlyphBounds {
  GlyphBounds::{ contours, x_min, y_min, x_max, y_max }
}

///|
/// Parsed glyf table (raw view).
pub struct GlyfTable {
  data : BytesView
} derive(Show, ToJson)

///|
/// Parse glyf table from its blob.
pub fn GlyfTable::parse(blob : @blob.Blob) -> Result[GlyfTable, SfntError] {
  Ok(GlyfTable::{ data: blob.as_view() })
}

///|
/// Read glyph bounds at a given offset/length.
pub fn GlyfTable::glyph_bounds(
  self : GlyfTable,
  offset : Int,
  length : Int,
) -> Result[GlyphBounds?, SfntError] {
  if offset < 0 || length < 0 {
    return Err(InvalidFormat)
  }
  let data_len = self.data.length()
  if offset > data_len {
    return Err(UnexpectedEof)
  }
  if length == 0 {
    return Ok(None)
  }
  if length < 10 || offset + length > data_len || offset + 10 > data_len {
    return Err(UnexpectedEof)
  }
  let contours = read_i16(self.data, offset)
  let x_min = read_i16(self.data, offset + 2)
  let y_min = read_i16(self.data, offset + 4)
  let x_max = read_i16(self.data, offset + 6)
  let y_max = read_i16(self.data, offset + 8)
  match (contours, x_min, y_min, x_max, y_max) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (Ok(contours), Ok(x_min), Ok(y_min), Ok(x_max), Ok(y_max)) =>
      Ok(Some(GlyphBounds::{ contours, x_min, y_min, x_max, y_max }))
  }
}
