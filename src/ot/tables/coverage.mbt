///|
fn coverage_index(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int?, OtLayoutError] {
  if glyph > 0xffffU {
    return Ok(None)
  }
  let glyph_int = u16_to_int(glyph)
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      if format == 1 {
        coverage_format1(data, offset, glyph_int)
      } else if format == 2 {
        coverage_format2(data, offset, glyph_int)
      } else {
        Err(InvalidFormat)
      }
  }
}

///|
fn coverage_format1(
  data : BytesView,
  offset : Int,
  glyph : Int,
) -> Result[Int?, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, offset + 2)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      let list_offset = offset + 4
      if list_offset < 0 || list_offset + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let value = read_u16_int(data, list_offset + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => if value == glyph { return Ok(Some(i)) }
        }
      }
      Ok(None)
    }
  }
}

///|
fn coverage_format2(
  data : BytesView,
  offset : Int,
  glyph : Int,
) -> Result[Int?, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, offset + 2)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      let record_offset = offset + 4
      let record_size = 6
      if record_offset < 0 || record_offset + count * record_size > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let base = record_offset + i * record_size
        let start = read_u16_int(data, base)
        let end = read_u16_int(data, base + 2)
        let start_index = read_u16_int(data, base + 4)
        match (start, end, start_index) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start), Ok(end), Ok(start_index)) =>
            if glyph >= start && glyph <= end {
              return Ok(Some(start_index + (glyph - start)))
            }
        }
      }
      Ok(None)
    }
  }
}
