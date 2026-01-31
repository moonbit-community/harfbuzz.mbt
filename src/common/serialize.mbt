///|
pub enum SerializeError {
  InvalidWidth
  OutOfBounds
  OffsetOverflow
  InvalidLink
  NegativeOffset
} derive(Eq, Show)

///|
pub(all) struct SerializeLink {
  width : Int
  position : Int
  objidx : Int
}

///|
pub struct SerializeObject {
  data : Bytes
  real_links : Array[SerializeLink]
}

///|
pub fn SerializeObject::new(data : Bytes) -> SerializeObject {
  SerializeObject::{ data, real_links: [] }
}

fn max_value_for_width(width : Int) -> UInt? {
  if width == 1 {
    Some(0xFFU)
  } else if width == 2 {
    Some(0xFFFFU)
  } else if width == 3 {
    Some(0xFFFFFFU)
  } else if width == 4 {
    Some(0xFFFF_FFFFU)
  } else {
    None
  }
}

fn write_offset(
  data : Array[Byte],
  position : Int,
  width : Int,
  value : UInt,
) -> Result[Unit, SerializeError] {
  let max_value = match max_value_for_width(width) {
    None => return Err(SerializeError::InvalidWidth)
    Some(v) => v
  }
  if value > max_value {
    return Err(SerializeError::OffsetOverflow)
  }
  if position < 0 || position + width > data.length() {
    return Err(SerializeError::OutOfBounds)
  }
  for i in 0..<width {
    let shift = (width - 1 - i) * 8
    let byte_value = ((value >> shift) & 0xFFU).to_byte()
    data[position + i] = byte_value
  }
  Ok(())
}

///|
/// Serialize objects into a contiguous buffer, patching offsets for real links.
pub fn serialize_objects(
  objects : ArrayView[SerializeObject],
) -> Result[Bytes, SerializeError] {
  let count = objects.length()
  let starts : Array[Int] = []
  let mut total = 0
  for obj in objects {
    starts.push(total)
    total = total + obj.data.length()
  }
  let patched : Array[Array[Byte]] = []
  for obj in objects {
    patched.push(obj.data.to_array())
  }
  for i in 0..<count {
    let base = starts[i]
    for link in objects[i].real_links {
      if link.objidx < 0 || link.objidx >= count {
        return Err(SerializeError::InvalidLink)
      }
      let target = starts[link.objidx] - base
      if target < 0 {
        return Err(SerializeError::NegativeOffset)
      }
      let result = write_offset(
        patched[i],
        link.position,
        link.width,
        target.reinterpret_as_uint(),
      )
      match result {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    }
  }
  let buffer = @buffer.new(size_hint=total)
  for bytes in patched {
    buffer.write_bytes(Bytes::from_array(bytes))
  }
  Ok(buffer.to_bytes())
}
