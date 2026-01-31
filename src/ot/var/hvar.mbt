///|
pub struct HvarTable {
  var_store : ItemVariationStore
  adv_map : DeltaSetIndexMap?
  lsb_map : DeltaSetIndexMap?
  rsb_map : DeltaSetIndexMap?
} derive(Show, ToJson)

fn parse_map_optional(data : BytesView, offset : Int) -> Result[DeltaSetIndexMap?, VarError] {
  if offset == 0 {
    return Ok(None)
  }
  let map = match DeltaSetIndexMap::parse(data, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  Ok(Some(map))
}

///|
pub fn HvarTable::parse(data : BytesView) -> Result[HvarTable, VarError] {
  let version = read_u32(data, 0)
  let var_store_offset = read_u32_int(data, 4)
  let adv_offset = read_u32_int(data, 8)
  let lsb_offset = read_u32_int(data, 12)
  let rsb_offset = read_u32_int(data, 16)
  match (version, var_store_offset, adv_offset, lsb_offset, rsb_offset) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(var_store_offset), Ok(adv_offset), Ok(lsb_offset), Ok(rsb_offset)) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if var_store_offset <= 0 || var_store_offset >= data.length() {
        return Err(UnexpectedEof)
      }
      let var_store = match ItemVariationStore::parse(data[var_store_offset:]) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let adv_map = match parse_map_optional(data, adv_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lsb_map = match parse_map_optional(data, lsb_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let rsb_map = match parse_map_optional(data, rsb_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(HvarTable::{ var_store, adv_map, lsb_map, rsb_map })
    }
  }
}

///|
pub fn HvarTable::advance_delta(
  self : HvarTable,
  glyph : UInt,
  coords : Array[Int],
) -> Double {
  let var_idx = match self.adv_map {
    None => glyph
    Some(map) => map.map(glyph)
  }
  self.var_store.get_delta(var_idx, coords)
}
