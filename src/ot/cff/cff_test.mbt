///|
test "cff1 index parse" {
  let bytes : Bytes = [0x00, 0x01, 0x01, 0x01, 0x02, 0xAA]
  let index = match parse_cff1_index(bytes[:], 0) {
    Err(err) => fail("index parse error: \{err}")
    Ok(value) => value
  }
  inspect(index.count, content="1")
  let item = match index.item_bytes(0) {
    Err(err) => fail("item error: \{err}")
    Ok(value) => value
  }
  inspect(item.length(), content="1")
  inspect(item[0].to_int(), content="170")
}

///|
test "cff1 index empty" {
  let bytes : Bytes = [0x00, 0x00]
  let index = match parse_cff1_index(bytes[:], 0) {
    Err(err) => fail("index parse error: \{err}")
    Ok(value) => value
  }
  inspect((index.count, index.byte_len(2)), content="(0, 2)")
}

///|
test "cff2 index parse" {
  let bytes : Bytes = [0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x02, 0xBB]
  let index = match parse_cff2_index(bytes[:], 0) {
    Err(err) => fail("index parse error: \{err}")
    Ok(value) => value
  }
  inspect(index.count, content="1")
  let item = match index.item_bytes(0) {
    Err(err) => fail("item error: \{err}")
    Ok(value) => value
  }
  inspect(item.length(), content="1")
  inspect(item[0].to_int(), content="187")
}

///|
test "cff dict parse int" {
  let bytes : Bytes = [181, 17]
  let dict = match parse_cff_dict(bytes[:]) {
    Err(err) => fail("dict parse error: \{err}")
    Ok(value) => value
  }
  inspect(dict.get_int(17), content="Some(42)")
}

///|
test "cff dict parse real" {
  let bytes : Bytes = [30, 0x12, 0xA5, 0xFF, 0]
  let dict = match parse_cff_dict(bytes[:]) {
    Err(err) => fail("dict parse error: \{err}")
    Ok(value) => value
  }
  match dict.get_real(0) {
    None => fail("missing real")
    Some(value) =>
      assert_true(
        value.is_close(
          12.5,
          relative_tolerance=0.000001,
          absolute_tolerance=0.000001,
        ),
      )
  }
}

///|
test "cff dict parse vsindex op" {
  let bytes : Bytes = [140, 22]
  let dict = match parse_cff_dict(bytes[:]) {
    Err(err) => fail("dict parse error: \{err}")
    Ok(value) => value
  }
  inspect(dict.get_int(22), content="Some(1)")
}

///|
test "cff charstring bounds simple" {
  let bytes : Bytes = [189, 139, 21, 239, 189, 5, 14]
  let bounds = match cff_charstring_bounds(bytes[:], None, None) {
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
      inspect((x_min, y_min, x_max, y_max), content="(50, 0, 150, 50)")
    }
  }
}

///|
test "cff2 parse minimal" {
  let bytes : Bytes = [
    0x02,
    0x00,
    0x05,
    0x00,
    0x08,
    0x9C,
    0x11,
    0xA3,
    0x0C,
    0x24,
    0xAA,
    0x0C,
    0x25,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x01,
    0x01,
    0x01,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x01,
    0x01,
    0x01,
    0x00,
    0x00,
  ]
  let cff2 = match Cff2Table::parse(bytes[:]) {
    Err(err) => fail("cff2 parse error: \{err}")
    Ok(value) => value
  }
  inspect((cff2.top_dict_offset, cff2.top_dict_size), content="(5, 8)")
  inspect((cff2.charstrings.count, cff2.fd_array.count), content="(1, 1)")
  inspect((cff2.fdselect_offset, cff2.vstore_offset), content="(31, 0)")
  match cff2.fd_select {
    None => fail("missing fd select")
    Some(values) => inspect(values, content="[0]")
  }
}

fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, adjusted)
}

fn build_item_variation_store_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1) // format
  push_u32(bytes, 12) // region list offset
  push_u16(bytes, 1) // data count
  push_u32(bytes, 22) // data offset
  push_u16(bytes, 1) // axis count
  push_u16(bytes, 1) // region count
  push_i16(bytes, 0) // start
  push_i16(bytes, 0x4000) // peak 1.0
  push_i16(bytes, 0x4000) // end 1.0
  push_u16(bytes, 1) // item count
  push_u16(bytes, 1) // word size count
  push_u16(bytes, 1) // region index count
  push_u16(bytes, 0) // region index
  push_i16(bytes, 0) // delta
  Bytes::from_array(bytes)
}

test "cff2 charstring blend bounds" {
  let store = match @ot_var.ItemVariationStore::parse(build_item_variation_store_bytes()[:]) {
    Err(err) => fail("var store parse error: \{err}")
    Ok(value) => value
  }
  let bytes : Bytes = [149, 144, 140, 16, 139, 21, 14]
  let bounds = match cff2_charstring_bounds(bytes[:], None, None, Some(store), 0, [16384]) {
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
      inspect((x_min, y_min, x_max, y_max), content="(15, 0, 15, 0)")
    }
  }
}
