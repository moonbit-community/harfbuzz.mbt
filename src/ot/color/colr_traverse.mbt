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

let max_paint_walk_depth : Int = 64

///|
/// Visitor callback for COLRv1 paint traversal.
pub type PaintVisitor = (@paint.Paint, Int) -> Bool

///|
/// Walk a COLRv1 paint graph, visiting each node and returning count.
pub fn ColrTable::walk_paint(
  self : ColrTable,
  paint : @paint.Paint,
  visit : PaintVisitor,
  max_depth? : Int = max_paint_walk_depth,
) -> Result[Int, ColorError] {
  walk_paint_impl(self, paint, visit, 0, max_depth)
}

fn walk_paint_impl(
  colr : ColrTable,
  paint : @paint.Paint,
  visit : PaintVisitor,
  depth : Int,
  max_depth : Int,
) -> Result[Int, ColorError] {
  if depth > max_depth {
    return Err(InvalidFormat)
  }
  let should_recurse = visit(paint, depth)
  let mut count = 1
  if !should_recurse {
    return Ok(count)
  }
  match paint {
    @paint.Paint::ColrLayers(first_layer_index, num_layers) => {
      if num_layers < 0 {
        return Err(InvalidFormat)
      }
      for i in 0..<num_layers {
        let layer_index = first_layer_index + i
        let layer = colr.layer_paint(layer_index)
        match layer {
          Err(err) => return Err(err)
          Ok(None) => ()
          Ok(Some(child)) => {
            let child_count = walk_paint_impl(colr, child, visit, depth + 1, max_depth)
            match child_count {
              Err(err) => return Err(err)
              Ok(value) => count = count + value
            }
          }
        }
      }
    }
    @paint.Paint::Glyph(_, child) => {
      let child_count = walk_paint_impl(colr, child, visit, depth + 1, max_depth)
      match child_count {
        Err(err) => return Err(err)
        Ok(value) => count = count + value
      }
    }
    @paint.Paint::ColrGlyph(glyph_id) => {
      let glyph_paint = colr.paint_for_glyph(glyph_id)
      match glyph_paint {
        Err(err) => return Err(err)
        Ok(None) => ()
        Ok(Some(child)) => {
          let child_count = walk_paint_impl(colr, child, visit, depth + 1, max_depth)
          match child_count {
            Err(err) => return Err(err)
            Ok(value) => count = count + value
          }
        }
      }
    }
    @paint.Paint::Transform(_, child)
    | @paint.Paint::Translate(_, _, _, child)
    | @paint.Paint::Scale(_, _, _, child)
    | @paint.Paint::ScaleAroundCenter(_, _, _, _, _, child)
    | @paint.Paint::ScaleUniform(_, _, child)
    | @paint.Paint::ScaleUniformAroundCenter(_, _, _, _, child)
    | @paint.Paint::Rotate(_, _, child)
    | @paint.Paint::RotateAroundCenter(_, _, _, _, child)
    | @paint.Paint::Skew(_, _, _, child)
    | @paint.Paint::SkewAroundCenter(_, _, _, _, _, child) => {
      let child_count = walk_paint_impl(colr, child, visit, depth + 1, max_depth)
      match child_count {
        Err(err) => return Err(err)
        Ok(value) => count = count + value
      }
    }
    @paint.Paint::Composite(_, src, backdrop) => {
      let src_count = walk_paint_impl(colr, src, visit, depth + 1, max_depth)
      match src_count {
        Err(err) => return Err(err)
        Ok(value) => count = count + value
      }
      let backdrop_count = walk_paint_impl(colr, backdrop, visit, depth + 1, max_depth)
      match backdrop_count {
        Err(err) => return Err(err)
        Ok(value) => count = count + value
      }
    }
    _ => ()
  }
  Ok(count)
}
