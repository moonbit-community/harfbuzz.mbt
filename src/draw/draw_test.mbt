test "draw session implicit move and close" {
  let ops : Array[String] = []
  let funcs : DrawFuncs[Array[String]] = DrawFuncs::new()
  funcs.set_move_to(Some((data, _st, x, y) => {
    data.push("M\{x.to_int()},\{y.to_int()}")
  }))
  funcs.set_line_to(Some((data, _st, x, y) => {
    data.push("L\{x.to_int()},\{y.to_int()}")
  }))
  funcs.set_close_path(Some((data, _st) => {
    data.push("Z")
  }))
  let session = DrawSession::new(funcs, ops)
  session.move_to(10.0, 20.0)
  session.line_to(30.0, 40.0)
  session.close_path()
  inspect(ops.join("|"), content="M10,20|L30,40|L10,20|Z")
}

test "quadratic fallback to cubic" {
  let ops : Array[String] = []
  let funcs : DrawFuncs[Array[String]] = DrawFuncs::new()
  funcs.set_move_to(Some((data, _st, x, y) => {
    data.push("M\{x.to_int()},\{y.to_int()}")
  }))
  funcs.set_cubic_to(Some((data, _st, _c1x, _c1y, _c2x, _c2y, _x, _y) => {
    data.push("C")
  }))
  let session = DrawSession::new(funcs, ops)
  session.move_to(0.0, 0.0)
  session.quadratic_to(10.0, 0.0, 20.0, 0.0)
  inspect(ops.join("|"), content="M0,0|C")
}

test "draw extents funcs" {
  let extents = DrawExtents::new()
  let funcs = draw_extents_get_funcs()
  let session = DrawSession::new(funcs, extents)
  session.move_to(10.0, 20.0)
  session.line_to(30.0, 40.0)
  session.quadratic_to(40.0, 50.0, 60.0, 70.0)
  inspect(
    (
      extents.xmin.to_int(),
      extents.ymin.to_int(),
      extents.xmax.to_int(),
      extents.ymax.to_int(),
    ),
    content="(10, 20, 60, 70)",
  )
}

test "outline recording and replay" {
  let outline = Outline::new()
  let funcs = outline_recording_pen_get_funcs()
  let session = DrawSession::new(funcs, outline)
  session.move_to(0.0, 0.0)
  session.line_to(10.0, 0.0)
  session.line_to(10.0, 10.0)
  session.close_path()
  inspect(outline.contours, content="[4]")
  let ops : Array[String] = []
  let pen : DrawFuncs[Array[String]] = DrawFuncs::new()
  pen.set_move_to(Some((data, _st, x, y) => {
    data.push("M\{x.to_int()},\{y.to_int()}")
  }))
  pen.set_line_to(Some((data, _st, x, y) => {
    data.push("L\{x.to_int()},\{y.to_int()}")
  }))
  pen.set_close_path(Some((data, _st) => {
    data.push("Z")
  }))
  outline.replay(pen, ops)
  inspect(ops.join("|"), content="M0,0|L10,0|L10,10|L0,0|Z")
}
