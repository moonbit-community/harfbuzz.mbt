///|
/// VarIdx points into an ItemVariationStore (outer:high 16 bits, inner:low 16 bits).
pub type VarIdx = UInt

///|
/// Special value indicating no variation.
pub let var_idx_none : VarIdx = 0xFFFFFFFFU

///|
/// RGBA color (0..255 per channel).
pub struct Color {
  r : Int
  g : Int
  b : Int
  a : Int
} derive(Eq, Show, ToJson)

///|
/// Helper to build a color from BGRA bytes.
pub fn Color::from_bgra(b : Int, g : Int, r : Int, a : Int) -> Color {
  Color::{ r, g, b, a }
}

///|
/// Color stop for gradients. Offset/alpha are raw F2DOT14 values.
pub(all) struct ColorStop {
  offset : Int
  palette_index : Int
  alpha : Int
  var_idx_base : VarIdx?
} derive(Eq, Show, ToJson)

///|
/// Color line for gradients. Extend is raw enum value (0..2).
pub(all) struct ColorLine {
  extend : Int
  stops : Array[ColorStop]
} derive(Eq, Show, ToJson)

///|
/// Affine transform (F16DOT16 values), with optional VarIdx base for variation.
pub(all) struct Affine2x3 {
  xx : Int
  yx : Int
  xy : Int
  yy : Int
  dx : Int
  dy : Int
  var_idx_base : VarIdx?
} derive(Eq, Show, ToJson)
