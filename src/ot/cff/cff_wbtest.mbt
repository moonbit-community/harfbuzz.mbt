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
