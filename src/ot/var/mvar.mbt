///|
pub struct MvarRecord {
  tag : @common.Tag
  var_idx : UInt
} derive(Eq, Show, ToJson)

///|
pub struct MvarTable {
  records : Array[MvarRecord]
  var_store : ItemVariationStore
}

///|
pub fn MvarTable::parse(data : BytesView) -> Result[MvarTable, VarError] {
  let version = read_u32(data, 0)
  let value_record_size = read_u16_int(data, 6)
  let value_record_count = read_u16_int(data, 8)
  let var_store_offset = read_u16_int(data, 10)
  match (version, value_record_size, value_record_count, var_store_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(value_record_size), Ok(value_record_count), Ok(var_store_offset)) => {
      let major = (version >> 16) & 0xFFFFU
      if major != 1U {
        return Err(InvalidFormat)
      }
      if value_record_size < 8 {
        return Err(InvalidFormat)
      }
      if var_store_offset < 0 || var_store_offset >= data.length() {
        return Err(UnexpectedEof)
      }
      let var_store = match ItemVariationStore::parse(data[var_store_offset:]) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut offset = 12
      let records : Array[MvarRecord] = []
      for _ in 0..<value_record_count {
        if offset + value_record_size > data.length() {
          return Err(UnexpectedEof)
        }
        let tag = read_tag(data, offset)
        let var_idx = read_u32(data, offset + 4)
        match (tag, var_idx) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(tag), Ok(var_idx)) =>
            records.push(MvarRecord::{ tag, var_idx })
        }
        offset = offset + value_record_size
      }
      Ok(MvarTable::{ records, var_store })
    }
  }
}

///|
pub fn MvarTable::get_var(
  self : MvarTable,
  tag : @common.Tag,
  coords : Array[Int],
) -> Double {
  for record in self.records {
    if record.tag == tag {
      return self.var_store.get_delta(record.var_idx, coords)
    }
  }
  0.0
}
