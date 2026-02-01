///|
pub struct VarcTransform {
  translate_x : Double
  translate_y : Double
  rotation : Double
  scale_x : Double
  scale_y : Double
  skew_x : Double
  skew_y : Double
  tcenter_x : Double
  tcenter_y : Double
} derive(Show, ToJson)

///|
pub fn VarcTransform::apply_to_point(
  self : VarcTransform,
  x : Double,
  y : Double,
) -> (Double, Double) {
  let mut px = x + self.translate_x + self.tcenter_x
  let mut py = y + self.translate_y + self.tcenter_y
  if self.rotation != 0.0 {
    let c = @math.cos(self.rotation)
    let s = @math.sin(self.rotation)
    let rx = px * c - py * s
    let ry = px * s + py * c
    px = rx
    py = ry
  }
  px = px * self.scale_x
  py = py * self.scale_y
  if self.skew_x != 0.0 || self.skew_y != 0.0 {
    let skew_x = if self.skew_x == 0.0 { 0.0 } else { @math.tan(-self.skew_x) }
    let skew_y = if self.skew_y == 0.0 { 0.0 } else { @math.tan(self.skew_y) }
    let sx = px + skew_x * py
    let sy = skew_y * px + py
    px = sx
    py = sy
  }
  px = px - self.tcenter_x
  py = py - self.tcenter_y
  (px, py)
}

///|
pub fn VarcTransform::apply_to_bounds(
  self : VarcTransform,
  x_min : Double,
  y_min : Double,
  x_max : Double,
  y_max : Double,
) -> (Double, Double, Double, Double) {
  let (x0, y0) = self.apply_to_point(x_min, y_min)
  let (x1, y1) = self.apply_to_point(x_min, y_max)
  let (x2, y2) = self.apply_to_point(x_max, y_min)
  let (x3, y3) = self.apply_to_point(x_max, y_max)
  let min_x = min4(x0, x1, x2, x3)
  let max_x = max4(x0, x1, x2, x3)
  let min_y = min4(y0, y1, y2, y3)
  let max_y = max4(y0, y1, y2, y3)
  (min_x, min_y, max_x, max_y)
}

fn min4(a : Double, b : Double, c : Double, d : Double) -> Double {
  let ab = if a < b { a } else { b }
  let cd = if c < d { c } else { d }
  if ab < cd { ab } else { cd }
}

fn max4(a : Double, b : Double, c : Double, d : Double) -> Double {
  let ab = if a > b { a } else { b }
  let cd = if c > d { c } else { d }
  if ab > cd { ab } else { cd }
}

///|
pub struct VarcComponent {
  glyph : Int
  visible : Bool
  axis_indices : Array[Int]
  axis_values : Array[Double]
  coords : Array[Int]
  transform : VarcTransform
} derive(Show, ToJson)

priv struct VarcTransformRaw {
  mut translate_x : Double?
  mut translate_y : Double?
  mut rotation : Double?
  mut scale_x : Double?
  mut scale_y : Double?
  mut skew_x : Double?
  mut skew_y : Double?
  mut tcenter_x : Double?
  mut tcenter_y : Double?
}

let varc_flag_reset_unspecified_axes : UInt = 1U << 0
let varc_flag_have_axes : UInt = 1U << 1
let varc_flag_axis_values_have_variation : UInt = 1U << 2
let varc_flag_transform_has_variation : UInt = 1U << 3
let varc_flag_have_translate_x : UInt = 1U << 4
let varc_flag_have_translate_y : UInt = 1U << 5
let varc_flag_have_rotation : UInt = 1U << 6
let varc_flag_have_condition : UInt = 1U << 7
let varc_flag_have_scale_x : UInt = 1U << 8
let varc_flag_have_scale_y : UInt = 1U << 9
let varc_flag_have_tcenter_x : UInt = 1U << 10
let varc_flag_have_tcenter_y : UInt = 1U << 11
let varc_flag_gid_is_24bit : UInt = 1U << 12
let varc_flag_have_skew_x : UInt = 1U << 13
let varc_flag_have_skew_y : UInt = 1U << 14
let varc_flag_reserved_mask : UInt = 0xFFFF8000U
let varc_no_variation : UInt = 0xFFFFFFFFU
let varc_max_axes : Int = 4096
let varc_pi : Double = 3.141592653589793

fn option_or(value : Double?, default_value : Double) -> Double {
  match value {
    None => default_value
    Some(v) => v
  }
}

fn read_glyph_id_24(data : BytesView, offset : Int) -> Result[Int, VarError] {
  if offset < 0 || offset + 3 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  let b2 = data[offset + 2].to_int()
  Ok((b0 << 16) | (b1 << 8) | b2)
}

