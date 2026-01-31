///|
fn push_u16_cvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32_cvar(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_cvar(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_cvar(bytes, adjusted)
}

///|
fn build_cvar_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_cvar(bytes, 0x00010000) // version
  push_u16_cvar(bytes, 1) // tuple var count
  push_u16_cvar(bytes, 10) // data offset
  push_u16_cvar(bytes, 4) // tuple data size
  push_u16_cvar(bytes, 0x8000) // embedded peak
  push_i16_cvar(bytes, 0x4000) // peak 1.0
  bytes.push(2) // run length 3 (0x02)
  bytes.push(10)
  bytes.push(0)
  bytes.push(0xFB)
  Bytes::from_array(bytes)
}

///|
test "cvar apply deltas" {
  let cvar = match CvarTable::parse(build_cvar_bytes()[:], 1) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let cvt : Array[Int] = [100, 200, 300]
  let applied = match cvar.apply_to_cvt(cvt, [16384]) {
    Err(err) => fail("apply failed: \{err}")
    Ok(value) => value
  }
  inspect(applied, content="[110, 200, 295]")
}
