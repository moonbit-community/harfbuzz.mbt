///|
suberror FaceTableError {
  TableNotFound
  TableError(@sfnt.SfntError)
  InvalidFaceIndex
  UnexpectedEof
  InvalidFormat
} derive(Eq, Show, ToJson)

///|
fn read_u32(data : BytesView, offset : Int) -> Result[Int, FaceTableError] {
  if offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  let value = ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3).reinterpret_as_int()
  if value < 0 { Err(InvalidFormat) } else { Ok(value) }
}

///|
fn ttc_font_offset(
  data : BytesView,
  index : Int,
) -> Result[Int, FaceTableError] {
  let count = read_u32(data, 8)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if index < 0 || index >= count {
        return Err(InvalidFaceIndex)
      }
      let offset = 12 + index * 4
      read_u32(data, offset)
    }
  }
}

///|
/// Build and cache the SFNT table directory from the face blob.
pub fn Face::ensure_sfnt_tables(self : Face) -> Result[Unit, FaceTableError] {
  if self.tables.length() > 0 {
    return Ok(())
  }
  let data = self.blob.as_view()
  if data.length() < 4 {
    return Err(UnexpectedEof)
  }
  let tag = @common.Tag::from_bytes(data[0], data[1], data[2], data[3])
  let ttcf = @common.Tag::from_chars('t', 't', 'c', 'f')
  let offset =
    if tag == ttcf {
      match ttc_font_offset(data, self.index) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
    } else {
      0
    }
  match @sfnt.Sfnt::parse_at(self.blob, offset) {
    Err(err) => Err(TableError(err))
    Ok(directory) => {
      for record in directory.tables() {
        match directory.table(record.tag) {
          Err(err) => return Err(TableError(err))
          Ok(blob) => self.tables[record.tag] = blob
        }
      }
      Ok(())
    }
  }
}

///|
/// Reference a table blob by tag, falling back to sfnt directory if needed.
pub fn Face::reference_table(
  self : Face,
  tag : @common.Tag,
) -> Result[@blob.Blob, FaceTableError] {
  match self.tables.get(tag) {
    Some(blob) => Ok(blob)
    None =>
      match self.ensure_sfnt_tables() {
        Err(err) => Err(err)
        Ok(_) =>
          match self.tables.get(tag) {
            Some(blob) => Ok(blob)
            None => Err(TableNotFound)
          }
      }
  }
}

///|
/// Reference a table blob, returning None when the table is missing.
pub fn Face::reference_table_optional(
  self : Face,
  tag : @common.Tag,
) -> Result[@blob.Blob?, FaceTableError] {
  match self.reference_table(tag) {
    Ok(blob) => Ok(Some(blob))
    Err(TableNotFound) => Ok(None)
    Err(err) => Err(err)
  }
}
