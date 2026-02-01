///|
/// Control value table (cvt ) raw entries.
pub struct CvtTable {
  values : Array[Int]
} derive(Show, ToJson)

///|
pub fn CvtTable::values(self : CvtTable) -> ArrayView[Int] {
  self.values[:]
}

///|
/// Parse cvt table bytes as signed 16-bit values.
pub fn CvtTable::parse(data : BytesView) -> Result[CvtTable, SfntError] {
  if data.length() % 2 != 0 {
    return Err(InvalidFormat)
  }
  let count = data.length() / 2
  let values : Array[Int] = []
  let mut pos = 0
  for _ in 0..<count {
    let value = read_i16(data, pos)
    match value {
      Err(err) => return Err(err)
      Ok(v) => values.push(v)
    }
    pos = pos + 2
  }
  Ok(CvtTable::{ values })
}
