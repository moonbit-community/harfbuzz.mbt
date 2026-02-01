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
