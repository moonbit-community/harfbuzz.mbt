///|
/// Parsed vhea table (subset).
pub struct VheaTable {
  number_of_vmetrics : Int
} derive(Eq, Show, ToJson)

///|
/// Parse vhea table bytes.
pub fn VheaTable::parse(data : BytesView) -> Result[VheaTable, SfntError] {
  match read_u16_int(data, 34) {
    Err(err) => Err(err)
    Ok(number_of_vmetrics) => Ok(VheaTable::{ number_of_vmetrics })
  }
}
