///|
/// Current drawing state.
pub struct DrawState {
  mut path_open : Bool
  mut path_start_x : Double
  mut path_start_y : Double
  mut current_x : Double
  mut current_y : Double
} derive(Show, ToJson)

///|
pub fn DrawState::new() -> DrawState {
  DrawState::{
    path_open: false,
    path_start_x: 0.0,
    path_start_y: 0.0,
    current_x: 0.0,
    current_y: 0.0,
  }
}

///|
/// Draw callback types.
pub type DrawMoveToFunc[T] = (T, DrawState, Double, Double) -> Unit

///|
pub type DrawLineToFunc[T] = (T, DrawState, Double, Double) -> Unit

///|
pub type DrawQuadraticToFunc[T] = (T, DrawState, Double, Double, Double, Double) -> Unit

///|
pub type DrawCubicToFunc[T] = (T, DrawState, Double, Double, Double, Double, Double, Double) -> Unit

///|
pub type DrawClosePathFunc[T] = (T, DrawState) -> Unit

fn[T] draw_move_to_nil(_data : T, _st : DrawState, _x : Double, _y : Double) -> Unit {}

fn[T] draw_line_to_nil(_data : T, _st : DrawState, _x : Double, _y : Double) -> Unit {}

fn[T] draw_cubic_to_nil(
  _data : T,
  _st : DrawState,
  _x1 : Double,
  _y1 : Double,
  _x2 : Double,
  _y2 : Double,
  _x : Double,
  _y : Double,
) -> Unit {
}

fn[T] draw_close_path_nil(_data : T, _st : DrawState) -> Unit {}

///|
/// Draw callbacks container.
pub struct DrawFuncs[T] {
  mut move_to_cb : DrawMoveToFunc[T]
  mut line_to_cb : DrawLineToFunc[T]
  mut quadratic_to_cb : DrawQuadraticToFunc[T]?
  mut cubic_to_cb : DrawCubicToFunc[T]
  mut close_path_cb : DrawClosePathFunc[T]
  mut immutable : Bool
}

///|
pub fn[T] DrawFuncs::new() -> DrawFuncs[T] {
  DrawFuncs::{
    move_to_cb: draw_move_to_nil,
    line_to_cb: draw_line_to_nil,
    quadratic_to_cb: None,
    cubic_to_cb: draw_cubic_to_nil,
    close_path_cb: draw_close_path_nil,
    immutable: false,
  }
}

///|
pub fn[T] DrawFuncs::empty() -> DrawFuncs[T] {
  let funcs = DrawFuncs::new()
  funcs.make_immutable()
  funcs
}

///|
pub fn[T] DrawFuncs::make_immutable(self : DrawFuncs[T]) -> Unit {
  self.immutable = true
}

///|
pub fn[T] DrawFuncs::is_immutable(self : DrawFuncs[T]) -> Bool {
  self.immutable
}

///|
pub fn[T] DrawFuncs::set_move_to(self : DrawFuncs[T], func : DrawMoveToFunc[T]?) -> Unit {
  if self.immutable {
    return
  }
  match func {
    Some(cb) => self.move_to_cb = cb
    None => self.move_to_cb = draw_move_to_nil
  }
}

///|
pub fn[T] DrawFuncs::set_line_to(self : DrawFuncs[T], func : DrawLineToFunc[T]?) -> Unit {
  if self.immutable {
    return
  }
  match func {
    Some(cb) => self.line_to_cb = cb
    None => self.line_to_cb = draw_line_to_nil
  }
}

///|
pub fn[T] DrawFuncs::set_quadratic_to(
  self : DrawFuncs[T],
  func : DrawQuadraticToFunc[T]?,
) -> Unit {
  if self.immutable {
    return
  }
  self.quadratic_to_cb = func
}

///|
pub fn[T] DrawFuncs::set_cubic_to(self : DrawFuncs[T], func : DrawCubicToFunc[T]?) -> Unit {
  if self.immutable {
    return
  }
  match func {
    Some(cb) => self.cubic_to_cb = cb
    None => self.cubic_to_cb = draw_cubic_to_nil
  }
}

