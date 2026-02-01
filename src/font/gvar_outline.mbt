///|
struct PointDelta {
  mut x : Double
  mut y : Double
  mut referenced : Bool
} derive(Show, ToJson)

fn clone_points(points : Array[@sfnt.GlyphPoint]) -> Array[@sfnt.GlyphPoint] {
  let out : Array[@sfnt.GlyphPoint] = []
  for point in points {
    out.push(@sfnt.GlyphPoint::new(
      point.x,
      point.y,
      point.flag,
      point.is_end_point,
    ))
  }
  out
}

fn make_deltas(count : Int) -> Array[PointDelta] {
  let deltas : Array[PointDelta] = []
  for _ in 0..<count {
    deltas.push(PointDelta::{ x: 0.0, y: 0.0, referenced: false })
  }
  deltas
}

fn next_index(i : Int, start : Int, end : Int) -> Int {
  if i >= end { start } else { i + 1 }
}

fn infer_delta(
  orig_points : Array[@sfnt.GlyphPoint],
  deltas : Array[PointDelta],
  target : Int,
  prev : Int,
  next : Int,
  use_x : Bool,
) -> Double {
  let prev_val = if use_x { orig_points[prev].x } else { orig_points[prev].y }
  let next_val = if use_x { orig_points[next].x } else { orig_points[next].y }
  let target_val = if use_x { orig_points[target].x } else { orig_points[target].y }
  let prev_delta = if use_x { deltas[prev].x } else { deltas[prev].y }
  let next_delta = if use_x { deltas[next].x } else { deltas[next].y }
  if prev_val == next_val {
    return if prev_delta == next_delta { prev_delta } else { 0.0 }
  }
  let min_val = if prev_val < next_val { prev_val } else { next_val }
  let max_val = if prev_val > next_val { prev_val } else { next_val }
  if target_val <= min_val {
    return if prev_val < next_val { prev_delta } else { next_delta }
  }
  if target_val >= max_val {
    return if prev_val > next_val { prev_delta } else { next_delta }
  }
  let ratio = (target_val - prev_val) / (next_val - prev_val)
  prev_delta + ratio * (next_delta - prev_delta)
}

fn iup_interpolate(
  orig_points : Array[@sfnt.GlyphPoint],
  deltas : Array[PointDelta],
) -> Unit {
  let count = orig_points.length()
  let mut start = 0
  let mut end = 0
  while true {
    while end < count && !orig_points[end].is_end_point {
      end = end + 1
    }
    if end >= count {
      break
    }
    let refs : Array[Int] = []
    for i in start..=end {
      if deltas[i].referenced {
        refs.push(i)
      }
    }
    let contour_len = end - start + 1
    if refs.length() > 0 && refs.length() < contour_len {
      let ref_count = refs.length()
      for r in 0..<ref_count {
        let prev = refs[r]
        let next = refs[(r + 1) % ref_count]
        let mut i = prev
        while true {
          i = next_index(i, start, end)
          if i == next {
            break
          }
          deltas[i].x = infer_delta(orig_points, deltas, i, prev, next, true)
          deltas[i].y = infer_delta(orig_points, deltas, i, prev, next, false)
        }
      }
    }
    start = end + 1
    end = start
  }
}

