///|
fn parse_lookup(
  data : BytesView,
  offset : Int,
  extension_lookup_type : Int,
) -> Result[(Int, Array[Int]), OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let lookup_type = read_u16_int(data, offset)
  let lookup_flag = read_u16_int(data, offset + 2)
  let subtable_count = read_u16_int(data, offset + 4)
  match (lookup_type, lookup_flag, subtable_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(lookup_type), Ok(lookup_flag), Ok(subtable_count)) => {
      let header_len = 6 + subtable_count * 2
      if offset + header_len > data.length() {
        return Err(UnexpectedEof)
      }
      let offsets : Array[Int] = []
      let mut resolved_type = lookup_type
      let mut extension_subtable_type : Int? = None
      let base = offset + 6
      for i in 0..<subtable_count {
        let sub_offset = read_u16_int(data, base + i * 2)
        match sub_offset {
          Err(err) => return Err(err)
          Ok(sub_offset) => {
            if sub_offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = offset + sub_offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            if lookup_type == extension_lookup_type {
              let ext = parse_extension_subtable(data, abs_offset)
              match ext {
                Err(err) => return Err(err)
                Ok((ext_type, ext_offset)) => {
                  match extension_subtable_type {
                    None => extension_subtable_type = Some(ext_type)
                    Some(prev) => if prev != ext_type { return Err(InvalidFormat) }
                  }
                  offsets.push(ext_offset)
                }
              }
            } else {
              offsets.push(abs_offset)
            }
          }
        }
      }
      if lookup_type == extension_lookup_type {
        match extension_subtable_type {
          None => return Err(InvalidFormat)
          Some(value) => resolved_type = value
        }
      }
      if (lookup_flag & 0x0010) != 0 {
        let mark_offset = offset + header_len
        if mark_offset + 2 > data.length() {
          return Err(UnexpectedEof)
        }
        let _ = read_u16_int(data, mark_offset)
      }
      Ok((resolved_type, offsets))
    }
  }
}

///|
fn parse_extension_subtable(
  data : BytesView,
  offset : Int,
) -> Result[(Int, Int), OtLayoutError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  let lookup_type = read_u16_int(data, offset + 2)
  let extension_offset = read_u32_int(data, offset + 4)
  match (format, lookup_type, extension_offset) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(format), Ok(lookup_type), Ok(extension_offset)) => {
      if format != 1 {
        return Err(InvalidFormat)
      }
      if extension_offset <= 0 {
        return Err(InvalidFormat)
      }
      let abs_offset = offset + extension_offset
      if abs_offset < 0 || abs_offset >= data.length() {
        return Err(UnexpectedEof)
      }
      Ok((lookup_type, abs_offset))
    }
  }
}
