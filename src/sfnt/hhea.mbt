///|
/// Parsed hhea table (subset).
pub struct HheaTable {
  number_of_hmetrics : Int
} derive(Eq, Show, ToJson)

///|
/// Parse hhea table bytes.
pub fn HheaTable::parse(data : BytesView) -> Result[HheaTable, SfntError] {
  match read_u16_int(data, 34) {
    Err(err) => Err(err)
    Ok(number_of_hmetrics) => Ok(HheaTable::{ number_of_hmetrics, })
  }
}