fn apply_gvar_deltas_to_points(
  points : Array[@sfnt.GlyphPoint],
  coords : Array[Int],
  gvar : @ot_var.GvarTable,
  glyph : Int,
) -> Result[Unit, @ot_var.VarError] {
  let tuple_data = match gvar.glyph_tuple_variations(glyph) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match tuple_data {
    None => Ok(())
    Some(data) => {
      let tuples = match data.decode(points.length(), true) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut orig_points : Array[@sfnt.GlyphPoint]? = None
      for tuple in tuples {
        let scalar = tuple.scalar(coords)
        if scalar == 0.0 {
          continue
        }
        match tuple.indices {
          None => {
            let deltas_y = match tuple.deltas_y {
              None => []
              Some(values) => values
            }
            for i in 0..<points.length() {
              let mut dx = 0.0
              let mut dy = 0.0
              if i < tuple.deltas_x.length() {
                dx = tuple.deltas_x[i].to_double() * scalar
              }
              if i < deltas_y.length() {
                dy = deltas_y[i].to_double() * scalar
              }
              if dx != 0.0 || dy != 0.0 {
                points[i].translate(dx, dy)
              }
            }
          }
          Some(indices) => {
            if orig_points is None {
              orig_points = Some(clone_points(points))
            }
            let deltas = make_deltas(points.length())
            let deltas_y = match tuple.deltas_y {
              None => []
              Some(values) => values
            }
            for i in 0..<indices.length() {
              let idx = indices[i]
              if idx < 0 || idx >= points.length() {
                continue
              }
              if i < tuple.deltas_x.length() {
                deltas[idx].x =
                  deltas[idx].x + tuple.deltas_x[i].to_double() * scalar
              }
              if i < deltas_y.length() {
                deltas[idx].y =
                  deltas[idx].y + deltas_y[i].to_double() * scalar
              }
              deltas[idx].referenced = true
            }
            match orig_points {
              None => ()
              Some(original) => iup_interpolate(original, deltas)
            }
            for i in 0..<points.length() {
              points[i].translate(deltas[i].x, deltas[i].y)
            }
          }
        }
      }
      Ok(())
    }
  }
}

fn transform_points(
  points : Array[@sfnt.GlyphPoint],
  a : Double,
  b : Double,
  c : Double,
  d : Double,
) -> Unit {
  if a == 1.0 && b == 0.0 && c == 0.0 && d == 1.0 {
    return
  }
  for point in points {
    point.transform(a, b, c, d)
  }
}

fn translate_points(
  points : Array[@sfnt.GlyphPoint],
  dx : Double,
  dy : Double,
) -> Unit {
  if dx == 0.0 && dy == 0.0 {
    return
  }
  for point in points {
    point.translate(dx, dy)
  }
}

fn apply_component_transform(
  points : Array[@sfnt.GlyphPoint],
  component : @sfnt.CompositeComponent,
  trans_point : @sfnt.GlyphPoint,
) -> Unit {
  if component.scaled_offset {
    translate_points(points, trans_point.x, trans_point.y)
    transform_points(points, component.a, component.b, component.c, component.d)
  } else {
    transform_points(points, component.a, component.b, component.c, component.d)
    translate_points(points, trans_point.x, trans_point.y)
  }
}

fn build_phantom_points(
  bounds : @sfnt.GlyphBounds?,
  hmtx : @sfnt.HmtxTable,
  vmtx : @sfnt.VmtxTable?,
  glyph : Int,
) -> Result[Array[@sfnt.GlyphPoint], FontError] {
  if glyph < 0 || glyph >= hmtx.advances.length() {
    return Err(GlyphOutOfRange)
  }
  let x_min = match bounds {
    None => 0
    Some(value) => value.x_min
  }
  let y_max = match bounds {
    None => 0
    Some(value) => value.y_max
  }
  let lsb = hmtx.lsbs[glyph]
  let h_adv = hmtx.advances[glyph]
  let h_delta = x_min - lsb
  let mut tsb = 0
  let mut v_adv = 0
  match vmtx {
    None => ()
    Some(table) => {
      if glyph < 0 || glyph >= table.advances.length() {
        return Err(GlyphOutOfRange)
      }
      tsb = table.tsbs[glyph]
      v_adv = table.advances[glyph]
    }
  }
  let v_orig = y_max + tsb
  let phantoms : Array[@sfnt.GlyphPoint] = []
  phantoms.push(@sfnt.GlyphPoint::new(
    h_delta.to_double(),
    0.0,
    0,
    false,
  ))
  phantoms.push(@sfnt.GlyphPoint::new(
    (h_adv + h_delta).to_double(),
    0.0,
    0,
    false,
  ))
  phantoms.push(@sfnt.GlyphPoint::new(
    0.0,
    v_orig.to_double(),
    0,
    false,
  ))
  phantoms.push(@sfnt.GlyphPoint::new(
    0.0,
    (v_orig - v_adv).to_double(),
    0,
    false,
  ))
  Ok(phantoms)
}

