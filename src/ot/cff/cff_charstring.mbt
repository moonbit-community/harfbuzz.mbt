///|
pub struct CffBounds {
  x_min : Double
  y_min : Double
  x_max : Double
  y_max : Double
} derive(Eq, Show, ToJson)

priv struct CffBoundsBuilder {
  mut has_bounds : Bool
  mut min_x : Double
  mut min_y : Double
  mut max_x : Double
  mut max_y : Double
}

fn CffBoundsBuilder::new() -> CffBoundsBuilder {
  CffBoundsBuilder::{
    has_bounds: false,
    min_x: 0.0,
    min_y: 0.0,
    max_x: 0.0,
    max_y: 0.0,
  }
}

fn CffBoundsBuilder::update(self : CffBoundsBuilder, x : Double, y : Double) -> Unit {
  if !self.has_bounds {
    self.has_bounds = true
    self.min_x = x
    self.max_x = x
    self.min_y = y
    self.max_y = y
    return
  }
  if x < self.min_x {
    self.min_x = x
  }
  if x > self.max_x {
    self.max_x = x
  }
  if y < self.min_y {
    self.min_y = y
  }
  if y > self.max_y {
    self.max_y = y
  }
}

fn CffBoundsBuilder::merge(self : CffBoundsBuilder, bounds : CffBounds) -> Unit {
  self.update(bounds.x_min, bounds.y_min)
  self.update(bounds.x_max, bounds.y_max)
}

fn CffBoundsBuilder::result(self : CffBoundsBuilder) -> CffBounds? {
  if !self.has_bounds {
    return None
  }
  Some(CffBounds::{
    x_min: self.min_x,
    y_min: self.min_y,
    x_max: self.max_x,
    y_max: self.max_y,
  })
}

priv struct CffPoint {
  x : Double
  y : Double
}

fn CffPoint::offset(self : CffPoint, dx : Double, dy : Double) -> CffPoint {
  CffPoint::{ x: self.x + dx, y: self.y + dy }
}

fn CffPoint::offset_x(self : CffPoint, dx : Double) -> CffPoint {
  CffPoint::{ x: self.x + dx, y: self.y }
}

fn CffPoint::offset_y(self : CffPoint, dy : Double) -> CffPoint {
  CffPoint::{ x: self.x, y: self.y + dy }
}

priv struct CffCharstringState {
  mut x : Double
  mut y : Double
  mut has_width : Bool
  mut stem_count : Int
  bounds : CffBoundsBuilder
}

fn CffCharstringState::new() -> CffCharstringState {
  CffCharstringState::{
    x: 0.0,
    y: 0.0,
    has_width: false,
    stem_count: 0,
    bounds: CffBoundsBuilder::new(),
  }
}

fn CffCharstringState::current_point(self : CffCharstringState) -> CffPoint {
  CffPoint::{ x: self.x, y: self.y }
}

fn CffCharstringState::moveto(self : CffCharstringState, pt : CffPoint) -> Unit {
  self.x = pt.x
  self.y = pt.y
  self.bounds.update(pt.x, pt.y)
}

fn CffCharstringState::line_to(self : CffCharstringState, pt : CffPoint) -> Unit {
  self.bounds.update(pt.x, pt.y)
  self.x = pt.x
  self.y = pt.y
}

fn CffCharstringState::curve_to(
  self : CffCharstringState,
  pt1 : CffPoint,
  pt2 : CffPoint,
  pt3 : CffPoint,
) -> Unit {
  self.bounds.update(pt1.x, pt1.y)
  self.bounds.update(pt2.x, pt2.y)
  self.bounds.update(pt3.x, pt3.y)
  self.x = pt3.x
  self.y = pt3.y
}

priv struct Cff1SeacContext {
  charstrings : CffIndex
  charset_offset : Int
  charset_map : Map[Int, Int]?
  glyph_count : Int
}

fn Cff1SeacContext::sid_to_gid(self : Cff1SeacContext, sid : Int) -> Int? {
  cff1_sid_to_gid(self.charset_offset, self.charset_map, sid, self.glyph_count)
}

priv struct Cff2BlendState {
  mut ivs : Int
  mut seen_vsindex : Bool
  mut seen_blend : Bool
  var_store : @ot_var.ItemVariationStore?
  coords : Array[Int]
}