fn apply_axis_overrides(
  base_coords : Array[Int],
  axis_indices : Array[Int],
  axis_values : Array[Double],
) -> Array[Int] {
  let coords = base_coords.copy()
  let count = if axis_indices.length() < axis_values.length() {
    axis_indices.length()
  } else {
    axis_values.length()
  }
  for i in 0..<count {
    let axis_index = axis_indices[i]
    if axis_index < 0 || axis_index >= varc_max_axes {
      continue
    }
    while coords.length() <= axis_index {
      coords.push(0)
    }
    coords[axis_index] = axis_values[i].to_int()
  }
  coords
}

fn finalize_value(raw : Double, mult : Double, divisor : Double) -> Double {
  (raw * mult).round() / divisor
}

fn finalize_transform(flags : UInt, raw : VarcTransformRaw) -> VarcTransform {
  let mut translate_x = 0.0
  let mut translate_y = 0.0
  let mut rotation = 0.0
  let mut scale_x = 1.0
  let mut scale_y = 1.0
  let mut skew_x = 0.0
  let mut skew_y = 0.0
  let mut tcenter_x = 0.0
  let mut tcenter_y = 0.0

  match raw.translate_x {
    Some(value) => translate_x = finalize_value(value, 1.0, 1.0)
    None => ()
  }
  match raw.translate_y {
    Some(value) => translate_y = finalize_value(value, 1.0, 1.0)
    None => ()
  }
  match raw.rotation {
    Some(value) => rotation = finalize_value(value, varc_pi, 4096.0)
    None => ()
  }
  match raw.scale_x {
    Some(value) => scale_x = finalize_value(value, 1.0, 1024.0)
    None => ()
  }
  match raw.scale_y {
    Some(value) => scale_y = finalize_value(value, 1.0, 1024.0)
    None => ()
  }
  match raw.skew_x {
    Some(value) => skew_x = finalize_value(value, varc_pi, 4096.0)
    None => ()
  }
  match raw.skew_y {
    Some(value) => skew_y = finalize_value(value, varc_pi, 4096.0)
    None => ()
  }
  match raw.tcenter_x {
    Some(value) => tcenter_x = finalize_value(value, 1.0, 1.0)
    None => ()
  }
  match raw.tcenter_y {
    Some(value) => tcenter_y = finalize_value(value, 1.0, 1.0)
    None => ()
  }

  if (flags & varc_flag_have_scale_y) == 0U {
    scale_y = scale_x
  }

  VarcTransform::{
    translate_x,
    translate_y,
    rotation,
    scale_x,
    scale_y,
    skew_x,
    skew_y,
    tcenter_x,
    tcenter_y,
  }
}

