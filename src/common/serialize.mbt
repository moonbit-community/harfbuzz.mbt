///|
pub enum SerializeError {
  InvalidWidth
  OutOfBounds
  OffsetOverflow
  InvalidLink
  NegativeOffset
  VirtualOrder
} derive(Eq, Show)

///|
pub(all) enum SerializeWhence {
  Head
  Tail
  Absolute
} derive(Eq, Show)

///|
pub(all) struct SerializeLink {
  width : Int
  position : Int
  objidx : Int
  is_signed : Bool
  whence : SerializeWhence
  bias : Int
}

///|
pub struct SerializeObject {
  data : Bytes
  real_links : Array[SerializeLink]
  virtual_links : Array[Int]
}

///|
pub fn SerializeObject::new(data : Bytes) -> SerializeObject {
  SerializeObject::{ data, real_links: [], virtual_links: [] }
}

///|
pub fn SerializeLink::new(
  width : Int,
  position : Int,
  objidx : Int,
  is_signed? : Bool = false,
  whence? : SerializeWhence = SerializeWhence::Head,
  bias? : Int = 0,
) -> SerializeLink {
  SerializeLink::{ width, position, objidx, is_signed, whence, bias }
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

fn signed_limits(width : Int) -> (Int, Int)? {
  if width <= 0 {
    return None
  }
  let bits = width * 8
  let max = (1 << (bits - 1)) - 1
  let min = -1 * (1 << (bits - 1))
  Some((min, max))
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
    for target in objects[i].virtual_links {
      if target < 0 || target >= count {
        return Err(SerializeError::InvalidLink)
      }
      if target <= i {
        return Err(SerializeError::VirtualOrder)
      }
    }
  }
  for i in 0..<count {
    let base = starts[i]
    for link in objects[i].real_links {
      if link.objidx < 0 || link.objidx >= count {
        return Err(SerializeError::InvalidLink)
      }
      let target_start = starts[link.objidx]
      let origin = match link.whence {
        SerializeWhence::Head => base
        SerializeWhence::Tail => base + objects[i].data.length()
        SerializeWhence::Absolute => 0
      }
      let offset = target_start + link.bias - origin
      if !link.is_signed && offset < 0 {
        return Err(SerializeError::NegativeOffset)
      }
      let value = if link.is_signed {
        let limits = match signed_limits(link.width) {
          None => return Err(SerializeError::InvalidWidth)
          Some((min, max)) => (min, max)
        }
        if offset < limits.0 || offset > limits.1 {
          return Err(SerializeError::OffsetOverflow)
        }
        if offset < 0 {
          let mask = 1 << (link.width * 8)
          (offset + mask).reinterpret_as_uint()
        } else {
          offset.reinterpret_as_uint()
        }
      } else {
        offset.reinterpret_as_uint()
      }
      let result = write_offset(
        patched[i],
        link.position,
        link.width,
        value,
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
