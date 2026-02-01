///|
let op_charstrings : Int = 0x11

///|
let op_encoding : Int = 0x10

///|
let op_private : Int = 0x12

///|
let op_subrs : Int = 0x13

///|
let op_charset : Int = 0x0F

///|
let op_ros : Int = 0x0C1E

///|
let op_fd_array : Int = 0x0C24

///|
let op_fd_select : Int = 0x0C25

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

///|
pub fn Cff1Table::glyph_count(self : Cff1Table) -> Int {
  self.charstrings.count
}

///|
pub fn Cff1Table::seac_components(
  self : Cff1Table,
  glyph : Int,
) -> Result[(Int, Int)?, CffError] {
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
  cff1_charstring_seac_components(
    bytes[:],
    Some(self.global_subrs),
    self.local_subrs,
    seac,
  )
}

fn clone_entries(entries : Map[Int, Array[CffNumber]]) -> Map[Int, Array[CffNumber]] {
  let next : Map[Int, Array[CffNumber]] = {}
  entries.eachi((_, key, value) => {
    next[key] = value.copy()
  })
  next
}

fn replace_entry(
  entries : Map[Int, Array[CffNumber]],
  op : Int,
  values : Array[CffNumber],
) -> Unit {
  entries[op] = values
}

fn remove_entry(entries : Map[Int, Array[CffNumber]], op : Int) -> Unit {
  match entries.get(op) {
    None => ()
    Some(_) => entries.remove(op)
  }
}

fn build_charset_bytes(
  glyphs : Array[Int],
  gid_to_sid : Array[Int],
) -> Result[Bytes, CffError] {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  if glyphs.length() <= 1 {
    return Ok(Bytes::from_array(bytes))
  }
  for i in 1..<glyphs.length() {
    let gid = glyphs[i]
    if gid < 0 || gid >= gid_to_sid.length() {
      return Err(InvalidFormat)
    }
    let sid = gid_to_sid[gid]
    if sid < 0 || sid > 0xFFFF {
      return Err(InvalidFormat)
    }
    bytes.push(((sid >> 8) & 0xff).to_byte())
    bytes.push((sid & 0xff).to_byte())
  }
  Ok(Bytes::from_array(bytes))
}

fn build_index_items(index : CffIndex) -> Result[Array[Bytes], CffError] {
  let items : Array[Bytes] = []
  for i in 0..<index.count {
    let bytes = match index.item_bytes(i) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    items.push(bytes)
  }
  Ok(items)
}

