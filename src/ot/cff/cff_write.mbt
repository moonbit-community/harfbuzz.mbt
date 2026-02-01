///|
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

fn push_count(bytes : Array[Byte], count : Int, count_bytes : Int) -> Result[Unit, CffError] {
  if count < 0 {
    return Err(InvalidFormat)
  }
  if count_bytes == 2 {
    if count > 0xFFFF {
      return Err(InvalidFormat)
    }
    push_u16(bytes, count)
    return Ok(())
  }
  if count_bytes == 4 {
    push_u32(bytes, count)
    return Ok(())
  }
  Err(InvalidFormat)
}

fn offset_size_for(value : Int) -> Result[Int, CffError] {
  if value <= 0 {
    return Err(InvalidFormat)
  }
  if value <= 0xFF {
    return Ok(1)
  }
  if value <= 0xFFFF {
    return Ok(2)
  }
  if value <= 0xFFFFFF {
    return Ok(3)
  }
  if value <= 0x7FFFFFFF {
    return Ok(4)
  }
  Err(InvalidFormat)
}

fn push_offset(bytes : Array[Byte], value : Int, size : Int) -> Result[Unit, CffError] {
  if value < 0 {
    return Err(InvalidFormat)
  }
  if size <= 0 || size > 4 {
    return Err(InvalidFormat)
  }
  for i in 0..<size {
    let shift = (size - 1 - i) * 8
    bytes.push(((value >> shift) & 0xff).to_byte())
  }
  Ok(())
}

fn write_cff_index(items : Array[Bytes], count_bytes : Int) -> Result[Bytes, CffError] {
  let bytes : Array[Byte] = []
  let count = items.length()
  match push_count(bytes, count, count_bytes) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if count == 0 {
    return Ok(Bytes::from_array(bytes))
  }
  let offsets : Array[Int] = []
  let mut current = 1
  offsets.push(current)
  for item in items {
    current = current + item.length()
    offsets.push(current)
  }
  let off_size = match offset_size_for(current) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  bytes.push(off_size.to_byte())
  for off in offsets {
    match push_offset(bytes, off, off_size) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  for item in items {
    for b in item {
      bytes.push(b)
    }
  }
  Ok(Bytes::from_array(bytes))
}

fn write_cff_int(bytes : Array[Byte], value : Int) -> Unit {
  if value >= -107 && value <= 107 {
    bytes.push((value + 139).to_byte())
    return
  }
  if value >= 108 && value <= 1131 {
    let v = value - 108
    bytes.push(((v / 256) + 247).to_byte())
    bytes.push((v % 256).to_byte())
    return
  }
  if value <= -108 && value >= -1131 {
    let v = -value - 108
    bytes.push(((v / 256) + 251).to_byte())
    bytes.push((v % 256).to_byte())
    return
  }
  if value >= -32768 && value <= 32767 {
    let raw = if value < 0 { value + 0x10000 } else { value }
    bytes.push(28)
    bytes.push(((raw >> 8) & 0xff).to_byte())
    bytes.push((raw & 0xff).to_byte())
    return
  }
  bytes.push(29)
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

fn write_cff_real(bytes : Array[Byte], value : Double) -> Result[Unit, CffError] {
  if value.is_nan() || value.is_inf() {
    return Err(InvalidFormat)
  }
  let text = value.to_string()
  if text == "NaN" || text == "Infinity" || text == "-Infinity" {
    return Err(InvalidFormat)
  }
  let chars = text.to_array()
  let nibbles : Array[Int] = []
  let mut i = 0
  while i < chars.length() {
    let ch = chars[i]
    if ch >= '0' && ch <= '9' {
      nibbles.push(ch.to_int() - '0'.to_int())
      i = i + 1
      continue
    }
    match ch {
      '.' => nibbles.push(0xA)
      '-' => nibbles.push(0xE)
      'e' | 'E' => {
        if i + 1 < chars.length() && chars[i + 1] == '-' {
          nibbles.push(0xC)
          i = i + 1
        } else {
          nibbles.push(0xB)
          if i + 1 < chars.length() && chars[i + 1] == '+' {
            i = i + 1
          }
        }
      }
      '+' => ()
      _ => return Err(InvalidFormat)
    }
    i = i + 1
  }
  nibbles.push(0xF)
  if (nibbles.length() % 2) != 0 {
    nibbles.push(0xF)
  }
  bytes.push(30)
  let mut idx = 0
  while idx + 1 < nibbles.length() {
    let byte = (nibbles[idx] << 4) | nibbles[idx + 1]
    bytes.push(byte.to_byte())
    idx = idx + 2
  }
  Ok(())
}

fn write_cff_number(bytes : Array[Byte], value : CffNumber) -> Result[Unit, CffError] {
  match value {
    Int(value) => {
      write_cff_int(bytes, value)
      Ok(())
    }
    Real(value) => write_cff_real(bytes, value)
  }
}

fn sort_ints(values : Array[Int]) -> Array[Int] {
  let sorted = values.copy()
  let n = sorted.length()
  for i in 1..<n {
    let key = sorted[i]
    let mut j = i - 1
    while j >= 0 && sorted[j] > key {
      sorted[j + 1] = sorted[j]
      j = j - 1
    }
    sorted[j + 1] = key
  }
  sorted
}

fn write_cff_dict(entries : Map[Int, Array[CffNumber]]) -> Result[Bytes, CffError] {
  let ops = sort_ints(entries.keys().to_array())
  let bytes : Array[Byte] = []
  for op in ops {
    let operands = match entries.get(op) {
      None => continue
      Some(values) => values
    }
    for operand in operands {
      match write_cff_number(bytes, operand) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
    }
    if op >= 0x100 {
      bytes.push(12)
      bytes.push((op & 0xff).to_byte())
    } else {
      bytes.push(op.to_byte())
    }
  }
  Ok(Bytes::from_array(bytes))
}
