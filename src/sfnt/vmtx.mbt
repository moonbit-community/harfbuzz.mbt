///|
/// Parsed vmtx table (subset).
pub struct VmtxTable {
  advances : Array[Int]
  tsbs : Array[Int]
} derive(Show, ToJson)

///|
/// Parse vmtx table bytes.
pub fn VmtxTable::parse(
  data : BytesView,
  num_glyphs : Int,
  number_of_vmetrics : Int,
) -> Result[VmtxTable, SfntError] {
  if num_glyphs < 0 || number_of_vmetrics < 0 {
    return Err(InvalidFormat)
  }
  let advances : Array[Int] = []
  let tsbs : Array[Int] = []
  let mut offset = 0
  let mut last_advance = 0
  for i in 0..<num_glyphs {
    if i < number_of_vmetrics {
      let adv = read_u16_int(data, offset)
      let tsb = read_i16(data, offset + 2)
      match (adv, tsb) {
        (Err(err), _) => return Err(err)
        (_, Err(err)) => return Err(err)
        (Ok(advance_height), Ok(top_side_bearing)) => {
          last_advance = advance_height
          advances.push(advance_height)
          tsbs.push(top_side_bearing)
        }
      }
      offset = offset + 4
    } else {
      let tsb = read_i16(data, offset)
      match tsb {
        Err(err) => return Err(err)
        Ok(top_side_bearing) => {
          advances.push(last_advance)
          tsbs.push(top_side_bearing)
        }
      }
      offset = offset + 2
    }
  }
  Ok(VmtxTable::{ advances, tsbs })
}
