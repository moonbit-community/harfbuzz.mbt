///|
let op_charstrings : Int = 0x11

///|
let op_private : Int = 0x12

///|
let op_subrs : Int = 0x13

///|
let op_charset : Int = 0x0F

///|
pub struct Cff1Table {
  data : Bytes
  name_index : CffIndex
  top_dict : CffDict
  string_index : CffIndex
  global_subrs : CffIndex
  charstrings : CffIndex
  private_dict : CffDict?
  local_subrs : CffIndex?
  charstrings_offset : Int
  private_offset : Int
  private_size : Int
  charset_offset : Int
  charset_map : Map[Int, Int]?
} derive(Eq, Show, ToJson)

///|
pub fn Cff1Table::parse(data : BytesView) -> Result[Cff1Table, CffError] {
  if data.length() < 4 {
    return Err(UnexpectedEof)
  }
  let header_size = data[2].to_int()
  if header_size < 4 || header_size > data.length() {
    return Err(InvalidFormat)
  }
  let mut pos = header_size
  let (name_index, next_pos) = match parse_cff1_index_at(data, pos) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  pos = next_pos
  let (top_dict_index, next_pos) = match parse_cff1_index_at(data, pos) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  pos = next_pos
  let (string_index, next_pos) = match parse_cff1_index_at(data, pos) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  pos = next_pos
  let (global_subrs, next_pos) = match parse_cff1_index_at(data, pos) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  pos = next_pos
  if top_dict_index.count <= 0 {
    return Err(InvalidFormat)
  }
  let top_bytes = match top_dict_index.item_bytes(0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let top_dict = match parse_cff_dict(top_bytes[:]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let charstrings_offset = match top_dict.get_int(op_charstrings) {
    None => return Err(InvalidFormat)
    Some(value) => value
  }
  let charset_offset = match top_dict.get_int(op_charset) {
    None => 0
    Some(value) => value
  }
  let private_size_opt = top_dict.get_int(op_private, index=0)
  let private_offset_opt = top_dict.get_int(op_private, index=1)
  let (private_size, private_offset) =
    match (private_size_opt, private_offset_opt) {
      (None, None) => (0, 0)
      (Some(size), Some(offset)) => (size, offset)
      _ => return Err(InvalidFormat)
    }
  let charstrings = match parse_cff1_index(data, charstrings_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let charset_map =
    if charset_offset > 2 {
      match parse_cff1_charset(data, charset_offset, charstrings.count) {
        Err(err) => return Err(err)
        Ok(value) => Some(value)
      }
    } else {
      None
    }
  let (private_dict, local_subrs) =
    if private_size > 0 {
      if private_offset < 0 || private_offset + private_size > data.length() {
        return Err(UnexpectedEof)
      }
      let priv_bytes = data[private_offset:private_offset + private_size]
      let priv_dict = match parse_cff_dict(priv_bytes) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let local_subrs = match priv_dict.get_int(op_subrs) {
        None => None
        Some(subrs_offset) => {
          let subrs_base = private_offset + subrs_offset
          match parse_cff1_index(data, subrs_base) {
            Err(err) => return Err(err)
            Ok(value) => Some(value)
          }
        }
      }
      (Some(priv_dict), local_subrs)
    } else {
      (None, None)
    }
  Ok(Cff1Table::{
    data: data.to_bytes(),
    name_index,
    top_dict,
    string_index,
    global_subrs,
    charstrings,
    private_dict,
    local_subrs,
    charstrings_offset,
    private_offset,
    private_size,
    charset_offset,
    charset_map,
  })
}

///|
pub fn Cff1Table::glyph_bounds(
  self : Cff1Table,
  glyph : Int,
) -> Result[CffBounds?, CffError] {
  if glyph < 0 || glyph >= self.charstrings.count {
    return Err(InvalidFormat)
  }
  let bytes = match self.charstrings.item_bytes(glyph) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let seac = Cff1SeacContext::{
    charstrings: self.charstrings,
    charset_offset: self.charset_offset,
    charset_map: self.charset_map,
    glyph_count: self.charstrings.count,
  }
  cff1_charstring_bounds(bytes[:], Some(self.global_subrs), self.local_subrs, seac)
}

fn parse_cff1_index_at(
  data : BytesView,
  offset : Int,
) -> Result[(CffIndex, Int), CffError] {
  let index = match parse_cff1_index(data, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  Ok((index, offset + index.byte_len(2)))
}
