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

///|
test "face_count handles sfnt and ttc headers" {
  let empty = @blob.Blob::from_bytes([])
  inspect(face_count(empty), content="0")

  let unknown = @blob.Blob::from_bytes([0x01, 0x02, 0x03, 0x04])
  inspect(face_count(unknown), content="0")

  let sfnt = @blob.Blob::from_bytes([0x00, 0x01, 0x00, 0x00])
  inspect(face_count(sfnt), content="1")

  let otto = @blob.Blob::from_bytes([0x4f, 0x54, 0x54, 0x4f])
  inspect(face_count(otto), content="1")

  let true_tag = @blob.Blob::from_bytes([0x74, 0x72, 0x75, 0x65])
  inspect(face_count(true_tag), content="1")

  let typ1 = @blob.Blob::from_bytes([0x74, 0x79, 0x70, 0x31])
  inspect(face_count(typ1), content="1")

  let ttc = @blob.Blob::from_bytes([
    0x74, 0x74, 0x63, 0x66,
    0x00, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x02,
  ])
  inspect(face_count(ttc), content="2")

  let ttc_negative = @blob.Blob::from_bytes([
    0x74, 0x74, 0x63, 0x66,
    0x00, 0x01, 0x00, 0x00,
    0xff, 0xff, 0xff, 0xff,
  ])
  inspect(face_count(ttc_negative), content="0")
}
