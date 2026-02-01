///|
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  let v = value & 0xffff
  bytes.push(((v >> 8) & 0xff).to_byte())
  bytes.push((v & 0xff).to_byte())
}

///|
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let v = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, v)
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  let v = value.reinterpret_as_uint()
  bytes.push(((v >> 24) & 0xffU).to_byte())
  bytes.push(((v >> 16) & 0xffU).to_byte())
  bytes.push(((v >> 8) & 0xffU).to_byte())
  bytes.push((v & 0xffU).to_byte())
}

///|
fn build_kerx_format0() -> Bytes {
  let bytes : Array[Byte] = []
  // kerx header
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u32(bytes, 1)
  // subtable header
  push_u32(bytes, 34)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  // binsearch header (len=1)
  push_u32(bytes, 1)
  push_u32(bytes, 16)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  // pair record
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_i16(bytes, -50)
  Bytes::from_array(bytes)
}

///|
test "aat kerx format0" {
  let data = build_kerx_format0()
  let kerx = match KerxTable::parse(data[:], 10) {
    Err(err) => fail("kerx parse failed: \{err}")
    Ok(value) => value
  }
  assert_true(kerx.has_data())
  inspect(kerx.kern_value(1U, 2U, true), content="-50")
  inspect(kerx.kern_value(2U, 1U, true), content="0")
}
