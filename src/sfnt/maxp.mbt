///|
/// Parsed maxp table (subset).
pub struct MaxpTable {
  num_glyphs : Int
} derive(Eq, Show, ToJson)

///|
/// Parse maxp table bytes.
pub fn MaxpTable::parse(data : BytesView) -> Result[MaxpTable, SfntError] {
  match read_u16_int(data, 4) {
    Err(err) => Err(err)
    Ok(num_glyphs) => Ok(MaxpTable::{ num_glyphs, })
  }
}
