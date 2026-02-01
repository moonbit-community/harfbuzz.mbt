///|
/// COLRv1 paint graph nodes.
pub(all) enum Paint {
  ColrLayers(Int, Int)
  Solid(Int, Int, VarIdx?)
  LinearGradient(
    ColorLine,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    VarIdx?,
  )
  RadialGradient(
    ColorLine,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    VarIdx?,
  )
  SweepGradient(
    ColorLine,
    Int,
    Int,
    Int,
    Int,
    VarIdx?,
  )
  Glyph(Int, Paint)
  ColrGlyph(Int)
  Transform(Affine2x3, Paint)
  Translate(Int, Int, VarIdx?, Paint)
  Scale(Int, Int, VarIdx?, Paint)
  ScaleAroundCenter(
    Int,
    Int,
    Int,
    Int,
    VarIdx?,
    Paint,
  )
  ScaleUniform(Int, VarIdx?, Paint)
  ScaleUniformAroundCenter(
    Int,
    Int,
    Int,
    VarIdx?,
    Paint,
  )
  Rotate(Int, VarIdx?, Paint)
  RotateAroundCenter(
    Int,
    Int,
    Int,
    VarIdx?,
    Paint,
  )
  Skew(Int, Int, VarIdx?, Paint)
  SkewAroundCenter(
    Int,
    Int,
    Int,
    Int,
    VarIdx?,
    Paint,
  )
  Composite(Int, Paint, Paint)
} derive(Show, ToJson)
