///|
fn parse_lookup(
  data : BytesView,
  offset : Int,
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
            offsets.push(abs_offset)
          }
        }
      }
      if (lookup_flag & 0x0010) != 0 {
        let mark_offset = offset + header_len
        if mark_offset + 2 > data.length() {
          return Err(UnexpectedEof)
        }
        let _ = read_u16_int(data, mark_offset)
      }
      Ok((lookup_type, offsets))
    }
  }
}
