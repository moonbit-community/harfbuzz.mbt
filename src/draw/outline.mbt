///|
/// Outline point types.
pub enum OutlinePointKind {
  MoveTo
  LineTo
  QuadraticTo
  CubicTo
} derive(Eq, Show, ToJson)

///|
/// Outline point with type.
pub struct OutlinePoint {
  mut x : Double
  mut y : Double
  kind : OutlinePointKind
} derive(Eq, Show, ToJson)

///|
pub fn OutlinePoint::new(x : Double, y : Double, kind : OutlinePointKind) -> OutlinePoint {
  OutlinePoint::{ x, y, kind }
}

priv struct OutlineVector {
  mut x : Double
  mut y : Double
}

fn OutlineVector::normalize_len(self : OutlineVector) -> Double {
  let len = (self.x * self.x + self.y * self.y).sqrt()
  if len != 0.0 {
    self.x = self.x / len
    self.y = self.y / len
  }
  len
}

///|
/// Outline path container (points + contour end indices).
pub struct Outline {
  points : Array[OutlinePoint]
  contours : Array[Int]
} derive(Show, ToJson)

///|
pub fn Outline::new() -> Outline {
  Outline::{ points: [], contours: [] }
}

///|
pub fn Outline::reset(self : Outline) -> Unit {
  self.points.clear()
  self.contours.clear()
}

///|
pub fn[T] Outline::replay(self : Outline, pen : DrawFuncs[T], pen_data : T) -> Unit {
  let session = DrawSession::new(pen, pen_data)
  let mut first = 0
  for contour in self.contours {
    let mut i = first
    while i < contour {
      let p1 = self.points[i]
      i = i + 1
      match p1.kind {
        OutlinePointKind::MoveTo => {
          session.move_to(p1.x, p1.y)
        }
        OutlinePointKind::LineTo => {
          session.line_to(p1.x, p1.y)
        }
        OutlinePointKind::QuadraticTo => {
          let p2 = self.points[i]
          i = i + 1
          session.quadratic_to(p1.x, p1.y, p2.x, p2.y)
        }
        OutlinePointKind::CubicTo => {
          let p2 = self.points[i]
          let p3 = self.points[i + 1]
          i = i + 2
          session.cubic_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)
        }
      }
    }
    session.close_path()
    first = contour
  }
}

///|
pub fn Outline::control_area(self : Outline) -> Double {
  let mut area = 0.0
  let mut first = 0
  for contour in self.contours {
    for i in first..<contour {
      let j = if i + 1 < contour { i + 1 } else { first }
      let pi = self.points[i]
      let pj = self.points[j]
      area = area + pi.x * pj.y - pi.y * pj.x
    }
    first = contour
  }
  area * 0.5
}

///|
pub fn Outline::translate(self : Outline, dx : Double, dy : Double) -> Unit {
  for point in self.points {
    point.x = point.x + dx
    point.y = point.y + dy
  }
}

///|
pub fn Outline::slant(self : Outline, slant_xy : Double) -> Unit {
  for point in self.points {
    point.x = point.x + slant_xy * point.y
  }
}

