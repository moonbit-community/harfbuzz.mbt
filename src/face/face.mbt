///|
/// Face holds font data and basic metadata.
pub struct Face {
  blob : @blob.Blob
  mut index : Int
  mut upem : Int
  mut glyph_count : Int
  tables : Map[@common.Tag, @blob.Blob]
} derive(Show, ToJson)

///|
/// Return the number of faces in a blob (placeholder implementation).
pub fn face_count(blob : @blob.Blob) -> Int {
  if blob.is_empty() {
    0
  } else {
    1
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
  self.index = index
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

///|
/// Reference a table blob by tag.
pub fn Face::reference_table(self : Face, tag : @common.Tag) -> @blob.Blob? {
  self.tables.get(tag)
}