fn build_private_dict(
  private_dict : CffDict,
  local_subrs : CffIndex?,
) -> Result[(Bytes, Bytes?), CffError] {
  let entries = clone_entries(private_dict.entries_map())
  remove_entry(entries, op_subrs)
  match local_subrs {
    None => {
      let private_bytes = match write_cff_dict(entries) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok((private_bytes, None))
    }
    Some(subrs) => {
      let subr_items = match build_index_items(subrs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let subr_index = match write_cff_index(subr_items, 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut dict_bytes = match write_cff_dict(entries) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut done = false
      let mut iter = 0
      while !done && iter < 5 {
        replace_entry(entries, op_subrs, [Int(dict_bytes.length())])
        let next = match write_cff_dict(entries) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if next.length() == dict_bytes.length() {
          dict_bytes = next
          done = true
        } else {
          dict_bytes = next
        }
        iter = iter + 1
      }
      if !done {
        return Err(InvalidFormat)
      }
      Ok((dict_bytes, Some(subr_index)))
    }
  }
}

fn build_top_dict(
  base : Map[Int, Array[CffNumber]],
  charset_offset : Int,
  charstrings_offset : Int,
  private_bytes : Bytes?,
  private_offset : Int?,
  encoding_value : Int?,
) -> Result[Bytes, CffError] {
  let entries = clone_entries(base)
  replace_entry(entries, op_charset, [Int(charset_offset)])
  replace_entry(entries, op_charstrings, [Int(charstrings_offset)])
  match (private_bytes, private_offset) {
    (Some(bytes), Some(offset)) =>
      replace_entry(
        entries,
        op_private,
        [Int(bytes.length()), Int(offset)],
      )
    _ => remove_entry(entries, op_private)
  }
  match encoding_value {
    None => remove_entry(entries, op_encoding)
    Some(value) => replace_entry(entries, op_encoding, [Int(value)])
  }
  if entries.get(op_ros) is Some(_) {
    return Err(InvalidFormat)
  }
  if entries.get(op_fd_array) is Some(_) || entries.get(op_fd_select) is Some(_) {
    return Err(InvalidFormat)
  }
  write_cff_dict(entries)
}

///|
pub fn Cff1Table::subset(
  self : Cff1Table,
  glyphs : Array[Int],
) -> Result[Bytes, CffError] {
  if glyphs.is_empty() {
    return Err(InvalidFormat)
  }
  if glyphs[0] != 0 {
    return Err(InvalidFormat)
  }
  let gid_to_sid = match build_gid_to_sid_map(
    self.charset_offset,
    self.charset_map,
    self.charstrings.count,
  ) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let charset_bytes = match build_charset_bytes(glyphs, gid_to_sid) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let char_items : Array[Bytes] = []
  for gid in glyphs {
    let bytes = match self.charstrings.item_bytes(gid) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    char_items.push(bytes)
  }
  let charstrings_index = match write_cff_index(char_items, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let name_items = match build_index_items(self.name_index) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let name_index = match write_cff_index(name_items, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let string_items = match build_index_items(self.string_index) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let string_index = match write_cff_index(string_items, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let global_items = match build_index_items(self.global_subrs) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let global_index = match write_cff_index(global_items, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let (private_bytes, local_subrs_index) =
    match self.private_dict {
      None => (None, None)
      Some(private_dict) =>
        match build_private_dict(private_dict, self.local_subrs) {
          Err(err) => return Err(err)
          Ok((priv_bytes, subrs_index)) => (Some(priv_bytes), subrs_index)
        }
    }
  let header_size = if self.data.length() >= 3 { self.data[2].to_int() } else { 0 }
  if header_size < 4 || header_size > self.data.length() {
    return Err(InvalidFormat)
  }
  let header_bytes = self.data[0:header_size].to_bytes()
  let mut top_dict_bytes = match write_cff_dict(self.top_dict.entries_map()) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mut top_index = match write_cff_index([top_dict_bytes], 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let encoding_value =
    match self.top_dict.get_int(op_encoding) {
      None => None
      Some(value) =>
        if value == 0 || value == 1 { Some(value) } else { Some(0) }
    }
  let mut done = false
  let mut iter = 0
  while !done && iter < 5 {
    let base_offset =
      header_bytes.length() +
      name_index.length() +
      top_index.length() +
      string_index.length() +
      global_index.length()
    let charset_offset = base_offset
    let charstrings_offset = charset_offset + charset_bytes.length()
    let mut private_offset : Int? = None
    if private_bytes is Some(_) {
      private_offset = Some(charstrings_offset + charstrings_index.length())
    }
    let updated_top = match build_top_dict(
      self.top_dict.entries_map(),
      charset_offset,
      charstrings_offset,
      private_bytes,
      private_offset,
      encoding_value,
    ) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let updated_index = match write_cff_index([updated_top], 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if updated_index.length() == top_index.length() {
      top_dict_bytes = updated_top
      top_index = updated_index
      done = true
    } else {
      top_dict_bytes = updated_top
      top_index = updated_index
    }
    iter = iter + 1
  }
  if !done {
    return Err(InvalidFormat)
  }
  let bytes : Array[Byte] = []
  for b in header_bytes {
    bytes.push(b)
  }
  for b in name_index {
    bytes.push(b)
  }
  for b in top_index {
    bytes.push(b)
  }
  for b in string_index {
    bytes.push(b)
  }
  for b in global_index {
    bytes.push(b)
  }
  for b in charset_bytes {
    bytes.push(b)
  }
  for b in charstrings_index {
    bytes.push(b)
  }
  match private_bytes {
    None => ()
    Some(private_blob) => {
      for b in private_blob {
        bytes.push(b)
      }
      match local_subrs_index {
        None => ()
        Some(subrs) =>
          for b in subrs {
            bytes.push(b)
          }
      }
    }
  }
  Ok(Bytes::from_array(bytes))
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
