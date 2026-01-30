fn is_zero_width_mark(u : UInt) -> Bool {
  let cat = @unicode.general_category(u)
  cat == @unicode.gc_non_spacing_mark || cat == @unicode.gc_enclosing_mark
}

fn mark_flags_from_infos(infos : Array[GlyphInfo]) -> Array[Bool] {
  let flags : Array[Bool] = []
  for info in infos {
    flags.push(is_zero_width_mark(info.codepoint))
  }
  flags
}

fn mark_flags_from_gdef(
  gdef : @ot_tables.GdefTable,
  infos : Array[GlyphInfo],
) -> Result[Array[Bool], ShapeError] {
  let flags : Array[Bool] = []
  for info in infos {
    let glyph_class = match gdef.glyph_class(info.codepoint) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
    flags.push(glyph_class == 3)
  }
  Ok(flags)
}

priv enum ZeroWidthMarks {
  Disabled
  ByGdefEarly
  ByGdefLate
}

fn collect_mark_fallback_data(infos : Array[GlyphInfo]) -> (Array[Bool], Array[Int]) {
  let marks = mark_flags_from_infos(infos)
  let combining_classes : Array[Int] = []
  for info in infos {
    let klass = @unicode.modified_combining_class(info.codepoint).reinterpret_as_int()
    combining_classes.push(recategorize_combining_class(info.codepoint, klass))
  }
  (marks, combining_classes)
}

struct GlyphExtents {
  mut x_bearing : Int
  mut y_bearing : Int
  mut width : Int
  mut height : Int
} derive(Show)

let cc_attached_below_left : Int = 200
let cc_attached_below : Int = 202
let cc_attached_above : Int = 214
let cc_attached_above_right : Int = 216
let cc_below_left : Int = 218
let cc_below : Int = 220
let cc_below_right : Int = 222
let cc_left : Int = 224
let cc_right : Int = 226
let cc_above_left : Int = 228
let cc_above : Int = 230
let cc_above_right : Int = 232
let cc_double_below : Int = 233
let cc_double_above : Int = 234

let mcc_ccc10 : Int = 22
let mcc_ccc11 : Int = 15
let mcc_ccc12 : Int = 16
let mcc_ccc13 : Int = 17
let mcc_ccc14 : Int = 23
let mcc_ccc15 : Int = 18
let mcc_ccc16 : Int = 19
let mcc_ccc17 : Int = 20
let mcc_ccc18 : Int = 21
let mcc_ccc19 : Int = 14
let mcc_ccc20 : Int = 24
let mcc_ccc22 : Int = 25
let mcc_ccc23 : Int = 13
let mcc_ccc24 : Int = 10
let mcc_ccc25 : Int = 11
let mcc_ccc26 : Int = 26
let mcc_ccc27 : Int = 28
let mcc_ccc28 : Int = 29
let mcc_ccc29 : Int = 30
let mcc_ccc30 : Int = 31
let mcc_ccc31 : Int = 32
let mcc_ccc32 : Int = 33
let mcc_ccc33 : Int = 27
let mcc_ccc34 : Int = 34
let mcc_ccc35 : Int = 35
let mcc_ccc36 : Int = 36
let mcc_ccc103 : Int = 3
let mcc_ccc107 : Int = 107
let mcc_ccc118 : Int = 118
let mcc_ccc122 : Int = 122
let mcc_ccc129 : Int = 129
let mcc_ccc130 : Int = 132
let mcc_ccc132 : Int = 131

fn recategorize_combining_class(u : UInt, klass : Int) -> Int {
  if klass >= 200 {
    return klass
  }
  if (u & 0xFFFFFF00U) == 0x0E00U {
    if klass == 0 {
      match u {
        0x0E31U |
        0x0E34U |
        0x0E35U |
        0x0E36U |
        0x0E37U |
        0x0E47U |
        0x0E4CU |
        0x0E4DU |
        0x0E4EU => return cc_above_right
        0x0EB1U |
        0x0EB4U |
        0x0EB5U |
        0x0EB6U |
        0x0EB7U |
        0x0EBBU |
        0x0ECCU |
        0x0ECDU => return cc_above
        0x0EBCU => return cc_below
        _ => ()
      }
    } else if u == 0x0E3AU {
      return cc_below_right
    }
  }
  if klass == mcc_ccc10 ||
    klass == mcc_ccc11 ||
    klass == mcc_ccc12 ||
    klass == mcc_ccc13 ||
    klass == mcc_ccc14 ||
    klass == mcc_ccc15 ||
    klass == mcc_ccc16 ||
    klass == mcc_ccc17 ||
    klass == mcc_ccc18 ||
    klass == mcc_ccc20 ||
    klass == mcc_ccc22 {
    return cc_below
  }
  if klass == mcc_ccc23 {
    return cc_attached_above
  }
  if klass == mcc_ccc24 {
    return cc_above_right
  }
  if klass == mcc_ccc25 || klass == mcc_ccc19 {
    return cc_above_left
  }
  if klass == mcc_ccc26 {
    return cc_above
  }
  if klass == mcc_ccc27 ||
    klass == mcc_ccc28 ||
    klass == mcc_ccc30 ||
    klass == mcc_ccc31 ||
    klass == mcc_ccc33 ||
    klass == mcc_ccc34 ||
    klass == mcc_ccc35 ||
    klass == mcc_ccc36 {
    return cc_above
  }
  if klass == mcc_ccc29 || klass == mcc_ccc32 {
    return cc_below
  }
  if klass == mcc_ccc103 {
    return cc_below_right
  }
  if klass == mcc_ccc107 {
    return cc_above_right
  }
  if klass == mcc_ccc118 {
    return cc_below
  }
  if klass == mcc_ccc122 {
    return cc_above
  }
  if klass == mcc_ccc129 {
    return cc_below
  }
  if klass == mcc_ccc130 {
    return cc_above
  }
  if klass == mcc_ccc132 {
    return cc_below
  }
  klass
}