fn parse_component(
  data : BytesView,
  offset : Int,
  coords : Array[Int],
  base_coords : Array[Int],
  varc : VarcTable,
  var_store : MultiItemVariationStore?,
  conditions : Array[VarcCondition],
) -> Result[(VarcComponent, Int), VarError] {
  let (flags, size) = match read_u32var(data, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mut pos = offset + size

  let glyph = if (flags & varc_flag_gid_is_24bit) != 0U {
    let glyph = match read_glyph_id_24(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 3
    glyph
  } else {
    let glyph = match read_u16_int(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    glyph
  }

  let mut show = true
  if (flags & varc_flag_have_condition) != 0U {
    let (condition_index, cond_size) = match read_u32var(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + cond_size
    let cond_idx = condition_index.reinterpret_as_int()
    if cond_idx < 0 || cond_idx >= conditions.length() {
      return Err(InvalidFormat)
    }
    let var_delta = match var_store {
      None => None
      Some(store) => Some((var_idx : Int) => {
        let var_idx_u = var_idx.reinterpret_as_uint()
        if var_idx_u == varc_no_variation {
          return 0.0
        }
        let out : Array[Double] = [0.0]
        store.get_delta(var_idx_u, coords, out)
        out[0]
      })
    }
    show = conditions[cond_idx].evaluate(coords, var_delta)
  }

  let mut axis_indices : Array[Int] = []
  let axis_values : Array[Double] = []
  if (flags & varc_flag_have_axes) != 0U {
    let (axis_index, axis_size) = match read_u32var(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + axis_size
    axis_indices = match varc.axis_indices(axis_index.reinterpret_as_int()) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let (values, consumed) = match decode_tuple_values_count(data[pos:], axis_indices.length()) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + consumed
    for value in values {
      axis_values.push(value.to_double())
    }
  }

  if (flags & varc_flag_axis_values_have_variation) != 0U {
    let (var_idx, var_size) = match read_u32var(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + var_size
    if show && axis_values.length() > 0 {
      match var_store {
        None => ()
        Some(store) =>
          if var_idx != varc_no_variation {
            store.get_delta(var_idx, coords, axis_values)
          }
      }
    }
  }

  let mut transform_var_idx : UInt? = None
  if (flags & varc_flag_transform_has_variation) != 0U {
    let (var_idx, var_size) = match read_u32var(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + var_size
    transform_var_idx = Some(var_idx)
  }

  let transform_raw = VarcTransformRaw::{
    translate_x: None,
    translate_y: None,
    rotation: None,
    scale_x: None,
    scale_y: None,
    skew_x: None,
    skew_y: None,
    tcenter_x: None,
    tcenter_y: None,
  }

  if (flags & varc_flag_have_translate_x) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.translate_x = Some(value.to_double())
  }
  if (flags & varc_flag_have_translate_y) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.translate_y = Some(value.to_double())
  }
  if (flags & varc_flag_have_rotation) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.rotation = Some(value.to_double())
  }
  if (flags & varc_flag_have_scale_x) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.scale_x = Some(value.to_double())
  }
  if (flags & varc_flag_have_scale_y) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.scale_y = Some(value.to_double())
  }
  if (flags & varc_flag_have_skew_x) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.skew_x = Some(value.to_double())
  }
  if (flags & varc_flag_have_skew_y) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.skew_y = Some(value.to_double())
  }
  if (flags & varc_flag_have_tcenter_x) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.tcenter_x = Some(value.to_double())
  }
  if (flags & varc_flag_have_tcenter_y) != 0U {
    let value = match read_i16(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2
    transform_raw.tcenter_y = Some(value.to_double())
  }

  let mut reserved = flags & varc_flag_reserved_mask
  while reserved != 0U {
    let (_, discard_size) = match read_u32var(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + discard_size
    reserved = reserved & (reserved - 1U)
  }

  if show {
  let transform_values : Array[Double] = []
    if (flags & varc_flag_have_translate_x) != 0U {
      transform_values.push(option_or(transform_raw.translate_x, 0.0))
    }
    if (flags & varc_flag_have_translate_y) != 0U {
      transform_values.push(option_or(transform_raw.translate_y, 0.0))
    }
    if (flags & varc_flag_have_rotation) != 0U {
      transform_values.push(option_or(transform_raw.rotation, 0.0))
    }
    if (flags & varc_flag_have_scale_x) != 0U {
      transform_values.push(option_or(transform_raw.scale_x, 0.0))
    }
    if (flags & varc_flag_have_scale_y) != 0U {
      transform_values.push(option_or(transform_raw.scale_y, 0.0))
    }
    if (flags & varc_flag_have_skew_x) != 0U {
      transform_values.push(option_or(transform_raw.skew_x, 0.0))
    }
    if (flags & varc_flag_have_skew_y) != 0U {
      transform_values.push(option_or(transform_raw.skew_y, 0.0))
    }
    if (flags & varc_flag_have_tcenter_x) != 0U {
      transform_values.push(option_or(transform_raw.tcenter_x, 0.0))
    }
    if (flags & varc_flag_have_tcenter_y) != 0U {
      transform_values.push(option_or(transform_raw.tcenter_y, 0.0))
    }

    match (transform_var_idx, var_store) {
      (Some(var_idx), Some(store)) =>
        if var_idx != varc_no_variation && transform_values.length() > 0 {
          store.get_delta(var_idx, coords, transform_values)
        }
      _ => ()
    }

    let mut index = 0
    if (flags & varc_flag_have_translate_x) != 0U {
      transform_raw.translate_x = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_translate_y) != 0U {
      transform_raw.translate_y = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_rotation) != 0U {
      transform_raw.rotation = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_scale_x) != 0U {
      transform_raw.scale_x = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_scale_y) != 0U {
      transform_raw.scale_y = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_skew_x) != 0U {
      transform_raw.skew_x = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_skew_y) != 0U {
      transform_raw.skew_y = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_tcenter_x) != 0U {
      transform_raw.tcenter_x = Some(transform_values[index]);
      index = index + 1
    }
    if (flags & varc_flag_have_tcenter_y) != 0U {
      transform_raw.tcenter_y = Some(transform_values[index]);
      index = index + 1
    }
  }

  let mut component_coords = if (flags & varc_flag_reset_unspecified_axes) != 0U || coords.length() > varc_max_axes {
    base_coords.copy()
  } else {
    coords.copy()
  }
  if axis_indices.length() > 0 {
    component_coords = apply_axis_overrides(component_coords, axis_indices, axis_values)
  }

  let transform = finalize_transform(flags, transform_raw)

  let component = VarcComponent::{
    glyph,
    visible: show,
    axis_indices,
    axis_values,
    coords: component_coords,
    transform,
  }

  Ok((component, pos))
}

///|
pub fn VarcTable::glyph_components(
  self : VarcTable,
  glyph : Int,
  coords : Array[Int],
  base_coords : Array[Int],
) -> Result[Array[VarcComponent], VarError] {
  let record = match self.glyph_record(glyph) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match record {
    None => Ok([])
    Some(bytes) => {
      let var_store = match self.var_store() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let conditions = match self.conditions() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let data = bytes[:]
      let components : Array[VarcComponent] = []
      let mut pos = 0
      while pos < data.length() {
        let (component, next_pos) = match parse_component(
          data,
          pos,
          coords,
          base_coords,
          self,
          var_store,
          conditions,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        components.push(component)
        if next_pos <= pos {
          return Err(InvalidFormat)
        }
        pos = next_pos
      }
      Ok(components)
    }
  }
}
