let max_paint_depth : Int = 64

fn resolve_offset(base : Int, rel : Int, data : BytesView) -> Result[Int, ColorError] {
  let abs = base + rel
  if abs < 0 || abs >= data.length() {
    Err(UnexpectedEof)
  } else {
    Ok(abs)
  }
}

fn parse_color_stop(
  data : BytesView,
  offset : Int,
  has_var : Bool,
) -> Result[@paint.ColorStop, ColorError] {
  let stop_offset = read_i16(data, offset)
  let palette_index = read_u16_int(data, offset + 2)
  let alpha = read_i16(data, offset + 4)
  match (stop_offset, palette_index, alpha) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(stop_offset), Ok(palette_index), Ok(alpha)) => {
      let mut var_idx_base : @paint.VarIdx? = None
      if has_var {
        let var_idx = read_u32(data, offset + 6)
        match var_idx {
          Err(err) => return Err(err)
          Ok(value) => var_idx_base = Some(value)
        }
      }
      Ok(@paint.ColorStop::{
        offset: stop_offset,
        palette_index,
        alpha,
        var_idx_base,
      })
    }
  }
}

fn parse_color_line(
  data : BytesView,
  offset : Int,
  has_var : Bool,
) -> Result[@paint.ColorLine, ColorError] {
  let extend = read_u8_int(data, offset)
  let count = read_u16_int(data, offset + 1)
  match (extend, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(extend), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let stop_size = if has_var { 10 } else { 6 }
      let stops_offset = offset + 3
      if stops_offset + count * stop_size > data.length() {
        return Err(UnexpectedEof)
      }
      let stops : Array[@paint.ColorStop] = []
      for i in 0..<count {
        let stop = parse_color_stop(data, stops_offset + i * stop_size, has_var)
        match stop {
          Err(err) => return Err(err)
          Ok(value) => stops.push(value)
        }
      }
      Ok(@paint.ColorLine::{ extend, stops })
    }
  }
}

fn parse_affine(
  data : BytesView,
  offset : Int,
  has_var : Bool,
) -> Result[@paint.Affine2x3, ColorError] {
  let xx = read_i32(data, offset)
  let yx = read_i32(data, offset + 4)
  let xy = read_i32(data, offset + 8)
  let yy = read_i32(data, offset + 12)
  let dx = read_i32(data, offset + 16)
  let dy = read_i32(data, offset + 20)
  match (xx, yx, xy, yy, dx, dy) {
    (Err(err), _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _) => Err(err)
    (_, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, Err(err)) => Err(err)
    (Ok(xx), Ok(yx), Ok(xy), Ok(yy), Ok(dx), Ok(dy)) => {
      let mut var_idx_base : @paint.VarIdx? = None
      if has_var {
        let var_idx = read_u32(data, offset + 24)
        match var_idx {
          Err(err) => return Err(err)
          Ok(value) => var_idx_base = Some(value)
        }
      }
      Ok(@paint.Affine2x3::{ xx, yx, xy, yy, dx, dy, var_idx_base })
    }
  }
}

