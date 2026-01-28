///|
/// Parsed head table (subset).
pub struct HeadTable {
  units_per_em : Int
  index_to_loc_format : Int
} derive(Eq, Show, ToJson)

///|
/// Parse head table bytes.
pub fn HeadTable::parse(data : BytesView) -> Result[HeadTable, SfntError] {
  let upem = read_u16_int(data, 18)
  let loc = read_i16(data, 50)
  match (upem, loc) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(units_per_em), Ok(index_to_loc_format)) =>
      Ok(HeadTable::{ units_per_em, index_to_loc_format })
  }
}
