///|
pub struct VarcTable {
  version : Int
  coverage_offset : Int
  var_store_offset : Int
  condition_list_offset : Int
  axis_indices_offset : Int
  glyph_records_offset : Int
  data : Bytes
} derive(Show, ToJson)

fn validate_offset(offset : Int, length : Int) -> Result[Unit, VarError] {
  if offset < 0 || offset > length {
    return Err(UnexpectedEof)
  }
  Ok(())
}

///|
pub fn VarcTable::parse(data : BytesView) -> Result[VarcTable, VarError] {
  let version = read_u32(data, 0)
  let coverage_offset = read_u32_int(data, 4)
  let var_store_offset = read_u32_int(data, 8)
  let condition_list_offset = read_u32_int(data, 12)
  let axis_indices_offset = read_u32_int(data, 16)
  let glyph_records_offset = read_u32_int(data, 20)
  match (
    version,
    coverage_offset,
    var_store_offset,
    condition_list_offset,
    axis_indices_offset,
    glyph_records_offset,
  ) {
    (Err(err), _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _) => Err(err)
    (_, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(coverage_offset), Ok(var_store_offset), Ok(condition_list_offset), Ok(axis_indices_offset), Ok(glyph_records_offset)) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      let length = data.length()
      match validate_offset(coverage_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(var_store_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(condition_list_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(axis_indices_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      match validate_offset(glyph_records_offset, length) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      Ok(VarcTable::{
        version: version.reinterpret_as_int(),
        coverage_offset,
        var_store_offset,
        condition_list_offset,
        axis_indices_offset,
        glyph_records_offset,
        data: data.to_bytes(),
      })
    }
  }
}