fn scale_value(value : Int, scale : Int, upem : Int) -> Int {
  if upem == 0 {
    return value
  }
  (value * scale) / upem
}

fn glyph_extents(
  font : @font.Font,
  glyph : UInt,
) -> Result[GlyphExtents?, ShapeError] {
  let bounds = match font.glyph_bounds(glyph) {
    Err(_) => return Ok(None)
    Ok(value) => value
  }
  match bounds {
    None => Ok(None)
    Some(bounds) => {
      let (scale_x, scale_y) = font.get_scale()
      let upem = font.get_face().get_upem()
      let x_min = scale_value(bounds.x_min, scale_x, upem)
      let x_max = scale_value(bounds.x_max, scale_x, upem)
      let y_min = scale_value(bounds.y_min, scale_y, upem)
      let y_max = scale_value(bounds.y_max, scale_y, upem)
      Ok(Some(GlyphExtents::{
        x_bearing: x_min,
        y_bearing: y_max,
        width: x_max - x_min,
        height: y_max - y_min,
      }))
    }
  }
}

fn position_mark_fallback(
  font : @font.Font,
  buffer : Buffer,
  extents : GlyphExtents,
  mark_index : Int,
  combining_class : Int,
  y_gap : Int,
) -> Result[GlyphExtents, ShapeError] {
  if combining_class == 0 || combining_class == cc_left || combining_class == cc_right {
    return Ok(extents)
  }
  let mark_extents = match glyph_extents(font, buffer.infos[mark_index].codepoint) {
    Err(err) => return Err(err)
    Ok(None) => return Ok(extents)
    Ok(Some(value)) => value
  }
  let extents = extents
  let mut x_offset = 0
  if combining_class == cc_double_below || combining_class == cc_double_above {
    if buffer.direction == @common.direction_ltr {
      x_offset =
        extents.x_bearing + extents.width - mark_extents.width / 2 - mark_extents.x_bearing
    } else if buffer.direction == @common.direction_rtl {
      x_offset = extents.x_bearing - mark_extents.width / 2 - mark_extents.x_bearing
    } else {
      x_offset =
        extents.x_bearing + (extents.width - mark_extents.width) / 2 - mark_extents.x_bearing
    }
  } else if combining_class == cc_attached_below_left ||
    combining_class == cc_below_left ||
    combining_class == cc_above_left {
    x_offset = extents.x_bearing - mark_extents.x_bearing
  } else if combining_class == cc_attached_above_right ||
    combining_class == cc_below_right ||
    combining_class == cc_above_right {
    x_offset = extents.x_bearing + extents.width - mark_extents.width - mark_extents.x_bearing
  } else {
    x_offset = extents.x_bearing + (extents.width - mark_extents.width) / 2 - mark_extents.x_bearing
  }
  let mut y_offset = 0
  if combining_class == cc_double_below ||
    combining_class == cc_below_left ||
    combining_class == cc_below ||
    combining_class == cc_below_right {
    extents.height = extents.height - y_gap
    y_offset = extents.y_bearing + extents.height - mark_extents.y_bearing
    if (y_gap > 0) == (y_offset > 0) {
      extents.height = extents.height - y_offset
      y_offset = 0
    }
    extents.height = extents.height + mark_extents.height
  } else if combining_class == cc_attached_below_left ||
    combining_class == cc_attached_below {
    y_offset = extents.y_bearing + extents.height - mark_extents.y_bearing
    if (y_gap > 0) == (y_offset > 0) {
      extents.height = extents.height - y_offset
      y_offset = 0
    }
    extents.height = extents.height + mark_extents.height
  } else if combining_class == cc_double_above ||
    combining_class == cc_above_left ||
    combining_class == cc_above ||
    combining_class == cc_above_right {
    extents.y_bearing = extents.y_bearing + y_gap
    extents.height = extents.height - y_gap
    y_offset = extents.y_bearing - (mark_extents.y_bearing + mark_extents.height)
    if (y_gap > 0) != (y_offset > 0) {
      let correction = -y_offset / 2
      extents.y_bearing = extents.y_bearing + correction
      extents.height = extents.height - correction
      y_offset = y_offset + correction
    }
    extents.y_bearing = extents.y_bearing - mark_extents.height
    extents.height = extents.height + mark_extents.height
  } else if combining_class == cc_attached_above ||
    combining_class == cc_attached_above_right {
    y_offset = extents.y_bearing - (mark_extents.y_bearing + mark_extents.height)
    if (y_gap > 0) != (y_offset > 0) {
      let correction = -y_offset / 2
      extents.y_bearing = extents.y_bearing + correction
      extents.height = extents.height - correction
      y_offset = y_offset + correction
    }
    extents.y_bearing = extents.y_bearing - mark_extents.height
    extents.height = extents.height + mark_extents.height
  }
  buffer.positions[mark_index] = GlyphPosition::{
    x_advance: 0,
    y_advance: 0,
    x_offset,
    y_offset,
  }
  Ok(extents)
}

