///|
#external
priv type JsElement

///|
#external
priv type JsEvent

///|
#external
priv type JsFile

///|
extern "js" fn document_get_element_by_id_or_throw(id : String) -> JsElement =
  #| (id) => {
  #|   const el = document.getElementById(id);
  #|   if (!el) {
  #|     throw new Error(`missing element: ${id}`);
  #|   }
  #|   return el;
  #| }

///|
extern "js" fn element_set_text(el : JsElement, text : String) -> Unit =
  #| (el, text) => { el.textContent = text; }

///|
extern "js" fn element_set_html(el : JsElement, html : String) -> Unit =
  #| (el, html) => { el.innerHTML = html; }

///|
extern "js" fn element_add_class(el : JsElement, name : String) -> Unit =
  #| (el, name) => { el.classList.add(name); }

///|
extern "js" fn element_remove_class(el : JsElement, name : String) -> Unit =
  #| (el, name) => { el.classList.remove(name); }

///|
extern "js" fn input_value(el : JsElement) -> String =
  #| (el) => (el && ("value" in el)) ? el.value : ""

///|
extern "js" fn add_event_listener(
  el : JsElement,
  event : String,
  handler : (JsEvent) -> Unit,
) -> Unit =
  #| (el, event, handler) => el.addEventListener(event, handler)

///|
extern "js" fn event_prevent_default(ev : JsEvent) -> Unit =
  #| (ev) => { ev.preventDefault(); }

///|
extern "js" fn event_stop_propagation(ev : JsEvent) -> Unit =
  #| (ev) => { ev.stopPropagation(); }

///|
extern "js" fn event_first_file(ev : JsEvent) -> JsFile =
  #| (ev) => {
  #|   const files = ev?.dataTransfer?.files ?? ev?.target?.files;
  #|   return (files && files.length) ? files[0] : null;
  #| }

///|
extern "js" fn file_name(file : JsFile) -> String =
  #| (file) => file?.name ?? "font"

///|
extern "js" fn read_file_bytes(
  file : JsFile,
  on_ok : (Array[Byte]) -> Unit,
  on_err : (String) -> Unit,
) -> Unit =
  #| (file, on_ok, on_err) => {
  #|   const reader = new FileReader();
  #|   reader.onerror = () => on_err(
  #|     reader.error ? reader.error.message : "File read failed",
  #|   );
  #|   reader.onload = () => {
  #|     const bytes = new Uint8Array(reader.result);
  #|     on_ok(Array.from(bytes));
  #|   };
  #|   reader.readAsArrayBuffer(file);
  #| }

///|
struct Bounds {
  mut has : Bool
  mut min_x : Double
  mut min_y : Double
  mut max_x : Double
  mut max_y : Double
}

///|
fn Bounds::new() -> Bounds {
  Bounds::{ has: false, min_x: 0.0, min_y: 0.0, max_x: 0.0, max_y: 0.0 }
}

///|
fn Bounds::update(self : Bounds, x : Double, y : Double) -> Unit {
  if !self.has {
    self.has = true
    self.min_x = x
    self.min_y = y
    self.max_x = x
    self.max_y = y
    return
  }
  if x < self.min_x {
    self.min_x = x
  }
  if y < self.min_y {
    self.min_y = y
  }
  if x > self.max_x {
    self.max_x = x
  }
  if y > self.max_y {
    self.max_y = y
  }
}

///|
struct SvgContext {
  paths : Array[String]
  bounds : Bounds
}

///|
fn SvgContext::new() -> SvgContext {
  SvgContext::{ paths: [], bounds: Bounds::new() }
}

///|
struct SvgPen {
  ctx : SvgContext
  sb : StringBuilder
  mut has_cmd : Bool
  offset_x : Double
  offset_y : Double
}

///|
fn SvgPen::new(
  ctx : SvgContext,
  offset_x : Double,
  offset_y : Double,
) -> SvgPen {
  SvgPen::{ ctx, sb: StringBuilder::new(), has_cmd: false, offset_x, offset_y }
}

///|
fn SvgPen::finish(self : SvgPen) -> Unit {
  if self.has_cmd {
    self.ctx.paths.push(self.sb.to_string())
  }
}

///|
fn SvgPen::start_cmd(self : SvgPen, cmd : Char) -> Unit {
  if self.has_cmd {
    self.sb.write_char(' ')
  }
  self.sb.write_char(cmd)
  self.has_cmd = true
}

