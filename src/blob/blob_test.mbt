///|
test "blob basics" {
  let bytes : Bytes = [0x00, 0x01, 0x02, 0x03]
  let blob = Blob::from_bytes(bytes)
  inspect(blob.len(), content="4")
  inspect(blob.get(2), content="Some(b'\\x02')")
  inspect(blob.get(5), content="None")
}

///|
test "blob empty" {
  let blob = Blob::from_bytes([])
  inspect(blob.len(), content="0")
  inspect(blob.is_empty(), content="true")
  inspect(blob.get(0), content="None")
  let sub = match blob.sub(0, 0) {
    Err(err) => fail("unexpected error: \{err}")
    Ok(value) => value
  }
  inspect(sub.len(), content="0")
  inspect(sub.is_empty(), content="true")
  inspect(blob.sub(0, 1), content="Err(OutOfBounds)")
}

///|
test "blob memory mode" {
  let bytes : Bytes = [0x10, 0x11]
  let ro_blob = Blob::from_bytes(bytes)
  inspect(ro_blob.memory_mode(), content="Readonly")
  let dup_blob = Blob::from_bytes_copy(bytes)
  inspect(dup_blob.memory_mode(), content="Duplicate")
  let sub = match dup_blob.sub(0, 1) {
    Err(err) => fail("unexpected error: \{err}")
    Ok(value) => value
  }
  inspect(sub.memory_mode(), content="Readonly")
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
