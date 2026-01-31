///|
fn push_u16_gvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_gvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_gvar_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_gvar(bytes, 0x00010000) // version 1.0
  push_u16_gvar(bytes, 1) // axis count
  push_u16_gvar(bytes, 0) // shared tuple count
  push_u32_gvar(bytes, 0) // shared tuples offset
  push_u16_gvar(bytes, 2) // glyph count
  push_u16_gvar(bytes, 0) // flags short offsets
  push_u32_gvar(bytes, 26) // data offset
  // offsets array (glyphCount+1) short, value is /2
  push_u16_gvar(bytes, 0) // start 0
  push_u16_gvar(bytes, 1) // start 2
  push_u16_gvar(bytes, 3) // start 6
  // glyph variation data bytes
  bytes.push(1)
  bytes.push(2)
  bytes.push(3)
  bytes.push(4)
  bytes.push(5)
  bytes.push(6)
  Bytes::from_array(bytes)
}

///|
test "gvar parse offsets" {
  let gvar = match GvarTable::parse(build_gvar_bytes()) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let g0 = gvar.glyph_variation_data(0)
  let g1 = gvar.glyph_variation_data(1)
  inspect(g0.map(bytes => bytes.to_array().map(b => b.to_int())), content="Some([1, 2])")
  inspect(g1.map(bytes => bytes.to_array().map(b => b.to_int())), content="Some([3, 4, 5, 6])")
}
