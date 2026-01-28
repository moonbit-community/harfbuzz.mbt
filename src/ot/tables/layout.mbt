///|
pub suberror OtLayoutError {
  UnexpectedEof
  InvalidFormat
} derive(Eq, Show, ToJson)

///|
/// Layout table header (GSUB/GPOS shared).
pub struct LayoutHeader {
  version : UInt
  script_list_offset : Int
  feature_list_offset : Int
  lookup_list_offset : Int
  feature_variations_offset : Int?
} derive(Eq, Show, ToJson)

///|
/// Script record entry (offset from table start).
pub struct ScriptRecord {
  tag : @common.Tag
  offset : Int
} derive(Eq, Show, ToJson)

///|
/// Script list table.
pub struct ScriptList {
  records : Array[ScriptRecord]
} derive(Eq, Show, ToJson)

///|
pub fn ScriptList::records(self : ScriptList) -> ArrayView[ScriptRecord] {
  self.records[:]
}

///|
/// Feature record entry (offset from table start).
pub struct FeatureRecord {
  tag : @common.Tag
  offset : Int
} derive(Eq, Show, ToJson)

///|
/// Feature list table.
pub struct FeatureList {
  records : Array[FeatureRecord]
} derive(Eq, Show, ToJson)

///|
pub fn FeatureList::records(self : FeatureList) -> ArrayView[FeatureRecord] {
  self.records[:]
}

///|
/// Lookup list table (offsets from table start).
pub struct LookupList {
  offsets : Array[Int]
} derive(Eq, Show, ToJson)

///|
pub fn LookupList::offsets(self : LookupList) -> ArrayView[Int] {
  self.offsets[:]
}

///|
/// Parsed layout table (GSUB/GPOS shared).
pub struct LayoutTable {
  data : BytesView
  header : LayoutHeader
  script_list : ScriptList
  feature_list : FeatureList
  lookup_list : LookupList
} derive(Show, ToJson)

///|
pub fn LayoutTable::header(self : LayoutTable) -> LayoutHeader {
  self.header
}

///|
pub fn LayoutTable::script_list(self : LayoutTable) -> ScriptList {
  self.script_list
}

///|
pub fn LayoutTable::feature_list(self : LayoutTable) -> FeatureList {
  self.feature_list
}

///|
pub fn LayoutTable::lookup_list(self : LayoutTable) -> LookupList {
  self.lookup_list
}

///|
/// GSUB table wrapper.
pub struct GsubTable {
  layout : LayoutTable
} derive(Show, ToJson)

///|
pub fn GsubTable::parse(blob : @blob.Blob) -> Result[GsubTable, OtLayoutError] {
  match LayoutTable::parse(blob) {
    Err(err) => Err(err)
    Ok(layout) => Ok(GsubTable::{ layout })
  }
}

///|
pub fn GsubTable::layout(self : GsubTable) -> LayoutTable {
  self.layout
}

///|
/// GPOS table wrapper.
pub struct GposTable {
  layout : LayoutTable
} derive(Show, ToJson)

///|
pub fn GposTable::parse(blob : @blob.Blob) -> Result[GposTable, OtLayoutError] {
  match LayoutTable::parse(blob) {
    Err(err) => Err(err)
    Ok(layout) => Ok(GposTable::{ layout })
  }
}

///|
pub fn GposTable::layout(self : GposTable) -> LayoutTable {
  self.layout
}

