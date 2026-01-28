///|
fn build_sfnt_with_table(tag : @common.Tag, table_bytes : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x10)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x1c)
  let len = table_bytes.length()
  bytes.push(((len >> 24) & 0xff).to_byte())
  bytes.push(((len >> 16) & 0xff).to_byte())
  bytes.push(((len >> 8) & 0xff).to_byte())
  bytes.push((len & 0xff).to_byte())
  for b in table_bytes {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
test "face references sfnt table" {
  let tag = @common.Tag::from_chars('n', 'a', 'm', 'e')
  let table_bytes : Bytes = [0x0a, 0x0b]
  let sfnt_bytes = build_sfnt_with_table(tag, table_bytes)
  let face = Face::from_bytes(sfnt_bytes)
  let table = match face.reference_table(tag) {
    Err(err) => fail("missing table: \{err}")
    Ok(value) => value
  }
  inspect(table.to_bytes(), content="b\"\\x0a\\x0b\"")
}
