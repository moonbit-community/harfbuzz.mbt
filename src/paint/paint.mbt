// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