///|
/// Parse a GSUB/GPOS layout table.
pub fn LayoutTable::parse(
  blob : @blob.Blob,
) -> Result[LayoutTable, OtLayoutError] {
  let data = blob.as_view()
  let version = read_u32(data, 0)
  let script_offset = read_u16_int(data, 4)
  let feature_offset = read_u16_int(data, 6)
  let lookup_offset = read_u16_int(data, 8)
  match (version, script_offset, feature_offset, lookup_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(script_offset), Ok(feature_offset), Ok(lookup_offset)) => {
      if version < 0x00010000U {
        return Err(InvalidFormat)
      }
      if script_offset == 0 || feature_offset == 0 || lookup_offset == 0 {
        return Err(InvalidFormat)
      }
      let feature_variations_offset =
        if version >= 0x00010001U {
          match read_u32_int(data, 10) {
            Err(err) => return Err(err)
            Ok(value) => if value == 0 { None } else { Some(value) }
          }
        } else {
          None
        }
      let script_list = match parse_script_list(data, script_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let feature_list = match parse_feature_list(data, feature_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lookup_list = match parse_lookup_list(data, lookup_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let header = LayoutHeader::{
        version,
        script_list_offset: script_offset,
        feature_list_offset: feature_offset,
        lookup_list_offset: lookup_offset,
        feature_variations_offset,
      }
      Ok(LayoutTable::{ data, header, script_list, feature_list, lookup_list })
    }
  }
}

///|
fn parse_script_list(
  data : BytesView,
  base : Int,
) -> Result[ScriptList, OtLayoutError] {
  if base < 0 || base + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, base)
  let records : Array[ScriptRecord] = []
  let record_base = base + 2
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if record_base < 0 || record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 6
        let tag = match read_tag(data, record_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let offset = read_u16_int(data, record_offset + 4)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            if offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = base + offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            records.push(ScriptRecord::{ tag, offset: abs_offset })
          }
        }
      }
      Ok(ScriptList::{ records })
    }
  }
}

///|
fn parse_feature_list(
  data : BytesView,
  base : Int,
) -> Result[FeatureList, OtLayoutError] {
  if base < 0 || base + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, base)
  let records : Array[FeatureRecord] = []
  let record_base = base + 2
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if record_base < 0 || record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 6
        let tag = match read_tag(data, record_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let offset = read_u16_int(data, record_offset + 4)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            if offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = base + offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            records.push(FeatureRecord::{ tag, offset: abs_offset })
          }
        }
      }
      Ok(FeatureList::{ records })
    }
  }
}

///|
fn parse_lookup_list(
  data : BytesView,
  base : Int,
) -> Result[LookupList, OtLayoutError] {
  if base < 0 || base + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, base)
  let offsets : Array[Int] = []
  let record_base = base + 2
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if record_base < 0 || record_base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 2
        let offset = read_u16_int(data, record_offset)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            if offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = base + offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            offsets.push(abs_offset)
          }
        }
      }
      Ok(LookupList::{ offsets })
    }
  }
}

///|
fn check_range(
  data : BytesView,
  offset : Int,
  size : Int,
) -> Result[Unit, OtLayoutError] {
  if offset < 0 || size < 0 || offset + size > data.length() {
    Err(UnexpectedEof)
  } else {
    Ok(())
  }
}

///|
fn read_u16(data : BytesView, offset : Int) -> Result[UInt, OtLayoutError] {
  match check_range(data, offset, 2) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  Ok((b0 << 8) | b1)
}

///|
fn read_u32(data : BytesView, offset : Int) -> Result[UInt, OtLayoutError] {
  match check_range(data, offset, 4) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

///|
fn u16_to_int(value : UInt) -> Int {
  let v = value.reinterpret_as_int()
  if v < 0 {
    v + 0x10000
  } else {
    v
  }
}

///|
fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, OtLayoutError] {
  match read_u16(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(u16_to_int(value))
  }
}

///|
fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, OtLayoutError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => {
      let v = value.reinterpret_as_int()
      if v < 0 {
        Err(InvalidFormat)
      } else {
        Ok(v)
      }
    }
  }
}

///|
fn read_i16(data : BytesView, offset : Int) -> Result[Int, OtLayoutError] {
  match read_u16_int(data, offset) {
    Err(err) => Err(err)
    Ok(value) => if value >= 0x8000 { Ok(value - 0x10000) } else { Ok(value) }
  }
}

///|
fn read_tag(data : BytesView, offset : Int) -> Result[@common.Tag, OtLayoutError] {
  match check_range(data, offset, 4) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  Ok(
    @common.Tag::from_bytes(
      data[offset],
      data[offset + 1],
      data[offset + 2],
      data[offset + 3],
    ),
  )
}