fn split_phantoms(
  points : Array[@sfnt.GlyphPoint],
) -> (Array[@sfnt.GlyphPoint], Array[@sfnt.GlyphPoint]) {
  let mut outline_len = points.length()
  if outline_len >= 4 {
    outline_len = outline_len - 4
  } else {
    outline_len = 0
  }
  let outlines : Array[@sfnt.GlyphPoint] = []
  let phantoms : Array[@sfnt.GlyphPoint] = []
  for i in 0..<outline_len {
    outlines.push(points[i])
  }
  for i in outline_len..<points.length() {
    phantoms.push(points[i])
  }
  (outlines, phantoms)
}

fn ensure_four_phantoms(points : Array[@sfnt.GlyphPoint]) -> Array[@sfnt.GlyphPoint] {
  if points.length() >= 4 {
    return points
  }
  let out : Array[@sfnt.GlyphPoint] = []
  for point in points {
    out.push(point)
  }
  while out.length() < 4 {
    out.push(@sfnt.GlyphPoint::new(0.0, 0.0, 0, false))
  }
  out
}

fn glyph_bounds_from_points(
  points : Array[@sfnt.GlyphPoint],
  contour_count : Int,
  contour_points : Int,
) -> @sfnt.GlyphBounds? {
  if contour_points <= 0 || contour_points > points.length() {
    return None
  }
  let mut min_x = points[0].x
  let mut max_x = points[0].x
  let mut min_y = points[0].y
  let mut max_y = points[0].y
  for i in 1..<contour_points {
    let p = points[i]
    if p.x < min_x { min_x = p.x }
    if p.x > max_x { max_x = p.x }
    if p.y < min_y { min_y = p.y }
    if p.y > max_y { max_y = p.y }
  }
  let x_min = @math.floor(min_x).to_int()
  let y_min = @math.floor(min_y).to_int()
  let x_max = @math.ceil(max_x).to_int()
  let y_max = @math.ceil(max_y).to_int()
  Some(@sfnt.GlyphBounds::new(contour_count, x_min, y_min, x_max, y_max))
}

