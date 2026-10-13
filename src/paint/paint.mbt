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
  ColrLayers(Int32, Int32)
  Solid(Int32, Int32, VarIdx?)
  LinearGradient(ColorLine, Int32, Int32, Int32, Int32, Int32, Int32, VarIdx?)
  RadialGradient(ColorLine, Int32, Int32, Int32, Int32, Int32, Int32, VarIdx?)
  SweepGradient(ColorLine, Int32, Int32, Int32, Int32, VarIdx?)
  Glyph(Int32, Paint)
  ColrGlyph(Int32)
  Transform(Affine2x3, Paint)
  Translate(Int32, Int32, VarIdx?, Paint)
  Scale(Int32, Int32, VarIdx?, Paint)
  ScaleAroundCenter(Int32, Int32, Int32, Int32, VarIdx?, Paint)
  ScaleUniform(Int32, VarIdx?, Paint)
  ScaleUniformAroundCenter(Int32, Int32, Int32, VarIdx?, Paint)
  Rotate(Int32, VarIdx?, Paint)
  RotateAroundCenter(Int32, Int32, Int32, VarIdx?, Paint)
  Skew(Int32, Int32, VarIdx?, Paint)
  SkewAroundCenter(Int32, Int32, Int32, Int32, VarIdx?, Paint)
  Composite(Int32, Paint, Paint)
} derive(Debug, ToJson)

///|
pub extend Paint with @debug.Debug::{to_repr}

///|
pub extend Paint with ToJson::{to_json}
