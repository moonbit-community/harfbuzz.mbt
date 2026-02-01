///|
/// COLRv0 layer record.
pub struct ColrLayer {
  glyph_id : Int
  color_index : Int
} derive(Eq, Show, ToJson)

///|
/// COLRv0 base glyph record.
pub struct ColrBaseGlyph {
  glyph_id : Int
  first_layer_index : Int
  num_layers : Int
} derive(Eq, Show, ToJson)

///|
/// COLRv1 base glyph -> paint record.
pub struct BaseGlyphPaintRecord {
  glyph_id : Int
  paint_offset : Int
} derive(Eq, Show, ToJson)

///|
/// Clip box data (format 1 or 2).
pub struct ClipBox {
  format : Int
  x_min : Int
  y_min : Int
  x_max : Int
  y_max : Int
  var_idx_base : @paint.VarIdx?
} derive(Eq, Show, ToJson)

///|
/// Clip record for a glyph range.
pub struct ClipRecord {
  start_glyph_id : Int
  end_glyph_id : Int
  clip_box : ClipBox
} derive(Eq, Show, ToJson)

///|
/// Clip list (format 1) for COLRv1.
pub struct ClipList {
  format : Int
  records : Array[ClipRecord]
} derive(Eq, Show, ToJson)
