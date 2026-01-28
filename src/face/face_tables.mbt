///|
suberror FaceTableError {
  TableNotFound
  TableError(@sfnt.SfntError)
} derive(Eq, Show, ToJson)

///|
/// Build and cache the SFNT table directory from the face blob.
pub fn Face::ensure_sfnt_tables(self : Face) -> Result[Unit, FaceTableError] {
  if self.tables.length() > 0 {
    return Ok(())
  }
  match @sfnt.Sfnt::parse(self.blob) {
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
