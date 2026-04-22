// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
} derive(Eq, Debug, ToJson)

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
} derive(Eq, Debug, ToJson)

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
        None => 0
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

///|
pub fn Cff2Table::glyph_count(self : Cff2Table) -> Int {
  self.charstrings.count
}

fn cff2_clone_entries(entries : Map[Int, Array[CffNumber]]) -> Map[Int, Array[CffNumber]] {
  let next : Map[Int, Array[CffNumber]] = {}
  entries.eachi((_, key, value) => {
    next[key] = value.copy()
  })
  next
}

fn cff2_build_index_items(index : CffIndex) -> Result[Array[Bytes], CffError] {
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

fn cff2_replace_entry(
  entries : Map[Int, Array[CffNumber]],
  op : Int,
  values : Array[CffNumber],
) -> Unit {
  entries[op] = values
}

fn cff2_remove_entry(entries : Map[Int, Array[CffNumber]], op : Int) -> Unit {
  match entries.get(op) {
    None => ()
    Some(_) => entries.remove(op)
  }
}

fn build_private_dict_cff2(
  private_dict : CffDict,
  local_subrs : CffIndex?,
) -> Result[(Bytes, Bytes?), CffError] {
  let entries = cff2_clone_entries(private_dict.entries_map())
  cff2_remove_entry(entries, op_subrs_cff2)
  match local_subrs {
    None => {
      let private_bytes = match write_cff_dict(entries) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok((private_bytes, None))
    }
    Some(subrs) => {
      let subr_items = match cff2_build_index_items(subrs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let subr_index = match write_cff_index(subr_items, 4) {
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
        cff2_replace_entry(entries, op_subrs_cff2, [Int(dict_bytes.length())])
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

fn build_fdselect_format0(fds : Array[Int]) -> Result[Bytes, CffError] {
  let bytes : Array[Byte] = []
  bytes.push(0)
  for fd in fds {
    if fd < 0 || fd > 255 {
      return Err(InvalidFormat)
    }
    bytes.push(fd.to_byte())
  }
  Ok(Bytes::from_array(bytes))
}

fn parse_cff2_private_dict_entries(
  data : BytesView,
  fd_dict : CffDict,
) -> Result[(CffDict, CffIndex?), CffError] {
  let private_size_opt = fd_dict.get_int(op_private_cff2, index=0)
  let private_offset_opt = fd_dict.get_int(op_private_cff2, index=1)
  let (private_size, private_offset) =
    match (private_size_opt, private_offset_opt) {
      (None, None) => (0, 0)
      (Some(size), Some(offset)) => (size, offset)
      _ => return Err(InvalidFormat)
    }
  if private_size <= 0 {
    return Ok((CffDict::{ entries: {} }, None))
  }
  if private_offset < 0 || private_offset + private_size > data.length() {
    return Err(UnexpectedEof)
  }
  let priv_bytes = data[private_offset:private_offset + private_size]
  let priv_dict = match parse_cff_dict(priv_bytes) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let local_subrs =
    match priv_dict.get_int(op_subrs_cff2) {
      None => None
      Some(subrs_offset) => {
        let subrs_base = private_offset + subrs_offset
        if subrs_base < 0 || subrs_base > data.length() {
          return Err(UnexpectedEof)
        }
        match parse_cff2_index(data, subrs_base) {
          Err(err) => return Err(err)
          Ok(value) => Some(value)
        }
      }
    }
  Ok((priv_dict, local_subrs))
}

fn build_top_dict_cff2(
  base : Map[Int, Array[CffNumber]],
  charstrings_offset : Int,
  fdarray_offset : Int,
  fdselect_offset : Int,
  vstore_offset : Int,
) -> Result[Bytes, CffError] {
  let entries = cff2_clone_entries(base)
  cff2_replace_entry(entries, op_charstrings_cff2, [Int(charstrings_offset)])
  cff2_replace_entry(entries, op_fdarray_cff2, [Int(fdarray_offset)])
  if fdselect_offset <= 0 {
    cff2_remove_entry(entries, op_fdselect_cff2)
  } else {
    cff2_replace_entry(entries, op_fdselect_cff2, [Int(fdselect_offset)])
  }
  if vstore_offset <= 0 {
    cff2_remove_entry(entries, op_vstore_cff2)
  } else {
    cff2_replace_entry(entries, op_vstore_cff2, [Int(vstore_offset)])
  }
  write_cff_dict(entries)
}

fn cff2_var_store_bytes(data : BytesView, offset : Int) -> Result[Bytes?, CffError] {
  if offset <= 0 {
    return Ok(None)
  }
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
  let bytes = data[offset:offset + 2 + size].to_bytes()
  Ok(Some(bytes))
}

///|
pub fn Cff2Table::subset(
  self : Cff2Table,
  glyphs : Array[Int],
) -> Result[Bytes, CffError] {
  if glyphs.is_empty() {
    return Err(InvalidFormat)
  }
  if glyphs[0] != 0 {
    return Err(InvalidFormat)
  }
  let glyph_count = self.charstrings.count
  for gid in glyphs {
    if gid < 0 || gid >= glyph_count {
      return Err(InvalidFormat)
    }
  }
  let char_items : Array[Bytes] = []
  for gid in glyphs {
    let bytes = match self.charstrings.item_bytes(gid) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    char_items.push(bytes)
  }
  let charstrings_index = match write_cff_index(char_items, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let global_items = match cff2_build_index_items(self.global_subrs) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let global_index = match write_cff_index(global_items, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let fd_values =
    match self.fd_select {
      None => None
      Some(values) => Some(values)
    }
  let unique_fds : Array[Int] = []
  let fd_seen : Array[Bool] = Array::make(self.fd_array.count, false)
  let glyph_fds : Array[Int] = []
  for gid in glyphs {
    let fd =
      match fd_values {
        None => 0
        Some(values) => {
          if gid < 0 || gid >= values.length() {
            return Err(InvalidFormat)
          }
          values[gid]
        }
      }
    glyph_fds.push(fd)
    if fd >= 0 && fd < fd_seen.length() && !fd_seen[fd] {
      fd_seen[fd] = true
      unique_fds.push(fd)
    }
  }
  let fd_map : Array[Int] = Array::make(self.fd_array.count, -1)
  for i in 0..<unique_fds.length() {
    let old_fd = unique_fds[i]
    if old_fd >= 0 && old_fd < fd_map.length() {
      fd_map[old_fd] = i
    }
  }
  let new_glyph_fds : Array[Int] = []
  for fd in glyph_fds {
    if fd < 0 || fd >= fd_map.length() {
      return Err(InvalidFormat)
    }
    let mapped = fd_map[fd]
    if mapped < 0 {
      return Err(InvalidFormat)
    }
    new_glyph_fds.push(mapped)
  }
  let fdselect_bytes = match build_fdselect_format0(new_glyph_fds) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let fd_entries : Array[(CffDict, Bytes, Bytes?)] = []
  for old_fd in unique_fds {
    let fd_bytes = match self.fd_array.item_bytes(old_fd) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let fd_dict = match parse_cff_dict(fd_bytes[:]) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let (priv_dict, local_subrs) =
      match parse_cff2_private_dict_entries(self.data[:], fd_dict) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
    let (priv_bytes, subrs_bytes) = match build_private_dict_cff2(priv_dict, local_subrs) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    fd_entries.push((fd_dict, priv_bytes, subrs_bytes))
  }

  let vstore_bytes = match cff2_var_store_bytes(self.data[:], self.vstore_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let mut top_dict_bytes = match write_cff_dict(self.top_dict.entries_map()) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mut fdarray_index = match write_cff_index([], 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mut done = false
  let mut iter = 0
  while !done && iter < 6 {
    let top_offset = 5
    let global_offset = top_offset + top_dict_bytes.length()
    let charstrings_offset = global_offset + global_index.length()
    let fdselect_offset = charstrings_offset + charstrings_index.length()
    let fdarray_offset = fdselect_offset + fdselect_bytes.length()
    let mut private_offset = fdarray_offset + fdarray_index.length()
    let fd_dict_bytes : Array[Bytes] = []
    for entry in fd_entries {
      let (fd_dict, priv_bytes, subrs_bytes) = entry
      let dict_entries = cff2_clone_entries(fd_dict.entries_map())
      let priv_size = priv_bytes.length()
      cff2_replace_entry(
        dict_entries,
        op_private_cff2,
        [Int(priv_size), Int(private_offset)],
      )
      let dict_bytes = match write_cff_dict(dict_entries) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      fd_dict_bytes.push(dict_bytes)
      private_offset = private_offset + priv_bytes.length()
      match subrs_bytes {
        None => ()
        Some(subrs) => private_offset = private_offset + subrs.length()
      }
    }
    let new_fdarray_index = match write_cff_index(fd_dict_bytes, 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mut vstore_offset = 0
    if vstore_bytes is Some(_) {
      vstore_offset = private_offset
    }
    let new_top_dict = match build_top_dict_cff2(
      self.top_dict.entries_map(),
      charstrings_offset,
      fdarray_offset,
      fdselect_offset,
      vstore_offset,
    ) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if new_top_dict.length() == top_dict_bytes.length() &&
      new_fdarray_index.length() == fdarray_index.length() {
      top_dict_bytes = new_top_dict
      fdarray_index = new_fdarray_index
      done = true
    } else {
      top_dict_bytes = new_top_dict
      fdarray_index = new_fdarray_index
    }
    iter = iter + 1
  }
  if !done {
    return Err(InvalidFormat)
  }

  let header : Array[Byte] = []
  header.push(self.data[0])
  header.push(self.data[1])
  header.push(5)
  push_u16(header, top_dict_bytes.length())

  let bytes : Array[Byte] = []
  for b in header { bytes.push(b) }
  for b in top_dict_bytes { bytes.push(b) }
  for b in global_index { bytes.push(b) }
  for b in charstrings_index { bytes.push(b) }
  for b in fdselect_bytes { bytes.push(b) }
  for b in fdarray_index { bytes.push(b) }

  for entry in fd_entries {
    let (_, priv_bytes, subrs_bytes) = entry
    for b in priv_bytes { bytes.push(b) }
    match subrs_bytes {
      None => ()
      Some(subrs) => for b in subrs { bytes.push(b) }
    }
  }
  match vstore_bytes {
    None => ()
    Some(vstore) => for b in vstore { bytes.push(b) }
  }
  Ok(Bytes::from_array(bytes))
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
