///|
/// Parsed loca table (glyph offsets).
pub struct LocaTable {
  offsets : Array[Int]
} derive(Eq, Show, ToJson)

///|
/// Parse loca table bytes.
/// index_to_loc_format: 0 (short, u16*2) or 1 (long, u32).
pub fn LocaTable::parse(
  data : BytesView,
  num_glyphs : Int,
  index_to_loc_format : Int,
) -> Result[LocaTable, SfntError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let count = num_glyphs + 1
  let offsets : Array[Int] = []
  let mut prev = 0
  if index_to_loc_format == 0 {
    let mut offset = 0
    for _ in 0..<count {
      let raw = read_u16_int(data, offset)
      match raw {
        Err(err) => return Err(err)
        Ok(value) => {
          let actual = value * 2
          if actual < prev {
            return Err(InvalidFormat)
          }
          offsets.push(actual)
          prev = actual
        }
      }
      offset = offset + 2
    }
    Ok(LocaTable::{ offsets })
  } else if index_to_loc_format == 1 {
    let mut offset = 0
    for _ in 0..<count {
      let raw = read_u32_int(data, offset)
      match raw {
        Err(err) => return Err(err)
        Ok(value) => {
          if value < prev {
            return Err(InvalidFormat)
          }
          offsets.push(value)
          prev = value
        }
      }
      offset = offset + 4
    }
    Ok(LocaTable::{ offsets })
  } else {
    Err(InvalidFormat)
  }
}