///|
pub fn[T] DrawFuncs::set_close_path(self : DrawFuncs[T], func : DrawClosePathFunc[T]?) -> Unit {
  if self.immutable {
    return
  }
  match func {
    Some(cb) => self.close_path_cb = cb
    None => self.close_path_cb = draw_close_path_nil
  }
}

///|
pub fn[T] DrawFuncs::emit_move_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  to_x : Double,
  to_y : Double,
) -> Unit {
  (self.move_to_cb)(draw_data, st, to_x, to_y)
}

///|
pub fn[T] DrawFuncs::emit_line_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  to_x : Double,
  to_y : Double,
) -> Unit {
  (self.line_to_cb)(draw_data, st, to_x, to_y)
}

///|
pub fn[T] DrawFuncs::emit_quadratic_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  control_x : Double,
  control_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  match self.quadratic_to_cb {
    Some(cb) => cb(draw_data, st, control_x, control_y, to_x, to_y)
    None => {
      let two_third = 2.0 / 3.0
      let c1x = st.current_x + (control_x - st.current_x) * two_third
      let c1y = st.current_y + (control_y - st.current_y) * two_third
      let c2x = to_x + (control_x - to_x) * two_third
      let c2y = to_y + (control_y - to_y) * two_third
      self.emit_cubic_to(draw_data, st, c1x, c1y, c2x, c2y, to_x, to_y)
    }
  }
}

///|
pub fn[T] DrawFuncs::emit_cubic_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  control1_x : Double,
  control1_y : Double,
  control2_x : Double,
  control2_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  (self.cubic_to_cb)(
    draw_data,
    st,
    control1_x,
    control1_y,
    control2_x,
    control2_y,
    to_x,
    to_y,
  )
}

///|
pub fn[T] DrawFuncs::emit_close_path(self : DrawFuncs[T], draw_data : T, st : DrawState) -> Unit {
  (self.close_path_cb)(draw_data, st)
}

///|
pub fn[T] DrawFuncs::move_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  to_x : Double,
  to_y : Double,
) -> Unit {
  if st.path_open {
    self.close_path(draw_data, st)
  }
  st.current_x = to_x
  st.current_y = to_y
}

///|
pub fn[T] DrawFuncs::line_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  to_x : Double,
  to_y : Double,
) -> Unit {
  if !st.path_open {
    self.start_path(draw_data, st)
  }
  self.emit_line_to(draw_data, st, to_x, to_y)
  st.current_x = to_x
  st.current_y = to_y
}

///|
pub fn[T] DrawFuncs::quadratic_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  control_x : Double,
  control_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  if !st.path_open {
    self.start_path(draw_data, st)
  }
  self.emit_quadratic_to(draw_data, st, control_x, control_y, to_x, to_y)
  st.current_x = to_x
  st.current_y = to_y
}

///|
pub fn[T] DrawFuncs::cubic_to(
  self : DrawFuncs[T],
  draw_data : T,
  st : DrawState,
  control1_x : Double,
  control1_y : Double,
  control2_x : Double,
  control2_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  if !st.path_open {
    self.start_path(draw_data, st)
  }
  self.emit_cubic_to(
    draw_data,
    st,
    control1_x,
    control1_y,
    control2_x,
    control2_y,
    to_x,
    to_y,
  )
  st.current_x = to_x
  st.current_y = to_y
}

///|
pub fn[T] DrawFuncs::close_path(self : DrawFuncs[T], draw_data : T, st : DrawState) -> Unit {
  if st.path_open {
    if st.path_start_x != st.current_x || st.path_start_y != st.current_y {
      self.emit_line_to(draw_data, st, st.path_start_x, st.path_start_y)
    }
    self.emit_close_path(draw_data, st)
  }
  st.path_open = false
  st.path_start_x = 0.0
  st.path_start_y = 0.0
  st.current_x = 0.0
  st.current_y = 0.0
}

fn[T] DrawFuncs::start_path(self : DrawFuncs[T], draw_data : T, st : DrawState) -> Unit {
  if st.path_open {
    return
  }
  self.emit_move_to(draw_data, st, st.current_x, st.current_y)
  st.path_open = true
  st.path_start_x = st.current_x
  st.path_start_y = st.current_y
}

