///|
pub suberror CffError {
  UnexpectedEof
  InvalidFormat
} derive(Eq, Show, ToJson)

///|
fn read_u8_int(data : BytesView, offset : Int) -> Result[Int, CffError] {
  if offset < 0 || offset + 1 > data.length() {
    return Err(UnexpectedEof)
  }
  Ok(data[offset].to_int())
}

fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, CffError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let value = (b0 << 8) | b1
  let v = value.reinterpret_as_int()
  if v < 0 { Ok(v + 0x10000) } else { Ok(v) }
}

fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, CffError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok(((b0 << 24) | (b1 << 16) | (b2 << 8) | b3).reinterpret_as_int())
}

fn read_cff_offset(data : BytesView, offset : Int, size : Int) -> Result[Int, CffError] {
  if size <= 0 || size > 4 {
    return Err(InvalidFormat)
  }
  if offset < 0 || offset + size > data.length() {
    return Err(UnexpectedEof)
  }
  let mut value = 0
  for i in 0..<size {
    value = (value << 8) | data[offset + i].to_int()
  }
  Ok(value)
}
