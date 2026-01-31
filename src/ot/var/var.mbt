///|
pub suberror VarError {
  UnexpectedEof
  InvalidFormat
} derive(Eq, Show, ToJson)

///|
pub struct AxisCoord {
  tag : @common.Tag
  value : Double
} derive(Eq, Show, ToJson)

///|
pub fn AxisCoord::new(tag : @common.Tag, value : Double) -> AxisCoord {
  AxisCoord::{ tag, value }
}

fn read_u16(data : BytesView, offset : Int) -> Result[UInt, VarError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  Ok((b0 << 8) | b1)
}

fn u16_to_int(value : UInt) -> Int {
  let v = value.reinterpret_as_int()
  if v < 0 { v + 0x10000 } else { v }
}

fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, VarError] {
  match read_u16(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(u16_to_int(value))
  }
}

fn read_u32(data : BytesView, offset : Int) -> Result[UInt, VarError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

fn read_u8_int(data : BytesView, offset : Int) -> Result[Int, VarError] {
  if offset < 0 || offset + 1 > data.length() {
    return Err(UnexpectedEof)
  }
  Ok(data[offset].to_int())
}

fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, VarError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

fn read_i16(data : BytesView, offset : Int) -> Result[Int, VarError] {
  match read_u16(data, offset) {
    Err(err) => Err(err)
    Ok(value) => {
      let v = value.reinterpret_as_int()
      if v >= 0x8000 { Ok(v - 0x10000) } else { Ok(v) }
    }
  }
}

fn read_i32(data : BytesView, offset : Int) -> Result[Int, VarError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

fn read_tag(data : BytesView, offset : Int) -> Result[@common.Tag, VarError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  Ok(@common.Tag::from_bytes(
    data[offset],
    data[offset + 1],
    data[offset + 2],
    data[offset + 3],
  ))
}

fn fixed16_to_double(raw : Int) -> Double {
  raw.to_double() / 65536.0
}

fn double_to_fixed16(value : Double) -> Int {
  (value * 65536.0).round().to_int()
}

fn f2dot14_to_double(raw : Int) -> Double {
  raw.to_double() / 16384.0
}

pub fn fixed16_to_f2dot14(raw : Int) -> Int {
  (raw + 2) >> 2
}

fn clamp_double(value : Double, min_value : Double, max_value : Double) -> Double {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}
