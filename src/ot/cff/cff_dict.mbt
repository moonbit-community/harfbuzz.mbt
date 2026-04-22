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
pub enum CffNumber {
  Int(Int)
  Real(Double)
} derive(Eq, Debug, ToJson)

///|
pub struct CffDict {
  entries : Map[Int, Array[CffNumber]]
} derive(Eq, Debug, ToJson)

///|
pub fn parse_cff_dict(data : BytesView) -> Result[CffDict, CffError] {
  let mut pos = 0
  let mut operands : Array[CffNumber] = []
  let entries : Map[Int, Array[CffNumber]] = {}
  while pos < data.length() {
    let b0 = data[pos].to_int()
    if b0 == 12 {
      if pos + 1 >= data.length() {
        return Err(UnexpectedEof)
      }
      let b1 = data[pos + 1].to_int()
      let op = (12 << 8) | b1
      entries[op] = operands.copy()
      operands = []
      pos = pos + 2
      continue
    }
    if b0 <= 27 {
      entries[b0] = operands.copy()
      operands = []
      pos = pos + 1
      continue
    }
    let parsed = parse_cff_number(data, pos)
    match parsed {
      Err(err) => return Err(err)
      Ok((num, next_pos)) => {
        operands.push(num)
        pos = next_pos
      }
    }
  }
  Ok(CffDict::{ entries })
}

///|
pub fn CffDict::get_numbers(self : CffDict, op : Int) -> Array[CffNumber]? {
  self.entries.get(op)
}

///|
pub fn CffDict::entries_map(self : CffDict) -> Map[Int, Array[CffNumber]] {
  let next : Map[Int, Array[CffNumber]] = {}
  self.entries.eachi((_, key, value) => {
    next[key] = value.copy()
  })
  next
}

///|
pub fn CffDict::get_int(self : CffDict, op : Int, index? : Int = 0) -> Int? {
  match self.entries.get(op) {
    None => None
    Some(values) => {
      if index < 0 || index >= values.length() {
        return None
      }
      match values[index] {
        Int(value) => Some(value)
        Real(value) => Some(value.round().to_int())
      }
    }
  }
}

///|
pub fn CffDict::get_real(self : CffDict, op : Int, index? : Int = 0) -> Double? {
  match self.entries.get(op) {
    None => None
    Some(values) => {
      if index < 0 || index >= values.length() {
        return None
      }
      match values[index] {
        Int(value) => Some(value.to_double())
        Real(value) => Some(value)
      }
    }
  }
}

fn parse_cff_number(
  data : BytesView,
  pos : Int,
) -> Result[(CffNumber, Int), CffError] {
  if pos < 0 || pos >= data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[pos].to_int()
  if b0 >= 32 && b0 <= 246 {
    return Ok((Int(b0 - 139), pos + 1))
  }
  if b0 >= 247 && b0 <= 250 {
    if pos + 1 >= data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[pos + 1].to_int()
    let value = (b0 - 247) * 256 + b1 + 108
    return Ok((Int(value), pos + 2))
  }
  if b0 >= 251 && b0 <= 254 {
    if pos + 1 >= data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[pos + 1].to_int()
    let value = -(b0 - 251) * 256 - b1 - 108
    return Ok((Int(value), pos + 2))
  }
  if b0 == 28 {
    if pos + 2 >= data.length() {
      return Err(UnexpectedEof)
    }
    let hi = data[pos + 1].to_int()
    let lo = data[pos + 2].to_int()
    let raw = (hi << 8) | lo
    let value = if raw >= 0x8000 { raw - 0x10000 } else { raw }
    return Ok((Int(value), pos + 3))
  }
  if b0 == 29 {
    if pos + 4 >= data.length() {
      return Err(UnexpectedEof)
    }
    let b1 = data[pos + 1].to_int()
    let b2 = data[pos + 2].to_int()
    let b3 = data[pos + 3].to_int()
    let b4 = data[pos + 4].to_int()
    let value = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
    return Ok((Int(value), pos + 5))
  }
  if b0 == 30 {
    return parse_cff_real(data, pos)
  }
  Err(InvalidFormat)
}

fn parse_cff_real(
  data : BytesView,
  pos : Int,
) -> Result[(CffNumber, Int), CffError] {
  let digits : Array[Char] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  let chars : Array[Char] = []
  let mut idx = pos + 1
  let mut done = false
  while idx < data.length() && !done {
    let byte = data[idx].to_int()
    let hi = (byte >> 4) & 0xF
    let lo = byte & 0xF
    let nibbles : Array[Int] = [hi, lo]
    for nib in nibbles {
      if done {
        break
      }
      if nib >= 0 && nib <= 9 {
        chars.push(digits[nib])
        continue
      }
      match nib {
        0xA => chars.push('.')
        0xB => chars.push('E')
        0xC => {
          chars.push('E')
          chars.push('-')
        }
        0xE => chars.push('-')
        0xF => done = true
        0xD => return Err(InvalidFormat)
        _ => return Err(InvalidFormat)
      }
    }
    idx = idx + 1
  }
  if !done {
    return Err(UnexpectedEof)
  }
  let value_str = String::from_array(chars)
  match @common.parse_double(value_str[:], whole=true) {
    None => Err(InvalidFormat)
    Some((value, _)) => Ok((Real(value), idx))
  }
}