fn Font::glyph_points_with_gvar_depth(
  self : Font,
  glyph : UInt,
  coords : Array[Int],
  depth : Int,
) -> Result[Array[@sfnt.GlyphPoint]?, FontError] {
  if depth <= 0 {
    return Ok(None)
  }
  let maxp = match self.ensure_maxp() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let index = glyph.reinterpret_as_int()
  if index < 0 || index >= maxp.num_glyphs {
    return Err(GlyphOutOfRange)
  }
  let loca = match self.ensure_loca() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let glyf = match self.ensure_glyf() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let offsets = loca.offsets
  if index + 1 >= offsets.length() {
    return Err(GlyphOutOfRange)
  }
  let start = offsets[index]
  let end = offsets[index + 1]
  let length = end - start
  let bounds = match glyf.glyph_bounds(start, length) {
    Err(err) => return Err(Parse(err))
    Ok(value) => value
  }
  let simple_points = match glyf.glyph_simple_points(start, length) {
    Err(err) => return Err(Parse(err))
    Ok(value) => value
  }
  match simple_points {
    None => {
      let components = match glyf.glyph_composite_components(start, length) {
        Err(err) => return Err(Parse(err))
        Ok(value) => value
      }
      match components {
        None => Ok(None)
        Some(components) => {
          let hmtx = match self.ensure_hmtx() {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let vmtx = match self.vmtx() {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let trans_points : Array[@sfnt.GlyphPoint] = []
          for component in components {
            trans_points.push(@sfnt.GlyphPoint::new(
              component.tx,
              component.ty,
              0,
              true,
            ))
          }
          let phantoms = match build_phantom_points(bounds, hmtx, vmtx, index) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let var_points : Array[@sfnt.GlyphPoint] = []
          for point in trans_points {
            var_points.push(point)
          }
          for phantom in phantoms {
            var_points.push(phantom)
          }
          if !coords.is_empty() {
            let gvar = match self.gvar() {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match gvar {
              None => ()
              Some(gvar) =>
                match apply_gvar_deltas_to_points(var_points, coords, gvar, index) {
                  Err(err) => return Err(Var(err))
                  Ok(_) => ()
                }
            }
          }
          let mut parent_phantoms = ensure_four_phantoms(
            var_points[var_points.length() - 4:var_points.length()].to_array(),
          )
          let all_points : Array[@sfnt.GlyphPoint] = []
          let mut comp_index = 0
          for component in components {
            if comp_index >= var_points.length() {
              break
            }
            let comp_gid = if component.glyph < 0 {
              None
            } else {
              Some(component.glyph.reinterpret_as_uint())
            }
            match comp_gid {
              None => ()
              Some(comp_gid) => {
                let comp_points = match self.glyph_points_with_gvar_depth(
                  comp_gid,
                  coords,
                  depth - 1,
                ) {
                  Err(err) => return Err(err)
                  Ok(value) => value
                }
                match comp_points {
                  None => ()
                  Some(comp_points) => {
                    let (comp_outline, comp_phantoms) = split_phantoms(comp_points)
                    if component.use_my_metrics && comp_phantoms.length() >= 4 {
                      parent_phantoms = comp_phantoms
                    }
                    if !comp_outline.is_empty() {
                      apply_component_transform(
                        comp_outline,
                        component,
                        var_points[comp_index],
                      )
                      if component.is_anchored {
                        let p1 = component.arg1
                        let p2 = component.arg2
                        if p1 >= 0 && p1 < all_points.length() &&
                          p2 >= 0 && p2 < comp_outline.length() {
                          let dx = all_points[p1].x - comp_outline[p2].x
                          let dy = all_points[p1].y - comp_outline[p2].y
                          translate_points(comp_outline, dx, dy)
                        }
                      }
                      for point in comp_outline {
                        all_points.push(point)
                      }
                    }
                  }
                }
              }
            }
            comp_index = comp_index + 1
          }
          for phantom in parent_phantoms {
            all_points.push(phantom)
          }
          Ok(Some(all_points))
        }
      }
    }
    Some(points) => {
      let points = points
      let hmtx = match self.ensure_hmtx() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let vmtx = match self.vmtx() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let phantoms = match build_phantom_points(bounds, hmtx, vmtx, index) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      for phantom in phantoms {
        points.push(phantom)
      }
      if !coords.is_empty() {
        let gvar = match self.gvar() {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        match gvar {
          None => ()
          Some(gvar) =>
            match apply_gvar_deltas_to_points(points, coords, gvar, index) {
              Err(err) => return Err(Var(err))
              Ok(_) => ()
            }
        }
      }
      Ok(Some(points))
    }
  }
}

fn Font::glyph_points_with_gvar(
  self : Font,
  glyph : UInt,
  coords : Array[Int],
) -> Result[Array[@sfnt.GlyphPoint]?, FontError] {
  self.glyph_points_with_gvar_depth(glyph, coords, 8)
}

fn glyph_bounds_from_points_for_font(
  points : Array[@sfnt.GlyphPoint],
) -> @sfnt.GlyphBounds? {
  let mut contour_count = 0
  let mut contour_points = points.length()
  if contour_points >= 4 {
    contour_points = contour_points - 4
  }
  for i in 0..<contour_points {
    if points[i].is_end_point {
      contour_count = contour_count + 1
    }
  }
  glyph_bounds_from_points(points, contour_count, contour_points)
}

fn Font::glyph_gvar_advance(
  self : Font,
  glyph : UInt,
  coords : Array[Int],
  vertical : Bool,
) -> Result[Int?, FontError] {
  let points = match self.glyph_points_with_gvar(glyph, coords) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match points {
    None => Ok(None)
    Some(points) => {
      if points.length() < 4 {
        return Ok(None)
      }
      let left = points[points.length() - 4].x
      let right = points[points.length() - 3].x
      let top = points[points.length() - 2].y
      let bottom = points[points.length() - 1].y
      if vertical {
        Ok(Some((top - bottom).round().to_int()))
      } else {
        Ok(Some((right - left).round().to_int()))
      }
    }
  }
}