fn fallback_mark_position(
  font : @font.Font,
  buffer : Buffer,
  marks : Array[Bool],
  combining_classes : Array[Int],
) -> Result[Unit, ShapeError] {
  if marks.length() != buffer.infos.length() ||
    combining_classes.length() != buffer.infos.length() {
    return Ok(())
  }
  if buffer.direction.is_vertical() {
    return Ok(())
  }
  let (_, scale_y) = font.get_scale()
  let y_gap = scale_y / 16
  let mut i = 0
  while i < buffer.infos.length() {
    if marks[i] {
      i = i + 1
      continue
    }
    let base_index = i
    let mut j = i + 1
    while j < buffer.infos.length() && marks[j] {
      j = j + 1
    }
    if j - base_index <= 1 {
      i = j
      continue
    }
    let base_extents = match glyph_extents(font, buffer.infos[base_index].codepoint) {
      Err(err) => return Err(err)
      Ok(None) => {
        i = j
        continue
      }
      Ok(Some(value)) => value
    }
    let mut cluster_extents = base_extents
    cluster_extents.x_bearing = 0
    cluster_extents.width = buffer.positions[base_index].x_advance
    let mut last_cc = -1
    for k in (base_index + 1)..<j {
      if !marks[k] {
        continue
      }
      let cc = combining_classes[k]
      if cc == 0 {
        continue
      }
      if cc != last_cc {
        cluster_extents = base_extents
        cluster_extents.x_bearing = 0
        cluster_extents.width = buffer.positions[base_index].x_advance
        last_cc = cc
      }
      cluster_extents = match position_mark_fallback(
        font,
        buffer,
        cluster_extents,
        k,
        cc,
        y_gap,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
    }
    i = j
  }
  Ok(())
}

fn zero_mark_advances_with_flags(
  buffer : Buffer,
  marks : Array[Bool],
  adjust_offsets? : Bool = false,
) -> Unit {
  if buffer.infos.length() != buffer.positions.length() ||
    buffer.infos.length() != marks.length() {
    return ()
  }
  for i in 0..<buffer.infos.length() {
    if marks[i] {
      let pos = buffer.positions[i]
      let x_offset = if adjust_offsets { pos.x_offset - pos.x_advance } else { pos.x_offset }
      let y_offset = if adjust_offsets { pos.y_offset - pos.y_advance } else { pos.y_offset }
      buffer.positions[i] = GlyphPosition::{
        x_advance: 0,
        y_advance: 0,
        x_offset,
        y_offset,
      }
    }
  }
}

fn zero_marks_by_gdef_or_unicode(
  font : @font.Font,
  buffer : Buffer,
  unicode_marks : Array[Bool],
  gpos_present : Bool,
) -> Result[Unit, ShapeError] {
  let adjust_offsets = !gpos_present && buffer.direction.is_forward()
  let mut zeroed = false
  let gdef = match font.gdef() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  match gdef {
    None => ()
    Some(gdef) => {
      if gdef.header().glyph_class_def_offset is Some(_) {
        let flags = match mark_flags_from_gdef(gdef, buffer.infos) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        zero_mark_advances_with_flags(buffer, flags, adjust_offsets=adjust_offsets)
        zeroed = true
      }
    }
  }
  if !zeroed &&
    !gpos_present &&
    unicode_marks.length() == buffer.infos.length() {
    zero_mark_advances_with_flags(buffer, unicode_marks, adjust_offsets=adjust_offsets)
  }
  Ok(())
}