fn Cff2BlendState::new(
  var_store : @ot_var.ItemVariationStore?,
  ivs : Int,
  coords : Array[Int],
) -> Cff2BlendState {
  Cff2BlendState::{
    ivs,
    seen_vsindex: false,
    seen_blend: false,
    var_store,
    coords,
  }
}

fn Cff2BlendState::region_count(self : Cff2BlendState) -> Result[Int, CffError] {
  let store = match self.var_store {
    None => return Err(InvalidFormat)
    Some(value) => value
  }
  match store.region_count(self.ivs) {
    None => Err(InvalidFormat)
    Some(value) => Ok(value)
  }
}

fn Cff2BlendState::region_scalars(self : Cff2BlendState) -> Result[Array[Double]?, CffError] {
  if self.coords.is_empty() {
    return Ok(None)
  }
  let store = match self.var_store {
    None => return Err(InvalidFormat)
    Some(value) => value
  }
  match store.region_scalars(self.ivs, self.coords) {
    None => Err(InvalidFormat)
    Some(values) => Ok(Some(values))
  }
}

///|
pub fn cff_charstring_bounds(
  data : BytesView,
  global_subrs : CffIndex?,
  local_subrs : CffIndex?,
) -> Result[CffBounds?, CffError] {
  let state = CffCharstringState::new()
  match interpret_charstring(data, state, global_subrs, local_subrs, 0, false, None, false) {
    Err(err) => Err(err)
    Ok(_) => Ok(state.bounds.result())
  }
}

fn cff1_charstring_bounds(
  data : BytesView,
  global_subrs : CffIndex?,
  local_subrs : CffIndex?,
  seac : Cff1SeacContext,
) -> Result[CffBounds?, CffError] {
  let state = CffCharstringState::new()
  match interpret_charstring(
    data,
    state,
    global_subrs,
    local_subrs,
    0,
    false,
    Some(seac),
    false,
  ) {
    Err(err) => Err(err)
    Ok(_) => Ok(state.bounds.result())
  }
}

///|
pub fn cff2_charstring_bounds(
  data : BytesView,
  global_subrs : CffIndex?,
  local_subrs : CffIndex?,
  var_store : @ot_var.ItemVariationStore?,
  ivs : Int,
  coords : Array[Int],
) -> Result[CffBounds?, CffError] {
  let state = CffCharstringState::new()
  let blend_state = Cff2BlendState::new(var_store, ivs, coords)
  match interpret_charstring_cff2(
    data,
    state,
    blend_state,
    global_subrs,
    local_subrs,
    0,
    false,
  ) {
    Err(err) => Err(err)
    Ok(_) => Ok(state.bounds.result())
  }
}

fn subr_bias(count : Int) -> Int {
  if count < 1240 {
    107
  } else if count < 33900 {
    1131
  } else {
    32768
  }
}

