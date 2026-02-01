///|
let op_charstrings_cff2 : Int = 0x11

///|
let op_fdarray_cff2 : Int = (12 << 8) | 36

///|
let op_fdselect_cff2 : Int = (12 << 8) | 37

///|
let op_vstore_cff2 : Int = 0x18

///|
let op_private_cff2 : Int = 0x12

///|
let op_subrs_cff2 : Int = 0x13

///|
let op_vsindexdict_cff2 : Int = 0x16

///|
pub struct Cff2PrivateDict {
  local_subrs : CffIndex?
  ivs : Int
} derive(Eq, Show, ToJson)

///|
pub struct Cff2Table {
  data : Bytes
  top_dict : CffDict
  global_subrs : CffIndex
  charstrings : CffIndex
  fd_array : CffIndex
  private_dicts : Array[Cff2PrivateDict]
  var_store : @ot_var.ItemVariationStore?
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
      let private_dicts = match parse_fd_array_private_dicts(data, fd_array) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let var_store =
        if vstore_offset == 0 {
          None
        } else {
          match parse_cff2_var_store(data, vstore_offset) {
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
        private_dicts,
        var_store,
        fd_select,
        fdselect_offset,
        vstore_offset,
        top_dict_offset: offset,
        top_dict_size: size,
      })
    }
  }
}

///|
pub fn Cff2Table::glyph_bounds(
  self : Cff2Table,
  glyph : Int,
  coords : Array[Int],
) -> Result[CffBounds?, CffError] {
  if glyph < 0 || glyph >= self.charstrings.count {
    return Err(InvalidFormat)
  }
  let fd =
    match self.fd_select {
      None => 0
      Some(values) => {
        if glyph < 0 || glyph >= values.length() {
          return Err(InvalidFormat)
        }
        values[glyph]
      }
    }
  if fd < 0 || fd >= self.private_dicts.length() {
    return Err(InvalidFormat)
  }
  let priv_dict = self.private_dicts[fd]
  let bytes = match self.charstrings.item_bytes(glyph) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  cff2_charstring_bounds(
    bytes[:],
    Some(self.global_subrs),
    priv_dict.local_subrs,
    self.var_store,
    priv_dict.ivs,
    coords,
  )
}

fn parse_fd_array_private_dicts(
  data : BytesView,
  fd_array : CffIndex,
) -> Result[Array[Cff2PrivateDict], CffError] {
  if fd_array.count < 0 {
    return Err(InvalidFormat)
  }
  let values : Array[Cff2PrivateDict] = []
  for i in 0..<fd_array.count {
    let bytes = match fd_array.item_bytes(i) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let dict = match parse_cff_dict(bytes[:]) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let private_size_opt = dict.get_int(op_private_cff2, index=0)
    let private_offset_opt = dict.get_int(op_private_cff2, index=1)
    let (private_size, private_offset) =
      match (private_size_opt, private_offset_opt) {
        (None, None) => (0, 0)
        (Some(size), Some(offset)) => (size, offset)
        _ => return Err(InvalidFormat)
      }
    let priv_dict = match parse_cff2_private_dict(data, private_offset, private_size) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    values.push(priv_dict)
  }
  Ok(values)
}

fn parse_cff2_private_dict(
  data : BytesView,
  offset : Int,
  size : Int,
) -> Result[Cff2PrivateDict, CffError] {
  if size <= 0 {
    return Ok(Cff2PrivateDict::{ local_subrs: None, ivs: 0 })
  }
  if offset < 0 || offset + size > data.length() {
    return Err(UnexpectedEof)
  }
  let priv_bytes = data[offset:offset + size]
  let dict = match parse_cff_dict(priv_bytes) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let ivs = match dict.get_int(op_vsindexdict_cff2) {
    None => 0
    Some(value) => value
  }
  let local_subrs =
    match dict.get_int(op_subrs_cff2) {
      None => None
      Some(subrs_offset) => {
        let subrs_base = offset + subrs_offset
        if subrs_base < 0 || subrs_base > data.length() {
          return Err(UnexpectedEof)
        }
        match parse_cff2_index(data, subrs_base) {
          Err(err) => return Err(err)
          Ok(value) => Some(value)
        }
      }
    }
  Ok(Cff2PrivateDict::{ local_subrs, ivs })
}

fn parse_cff2_var_store(
  data : BytesView,
  offset : Int,
) -> Result[@ot_var.ItemVariationStore, CffError] {
  let size = read_u16_int(data, offset)
  let size = match size {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if size <= 0 {
    return Err(InvalidFormat)
  }
  if offset + 2 + size > data.length() {
    return Err(UnexpectedEof)
  }
  let bytes = data[offset + 2:offset + 2 + size]
  match @ot_var.ItemVariationStore::parse(bytes) {
    Err(err) => Err(map_var_error(err))
    Ok(value) => Ok(value)
  }
}

fn map_var_error(err : @ot_var.VarError) -> CffError {
  match err {
    @ot_var.VarError::UnexpectedEof => UnexpectedEof
    @ot_var.VarError::InvalidFormat => InvalidFormat
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
      } else if format == 4 {
        let range_count = read_u32_int(data, offset + 1)
        match range_count {
          Err(err) => Err(err)
          Ok(range_count) => {
            if range_count < 0 {
              return Err(InvalidFormat)
            }
            let mut pos = offset + 5
            let starts : Array[Int] = []
            let fds : Array[Int] = []
            for _ in 0..<range_count {
              let start = read_u32_int(data, pos)
              let fd = read_u16_int(data, pos + 4)
              match (start, fd) {
                (Err(err), _) => return Err(err)
                (_, Err(err)) => return Err(err)
                (Ok(start), Ok(fd)) => {
                  starts.push(start)
                  fds.push(fd)
                }
              }
              pos = pos + 6
            }
            let sentinel = read_u32_int(data, pos)
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
