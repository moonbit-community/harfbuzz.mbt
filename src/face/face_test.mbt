///|
test "face basics" {
  let bytes : Bytes = [0x00, 0x01, 0x02]
  let face = Face::from_bytes(bytes)
  inspect(face.get_index(), content="0")
  inspect(face.get_upem(), content="0")
  inspect(face.get_glyph_count(), content="0")
}

///|
test "face table storage" {
  let bytes : Bytes = [0x10, 0x11, 0x12, 0x13]
  let face = Face::from_bytes(bytes)
  let tag = @common.Tag::from_chars('h', 'e', 'a', 'd')
  let table = @blob.Blob::from_bytes([0x00, 0x01])
  face.set_table(tag, table)
  let found = face.reference_table(tag)
  let size = match found {
    Err(_) => None
    Ok(blob) => Some(blob.len())
  }
  inspect(size, content="Some(2)")
}

///|
test "face setters" {
  let face = Face::from_bytes([0x00])
  face.set_index(2)
  face.set_upem(1024)
  face.set_glyph_count(500)
  inspect(face.get_index(), content="2")
  inspect(face.get_upem(), content="1024")
  inspect(face.get_glyph_count(), content="500")
}
