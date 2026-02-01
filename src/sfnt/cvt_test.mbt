///|
fn push_u16_cvt(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_cvt(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_cvt(bytes, adjusted)
}

///|
test "cvt parse" {
  let bytes : Array[Byte] = []
  push_i16_cvt(bytes, 100)
  push_i16_cvt(bytes, -200)
  push_i16_cvt(bytes, 0)
  let table = match CvtTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  inspect(table.values().to_array(), content="[100, -200, 0]")
}
