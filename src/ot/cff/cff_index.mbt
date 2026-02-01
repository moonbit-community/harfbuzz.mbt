///|
pub struct CffIndex {
  count : Int
  off_size : Int
  offsets : Array[Int]
  data : Bytes
} derive(Eq, Show, ToJson)

///|
pub fn parse_cff1_index(data : BytesView, offset : Int) -> Result[CffIndex, CffError] {
  parse_cff_index(data, offset, 2)
}

///|
pub fn parse_cff2_index(data : BytesView, offset : Int) -> Result[CffIndex, CffError] {
  parse_cff_index(data, offset, 4)
}

fn parse_cff_index(
  data : BytesView,
  offset : Int,
  count_bytes : Int,
) -> Result[CffIndex, CffError] {
  let count =
    if count_bytes == 2 {
      read_u16_int(data, offset)
    } else if count_bytes == 4 {
      read_u32_int(data, offset)
    } else {
      Err(InvalidFormat)
    }
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      if count == 0 {
        return Ok(CffIndex::{ count: 0, off_size: 0, offsets: [], data: Bytes::from_array([]) })
      }
      let off_size = read_u8_int(data, offset + count_bytes)
      match off_size {
        Err(err) => Err(err)
        Ok(off_size) => {
          if off_size <= 0 || off_size > 4 {
            return Err(InvalidFormat)
          }
          let mut pos = offset + count_bytes + 1
          let offsets : Array[Int] = []
          for _ in 0..<(count + 1) {
            let value = read_cff_offset(data, pos, off_size)
            match value {
              Err(err) => return Err(err)
              Ok(v) => offsets.push(v)
            }
            pos = pos + off_size
          }
          let data_start = pos
          let last = offsets[offsets.length() - 1]
          if last <= 0 {
            return Err(InvalidFormat)
          }
          let data_len = last - 1
          if data_len < 0 || data_start + data_len > data.length() {
            return Err(UnexpectedEof)
          }
          let data_bytes = data[data_start:data_start + data_len].to_bytes()
          Ok(CffIndex::{ count, off_size, offsets, data: data_bytes })
        }
      }
    }
  }
}

///|
pub fn CffIndex::item_bytes(self : CffIndex, index : Int) -> Result[Bytes, CffError] {
  if index < 0 || index >= self.count {
    return Err(InvalidFormat)
  }
  if self.count == 0 {
    return Ok(Bytes::from_array([]))
  }
  let start = self.offsets[index] - 1
  let end = self.offsets[index + 1] - 1
  if start < 0 || end < start || end > self.data.length() {
    return Err(InvalidFormat)
  }
  Ok(self.data[start:end].to_bytes())
}

///|
pub fn CffIndex::byte_len(self : CffIndex, count_bytes : Int) -> Int {
  if self.count == 0 {
    return count_bytes
  }
  count_bytes + 1 + (self.count + 1) * self.off_size + self.data.length()
}
