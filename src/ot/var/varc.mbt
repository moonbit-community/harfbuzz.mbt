///|
pub struct VarcTable {
  version : Int
  coverage_offset : Int
  var_store_offset : Int
  condition_list_offset : Int
  axis_indices_offset : Int
  glyph_records_offset : Int
  data : Bytes
} derive(Show, ToJson)

struct CffIndex {
  count : Int
  off_size : Int
  offsets : Array[Int]
  data : Bytes
} derive(Show, ToJson)

fn validate_offset(offset : Int, length : Int) -> Result[Unit, VarError] {
  if offset < 0 || offset > length {
    return Err(UnexpectedEof)
  }
  Ok(())
}

fn read_cff_offset(data : BytesView, offset : Int, size : Int) -> Result[Int, VarError] {
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

fn parse_cff2_index(data : BytesView, offset : Int) -> Result[CffIndex, VarError] {
  let count = read_u32_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      if count == 0 {
        return Ok(CffIndex::{ count: 0, off_size: 0, offsets: [], data: Bytes::from_array([]) })
      }
      let off_size = read_u8_int(data, offset + 4)
      match off_size {
        Err(err) => Err(err)
        Ok(off_size) => {
          if off_size <= 0 || off_size > 4 {
            return Err(InvalidFormat)
          }
          let mut pos = offset + 5
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

fn CffIndex::item_bytes(self : CffIndex, index : Int) -> Result[Bytes, VarError] {
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

fn int8_from_byte_varc(value : Byte) -> Int {
  let v = value.to_int()
  if v >= 0x80 { v - 0x100 } else { v }
}

fn decode_tuple_values(data : BytesView) -> Result[Array[Int], VarError] {
  let values : Array[Int] = []
  let mut pos = 0
  while pos < data.length() {
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x3F) + 1
    let mode = control & 0xC0
    if mode == 0x80 {
      for _ in 0..<run_count {
        values.push(0)
      }
    } else if mode == 0x40 {
      let needed = run_count * 2
      if pos + needed > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i16(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => values.push(v)
        }
        pos = pos + 2
      }
    } else if mode == 0xC0 {
      let needed = run_count * 4
      if pos + needed > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        let value = read_i32(data, pos)
        match value {
          Err(err) => return Err(err)
          Ok(v) => values.push(v)
        }
        pos = pos + 4
      }
    } else {
      if pos + run_count > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<run_count {
        values.push(int8_from_byte_varc(data[pos]))
        pos = pos + 1
      }
    }
  }
  Ok(values)
}

///|
pub fn VarcTable::parse(data : BytesView) -> Result[VarcTable, VarError] {
  let version = read_u32(data, 0)
  let coverage_offset = read_u32_int(data, 4)
  let var_store_offset = read_u32_int(data, 8)
  let condition_list_offset = read_u32_int(data, 12)
  let axis_indices_offset = read_u32_int(data, 16)
  let glyph_records_offset = read_u32_int(data, 20)
  match (
    version,
    coverage_offset,
    var_store_offset,
    condition_list_offset,
    axis_indices_offset,
    glyph_records_offset,
  ) {
    (Err(err), _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _) => Err(err)
    (_, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(coverage_offset), Ok(var_store_offset), Ok(condition_list_offset), Ok(axis_indices_offset), Ok(glyph_records_offset)) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      let length = data.length()
      match validate_offset(coverage_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(var_store_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(condition_list_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(axis_indices_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(glyph_records_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      Ok(VarcTable::{
        version: version.reinterpret_as_int(),
        coverage_offset,
        var_store_offset,
        condition_list_offset,
        axis_indices_offset,
        glyph_records_offset,
        data: data.to_bytes(),
      })
    }
  }
}

///|
pub fn VarcTable::axis_indices(self : VarcTable, index : Int) -> Result[Array[Int], VarError] {
  if self.axis_indices_offset == 0 {
    return Err(InvalidFormat)
  }
  let idx = match parse_cff2_index(self.data[:], self.axis_indices_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let bytes = match idx.item_bytes(index) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  decode_tuple_values(bytes[:])
}
