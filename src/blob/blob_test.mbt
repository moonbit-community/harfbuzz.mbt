// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
test "blob basics" {
  let bytes : Bytes = [0x00, 0x01, 0x02, 0x03]
  let blob = Blob::from_bytes(bytes)
  @debug.debug_inspect(blob.len(), content="4")
  @debug.debug_inspect(
    blob.get(2),
    content=(
      #|Some(0x02)
    ),
  )
  @debug.debug_inspect(blob.get(5), content="None")
}

///|
test "blob empty" {
  let blob = Blob::from_bytes([])
  @debug.debug_inspect(blob.len(), content="0")
  @debug.debug_inspect(blob.is_empty(), content="true")
  @debug.debug_inspect(blob.get(0), content="None")
  let sub = match blob.sub(0, 0) {
    Err(err) => fail("unexpected error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(sub.len(), content="0")
  @debug.debug_inspect(sub.is_empty(), content="true")
  @debug.debug_inspect(blob.sub(0, 1), content="Err(OutOfBounds)")
}

///|
test "blob memory mode" {
  let bytes : Bytes = [0x10, 0x11]
  let ro_blob = Blob::from_bytes(bytes)
  @debug.debug_inspect(ro_blob.memory_mode(), content="Readonly")
  let dup_blob = Blob::from_bytes_copy(bytes)
  @debug.debug_inspect(dup_blob.memory_mode(), content="Duplicate")
  let sub = match dup_blob.sub(0, 1) {
    Err(err) => fail("unexpected error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(sub.memory_mode(), content="Readonly")
}

///|
test "blob sub view" {
  let bytes : Bytes = [0x10, 0x11, 0x12, 0x13, 0x14]
  let blob = Blob::from_bytes(bytes)
  let sub = match blob.sub(1, 3) {
    Err(err) => fail("unexpected error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(sub.len(), content="3")
  inspect(sub.to_bytes(), content="b\"\\x11\\x12\\x13\"")
}

///|
test "blob out of bounds" {
  let bytes : Bytes = [0x10, 0x11]
  let blob = Blob::from_bytes(bytes)
  let res : Result[Blob, BlobError] = blob.sub(2, 1)
  @debug.debug_inspect(res, content="Err(OutOfBounds)")
}
