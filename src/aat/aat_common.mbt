///|
pub suberror AatError {
  UnexpectedEof
  InvalidFormat
} derive(Eq, Show, ToJson)

fn read_u16(data : BytesView, offset : Int) -> Result[UInt, AatError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  Ok((b0 << 8) | b1)
}

fn read_u32(data : BytesView, offset : Int) -> Result[UInt, AatError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

fn u16_to_int(value : UInt) -> Int {
  let v = value.reinterpret_as_int()
  if v < 0 { v + 0x10000 } else { v }
}

fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, AatError] {
  match read_u16(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(u16_to_int(value))
  }
}

fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, AatError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

fn read_i16(data : BytesView, offset : Int) -> Result[Int, AatError] {
  match read_u16_int(data, offset) {
    Err(err) => Err(err)
    Ok(value) => if value >= 0x8000 { Ok(value - 0x10000) } else { Ok(value) }
  }
}

fn read_i32(data : BytesView, offset : Int) -> Result[Int, AatError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}