///|
/// A draw session ties draw funcs and data to a mutable draw state.
pub struct DrawSession[T] {
  funcs : DrawFuncs[T]
  draw_data : T
  st : DrawState
}

///|
pub fn[T] DrawSession::new(funcs : DrawFuncs[T], draw_data : T) -> DrawSession[T] {
  DrawSession::{
    funcs,
    draw_data,
    st: DrawState::new(),
  }
}

///|
pub fn[T] DrawSession::move_to(self : DrawSession[T], to_x : Double, to_y : Double) -> Unit {
  self.funcs.move_to(self.draw_data, self.st, to_x, to_y)
}

///|
pub fn[T] DrawSession::line_to(self : DrawSession[T], to_x : Double, to_y : Double) -> Unit {
  self.funcs.line_to(self.draw_data, self.st, to_x, to_y)
}

///|
pub fn[T] DrawSession::quadratic_to(
  self : DrawSession[T],
  control_x : Double,
  control_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  self.funcs.quadratic_to(self.draw_data, self.st, control_x, control_y, to_x, to_y)
}

///|
pub fn[T] DrawSession::cubic_to(
  self : DrawSession[T],
  control1_x : Double,
  control1_y : Double,
  control2_x : Double,
  control2_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  self.funcs.cubic_to(
    self.draw_data,
    self.st,
    control1_x,
    control1_y,
    control2_x,
    control2_y,
    to_x,
    to_y,
  )
}

///|
pub fn[T] DrawSession::close_path(self : DrawSession[T]) -> Unit {
  self.funcs.close_path(self.draw_data, self.st)
}

///|
/// Bounding box builder for draw callbacks.
pub struct DrawExtents {
  mut xmin : Double
  mut ymin : Double
  mut xmax : Double
  mut ymax : Double
} derive(Show, ToJson)

///|
pub fn DrawExtents::new() -> DrawExtents {
  DrawExtents::{ xmin: 0.0, ymin: 0.0, xmax: -1.0, ymax: -1.0 }
}

///|
pub fn DrawExtents::is_empty(self : DrawExtents) -> Bool {
  self.xmin >= self.xmax || self.ymin >= self.ymax
}

///|
pub fn DrawExtents::is_void(self : DrawExtents) -> Bool {
  self.xmin > self.xmax
}

///|
pub fn DrawExtents::add_point(self : DrawExtents, x : Double, y : Double) -> Unit {
  if self.is_void() {
    self.xmin = x
    self.xmax = x
    self.ymin = y
    self.ymax = y
    return
  }
  if x < self.xmin {
    self.xmin = x
  }
  if y < self.ymin {
    self.ymin = y
  }
  if x > self.xmax {
    self.xmax = x
  }
  if y > self.ymax {
    self.ymax = y
  }
}

fn draw_extents_move_to(data : DrawExtents, _st : DrawState, to_x : Double, to_y : Double) -> Unit {
  data.add_point(to_x, to_y)
}

fn draw_extents_line_to(data : DrawExtents, _st : DrawState, to_x : Double, to_y : Double) -> Unit {
  data.add_point(to_x, to_y)
}

fn draw_extents_quadratic_to(
  data : DrawExtents,
  _st : DrawState,
  control_x : Double,
  control_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  data.add_point(control_x, control_y)
  data.add_point(to_x, to_y)
}

fn draw_extents_cubic_to(
  data : DrawExtents,
  _st : DrawState,
  control1_x : Double,
  control1_y : Double,
  control2_x : Double,
  control2_y : Double,
  to_x : Double,
  to_y : Double,
) -> Unit {
  data.add_point(control1_x, control1_y)
  data.add_point(control2_x, control2_y)
  data.add_point(to_x, to_y)
}

///|
pub fn draw_extents_get_funcs() -> DrawFuncs[DrawExtents] {
  let funcs : DrawFuncs[DrawExtents] = DrawFuncs::new()
  funcs.set_move_to(Some(draw_extents_move_to))
  funcs.set_line_to(Some(draw_extents_line_to))
  funcs.set_quadratic_to(Some(draw_extents_quadratic_to))
  funcs.set_cubic_to(Some(draw_extents_cubic_to))
  funcs.make_immutable()
  funcs
}
