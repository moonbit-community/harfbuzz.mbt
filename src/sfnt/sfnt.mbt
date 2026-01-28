///|
pub suberror SfntError {
  UnexpectedEof
  InvalidFormat
  TableNotFound
} derive(Eq, Show, ToJson)

///|
/// Table directory entry.
pub struct TableRecord {
  tag : @common.Tag
  offset : Int
  length : Int
} derive(Eq, Show, ToJson)

///|
/// SFNT font directory.
pub struct Sfnt {
  blob : @blob.Blob
  records : Array[TableRecord]
} derive(Show, ToJson)

///|
fn read_u16(data : BytesView, offset : Int) -> Result[UInt, SfntError] {
  if offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  Ok((b0 << 8) | b1)
}

///|
fn read_u32(data : BytesView, offset : Int) -> Result[UInt, SfntError] {
  if offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

///|
fn u16_to_int(value : UInt) -> Int {
  let v = value.reinterpret_as_int()
  if v < 0 {
    v + 0x10000
  } else {
    v
  }
}

///|
fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  match read_u16(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(u16_to_int(value))
  }
}

///|
fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => {
      let v = value.reinterpret_as_int()
      if v < 0 {
        Err(InvalidFormat)
      } else {
        Ok(v)
      }
    }
  }
}

///|
fn read_i16(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  match read_u16_int(data, offset) {
    Err(err) => Err(err)
    Ok(value) => if value >= 0x8000 { Ok(value - 0x10000) } else { Ok(value) }
  }
}

///|
/// Parse a SFNT directory from a blob.
pub fn Sfnt::parse(blob : @blob.Blob) -> Result[Sfnt, SfntError] {
  let data = blob.as_view()
  let scaler = read_u32(data, 0)
  match scaler {
    Err(err) => Err(err)
    Ok(_) => {
      let tables = read_u16_int(data, 4)
      match tables {
        Err(err) => Err(err)
        Ok(num_tables) => {
          let count = num_tables
          let records : Array[TableRecord] = []
          let mut offset = 12
          for _ in 0..<count {
            let tag = @common.Tag::from_bytes(
              data[offset],
              data[offset + 1],
              data[offset + 2],
              data[offset + 3],
            )
            let table_offset = read_u32_int(data, offset + 8)
            let length = read_u32_int(data, offset + 12)
            match (table_offset, length) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(table_offset), Ok(length)) =>
                records.push(TableRecord::{ tag, offset: table_offset, length })
            }
            offset = offset + 16
          }
          Ok(Sfnt::{ blob, records })
        }
      }
    }
  }
}

///|
/// List all table records.
pub fn Sfnt::tables(self : Sfnt) -> ArrayView[TableRecord] {
  self.records[:]
}

///|
/// Reference a table blob by tag.
pub fn Sfnt::table(
  self : Sfnt,
  tag : @common.Tag,
) -> Result[@blob.Blob, SfntError] {
  for record in self.records {
    if record.tag == tag {
      return match self.blob.sub(record.offset, record.length) {
        Ok(blob) => Ok(blob)
        Err(_) => Err(UnexpectedEof)
      }
    }
  }
  Err(TableNotFound)
}