///|
pub fn Outline::embolden(
  self : Outline,
  x_strength : Double,
  y_strength : Double,
  x_shift : Double,
  y_shift : Double,
) -> Unit {
  if x_strength == 0.0 && y_strength == 0.0 {
    return
  }
  if self.points.is_empty() {
    return
  }
  let x_strength = x_strength / 2.0
  let y_strength = y_strength / 2.0
  let orientation_negative = self.control_area() < 0.0
  let mut first = 0
  for contour_index in 0..<self.contours.length() {
    let mut input_vec = OutlineVector::{ x: 0.0, y: 0.0 }
    let mut output_vec = OutlineVector::{ x: 0.0, y: 0.0 }
    let mut anchor_vec = OutlineVector::{ x: 0.0, y: 0.0 }
    let shift = OutlineVector::{ x: 0.0, y: 0.0 }
    let mut l_in = 0.0
    let mut l_out = 0.0
    let mut l_anchor = 0.0
    let last = self.contours[contour_index] - 1
    let mut i = last
    let mut j = first
    let mut k = -1
    while j != i && i != k {
      if j != k {
        output_vec.x = self.points[j].x - self.points[i].x
        output_vec.y = self.points[j].y - self.points[i].y
        l_out = output_vec.normalize_len()
        if l_out == 0.0 {
          j = if j < last { j + 1 } else { first }
          continue
        }
      } else {
        output_vec = anchor_vec
        l_out = l_anchor
      }
      if l_in != 0.0 {
        if k < 0 {
          k = i
          anchor_vec = input_vec
          l_anchor = l_in
        }
        let mut d = input_vec.x * output_vec.x + input_vec.y * output_vec.y
        if d > -15.0 / 16.0 {
          d = d + 1.0
          shift.x = input_vec.y + output_vec.y
          shift.y = input_vec.x + output_vec.x
          if orientation_negative {
            shift.x = -shift.x
          } else {
            shift.y = -shift.y
          }
          let mut q = output_vec.x * input_vec.y - output_vec.y * input_vec.x
          if orientation_negative {
            q = -q
          }
          let l = if l_in < l_out { l_in } else { l_out }
          if x_strength * q <= l * d {
            shift.x = shift.x * x_strength / d
          } else {
            shift.x = shift.x * l / q
          }
          if y_strength * q <= l * d {
            shift.y = shift.y * y_strength / d
          } else {
            shift.y = shift.y * l / q
          }
        } else {
          shift.x = 0.0
          shift.y = 0.0
        }
        while i != j {
          self.points[i].x = self.points[i].x + x_shift + shift.x
          self.points[i].y = self.points[i].y + y_shift + shift.y
          i = if i < last { i + 1 } else { first }
        }
      } else {
        i = j
      }
      input_vec = output_vec
      l_in = l_out
      j = if j < last { j + 1 } else { first }
    }
    first = last + 1
  }
}

fn outline_recording_pen_move_to(data : Outline, _st : DrawState, to_x : Double, to_y : Double) -> Unit {
  data.points.push(OutlinePoint::new(to_x, to_y, OutlinePointKind::MoveTo))
}

fn outline_recording_pen_line_to(data : Outline, _st : DrawState, to_x : Double, to_y : Double) -> Unit {
  data.points.push(OutlinePoint::new(to_x, to_y, OutlinePointKind::LineTo))
}

fn outline_recording_pen_quadratic_to(
  data : Outline,
  _st : DrawState,
  control_x : Double,
  control_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  data.points.push(OutlinePoint::new(control_x, control_y, OutlinePointKind::QuadraticTo))
  data.points.push(OutlinePoint::new(to_x, to_y, OutlinePointKind::QuadraticTo))
}

fn outline_recording_pen_cubic_to(
  data : Outline,
  _st : DrawState,
  control1_x : Double,
  control1_y : Double,
  control2_x : Double,
  control2_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  data.points.push(OutlinePoint::new(control1_x, control1_y, OutlinePointKind::CubicTo))
  data.points.push(OutlinePoint::new(control2_x, control2_y, OutlinePointKind::CubicTo))
  data.points.push(OutlinePoint::new(to_x, to_y, OutlinePointKind::CubicTo))
}

fn outline_recording_pen_close_path(data : Outline, _st : DrawState) -> Unit {
  data.contours.push(data.points.length())
}

///|
pub fn outline_recording_pen_get_funcs() -> DrawFuncs[Outline] {
  let funcs : DrawFuncs[Outline] = DrawFuncs::new()
  funcs.set_move_to(Some(outline_recording_pen_move_to))
  funcs.set_line_to(Some(outline_recording_pen_line_to))
  funcs.set_quadratic_to(Some(outline_recording_pen_quadratic_to))
  funcs.set_cubic_to(Some(outline_recording_pen_cubic_to))
  funcs.set_close_path(Some(outline_recording_pen_close_path))
  funcs.make_immutable()
  funcs
}