fn interpret_charstring(
  data : BytesView,
  state : CffCharstringState,
  global_subrs : CffIndex?,
  local_subrs : CffIndex?,
  depth : Int,
  allow_return : Bool,
  seac : Cff1SeacContext?,
  in_seac : Bool,
) -> Result[Unit, CffError] {
  if depth > 16 {
    return Err(InvalidFormat)
  }
  let mut pos = 0
  let mut stack : Array[Double] = []
  while pos < data.length() {
    let b0 = data[pos].to_int()
    if b0 >= 32 || b0 == 28 || b0 == 255 {
      let parsed = parse_charstring_number(data, pos)
      match parsed {
        Err(err) => return Err(err)
        Ok((value, next_pos)) => {
          stack.push(value)
          pos = next_pos
          continue
        }
      }
    }
    match b0 {
      1 | 3 | 18 | 23 => {
        let offset = width_offset(state, stack)
        let count = stack.length() - offset
        if count < 0 || (count % 2) != 0 {
          return Err(InvalidFormat)
        }
        state.stem_count = state.stem_count + (count / 2)
        stack = []
        pos = pos + 1
      }
      19 | 20 => {
        let offset = width_offset(state, stack)
        let count = stack.length() - offset
        if count < 0 || (count % 2) != 0 {
          return Err(InvalidFormat)
        }
        state.stem_count = state.stem_count + (count / 2)
        stack = []
        pos = pos + 1
        let mask_bytes = (state.stem_count + 7) / 8
        if pos + mask_bytes > data.length() {
          return Err(UnexpectedEof)
        }
        pos = pos + mask_bytes
      }
      4 => {
        let offset = width_offset(state, stack)
        if stack.length() - offset < 1 {
          return Err(InvalidFormat)
        }
        let dy = stack[offset]
          let pt = state.current_point().offset(0.0, dy)
        state.moveto(pt)
        stack = []
        pos = pos + 1
      }
      5 => {
        if (stack.length() % 2) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        while i + 1 < stack.length() {
          let dx = stack[i]
          let dy = stack[i + 1]
          let pt = state.current_point().offset(dx, dy)
          state.line_to(pt)
          i = i + 2
        }
        stack = []
        pos = pos + 1
      }
      6 | 7 => {
        let mut horizontal = b0 == 6
        for value in stack {
          let pt =
            if horizontal {
              state.current_point().offset(value, 0.0)
            } else {
              state.current_point().offset(0.0, value)
            }
          state.line_to(pt)
          horizontal = !horizontal
        }
        stack = []
        pos = pos + 1
      }
      8 => {
        if (stack.length() % 6) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        while i + 5 < stack.length() {
          let pt1 = state.current_point().offset(stack[i], stack[i + 1])
          let pt2 = pt1.offset(stack[i + 2], stack[i + 3])
          let pt3 = pt2.offset(stack[i + 4], stack[i + 5])
          state.curve_to(pt1, pt2, pt3)
          i = i + 6
        }
        stack = []
        pos = pos + 1
      }
      10 => {
        if stack.is_empty() {
          return Err(InvalidFormat)
        }
        let subr_index = stack[stack.length() - 1].round().to_int()
        stack = []
        let local_subrs_value = match local_subrs {
          None => return Err(InvalidFormat)
          Some(value) => value
        }
        let bias = subr_bias(local_subrs_value.count)
        let idx = subr_index + bias
        let bytes = match local_subrs_value.item_bytes(idx) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        match interpret_charstring(
          bytes[:],
          state,
          global_subrs,
          local_subrs,
          depth + 1,
          true,
          seac,
          in_seac,
        ) {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        pos = pos + 1
      }
      11 => {
        if allow_return {
          return Ok(())
        }
        return Err(InvalidFormat)
      }
      12 => {
        if pos + 1 >= data.length() {
          return Err(UnexpectedEof)
        }
        let op = data[pos + 1].to_int()
        let err = match op {
          0 => Ok(())
          34 => handle_hflex(state, stack)
          35 => handle_flex(state, stack)
          36 => handle_hflex1(state, stack)
          37 => handle_flex1(state, stack)
          _ => Err(InvalidFormat)
        }
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 2
      }
      14 => {
        let offset = width_offset(state, stack)
        let count = stack.length() - offset
        if count >= 4 {
          let seac_context = match seac {
            None => return Err(InvalidFormat)
            Some(value) => value
          }
          if in_seac {
            return Err(InvalidFormat)
          }
          let base_index = offset + count - 4
          let adx = stack[base_index]
          let ady = stack[base_index + 1]
          let bchar = stack[base_index + 2].round().to_int()
          let achar = stack[base_index + 3].round().to_int()
          let base_sid = match cff1_standard_sid(bchar) {
            None => return Err(InvalidFormat)
            Some(value) => value
          }
          let accent_sid = match cff1_standard_sid(achar) {
            None => return Err(InvalidFormat)
            Some(value) => value
          }
          let base_gid = match seac_context.sid_to_gid(base_sid) {
            None => return Err(InvalidFormat)
            Some(value) => value
          }
          let accent_gid = match seac_context.sid_to_gid(accent_sid) {
            None => return Err(InvalidFormat)
            Some(value) => value
          }
          let base_bytes = match seac_context.charstrings.item_bytes(base_gid) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let accent_bytes = match seac_context.charstrings.item_bytes(accent_gid) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let base_state = CffCharstringState::new()
          match interpret_charstring(
            base_bytes[:],
            base_state,
            global_subrs,
            local_subrs,
            depth + 1,
            false,
            seac,
            true,
          ) {
            Err(err) => return Err(err)
            Ok(_) => ()
          }
          let accent_state = CffCharstringState::new()
          match interpret_charstring(
            accent_bytes[:],
            accent_state,
            global_subrs,
            local_subrs,
            depth + 1,
            false,
            seac,
            true,
          ) {
            Err(err) => return Err(err)
            Ok(_) => ()
          }
          match (base_state.bounds.result(), accent_state.bounds.result()) {
            (Some(base_bounds), Some(accent_bounds)) => {
              state.bounds.merge(base_bounds)
              state.bounds.merge(offset_bounds(accent_bounds, adx, ady))
            }
            _ => return Err(InvalidFormat)
          }
        } else if count != 0 {
          return Err(InvalidFormat)
        }
        stack = []
        pos = pos + 1
        return Ok(())
      }
      21 => {
        let offset = width_offset(state, stack)
        if stack.length() - offset < 2 {
          return Err(InvalidFormat)
        }
        let dx = stack[offset]
        let dy = stack[offset + 1]
        let pt = state.current_point().offset(dx, dy)
        state.moveto(pt)
        stack = []
        pos = pos + 1
      }
      22 => {
        let offset = width_offset(state, stack)
        if stack.length() - offset < 1 {
          return Err(InvalidFormat)
        }
        let dx = stack[offset]
        let pt = state.current_point().offset(dx, 0.0)
        state.moveto(pt)
        stack = []
        pos = pos + 1
      }
      24 => {
        if stack.length() < 8 || ((stack.length() - 2) % 6) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        let line_index = stack.length() - 2
        while i + 5 < line_index {
          let pt1 = state.current_point().offset(stack[i], stack[i + 1])
          let pt2 = pt1.offset(stack[i + 2], stack[i + 3])
          let pt3 = pt2.offset(stack[i + 4], stack[i + 5])
          state.curve_to(pt1, pt2, pt3)
          i = i + 6
        }
        let dx = stack[line_index]
        let dy = stack[line_index + 1]
        let pt = state.current_point().offset(dx, dy)
        state.line_to(pt)
        stack = []
        pos = pos + 1
      }
      25 => {
        if stack.length() < 8 || ((stack.length() - 6) % 2) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        let curve_index = stack.length() - 6
        while i + 1 < curve_index {
        let pt = state.current_point().offset(stack[i], stack[i + 1])
          state.line_to(pt)
          i = i + 2
        }
        let pt1 = state.current_point().offset(stack[curve_index], stack[curve_index + 1])
        let pt2 = pt1.offset(stack[curve_index + 2], stack[curve_index + 3])
        let pt3 = pt2.offset(stack[curve_index + 4], stack[curve_index + 5])
        state.curve_to(pt1, pt2, pt3)
        stack = []
        pos = pos + 1
      }
      26 => {
        let err = handle_vvcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      27 => {
        let err = handle_hhcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      29 => {
        if stack.is_empty() {
          return Err(InvalidFormat)
        }
        let subr_index = stack[stack.length() - 1].round().to_int()
        stack = []
        let global = match global_subrs {
          None => return Err(InvalidFormat)
          Some(value) => value
        }
        let bias = subr_bias(global.count)
        let idx = subr_index + bias
        let bytes = match global.item_bytes(idx) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        match interpret_charstring(
          bytes[:],
          state,
          global_subrs,
          local_subrs,
          depth + 1,
          true,
          seac,
          in_seac,
        ) {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        pos = pos + 1
      }
      30 => {
        let err = handle_vhcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      31 => {
        let err = handle_hvcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      _ => return Err(InvalidFormat)
    }
  }
  Ok(())
}

fn interpret_charstring_cff2(
  data : BytesView,
  state : CffCharstringState,
  blend_state : Cff2BlendState,
  global_subrs : CffIndex?,
  local_subrs : CffIndex?,
  depth : Int,
  allow_return : Bool,
) -> Result[Unit, CffError] {
  if depth > 16 {
    return Err(InvalidFormat)
  }
  let mut pos = 0
  let mut stack : Array[Double] = []
  while pos < data.length() {
    let b0 = data[pos].to_int()
    if b0 >= 32 || b0 == 28 || b0 == 255 {
      let parsed = parse_charstring_number(data, pos)
      match parsed {
        Err(err) => return Err(err)
        Ok((value, next_pos)) => {
          stack.push(value)
          pos = next_pos
          continue
        }
      }
    }
    match b0 {
      1 | 3 | 18 | 23 => {
        if (stack.length() % 2) != 0 {
          return Err(InvalidFormat)
        }
        state.stem_count = state.stem_count + (stack.length() / 2)
        stack = []
        pos = pos + 1
      }
      19 | 20 => {
        if (stack.length() % 2) != 0 {
          return Err(InvalidFormat)
        }
        state.stem_count = state.stem_count + (stack.length() / 2)
        stack = []
        pos = pos + 1
        let mask_bytes = (state.stem_count + 7) / 8
        if pos + mask_bytes > data.length() {
          return Err(UnexpectedEof)
        }
        pos = pos + mask_bytes
      }
      4 => {
        if stack.length() < 1 {
          return Err(InvalidFormat)
        }
        let dy = stack[0]
        let pt = state.current_point().offset(0.0, dy)
        state.moveto(pt)
        stack = []
        pos = pos + 1
      }
      5 => {
        if (stack.length() % 2) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        while i + 1 < stack.length() {
          let dx = stack[i]
          let dy = stack[i + 1]
          let pt = state.current_point().offset(dx, dy)
          state.line_to(pt)
          i = i + 2
        }
        stack = []
        pos = pos + 1
      }
      6 | 7 => {
        let mut horizontal = b0 == 6
        for value in stack {
          let pt =
            if horizontal {
              state.current_point().offset(value, 0.0)
            } else {
              state.current_point().offset(0.0, value)
            }
          state.line_to(pt)
          horizontal = !horizontal
        }
        stack = []
        pos = pos + 1
      }
      8 => {
        if (stack.length() % 6) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        while i + 5 < stack.length() {
          let pt1 = state.current_point().offset(stack[i], stack[i + 1])
          let pt2 = pt1.offset(stack[i + 2], stack[i + 3])
          let pt3 = pt2.offset(stack[i + 4], stack[i + 5])
          state.curve_to(pt1, pt2, pt3)
          i = i + 6
        }
        stack = []
        pos = pos + 1
      }
      10 => {
        if stack.is_empty() {
          return Err(InvalidFormat)
        }
        let subr_index = stack[stack.length() - 1].round().to_int()
        stack = []
        let local_subrs_value = match local_subrs {
          None => return Err(InvalidFormat)
          Some(value) => value
        }
        let bias = subr_bias(local_subrs_value.count)
        let idx = subr_index + bias
        let bytes = match local_subrs_value.item_bytes(idx) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        match interpret_charstring_cff2(
          bytes[:],
          state,
          blend_state,
          global_subrs,
          local_subrs,
          depth + 1,
          true,
        ) {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        pos = pos + 1
      }
      11 => {
        if allow_return {
          return Ok(())
        }
        return Err(InvalidFormat)
      }
      12 => {
        if pos + 1 >= data.length() {
          return Err(UnexpectedEof)
        }
        let op = data[pos + 1].to_int()
        let err = match op {
          34 => handle_hflex(state, stack)
          35 => handle_flex(state, stack)
          36 => handle_hflex1(state, stack)
          37 => handle_flex1(state, stack)
          _ => Err(InvalidFormat)
        }
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 2
      }
      14 => {
        stack = []
        pos = pos + 1
        return Ok(())
      }
      15 => {
        if stack.is_empty() {
          return Err(InvalidFormat)
        }
        if blend_state.seen_vsindex || blend_state.seen_blend {
          return Err(InvalidFormat)
        }
        let ivs = stack[stack.length() - 1].round().to_int()
        ignore(stack.pop())
        if ivs < 0 {
          return Err(InvalidFormat)
        }
        blend_state.ivs = ivs
        blend_state.seen_vsindex = true
        stack = []
        pos = pos + 1
      }
      16 => {
        if stack.is_empty() {
          return Err(InvalidFormat)
        }
        let n = stack[stack.length() - 1].round().to_int()
        ignore(stack.pop())
        if n < 0 {
          return Err(InvalidFormat)
        }
        let k = match blend_state.region_count() {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let start = stack.length() - (k + 1) * n
        if start < 0 {
          return Err(InvalidFormat)
        }
        let scalars = match blend_state.region_scalars() {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        for i in 0..<n {
          let mut value = stack[start + i]
          match scalars {
            None => ()
            Some(values) => {
              let base = start + n + (i * k)
              for j in 0..<k {
                value = value + values[j] * stack[base + j]
              }
            }
          }
          stack[start + i] = value
        }
        let mut to_pop = k * n
        while to_pop > 0 {
          ignore(stack.pop())
          to_pop = to_pop - 1
        }
        blend_state.seen_blend = true
        pos = pos + 1
      }
      21 => {
        if stack.length() < 2 {
          return Err(InvalidFormat)
        }
        let dx = stack[0]
        let dy = stack[1]
        let pt = state.current_point().offset(dx, dy)
        state.moveto(pt)
        stack = []
        pos = pos + 1
      }
      22 => {
        if stack.length() < 1 {
          return Err(InvalidFormat)
        }
        let dx = stack[0]
        let pt = state.current_point().offset(dx, 0.0)
        state.moveto(pt)
        stack = []
        pos = pos + 1
      }
      24 => {
        if stack.length() < 8 || ((stack.length() - 2) % 6) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        let line_index = stack.length() - 2
        while i + 5 < line_index {
          let pt1 = state.current_point().offset(stack[i], stack[i + 1])
          let pt2 = pt1.offset(stack[i + 2], stack[i + 3])
          let pt3 = pt2.offset(stack[i + 4], stack[i + 5])
          state.curve_to(pt1, pt2, pt3)
          i = i + 6
        }
        let dx = stack[line_index]
        let dy = stack[line_index + 1]
        let pt = state.current_point().offset(dx, dy)
        state.line_to(pt)
        stack = []
        pos = pos + 1
      }
      25 => {
        if stack.length() < 8 || ((stack.length() - 6) % 2) != 0 {
          return Err(InvalidFormat)
        }
        let mut i = 0
        let curve_index = stack.length() - 6
        while i + 1 < curve_index {
          let pt = state.current_point().offset(stack[i], stack[i + 1])
          state.line_to(pt)
          i = i + 2
        }
        let pt1 = state.current_point().offset(stack[curve_index], stack[curve_index + 1])
        let pt2 = pt1.offset(stack[curve_index + 2], stack[curve_index + 3])
        let pt3 = pt2.offset(stack[curve_index + 4], stack[curve_index + 5])
        state.curve_to(pt1, pt2, pt3)
        stack = []
        pos = pos + 1
      }
      26 => {
        let err = handle_vvcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      27 => {
        let err = handle_hhcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      29 => {
        if stack.is_empty() {
          return Err(InvalidFormat)
        }
        let subr_index = stack[stack.length() - 1].round().to_int()
        stack = []
        let global = match global_subrs {
          None => return Err(InvalidFormat)
          Some(value) => value
        }
        let bias = subr_bias(global.count)
        let idx = subr_index + bias
        let bytes = match global.item_bytes(idx) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        match interpret_charstring_cff2(
          bytes[:],
          state,
          blend_state,
          global_subrs,
          local_subrs,
          depth + 1,
          true,
        ) {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        pos = pos + 1
      }
      30 => {
        let err = handle_vhcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      31 => {
        let err = handle_hvcurveto(state, stack)
        match err {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
        stack = []
        pos = pos + 1
      }
      _ => return Err(InvalidFormat)
    }
  }
  Ok(())
}

fn offset_bounds(bounds : CffBounds, dx : Double, dy : Double) -> CffBounds {
  CffBounds::{
    x_min: bounds.x_min + dx,
    y_min: bounds.y_min + dy,
    x_max: bounds.x_max + dx,
    y_max: bounds.y_max + dy,
  }
}

fn width_offset(state : CffCharstringState, stack : Array[Double]) -> Int {
  if state.has_width {
    return 0
  }
  if (stack.length() % 2) != 0 {
    state.has_width = true
    return 1
  }
  0
}

fn parse_charstring_number(
  data : BytesView,
  pos : Int,
) -> Result[(Double, Int), CffError] {
  if pos < 0 || pos >= data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[pos].to_int()
  if b0 >= 32 && b0 <= 246 {
    return Ok(((b0 - 139).to_double(), pos + 1))
  }
  if b0 >= 247 && b0 <= 250 {
    if pos + 1 >= data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[pos + 1].to_int()
    let value = (b0 - 247) * 256 + b1 + 108
    return Ok((value.to_double(), pos + 2))
  }
  if b0 >= 251 && b0 <= 254 {
    if pos + 1 >= data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[pos + 1].to_int()
    let value = -(b0 - 251) * 256 - b1 - 108
    return Ok((value.to_double(), pos + 2))
  }
  if b0 == 28 {
    if pos + 2 >= data.length() {
      return Err(UnexpectedEof)
    }
    let hi = data[pos + 1].to_int()
    let lo = data[pos + 2].to_int()
    let raw = (hi << 8) | lo
    let value = if raw >= 0x8000 { raw - 0x10000 } else { raw }
    return Ok((value.to_double(), pos + 3))
  }
  if b0 == 255 {
    if pos + 4 >= data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[pos + 1].to_int64()
    let b2 = data[pos + 2].to_int64()
    let b3 = data[pos + 3].to_int64()
    let b4 = data[pos + 4].to_int64()
    let raw : Int64 = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
    let signed : Int64 = if raw >= 2147483648 { raw - 4294967296 } else { raw }
    return Ok((signed.to_double() / 65536.0, pos + 5))
  }
  Err(InvalidFormat)
}

fn handle_vvcurveto(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  let mut i = 0
  let count = stack.length()
  let mut pt1 = state.current_point()
  if (count & 1) != 0 {
    pt1 = pt1.offset_x(stack[i])
    i = i + 1
  }
  while i + 3 < count {
    pt1 = pt1.offset_y(stack[i])
    let pt2 = pt1.offset(stack[i + 1], stack[i + 2])
    let pt3 = pt2.offset_y(stack[i + 3])
    state.curve_to(pt1, pt2, pt3)
    pt1 = state.current_point()
    i = i + 4
  }
  Ok(())
}

fn handle_hhcurveto(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  let mut i = 0
  let count = stack.length()
  let mut pt1 = state.current_point()
  if (count & 1) != 0 {
    pt1 = pt1.offset_y(stack[i])
    i = i + 1
  }
  while i + 3 < count {
    pt1 = pt1.offset_x(stack[i])
    let pt2 = pt1.offset(stack[i + 1], stack[i + 2])
    let pt3 = pt2.offset_x(stack[i + 3])
    state.curve_to(pt1, pt2, pt3)
    pt1 = state.current_point()
    i = i + 4
  }
  Ok(())
}

fn handle_vhcurveto(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  let count = stack.length()
  let mut i = 0
  if (count % 8) >= 4 {
    let mut pt1 = state.current_point().offset_y(stack[i])
    let mut pt2 = pt1.offset(stack[i + 1], stack[i + 2])
    let mut pt3 = pt2.offset_x(stack[i + 3])
    i = i + 4
    while i + 7 < count {
      state.curve_to(pt1, pt2, pt3)
      pt1 = state.current_point().offset_x(stack[i])
      pt2 = pt1.offset(stack[i + 1], stack[i + 2])
      pt3 = pt2.offset_y(stack[i + 3])
      state.curve_to(pt1, pt2, pt3)
      pt1 = pt3.offset_y(stack[i + 4])
      pt2 = pt1.offset(stack[i + 5], stack[i + 6])
      pt3 = pt2.offset_x(stack[i + 7])
      i = i + 8
    }
    if i < count {
      pt3 = pt3.offset_y(stack[i])
    }
    state.curve_to(pt1, pt2, pt3)
    return Ok(())
  }
  while i + 7 < count {
    let mut pt1 = state.current_point().offset_y(stack[i])
    let mut pt2 = pt1.offset(stack[i + 1], stack[i + 2])
    let mut pt3 = pt2.offset_x(stack[i + 3])
    state.curve_to(pt1, pt2, pt3)
    pt1 = pt3.offset_x(stack[i + 4])
    pt2 = pt1.offset(stack[i + 5], stack[i + 6])
    pt3 = pt2.offset_y(stack[i + 7])
    if (count - i < 16) && ((count & 1) != 0) && (i + 8 < count) {
      pt3 = pt3.offset_x(stack[i + 8])
    }
    state.curve_to(pt1, pt2, pt3)
    i = i + 8
  }
  Ok(())
}

fn handle_hvcurveto(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  let count = stack.length()
  let mut i = 0
  if (count % 8) >= 4 {
    let mut pt1 = state.current_point().offset_x(stack[i])
    let mut pt2 = pt1.offset(stack[i + 1], stack[i + 2])
    let mut pt3 = pt2.offset_y(stack[i + 3])
    i = i + 4
    while i + 7 < count {
      state.curve_to(pt1, pt2, pt3)
      pt1 = state.current_point().offset_y(stack[i])
      pt2 = pt1.offset(stack[i + 1], stack[i + 2])
      pt3 = pt2.offset_x(stack[i + 3])
      state.curve_to(pt1, pt2, pt3)
      pt1 = pt3.offset_x(stack[i + 4])
      pt2 = pt1.offset(stack[i + 5], stack[i + 6])
      pt3 = pt2.offset_y(stack[i + 7])
      i = i + 8
    }
    if i < count {
      pt3 = pt3.offset_x(stack[i])
    }
    state.curve_to(pt1, pt2, pt3)
    return Ok(())
  }
  while i + 7 < count {
    let mut pt1 = state.current_point().offset_x(stack[i])
    let mut pt2 = pt1.offset(stack[i + 1], stack[i + 2])
    let mut pt3 = pt2.offset_y(stack[i + 3])
    state.curve_to(pt1, pt2, pt3)
    pt1 = pt3.offset_y(stack[i + 4])
    pt2 = pt1.offset(stack[i + 5], stack[i + 6])
    pt3 = pt2.offset_x(stack[i + 7])
    if (count - i < 16) && ((count & 1) != 0) && (i + 8 < count) {
      pt3 = pt3.offset_y(stack[i + 8])
    }
    state.curve_to(pt1, pt2, pt3)
    i = i + 8
  }
  Ok(())
}

fn handle_hflex(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  if stack.length() != 7 {
    return Err(InvalidFormat)
  }
  let pt1 = state.current_point().offset_x(stack[0])
  let pt2 = pt1.offset(stack[1], stack[2])
  let pt3 = pt2.offset_x(stack[3])
  let pt4 = pt3.offset_x(stack[4])
  let pt5 = pt4.offset_x(stack[5])
  let pt5 = CffPoint::{ x: pt5.x, y: pt1.y }
  let pt6 = pt5.offset_x(stack[6])
  state.curve_to(pt1, pt2, pt3)
  state.curve_to(pt4, pt5, pt6)
  Ok(())
}

fn handle_flex(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  if stack.length() != 13 {
    return Err(InvalidFormat)
  }
  let pt1 = state.current_point().offset(stack[0], stack[1])
  let pt2 = pt1.offset(stack[2], stack[3])
  let pt3 = pt2.offset(stack[4], stack[5])
  let pt4 = pt3.offset(stack[6], stack[7])
  let pt5 = pt4.offset(stack[8], stack[9])
  let pt6 = pt5.offset(stack[10], stack[11])
  state.curve_to(pt1, pt2, pt3)
  state.curve_to(pt4, pt5, pt6)
  Ok(())
}

fn handle_hflex1(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  if stack.length() != 9 {
    return Err(InvalidFormat)
  }
  let pt1 = state.current_point().offset(stack[0], stack[1])
  let pt2 = pt1.offset(stack[2], stack[3])
  let pt3 = pt2.offset_x(stack[4])
  let pt4 = pt3.offset_x(stack[5])
  let pt5 = pt4.offset(stack[6], stack[7])
  let mut pt6 = pt5.offset_x(stack[8])
  pt6 = CffPoint::{ x: pt6.x, y: state.current_point().y }
  state.curve_to(pt1, pt2, pt3)
  state.curve_to(pt4, pt5, pt6)
  Ok(())
}

fn handle_flex1(state : CffCharstringState, stack : Array[Double]) -> Result[Unit, CffError] {
  if stack.length() != 11 {
    return Err(InvalidFormat)
  }
  let mut dx = 0.0
  let mut dy = 0.0
  let mut i = 0
  while i < 10 {
    dx = dx + stack[i]
    dy = dy + stack[i + 1]
    i = i + 2
  }
  let pt1 = state.current_point().offset(stack[0], stack[1])
  let pt2 = pt1.offset(stack[2], stack[3])
  let pt3 = pt2.offset(stack[4], stack[5])
  let pt4 = pt3.offset(stack[6], stack[7])
  let pt5 = pt4.offset(stack[8], stack[9])
  let mut pt6 = pt5
  if dx.abs() > dy.abs() {
    pt6 = pt6.offset_x(stack[10])
    pt6 = CffPoint::{ x: pt6.x, y: state.current_point().y }
  } else {
    pt6 = CffPoint::{ x: state.current_point().x, y: pt6.y }
    pt6 = pt6.offset_y(stack[10])
  }
  state.curve_to(pt1, pt2, pt3)
  state.curve_to(pt4, pt5, pt6)
  Ok(())
}
