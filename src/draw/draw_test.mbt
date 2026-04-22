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
test "draw session implicit move and close" {
  let ops : Array[String] = []
  let funcs : DrawFuncs[Array[String]] = DrawFuncs::new()
  funcs.set_move_to(
    Some((data, _st, x, y) => data.push("M\{x.to_int()},\{y.to_int()}")),
  )
  funcs.set_line_to(
    Some((data, _st, x, y) => data.push("L\{x.to_int()},\{y.to_int()}")),
  )
  funcs.set_close_path(Some((data, _st) => data.push("Z")))
  let session = DrawSession::new(funcs, ops)
  session.move_to(10.0, 20.0)
  session.line_to(30.0, 40.0)
  session.close_path()
  @debug.debug_inspect(ops.join("|"), content="M10,20|L30,40|L10,20|Z")
}

///|
test "quadratic fallback to cubic" {
  let ops : Array[String] = []
  let funcs : DrawFuncs[Array[String]] = DrawFuncs::new()
  funcs.set_move_to(
    Some((data, _st, x, y) => data.push("M\{x.to_int()},\{y.to_int()}")),
  )
  funcs.set_cubic_to(
    Some((data, _st, _c1x, _c1y, _c2x, _c2y, _x, _y) => data.push("C")),
  )
  let session = DrawSession::new(funcs, ops)
  session.move_to(0.0, 0.0)
  session.quadratic_to(10.0, 0.0, 20.0, 0.0)
  @debug.debug_inspect(ops.join("|"), content="M0,0|C")
}

///|
test "draw extents funcs" {
  let extents = DrawExtents::new()
  let funcs = draw_extents_get_funcs()
  let session = DrawSession::new(funcs, extents)
  session.move_to(10.0, 20.0)
  session.line_to(30.0, 40.0)
  session.quadratic_to(40.0, 50.0, 60.0, 70.0)
  @debug.debug_inspect(
    (
      extents.xmin.to_int(),
      extents.ymin.to_int(),
      extents.xmax.to_int(),
      extents.ymax.to_int(),
    ),
    content="(10, 20, 60, 70)",
  )
}

///|
test "outline recording and replay" {
  let outline = Outline::new()
  let funcs = outline_recording_pen_get_funcs()
  let session = DrawSession::new(funcs, outline)
  session.move_to(0.0, 0.0)
  session.line_to(10.0, 0.0)
  session.line_to(10.0, 10.0)
  session.close_path()
  @debug.debug_inspect(outline.contours, content="[4]")
  let ops : Array[String] = []
  let pen : DrawFuncs[Array[String]] = DrawFuncs::new()
  pen.set_move_to(
    Some((data, _st, x, y) => data.push("M\{x.to_int()},\{y.to_int()}")),
  )
  pen.set_line_to(
    Some((data, _st, x, y) => data.push("L\{x.to_int()},\{y.to_int()}")),
  )
  pen.set_close_path(Some((data, _st) => data.push("Z")))
  outline.replay(pen, ops)
  @debug.debug_inspect(ops.join("|"), content="M0,0|L10,0|L10,10|L0,0|Z")
}
