///|
fn push_u32_varc_comp(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u16_varc_comp(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_varc_comp(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_varc_comp(bytes, adjusted)
}

///|
fn push_u32var_comp(bytes : Array[Byte], value : UInt) -> Unit {
  if value < 0x80U {
    bytes.push(value.reinterpret_as_int().to_byte())
    return
  }
  if value < 0x4000U {
    let b0 = 0x80U | ((value >> 8) & 0x3FU)
    bytes.push(b0.reinterpret_as_int().to_byte())
    bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
    return
  }
  if value < 0x200000U {
    let b0 = 0xC0U | ((value >> 16) & 0x1FU)
    bytes.push(b0.reinterpret_as_int().to_byte())
    bytes.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
    return
  }
  if value < 0x10000000U {
    let b0 = 0xE0U | ((value >> 24) & 0x0FU)
    bytes.push(b0.reinterpret_as_int().to_byte())
    bytes.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
    bytes.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
    return
  }
  bytes.push((0xF0).to_byte())
  bytes.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
  bytes.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  bytes.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
}

fn push_tuple_values_bytes(bytes : Array[Byte], values : Array[Int]) -> Unit {
  let count = values.length()
  let control = (count - 1) & 0x3F
  bytes.push(control.to_byte())
  for value in values {
    bytes.push((value & 0xFF).to_byte())
  }
}

fn push_tuple_values_words(bytes : Array[Byte], values : Array[Int]) -> Unit {
  let count = values.length()
  let control = 0x40 | ((count - 1) & 0x3F)
  bytes.push(control.to_byte())
  for value in values {
    push_i16_varc_comp(bytes, value)
  }
}

fn build_varc_component_table() -> Bytes {
  let record : Array[Byte] = []
  let flags = 274U // HAVE_AXES | HAVE_TRANSLATE_X | HAVE_SCALE_X
  push_u32var_comp(record, flags)
  push_u16_varc_comp(record, 7)
  push_u32var_comp(record, 0U)
  push_tuple_values_words(record, [0x2000, 0x4000])
  push_i16_varc_comp(record, 50)
  push_i16_varc_comp(record, 1024)

  let axis_indices : Array[Byte] = []
  push_tuple_values_bytes(axis_indices, [1, 2])

  let bytes : Array[Byte] = []
  let coverage_offset = 24
  let axis_indices_offset = coverage_offset + 6
  let glyph_records_offset = axis_indices_offset + 10

  push_u32_varc_comp(bytes, 0x00010000)
  push_u32_varc_comp(bytes, coverage_offset)
  push_u32_varc_comp(bytes, 0)
  push_u32_varc_comp(bytes, 0)
  push_u32_varc_comp(bytes, axis_indices_offset)
  push_u32_varc_comp(bytes, glyph_records_offset)

  // Coverage format 1 for glyph 5
  push_u16_varc_comp(bytes, 1)
  push_u16_varc_comp(bytes, 1)
  push_u16_varc_comp(bytes, 5)

  // Axis indices list CFF2 INDEX
  push_u32_varc_comp(bytes, 1)
  bytes.push(1)
  bytes.push(1)
  bytes.push((1 + axis_indices.length()).to_byte())
  for b in axis_indices {
    bytes.push(b)
  }

  // Glyph records CFF2 INDEX
  push_u32_varc_comp(bytes, 1)
  bytes.push(1)
  bytes.push(1)
  bytes.push((1 + record.length()).to_byte())
  for b in record {
    bytes.push(b)
  }

  Bytes::from_array(bytes)
}

///|
test "varc component parse" {
  let varc = match VarcTable::parse(build_varc_component_table()[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let comps = match varc.glyph_components(5, [0, 0, 0], [0, 0, 0]) {
    Err(err) => fail("components failed: \{err}")
    Ok(value) => value
  }
  inspect(comps.length(), content="1")
  let comp = comps[0]
  inspect(comp.glyph, content="7")
  inspect(comp.axis_indices, content="[1, 2]")
  inspect(comp.axis_values.map(v => v.round().to_int()), content="[8192, 16384]")
  inspect(comp.coords, content="[0, 8192, 16384]")
  let tx = comp.transform.translate_x.round().to_int()
  let sx = (comp.transform.scale_x * 1000.0).round().to_int()
  let sy = (comp.transform.scale_y * 1000.0).round().to_int()
  inspect((tx, sx, sy), content="(50, 1000, 1000)")
}