fn parse_paint(
  data : BytesView,
  offset : Int,
  depth : Int,
) -> Result[@paint.Paint, ColorError] {
  if depth <= 0 {
    return Err(InvalidFormat)
  }
  let format = read_u8_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      match format {
        1 => {
          let num_layers = read_u8_int(data, offset + 1)
          let first_layer_index = read_u32_int(data, offset + 2)
          match (num_layers, first_layer_index) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(num_layers), Ok(first_layer_index)) =>
              Ok(@paint.Paint::ColrLayers(first_layer_index, num_layers))
          }
        }
        2 | 3 => {
          let palette_index = read_u16_int(data, offset + 1)
          let alpha = read_i16(data, offset + 3)
          match (palette_index, alpha) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(palette_index), Ok(alpha)) => {
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 3 {
                let var_idx = read_u32(data, offset + 5)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::Solid(palette_index, alpha, var_idx_base))
            }
          }
        }
        4 | 5 => {
          let color_line_offset = read_u24_int(data, offset + 1)
          let x0 = read_i16(data, offset + 4)
          let y0 = read_i16(data, offset + 6)
          let x1 = read_i16(data, offset + 8)
          let y1 = read_i16(data, offset + 10)
          let x2 = read_i16(data, offset + 12)
          let y2 = read_i16(data, offset + 14)
          match (color_line_offset, x0, y0, x1, y1, x2, y2) {
            (Err(err), _, _, _, _, _, _) => Err(err)
            (_, Err(err), _, _, _, _, _) => Err(err)
            (_, _, Err(err), _, _, _, _) => Err(err)
            (_, _, _, Err(err), _, _, _) => Err(err)
            (_, _, _, _, Err(err), _, _) => Err(err)
            (_, _, _, _, _, Err(err), _) => Err(err)
            (_, _, _, _, _, _, Err(err)) => Err(err)
            (Ok(color_line_offset), Ok(x0), Ok(y0), Ok(x1), Ok(y1), Ok(x2), Ok(y2)) => {
              let line_offset = match resolve_offset(offset, color_line_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let color_line = parse_color_line(data, line_offset, format == 5)
              let color_line = match color_line {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 5 {
                let var_idx = read_u32(data, offset + 16)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::LinearGradient(
                color_line,
                x0,
                y0,
                x1,
                y1,
                x2,
                y2,
                var_idx_base,
              ))
            }
          }
        }
        6 | 7 => {
          let color_line_offset = read_u24_int(data, offset + 1)
          let x0 = read_i16(data, offset + 4)
          let y0 = read_i16(data, offset + 6)
          let r0 = read_u16_int(data, offset + 8)
          let x1 = read_i16(data, offset + 10)
          let y1 = read_i16(data, offset + 12)
          let r1 = read_u16_int(data, offset + 14)
          match (color_line_offset, x0, y0, r0, x1, y1, r1) {
            (Err(err), _, _, _, _, _, _) => Err(err)
            (_, Err(err), _, _, _, _, _) => Err(err)
            (_, _, Err(err), _, _, _, _) => Err(err)
            (_, _, _, Err(err), _, _, _) => Err(err)
            (_, _, _, _, Err(err), _, _) => Err(err)
            (_, _, _, _, _, Err(err), _) => Err(err)
            (_, _, _, _, _, _, Err(err)) => Err(err)
            (Ok(color_line_offset), Ok(x0), Ok(y0), Ok(r0), Ok(x1), Ok(y1), Ok(r1)) => {
              let line_offset = match resolve_offset(offset, color_line_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let color_line = parse_color_line(data, line_offset, format == 7)
              let color_line = match color_line {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 7 {
                let var_idx = read_u32(data, offset + 16)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::RadialGradient(
                color_line,
                x0,
                y0,
                r0,
                x1,
                y1,
                r1,
                var_idx_base,
              ))
            }
          }
        }
        8 | 9 => {
          let color_line_offset = read_u24_int(data, offset + 1)
          let center_x = read_i16(data, offset + 4)
          let center_y = read_i16(data, offset + 6)
          let start_angle = read_i16(data, offset + 8)
          let end_angle = read_i16(data, offset + 10)
          match (color_line_offset, center_x, center_y, start_angle, end_angle) {
            (Err(err), _, _, _, _) => Err(err)
            (_, Err(err), _, _, _) => Err(err)
            (_, _, Err(err), _, _) => Err(err)
            (_, _, _, Err(err), _) => Err(err)
            (_, _, _, _, Err(err)) => Err(err)
            (Ok(color_line_offset), Ok(center_x), Ok(center_y), Ok(start_angle), Ok(end_angle)) => {
              let line_offset = match resolve_offset(offset, color_line_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let color_line = parse_color_line(data, line_offset, format == 9)
              let color_line = match color_line {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 9 {
                let var_idx = read_u32(data, offset + 12)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::SweepGradient(
                color_line,
                center_x,
                center_y,
                start_angle,
                end_angle,
                var_idx_base,
              ))
            }
          }
        }
        10 => {
          let paint_offset = read_u24_int(data, offset + 1)
          let glyph_id = read_u16_int(data, offset + 4)
          match (paint_offset, glyph_id) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(paint_offset), Ok(glyph_id)) => {
              let child_offset = match resolve_offset(offset, paint_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let child = parse_paint(data, child_offset, depth - 1)
              match child {
                Err(err) => Err(err)
                Ok(child) => Ok(@paint.Paint::Glyph(glyph_id, child))
              }
            }
          }
        }
        11 => {
          let glyph_id = read_u16_int(data, offset + 1)
          match glyph_id {
            Err(err) => Err(err)
            Ok(glyph_id) => Ok(@paint.Paint::ColrGlyph(glyph_id))
          }
        }
        12 | 13 => {
          let src_offset = read_u24_int(data, offset + 1)
          let transform_offset = read_u24_int(data, offset + 4)
          match (src_offset, transform_offset) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(src_offset), Ok(transform_offset)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let transform_abs = match resolve_offset(offset, transform_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let transform = parse_affine(data, transform_abs, format == 13)
              let transform = match transform {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              Ok(@paint.Paint::Transform(transform, src))
            }
          }
        }
        14 | 15 => {
          let src_offset = read_u24_int(data, offset + 1)
          let dx = read_i16(data, offset + 4)
          let dy = read_i16(data, offset + 6)
          match (src_offset, dx, dy) {
            (Err(err), _, _) => Err(err)
            (_, Err(err), _) => Err(err)
            (_, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(dx), Ok(dy)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 15 {
                let var_idx = read_u32(data, offset + 8)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::Translate(dx, dy, var_idx_base, src))
            }
          }
        }
        16 | 17 => {
          let src_offset = read_u24_int(data, offset + 1)
          let scale_x = read_i16(data, offset + 4)
          let scale_y = read_i16(data, offset + 6)
          match (src_offset, scale_x, scale_y) {
            (Err(err), _, _) => Err(err)
            (_, Err(err), _) => Err(err)
            (_, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(scale_x), Ok(scale_y)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 17 {
                let var_idx = read_u32(data, offset + 8)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::Scale(scale_x, scale_y, var_idx_base, src))
            }
          }
        }
        18 | 19 => {
          let src_offset = read_u24_int(data, offset + 1)
          let scale_x = read_i16(data, offset + 4)
          let scale_y = read_i16(data, offset + 6)
          let center_x = read_i16(data, offset + 8)
          let center_y = read_i16(data, offset + 10)
          match (src_offset, scale_x, scale_y, center_x, center_y) {
            (Err(err), _, _, _, _) => Err(err)
            (_, Err(err), _, _, _) => Err(err)
            (_, _, Err(err), _, _) => Err(err)
            (_, _, _, Err(err), _) => Err(err)
            (_, _, _, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(scale_x), Ok(scale_y), Ok(center_x), Ok(center_y)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 19 {
                let var_idx = read_u32(data, offset + 12)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::ScaleAroundCenter(
                scale_x,
                scale_y,
                center_x,
                center_y,
                var_idx_base,
                src,
              ))
            }
          }
        }
        20 | 21 => {
          let src_offset = read_u24_int(data, offset + 1)
          let scale = read_i16(data, offset + 4)
          match (src_offset, scale) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(src_offset), Ok(scale)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 21 {
                let var_idx = read_u32(data, offset + 6)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::ScaleUniform(scale, var_idx_base, src))
            }
          }
        }
        22 | 23 => {
          let src_offset = read_u24_int(data, offset + 1)
          let scale = read_i16(data, offset + 4)
          let center_x = read_i16(data, offset + 6)
          let center_y = read_i16(data, offset + 8)
          match (src_offset, scale, center_x, center_y) {
            (Err(err), _, _, _) => Err(err)
            (_, Err(err), _, _) => Err(err)
            (_, _, Err(err), _) => Err(err)
            (_, _, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(scale), Ok(center_x), Ok(center_y)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 23 {
                let var_idx = read_u32(data, offset + 10)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::ScaleUniformAroundCenter(
                scale,
                center_x,
                center_y,
                var_idx_base,
                src,
              ))
            }
          }
        }
        24 | 25 => {
          let src_offset = read_u24_int(data, offset + 1)
          let angle = read_i16(data, offset + 4)
          match (src_offset, angle) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(src_offset), Ok(angle)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 25 {
                let var_idx = read_u32(data, offset + 6)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::Rotate(angle, var_idx_base, src))
            }
          }
        }
        26 | 27 => {
          let src_offset = read_u24_int(data, offset + 1)
          let angle = read_i16(data, offset + 4)
          let center_x = read_i16(data, offset + 6)
          let center_y = read_i16(data, offset + 8)
          match (src_offset, angle, center_x, center_y) {
            (Err(err), _, _, _) => Err(err)
            (_, Err(err), _, _) => Err(err)
            (_, _, Err(err), _) => Err(err)
            (_, _, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(angle), Ok(center_x), Ok(center_y)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 27 {
                let var_idx = read_u32(data, offset + 10)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::RotateAroundCenter(
                angle,
                center_x,
                center_y,
                var_idx_base,
                src,
              ))
            }
          }
        }
        28 | 29 => {
          let src_offset = read_u24_int(data, offset + 1)
          let x_skew = read_i16(data, offset + 4)
          let y_skew = read_i16(data, offset + 6)
          match (src_offset, x_skew, y_skew) {
            (Err(err), _, _) => Err(err)
            (_, Err(err), _) => Err(err)
            (_, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(x_skew), Ok(y_skew)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 29 {
                let var_idx = read_u32(data, offset + 8)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::Skew(x_skew, y_skew, var_idx_base, src))
            }
          }
        }
        30 | 31 => {
          let src_offset = read_u24_int(data, offset + 1)
          let x_skew = read_i16(data, offset + 4)
          let y_skew = read_i16(data, offset + 6)
          let center_x = read_i16(data, offset + 8)
          let center_y = read_i16(data, offset + 10)
          match (src_offset, x_skew, y_skew, center_x, center_y) {
            (Err(err), _, _, _, _) => Err(err)
            (_, Err(err), _, _, _) => Err(err)
            (_, _, Err(err), _, _) => Err(err)
            (_, _, _, Err(err), _) => Err(err)
            (_, _, _, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(x_skew), Ok(y_skew), Ok(center_x), Ok(center_y)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let mut var_idx_base : @paint.VarIdx? = None
              if format == 31 {
                let var_idx = read_u32(data, offset + 12)
                match var_idx {
                  Err(err) => return Err(err)
                  Ok(value) => var_idx_base = Some(value)
                }
              }
              Ok(@paint.Paint::SkewAroundCenter(
                x_skew,
                y_skew,
                center_x,
                center_y,
                var_idx_base,
                src,
              ))
            }
          }
        }
        32 => {
          let src_offset = read_u24_int(data, offset + 1)
          let mode = read_u8_int(data, offset + 4)
          let backdrop_offset = read_u24_int(data, offset + 5)
          match (src_offset, mode, backdrop_offset) {
            (Err(err), _, _) => Err(err)
            (_, Err(err), _) => Err(err)
            (_, _, Err(err)) => Err(err)
            (Ok(src_offset), Ok(mode), Ok(backdrop_offset)) => {
              let src_abs = match resolve_offset(offset, src_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let backdrop_abs = match resolve_offset(offset, backdrop_offset, data) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let src = parse_paint(data, src_abs, depth - 1)
              let src = match src {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              let backdrop = parse_paint(data, backdrop_abs, depth - 1)
              match backdrop {
                Err(err) => Err(err)
                Ok(backdrop) => Ok(@paint.Paint::Composite(mode, src, backdrop))
              }
            }
          }
        }
        _ => Err(InvalidFormat)
      }
  }
}

fn parse_paint_root(
  data : BytesView,
  offset : Int,
) -> Result[@paint.Paint, ColorError] {
  parse_paint(data, offset, max_paint_depth)
}
