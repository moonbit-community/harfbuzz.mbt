fn main {
  if false {
    ignore(@hb_buffer.Buffer::new())
    let _ : @hb_draw.DrawFuncs[Unit] = @hb_draw.DrawFuncs::new()
    ignore(@hb_font.Font::from_bytes(Bytes::from_array([])))
    ignore(@hb_shape.available_shapers())
  }
  println(
    "This example is intended for the JS target. Build with: moon build --target js src/examples/js_svg",
  )
}
