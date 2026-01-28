///|
/// Parsed hmtx table (subset).
pub struct HmtxTable {
  advances : Array[Int]
  lsbs : Array[Int]
} derive(Show, ToJson)

///|
/// Parse hmtx table bytes.
pub fn HmtxTable::parse(
  data : BytesView,
  num_glyphs : Int,
  number_of_hmetrics : Int,
) -> Result[HmtxTable, SfntError] {
  if num_glyphs < 0 || number_of_hmetrics < 0 {
    return Err(InvalidFormat)
  }
  let advances : Array[Int] = []
  let lsbs : Array[Int] = []
  let mut offset = 0
  let mut last_advance = 0
  for i in 0..<num_glyphs {
    if i < number_of_hmetrics {
      let adv = read_u16_int(data, offset)
      let lsb = read_i16(data, offset + 2)
      match (adv, lsb) {
        (Err(err), _) => return Err(err)
        (_, Err(err)) => return Err(err)
        (Ok(advance_width), Ok(left_side_bearing)) => {
          last_advance = advance_width
          advances.push(advance_width)
          lsbs.push(left_side_bearing)
        }
      }
      offset = offset + 4
    } else {
      let lsb = read_i16(data, offset)
      match lsb {
        Err(err) => return Err(err)
        Ok(left_side_bearing) => {
          advances.push(last_advance)
          lsbs.push(left_side_bearing)
        }
      }
      offset = offset + 2
    }
  }
  Ok(HmtxTable::{ advances, lsbs })
}