///|
fn SvgPen::write_num(self : SvgPen, value : Double) -> Unit {
  let rounded = (value * 100.0).round() / 100.0
  if rounded == 0.0 {
    self.sb.write_char('0')
  } else {
    self.sb.write_string(rounded.to_string())
  }
}

///|
fn SvgPen::write_pair(self : SvgPen, x : Double, y : Double) -> Unit {
  self.write_num(x)
  self.sb.write_char(' ')
  self.write_num(y)
}

///|
fn SvgPen::transform(self : SvgPen, x : Double, y : Double) -> (Double, Double) {
  let scale = 1.0 / 64.0
  let tx = x * scale + self.offset_x
  let ty = -y * scale + self.offset_y
  (tx, ty)
}

///|
fn svg_move_to(
  pen : SvgPen,
  _st : @hb_draw.DrawState,
  x : Double,
  y : Double,
) -> Unit {
  let (tx, ty) = pen.transform(x, y)
  pen.start_cmd('M')
  pen.write_pair(tx, ty)
  pen.ctx.bounds.update(tx, ty)
}

///|
fn svg_line_to(
  pen : SvgPen,
  _st : @hb_draw.DrawState,
  x : Double,
  y : Double,
) -> Unit {
  let (tx, ty) = pen.transform(x, y)
  pen.start_cmd('L')
  pen.write_pair(tx, ty)
  pen.ctx.bounds.update(tx, ty)
}

///|
fn svg_quadratic_to(
  pen : SvgPen,
  _st : @hb_draw.DrawState,
  cx : Double,
  cy : Double,
  x : Double,
  y : Double,
) -> Unit {
  let (tcx, tcy) = pen.transform(cx, cy)
  let (tx, ty) = pen.transform(x, y)
  pen.start_cmd('Q')
  pen.write_pair(tcx, tcy)
  pen.sb.write_char(' ')
  pen.write_pair(tx, ty)
  pen.ctx.bounds.update(tcx, tcy)
  pen.ctx.bounds.update(tx, ty)
}

///|
fn svg_cubic_to(
  pen : SvgPen,
  _st : @hb_draw.DrawState,
  cx1 : Double,
  cy1 : Double,
  cx2 : Double,
  cy2 : Double,
  x : Double,
  y : Double,
) -> Unit {
  let (tcx1, tcy1) = pen.transform(cx1, cy1)
  let (tcx2, tcy2) = pen.transform(cx2, cy2)
  let (tx, ty) = pen.transform(x, y)
  pen.start_cmd('C')
  pen.write_pair(tcx1, tcy1)
  pen.sb.write_char(' ')
  pen.write_pair(tcx2, tcy2)
  pen.sb.write_char(' ')
  pen.write_pair(tx, ty)
  pen.ctx.bounds.update(tcx1, tcy1)
  pen.ctx.bounds.update(tcx2, tcy2)
  pen.ctx.bounds.update(tx, ty)
}

///|
fn svg_close_path(pen : SvgPen, _st : @hb_draw.DrawState) -> Unit {
  pen.start_cmd('Z')
}

///|
fn build_draw_funcs() -> @hb_draw.DrawFuncs[SvgPen] {
  let funcs : @hb_draw.DrawFuncs[SvgPen] = @hb_draw.DrawFuncs::new()
  funcs.set_move_to(Some(svg_move_to))
  funcs.set_line_to(Some(svg_line_to))
  funcs.set_quadratic_to(Some(svg_quadratic_to))
  funcs.set_cubic_to(Some(svg_cubic_to))
  funcs.set_close_path(Some(svg_close_path))
  funcs
}

