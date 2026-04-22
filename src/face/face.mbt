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
/// Face holds font data and basic metadata.
pub struct Face {
  blob : @blob.Blob
  mut index : Int
  mut upem : Int
  mut glyph_count : Int
  mut tables : Map[@common.Tag, @blob.Blob]
} derive(Debug, ToJson)

///|
/// Return the number of faces in a blob.
pub fn face_count(blob : @blob.Blob) -> Int {
  let data = blob.as_view()
  if data.length() < 4 {
    return 0
  }
  let tag = @common.Tag::from_bytes(data[0], data[1], data[2], data[3])
  let ttcf = @common.Tag::from_chars('t', 't', 'c', 'f')
  if tag == ttcf {
    if data.length() < 12 {
      return 0
    }
    let b0 = data[8].to_uint()
    let b1 = data[9].to_uint()
    let b2 = data[10].to_uint()
    let b3 = data[11].to_uint()
    let value = ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3).reinterpret_as_int()
    if value < 0 {
      0
    } else {
      value
    }
  } else {
    let sfnt = @common.Tag::from_bytes(0x00, 0x01, 0x00, 0x00)
    let otto = @common.Tag::from_chars('O', 'T', 'T', 'O')
    let true_tag = @common.Tag::from_chars('t', 'r', 'u', 'e')
    let typ1 = @common.Tag::from_chars('t', 'y', 'p', '1')
    if tag == sfnt || tag == otto || tag == true_tag || tag == typ1 {
      1
    } else {
      0
    }
  }
}

///|
/// Create a face from a blob.
pub fn Face::new(blob : @blob.Blob, index? : Int = 0) -> Face {
  Face::{ blob, index, upem: 0, glyph_count: 0, tables: Map::new() }
}

///|
/// Create a face from raw bytes.
pub fn Face::from_bytes(bytes : Bytes, index? : Int = 0) -> Face {
  Face::new(@blob.Blob::from_bytes(bytes), index~)
}

///|
/// Access the face blob.
pub fn Face::reference_blob(self : Face) -> @blob.Blob {
  self.blob
}

///|
/// Update the face index.
pub fn Face::set_index(self : Face, index : Int) -> Unit {
  if self.index != index {
    self.index = index
    self.tables = Map::new()
    self.upem = 0
    self.glyph_count = 0
  }
}

///|
/// Read the face index.
pub fn Face::get_index(self : Face) -> Int {
  self.index
}

///|
/// Update units-per-em.
pub fn Face::set_upem(self : Face, upem : Int) -> Unit {
  self.upem = upem
}

///|
/// Read units-per-em.
pub fn Face::get_upem(self : Face) -> Int {
  self.upem
}

///|
/// Update glyph count.
pub fn Face::set_glyph_count(self : Face, count : Int) -> Unit {
  self.glyph_count = count
}

///|
/// Read glyph count.
pub fn Face::get_glyph_count(self : Face) -> Int {
  self.glyph_count
}

///|
/// Attach a table blob.
pub fn Face::set_table(
  self : Face,
  tag : @common.Tag,
  blob : @blob.Blob,
) -> Unit {
  self.tables[tag] = blob
}
