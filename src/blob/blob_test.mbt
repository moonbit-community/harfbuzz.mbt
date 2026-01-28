///|
test "blob basics" {
  let bytes : Bytes = [0x00, 0x01, 0x02, 0x03]
  let blob = Blob::from_bytes(bytes)
  inspect(blob.len(), content="4")
  inspect(blob.get(2), content="Some(b'\\x02')")
  inspect(blob.get(5), content="None")
}

///|
test "blob sub view" {
  let bytes : Bytes = [0x10, 0x11, 0x12, 0x13, 0x14]
  let blob = Blob::from_bytes(bytes)
  let sub = match blob.sub(1, 3) {
    Err(err) => fail("unexpected error: \{err}")
    Ok(value) => value
  }
  inspect(sub.len(), content="3")
  inspect(sub.to_bytes(), content="b\"\\x11\\x12\\x13\"")
}

///|
test "blob out of bounds" {
  let bytes : Bytes = [0x10, 0x11]
  let blob = Blob::from_bytes(bytes)
  let res : Result[Blob, BlobError] = blob.sub(2, 1)
  inspect(res, content="Err(OutOfBounds)")
}
