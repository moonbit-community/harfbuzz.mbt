///|
fn push_u32_varc(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_varc_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_varc(bytes, 0x00010000) // version
  push_u32_varc(bytes, 24) // coverage offset
  push_u32_varc(bytes, 0) // var store offset
  push_u32_varc(bytes, 0) // condition list offset
  push_u32_varc(bytes, 0) // axis indices offset
  push_u32_varc(bytes, 24) // glyph records offset
  bytes.push(0)
  bytes.push(1)
  bytes.push(2)
  bytes.push(3)
  Bytes::from_array(bytes)
}

///|
test "varc parse" {
  let varc = match VarcTable::parse(build_varc_bytes()[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  inspect((varc.coverage_offset, varc.glyph_records_offset), content="(24, 24)")
}
