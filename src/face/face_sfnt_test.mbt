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
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_ttc(fonts : Array[Bytes]) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x74)
  bytes.push(0x74)
  bytes.push(0x63)
  bytes.push(0x66)
  push_u32(bytes, 0x00010000)
  push_u32(bytes, fonts.length())
  let mut offset = 12 + fonts.length() * 4
  for font in fonts {
    push_u32(bytes, offset)
    offset = offset + font.length()
  }
  for font in fonts {
    for b in font {
      bytes.push(b)
    }
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

///|
test "face references ttc tables by index" {
  let tag = @common.Tag::from_chars('n', 'a', 'm', 'e')
  let font0 = build_sfnt_with_table(tag, [0x0a])
  let font1 = build_sfnt_with_table(tag, [0x0b, 0x0c])
  let ttc = build_ttc([font0, font1])
  let face0 = Face::from_bytes(ttc, index=0)
  let face1 = Face::from_bytes(ttc, index=1)
  let table0 = match face0.reference_table(tag) {
    Err(err) => fail("missing table: \{err}")
    Ok(value) => value
  }
  let table1 = match face1.reference_table(tag) {
    Err(err) => fail("missing table: \{err}")
    Ok(value) => value
  }
  inspect(table0.to_bytes(), content="b\"\\x0a\"")
  inspect(table1.to_bytes(), content="b\"\\x0b\\x0c\"")
}
