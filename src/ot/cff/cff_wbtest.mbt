///|
test "cff2 fdselect format4" {
  let bytes : Bytes = [
    0x04,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x02,
    0x00,
    0x00,
    0x00,
    0x03,
  ]
  let values = match parse_fdselect(bytes[:], 0, 3) {
    Err(err) => fail("fdselect parse error: \{err}")
    Ok(value) => value
  }
  inspect(values, content="[2, 2, 2]")
}

///|
test "cff1 seac bounds" {
  let data : Bytes = [
    14,
    139,
    139,
    21,
    149,
    139,
    5,
    14,
    139,
    139,
    21,
    139,
    144,
    5,
    14,
    159,
    169,
    171,
    172,
    14,
    149,
    159,
    169,
    171,
    172,
    14,
  ]
  let charstrings = CffIndex::{
    count: 5,
    off_size: 1,
    offsets: [1, 2, 9, 16, 21, 27],
    data,
  }
  let empty_index = CffIndex::{ count: 0, off_size: 0, offsets: [], data: Bytes::from_array([]) }
  let empty_dict = CffDict::{ entries: {} }
  let cff1 = Cff1Table::{
    data: Bytes::from_array([]),
    name_index: empty_index,
    top_dict: empty_dict,
    string_index: empty_index,
    global_subrs: empty_index,
    charstrings,
    private_dict: None,
    local_subrs: None,
    charstrings_offset: 0,
    private_offset: 0,
    private_size: 0,
    charset_offset: 0,
    charset_map: None,
  }
  let bounds = match cff1.glyph_bounds(3) {
    Err(err) => fail("bounds error: \{err}")
    Ok(value) => value
  }
  match bounds {
    None => fail("missing bounds")
    Some(bounds) => {
      let x_min = bounds.x_min.round().to_int()
      let y_min = bounds.y_min.round().to_int()
      let x_max = bounds.x_max.round().to_int()
      let y_max = bounds.y_max.round().to_int()
      inspect((x_min, y_min, x_max, y_max), content="(0, 0, 20, 35)")
    }
  }

  let bounds = match cff1.glyph_bounds(4) {
    Err(err) => fail("bounds error: \{err}")
    Ok(value) => value
  }
  match bounds {
    None => fail("missing bounds")
    Some(bounds) => {
      let x_min = bounds.x_min.round().to_int()
      let y_min = bounds.y_min.round().to_int()
      let x_max = bounds.x_max.round().to_int()
      let y_max = bounds.y_max.round().to_int()
      inspect((x_min, y_min, x_max, y_max), content="(0, 0, 20, 35)")
    }
  }

  let components = match cff1.seac_components(3) {
    Err(err) => fail("seac components error: \{err}")
    Ok(value) => value
  }
  inspect(components, content="Some((1, 2))")

  let components = match cff1.seac_components(4) {
    Err(err) => fail("seac components error: \{err}")
    Ok(value) => value
  }
  inspect(components, content="Some((1, 2))")
}

///|
fn empty_index() -> CffIndex {
  CffIndex::{ count: 0, off_size: 0, offsets: [], data: Bytes::from_array([]) }
}

///|
fn zero_charstrings(count : Int) -> CffIndex {
  let offsets : Array[Int] = Array::make(count + 1, 1)
  CffIndex::{ count, off_size: 1, offsets, data: Bytes::from_array([]) }
}

///|
fn build_string_index(names : Array[String]) -> CffIndex {
  if names.is_empty() {
    return empty_index()
  }
  let bytes : Array[Byte] = []
  let offsets : Array[Int] = [1]
  let mut cursor = 1
  for name in names {
    let name_bytes = @utf8.encode(name)
    for b in name_bytes {
      bytes.push(b)
    }
    cursor = cursor + name_bytes.length()
    offsets.push(cursor)
  }
  CffIndex::{ count: names.length(), off_size: 1, offsets, data: Bytes::from_array(bytes) }
}

///|
test "cff1 glyph names standard charset" {
  let empty = empty_index()
  let empty_dict = CffDict::{ entries: {} }
  let charstrings = zero_charstrings(3)
  let cff1 = Cff1Table::{
    data: Bytes::from_array([]),
    name_index: empty,
    top_dict: empty_dict,
    string_index: empty,
    global_subrs: empty,
    charstrings,
    private_dict: None,
    local_subrs: None,
    charstrings_offset: 0,
    private_offset: 0,
    private_size: 0,
    charset_offset: 0,
    charset_map: None,
  }
  let name0 = match cff1.glyph_name(0) {
    Err(err) => fail("glyph name error: \{err}")
    Ok(value) => value
  }
  let name1 = match cff1.glyph_name(1) {
    Err(err) => fail("glyph name error: \{err}")
    Ok(value) => value
  }
  let gid1 = match cff1.glyph_from_name("space") {
    Err(err) => fail("glyph from name error: \{err}")
    Ok(value) => value
  }
  inspect(name0, content="Some(\".notdef\")")
  inspect(name1, content="Some(\"space\")")
  inspect(gid1, content="Some(1)")
}

///|
test "cff1 glyph names custom strings" {
  let empty = empty_index()
  let empty_dict = CffDict::{ entries: {} }
  let charstrings = zero_charstrings(3)
  let string_index = build_string_index(["customA", "customB"])
  let standard_len = cff1_standard_strings_len()
  let map : Map[Int, Int] = {}
  map[standard_len] = 1
  map[standard_len + 1] = 2
  let cff1 = Cff1Table::{
    data: Bytes::from_array([]),
    name_index: empty,
    top_dict: empty_dict,
    string_index,
    global_subrs: empty,
    charstrings,
    private_dict: None,
    local_subrs: None,
    charstrings_offset: 0,
    private_offset: 0,
    private_size: 0,
    charset_offset: 3,
    charset_map: Some(map),
  }
  let name1 = match cff1.glyph_name(1) {
    Err(err) => fail("glyph name error: \{err}")
    Ok(value) => value
  }
  let name2 = match cff1.glyph_name(2) {
    Err(err) => fail("glyph name error: \{err}")
    Ok(value) => value
  }
  let gid2 = match cff1.glyph_from_name("customB") {
    Err(err) => fail("glyph from name error: \{err}")
    Ok(value) => value
  }
  inspect(name1, content="Some(\"customA\")")
  inspect(name2, content="Some(\"customB\")")
  inspect(gid2, content="Some(2)")
}
