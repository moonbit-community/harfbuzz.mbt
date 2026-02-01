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
}
