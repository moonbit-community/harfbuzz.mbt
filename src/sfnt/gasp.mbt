///|
/// Gasp range entry.
pub struct GaspRange {
  max_ppem : Int
  behavior : Int
} derive(Eq, Show, ToJson)

///|
/// Parsed gasp table.
pub struct GaspTable {
  version : Int
  ranges : Array[GaspRange]
} derive(Show, ToJson)

///|
/// Parse gasp table bytes (version 0/1).
pub fn GaspTable::parse(data : BytesView) -> Result[GaspTable, SfntError] {
  let version = read_u16_int(data, 0)
  let num_ranges = read_u16_int(data, 2)
  match (version, num_ranges) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(count)) => {
      if version < 0 || version > 1 || count < 0 {
        return Err(InvalidFormat)
      }
      let ranges : Array[GaspRange] = []
      let mut offset = 4
      if offset + count * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      for _ in 0..<count {
        let max_ppem = read_u16_int(data, offset)
        let behavior = read_u16_int(data, offset + 2)
        match (max_ppem, behavior) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(max_ppem), Ok(behavior)) =>
            ranges.push(GaspRange::{ max_ppem, behavior })
        }
        offset = offset + 4
      }
      Ok(GaspTable::{ version, ranges })
    }
  }
}

///|
/// Return gasp behavior flags for a given ppem (first range with max_ppem >= ppem).
pub fn GaspTable::behavior_for_ppem(self : GaspTable, ppem : Int) -> Int? {
  for range in self.ranges {
    if ppem <= range.max_ppem {
      return Some(range.behavior)
    }
  }
  None
}
