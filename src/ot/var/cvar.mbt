///|
pub struct CvarTable {
  version : Int
  tuple_data : TupleVariationData
} derive(Show, ToJson)

///|
pub fn CvarTable::parse(
  data : BytesView,
  axis_count : Int,
) -> Result[CvarTable, VarError] {
  let version = read_u32(data, 0)
  match version {
    Err(err) => Err(err)
    Ok(value) => {
      let major = (value >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if data.length() < 4 {
        return Err(UnexpectedEof)
      }
      let tuple_data = match TupleVariationData::parse(data[4:], axis_count, []) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(CvarTable::{
        version: value.reinterpret_as_int(),
        tuple_data,
      })
    }
  }
}

///|
pub fn CvarTable::cvt_deltas(
  self : CvarTable,
  coords : Array[Int],
  point_count : Int,
) -> Result[Array[Double], VarError] {
  let (deltas, _) = match self.tuple_data.apply(coords, point_count, false) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  Ok(deltas)
}

///|
pub fn CvarTable::apply_to_cvt(
  self : CvarTable,
  cvt : Array[Int],
  coords : Array[Int],
) -> Result[Array[Int], VarError] {
  let deltas = match self.cvt_deltas(coords, cvt.length()) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let out : Array[Int] = []
  for i in 0..<cvt.length() {
    out.push(cvt[i] + deltas[i].round().to_int())
  }
  Ok(out)
}