///|
fn render_svg(font_bytes : Bytes, text : String) -> Result[String, String] {
  if text.is_empty() {
    return Ok("")
  }
  let font = @hb_font.Font::from_bytes(font_bytes)
  let font_size = 64
  font.set_scale(font_size * 64, font_size * 64)
  let buffer = @hb_buffer.Buffer::new()
  buffer.add_string(text)
  match @hb_shape.shape(font, buffer) {
    Err(err) => return Err(err.to_string())
    Ok(_) => ()
  }
  let infos = buffer.infos()
  let positions = buffer.positions()
  let ctx = SvgContext::new()
  let funcs = build_draw_funcs()
  let mut pen_x = 0.0
  let mut pen_y = 0.0
  let count = infos.length()
  for i in 0..<count {
    let info = infos[i]
    let pos = positions[i]
    let offset_x = pen_x + pos.x_offset.to_double() / 64.0
    let offset_y = -(pen_y + pos.y_offset.to_double() / 64.0)
    let pen = SvgPen::new(ctx, offset_x, offset_y)
    match font.draw_glyph(info.codepoint, funcs, pen) {
      Err(err) => return Err("draw_glyph failed: \{err}")
      Ok(_) => pen.finish()
    }
    pen_x = pen_x + pos.x_advance.to_double() / 64.0
    pen_y = pen_y + pos.y_advance.to_double() / 64.0
  }
  if !ctx.bounds.has {
    return Ok("")
  }
  let padding = 4.0
  let min_x = ctx.bounds.min_x - padding
  let min_y = ctx.bounds.min_y - padding
  let max_x = ctx.bounds.max_x + padding
  let max_y = ctx.bounds.max_y + padding
  let mut width = max_x - min_x
  let mut height = max_y - min_y
  if width <= 0.0 {
    width = 1.0
  }
  if height <= 0.0 {
    height = 1.0
  }
  let sb = StringBuilder::new()
  sb.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"")
  sb.write_string(min_x.to_string())
  sb.write_char(' ')
  sb.write_string(min_y.to_string())
  sb.write_char(' ')
  sb.write_string(width.to_string())
  sb.write_char(' ')
  sb.write_string(height.to_string())
  sb.write_string("\">")
  sb.write_string("<g fill=\"black\" stroke=\"none\">")
  for path in ctx.paths {
    sb.write_string("<path d=\"")
    sb.write_string(path)
    sb.write_string("\"/>")
  }
  sb.write_string("</g></svg>")
  Ok(sb.to_string())
}

///|
struct AppUi {
  drop_zone : JsElement
  file_input : JsElement
  text_input : JsElement
  status : JsElement
  output : JsElement
}

///|
struct AppState {
  mut font_bytes : Bytes?
  mut font_name : String
}

///|
fn require_element(id : String) -> JsElement {
  document_get_element_by_id_or_throw(id)
}

///|
fn update_output(ui : AppUi, svg : String) -> Unit {
  if svg.is_empty() {
    element_set_html(ui.output, "")
  } else {
    element_set_html(ui.output, svg)
  }
}

///|
fn render_if_ready(app : AppState, ui : AppUi) -> Unit {
  let text = input_value(ui.text_input)
  match app.font_bytes {
    None => {
      element_set_text(ui.status, "Drop a font file to start.")
      update_output(ui, "")
    }
    Some(bytes) =>
      match render_svg(bytes, text) {
        Err(err) => element_set_text(ui.status, "Render error: \{err}")
        Ok(svg) => {
          element_set_text(ui.status, "Font: \{app.font_name}")
          update_output(ui, svg)
        }
      }
  }
}

///|
fn load_font(app : AppState, ui : AppUi, file : JsFile) -> Unit {
  element_set_text(ui.status, "Loading font...")
  read_file_bytes(
    file,
    data => {
      let bytes = Bytes::from_array(data)
      app.font_bytes = Some(bytes)
      app.font_name = file_name(file)
      render_if_ready(app, ui)
    },
    err => element_set_text(ui.status, "Font load failed: \{err}"),
  )
}

///|
fn main {
  let ui = AppUi::{
    drop_zone: require_element("drop-zone"),
    file_input: require_element("font-input"),
    text_input: require_element("text-input"),
    status: require_element("status"),
    output: require_element("svg-output"),
  }
  let app = AppState::{ font_bytes: None, font_name: "" }
  element_set_text(ui.status, "Drop a font file to start.")
  add_event_listener(ui.file_input, "change", ev => {
    let file = event_first_file(ev)
    load_font(app, ui, file)
  })
  add_event_listener(ui.text_input, "input", _ev => render_if_ready(app, ui))
  add_event_listener(ui.drop_zone, "dragenter", ev => {
    event_prevent_default(ev)
    event_stop_propagation(ev)
    element_add_class(ui.drop_zone, "dragover")
  })
  add_event_listener(ui.drop_zone, "dragover", ev => {
    event_prevent_default(ev)
    event_stop_propagation(ev)
    element_add_class(ui.drop_zone, "dragover")
  })
  add_event_listener(ui.drop_zone, "dragleave", ev => {
    event_prevent_default(ev)
    event_stop_propagation(ev)
    element_remove_class(ui.drop_zone, "dragover")
  })
  add_event_listener(ui.drop_zone, "drop", ev => {
    event_prevent_default(ev)
    event_stop_propagation(ev)
    element_remove_class(ui.drop_zone, "dragover")
    let file = event_first_file(ev)
    load_font(app, ui, file)
  })
}
