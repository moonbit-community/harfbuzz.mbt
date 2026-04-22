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
let flag_on_curve : Int = 0x01

///|
let flag_cubic : Int = 0x80

///|
priv struct DrawPoint {
  x : Double
  y : Double
}

///|
fn mid_point(a : DrawPoint, b : DrawPoint) -> DrawPoint {
  DrawPoint::{ x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5 }
}

///|
fn scale_coord(value : Double, scale : Int, upem : Int) -> Double {
  if upem == 0 {
    return value
  }
  value * scale.to_double() / upem.to_double()
}

///|
fn scale_point(
  p : @sfnt.GlyphPoint,
  scale_x : Int,
  scale_y : Int,
  upem : Int,
) -> DrawPoint {
  DrawPoint::{
    x: scale_coord(p.x, scale_x, upem),
    y: scale_coord(p.y, scale_y, upem),
  }
}

///|
fn[T] draw_contour(
  points : Array[@sfnt.GlyphPoint],
  start : Int,
  end : Int,
  session : @draw.DrawSession[T],
  scale_x : Int,
  scale_y : Int,
  upem : Int,
) -> Unit {
  if start > end {
    return
  }
  let mut first_oncurve : DrawPoint? = None
  let mut first_offcurve : DrawPoint? = None
  let mut first_offcurve2 : DrawPoint? = None
  let mut last_offcurve : DrawPoint? = None
  let mut last_offcurve2 : DrawPoint? = None
  for idx in start..<=end {
    let point = points[idx]
    let on_curve = (point.flag & flag_on_curve) != 0
    let is_cubic = !on_curve && (point.flag & flag_cubic) != 0
    let p = scale_point(point, scale_x, scale_y, upem)
    if first_oncurve is None {
      if on_curve {
        first_oncurve = Some(p)
        session.move_to(p.x, p.y)
      } else if is_cubic && first_offcurve2 is None {
        first_offcurve2 = first_offcurve
        first_offcurve = Some(p)
      } else {
        match first_offcurve {
          Some(ofc) => {
            let mid = mid_point(ofc, p)
            first_oncurve = Some(mid)
            last_offcurve = Some(p)
            session.move_to(mid.x, mid.y)
          }
          None => first_offcurve = Some(p)
        }
      }
    } else {
      match last_offcurve {
        Some(lof) =>
          if on_curve {
            match last_offcurve2 {
              Some(lof2) => {
                session.cubic_to(lof2.x, lof2.y, lof.x, lof.y, p.x, p.y)
                last_offcurve2 = None
              }
              None => session.quadratic_to(lof.x, lof.y, p.x, p.y)
            }
            last_offcurve = None
          } else if is_cubic && last_offcurve2 is None {
            last_offcurve2 = Some(lof)
            last_offcurve = Some(p)
          } else {
            let mid = mid_point(lof, p)
            if is_cubic {
              match last_offcurve2 {
                Some(lof2) =>
                  session.cubic_to(lof2.x, lof2.y, lof.x, lof.y, mid.x, mid.y)
                None => session.quadratic_to(lof.x, lof.y, mid.x, mid.y)
              }
              last_offcurve2 = None
            } else {
              session.quadratic_to(lof.x, lof.y, mid.x, mid.y)
            }
            last_offcurve = Some(p)
          }
        None =>
          if on_curve {
            session.line_to(p.x, p.y)
          } else {
            last_offcurve = Some(p)
          }
      }
    }
  }
  if first_offcurve is Some(ofc) && last_offcurve is Some(lof) {
    let first_for_mid = match first_offcurve2 {
      Some(ofc2) => ofc2
      None => ofc
    }
    let mid = mid_point(lof, first_for_mid)
    match last_offcurve2 {
      Some(lof2) => session.cubic_to(lof2.x, lof2.y, lof.x, lof.y, mid.x, mid.y)
      None => session.quadratic_to(lof.x, lof.y, mid.x, mid.y)
    }
    last_offcurve = None
    last_offcurve2 = None
  }
  if first_offcurve is Some(ofc) && first_oncurve is Some(onc) {
    match first_offcurve2 {
      Some(ofc2) => session.cubic_to(ofc2.x, ofc2.y, ofc.x, ofc.y, onc.x, onc.y)
      None => session.quadratic_to(ofc.x, ofc.y, onc.x, onc.y)
    }
  } else if last_offcurve is Some(lof) && first_oncurve is Some(onc) {
    match last_offcurve2 {
      Some(lof2) => session.cubic_to(lof2.x, lof2.y, lof.x, lof.y, onc.x, onc.y)
      None => session.quadratic_to(lof.x, lof.y, onc.x, onc.y)
    }
  } else if first_oncurve is Some(onc) {
    session.line_to(onc.x, onc.y)
  } else if first_offcurve is Some(ofc) {
    session.move_to(ofc.x, ofc.y)
    session.quadratic_to(ofc.x, ofc.y, ofc.x, ofc.y)
  }
  session.close_path()
}

///|
fn[T] draw_glyf_points(
  points : Array[@sfnt.GlyphPoint],
  session : @draw.DrawSession[T],
  scale_x : Int,
  scale_y : Int,
  upem : Int,
) -> Unit {
  let mut start = 0
  let count = points.length()
  for i in 0..<count {
    if points[i].is_end_point {
      draw_contour(points, start, i, session, scale_x, scale_y, upem)
      start = i + 1
    }
  }
  if start < count {
    draw_contour(points, start, count - 1, session, scale_x, scale_y, upem)
  }
}

///|
/// Draw glyph outline into draw callbacks. Returns false if unsupported.
pub fn[T] Font::draw_glyph_or_fail(
  self : Font,
  glyph : UInt,
  funcs : @draw.DrawFuncs[T],
  draw_data : T,
) -> Result[Bool, FontError] {
  let glyf_blob = match self.face.reference_table_optional(tag_glyf) {
    Err(err) => return Err(FaceTable(err))
    Ok(value) => value
  }
  let loca_blob = match self.face.reference_table_optional(tag_loca) {
    Err(err) => return Err(FaceTable(err))
    Ok(value) => value
  }
  if glyf_blob is None || loca_blob is None {
    return Ok(false)
  }
  let head = match self.ensure_head() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let coords : Array[Int] = match self.var_coords_norm {
    None => []
    Some(value) => value
  }
  let points = match self.glyph_points_with_gvar(glyph, coords) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match points {
    None => Ok(false)
    Some(points) => {
      let (outline, _) = split_phantoms(points)
      if outline.is_empty() {
        return Ok(true)
      }
      let session = @draw.DrawSession::new(funcs, draw_data)
      draw_glyf_points(
        outline,
        session,
        self.scale_x,
        self.scale_y,
        head.units_per_em,
      )
      Ok(true)
    }
  }
}

///|
/// Convenience wrapper that ignores draw failures.
pub fn[T] Font::draw_glyph(
  self : Font,
  glyph : UInt,
  funcs : @draw.DrawFuncs[T],
  draw_data : T,
) -> Result[Unit, FontError] {
  match self.draw_glyph_or_fail(glyph, funcs, draw_data) {
    Err(err) => Err(err)
    Ok(_) => Ok(())
  }
}
