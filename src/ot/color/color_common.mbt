// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
pub suberror ColorError {
  UnexpectedEof
  InvalidFormat
  Var(@ot_var.VarError)
} derive(Eq, Debug, ToJson)

fn read_u8_int(data : BytesView, offset : Int) -> Result[Int, ColorError] {
  if offset < 0 || offset + 1 > data.length() {
    return Err(UnexpectedEof)
  }
  Ok(data[offset].to_int())
}

fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, ColorError] {
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let value = (b0 << 8) | b1
  let v = value.reinterpret_as_int()
  if v < 0 { Ok(v + 0x10000) } else { Ok(v) }
}

fn read_i16(data : BytesView, offset : Int) -> Result[Int, ColorError] {
  match read_u16_int(data, offset) {
    Err(err) => Err(err)
    Ok(value) => if value >= 0x8000 { Ok(value - 0x10000) } else { Ok(value) }
  }
}

fn read_u24_int(data : BytesView, offset : Int) -> Result[Int, ColorError] {
  if offset < 0 || offset + 3 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let value = ((b0 << 16) | (b1 << 8) | b2).reinterpret_as_int()
  if value < 0 { Err(InvalidFormat) } else { Ok(value) }
}

fn read_u32(data : BytesView, offset : Int) -> Result[UInt, ColorError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, ColorError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

fn read_i32(data : BytesView, offset : Int) -> Result[Int, ColorError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}
