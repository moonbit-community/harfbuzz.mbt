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
/// Memory ownership mode for blob data.
pub(all) enum MemoryMode {
  Duplicate
  Readonly
  Writable
  ReadonlyMayMakeWritable
} derive(Eq, Debug, ToJson)

///|
suberror BlobError {
  OutOfBounds
} derive(Eq, Debug, ToJson)

///|
/// Blob wraps binary data with a view range.
pub struct Blob {
  bytes : Bytes
  offset : Int
  length : Int
  mode : MemoryMode
} derive(Eq, Debug, ToJson)

///|
/// Create a blob from bytes.
pub fn Blob::from_bytes(
  bytes : Bytes,
  mode? : MemoryMode = MemoryMode::Readonly,
) -> Blob {
  Blob::{ bytes, offset: 0, length: bytes.length(), mode }
}

///|
/// Create a blob by copying bytes.
pub fn Blob::from_bytes_copy(bytes : Bytes) -> Blob {
  let copy = Bytes::from_array(bytes.to_array())
  Blob::from_bytes(copy, mode=MemoryMode::Duplicate)
}

///|
/// Create a blob from a byte array view.
pub fn Blob::from_array(
  bytes : ArrayView[Byte],
  mode? : MemoryMode = MemoryMode::Readonly,
) -> Blob {
  Blob::from_bytes(Bytes::from_array(bytes), mode~)
}

///|
/// Create a sub-blob.
pub fn Blob::sub(
  self : Blob,
  offset : Int,
  length : Int,
) -> Result[Blob, BlobError] {
  if offset < 0 || length < 0 {
    return Err(OutOfBounds)
  }
  if offset > self.length {
    return Err(OutOfBounds)
  }
  let end = offset + length
  if end > self.length {
    return Err(OutOfBounds)
  }
  Ok(Blob::{
    bytes: self.bytes,
    offset: self.offset + offset,
    length,
    mode: MemoryMode::Readonly,
  })
}

///|
/// Return the blob length in bytes.
pub fn Blob::len(self : Blob) -> Int {
  self.length
}

///|
/// Return true when empty.
pub fn Blob::is_empty(self : Blob) -> Bool {
  self.length == 0
}

///|
/// Get a view of the blob bytes.
pub fn Blob::as_view(self : Blob) -> BytesView {
  self.bytes[self.offset:self.offset + self.length]
}

///|
/// Copy the blob into a new Bytes value.
pub fn Blob::to_bytes(self : Blob) -> Bytes {
  self.as_view().to_owned()
}

///|
/// Raw byte access with bounds checking.
pub fn Blob::get(self : Blob, index : Int) -> Byte? {
  if index < 0 || index >= self.length {
    None
  } else {
    self.bytes.get(self.offset + index)
  }
}

///|
/// Access the memory mode.
pub fn Blob::memory_mode(self : Blob) -> MemoryMode {
  self.mode
}
