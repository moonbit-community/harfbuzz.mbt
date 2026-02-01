///|
let op_charstrings_cff2 : Int = 0x11

///|
let op_fdarray_cff2 : Int = (12 << 8) | 36

///|
let op_fdselect_cff2 : Int = (12 << 8) | 37

///|
let op_vstore_cff2 : Int = 0x18

///|
pub struct Cff2Table {
  data : Bytes
  top_dict : CffDict
  global_subrs : CffIndex
  charstrings : CffIndex
  fd_array : CffIndex
  fd_select : Array[Int]?
  fdselect_offset : Int
  vstore_offset : Int
  top_dict_offset : Int
  top_dict_size : Int
} derive(Eq, Show, ToJson)

///|
pub fn Cff2Table::parse(data : BytesView) -> Result[Cff2Table, CffError] {
  if data.length() < 5 {
    return Err(UnexpectedEof)
  }
  let major = data[0].to_int()
  if major != 2 {
    return Err(InvalidFormat)
  }
  let top_dict_offset = read_u8_int(data, 2)
  let top_dict_size = read_u16_int(data, 3)
  match (top_dict_offset, top_dict_size) {
    (Err(err), _) => return Err(err)
    (_, Err(err)) => return Err(err)
    (Ok(offset), Ok(size)) => {
      if offset < 5 || size < 0 || offset + size > data.length() {
        return Err(InvalidFormat)
      }
      let top_dict_bytes = data[offset:offset + size]
      let top_dict = match parse_cff_dict(top_dict_bytes) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let charstrings_offset = match top_dict.get_int(op_charstrings_cff2) {
        None => return Err(InvalidFormat)
        Some(value) => value
      }
      let fdarray_offset = match top_dict.get_int(op_fdarray_cff2) {
        None => return Err(InvalidFormat)
        Some(value) => value
      }
      let fdselect_offset = match top_dict.get_int(op_fdselect_cff2) {
        None => return Err(InvalidFormat)
        Some(value) => value
      }
      let vstore_offset = match top_dict.get_int(op_vstore_cff2) {
        None => 0
        Some(value) => value
      }
      if charstrings_offset < 0 || charstrings_offset > data.length() {
        return Err(InvalidFormat)
      }
      if fdarray_offset < 0 || fdarray_offset > data.length() {
        return Err(InvalidFormat)
      }
      if fdselect_offset < 0 || fdselect_offset > data.length() {
        return Err(InvalidFormat)
      }
      if vstore_offset < 0 || vstore_offset > data.length() {
        return Err(InvalidFormat)
      }
      let global_offset = offset + size
      let global_subrs = match parse_cff2_index(data, global_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let charstrings = match parse_cff2_index(data, charstrings_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let fd_array = match parse_cff2_index(data, fdarray_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let fd_select =
        if fdselect_offset == 0 || charstrings.count == 0 {
          None
        } else {
          match parse_fdselect(data, fdselect_offset, charstrings.count) {
            Err(err) => return Err(err)
            Ok(value) => Some(value)
          }
        }
      Ok(Cff2Table::{
        data: data.to_bytes(),
        top_dict,
        global_subrs,
        charstrings,
        fd_array,
        fd_select,
        fdselect_offset,
        vstore_offset,
        top_dict_offset: offset,
        top_dict_size: size,
      })
    }
  }
}

fn parse_fdselect(
  data : BytesView,
  offset : Int,
  glyph_count : Int,
) -> Result[Array[Int], CffError] {
  if glyph_count < 0 {
    return Err(InvalidFormat)
  }
  let format = read_u8_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      if format == 0 {
        if offset + 1 + glyph_count > data.length() {
          return Err(UnexpectedEof)
        }
        let values : Array[Int] = []
        for i in 0..<glyph_count {
          values.push(data[offset + 1 + i].to_int())
        }
        Ok(values)
      } else if format == 3 {
        let range_count = read_u16_int(data, offset + 1)
        match range_count {
          Err(err) => Err(err)
          Ok(range_count) => {
            if range_count < 0 {
              return Err(InvalidFormat)
            }
            let mut pos = offset + 3
            let starts : Array[Int] = []
            let fds : Array[Int] = []
            for _ in 0..<range_count {
              let start = read_u16_int(data, pos)
              let fd = read_u8_int(data, pos + 2)
              match (start, fd) {
                (Err(err), _) => return Err(err)
                (_, Err(err)) => return Err(err)
                (Ok(start), Ok(fd)) => {
                  starts.push(start)
                  fds.push(fd)
                }
              }
              pos = pos + 3
            }
            let sentinel = read_u16_int(data, pos)
            let sentinel = match sentinel {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            let values : Array[Int] = Array::make(glyph_count, 0)
            for i in 0..<starts.length() {
              let start = starts[i]
              let end =
                if i + 1 < starts.length() { starts[i + 1] } else { sentinel }
              if start < 0 || end < start {
                return Err(InvalidFormat)
              }
              let mut g = start
              while g < end && g < glyph_count {
                values[g] = fds[i]
                g = g + 1
              }
            }
            Ok(values)
          }
        }
      } else {
        Err(InvalidFormat)
      }
  }
}
