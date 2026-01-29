///|
/// Kern pair record (format 0).
pub struct KernPair {
  left : UInt
  right : UInt
  value : Int
} derive(Eq, Show, ToJson)

///|
/// Parsed kern subtable (format 0 only).
pub struct KernSubtable {
  format : Int
  horizontal : Bool
  minimum : Bool
  cross_stream : Bool
  override_flag : Bool
  pairs : Array[KernPair]
} derive(Show, ToJson)

///|
/// Parsed kern table (subset).
pub struct KernTable {
  subtables : Array[KernSubtable]
} derive(Show, ToJson)

///|
fn parse_kern_subtable_format0(
  data : BytesView,
  offset : Int,
  length : Int,
  format : Int,
  horizontal : Bool,
  minimum : Bool,
  cross_stream : Bool,
  override_flag : Bool,
) -> Result[KernSubtable, SfntError] {
  let count = read_u16_int(data, offset + 6)
  match count {
    Err(err) => Err(err)
    Ok(pair_count) => {
      if pair_count < 0 {
        return Err(InvalidFormat)
      }
      let pair_base = offset + 14
      let required = pair_base + pair_count * 6
      if required > offset + length {
        return Err(InvalidFormat)
      }
      let pairs : Array[KernPair] = []
      for i in 0..<pair_count {
        let record_offset = pair_base + i * 6
        let left = read_u16(data, record_offset)
        let right = read_u16(data, record_offset + 2)
        let value = read_i16(data, record_offset + 4)
        match (left, right, value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(left), Ok(right), Ok(value)) =>
            pairs.push(KernPair::{ left, right, value })
        }
      }
      Ok(KernSubtable::{
        format,
        horizontal,
        minimum,
        cross_stream,
        override_flag,
        pairs,
      })
    }
  }
}

///|
/// Parse kern table bytes (version 0, format 0 subtables).
pub fn KernTable::parse(data : BytesView) -> Result[KernTable, SfntError] {
  let version = read_u16_int(data, 0)
  let num_tables = read_u16_int(data, 2)
  match (version, num_tables) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(count)) => {
      if version != 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let subtables : Array[KernSubtable] = []
      let mut offset = 4
      for _ in 0..<count {
        if offset + 6 > data.length() {
          return Err(UnexpectedEof)
        }
        let sub_version = read_u16_int(data, offset)
        let length = read_u16_int(data, offset + 2)
        let coverage = read_u16_int(data, offset + 4)
        match (sub_version, length, coverage) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(sub_version), Ok(length), Ok(coverage)) => {
            if sub_version != 0 || length < 6 {
              return Err(InvalidFormat)
            }
            if offset + length > data.length() {
              return Err(UnexpectedEof)
            }
            let format = (coverage >> 8) & 0xff
            let flags = coverage & 0xff
            let horizontal = (flags & 0x01) != 0
            let minimum = (flags & 0x02) != 0
            let cross_stream = (flags & 0x04) != 0
            let override_flag = (flags & 0x08) != 0
            if format == 0 {
              let subtable = match parse_kern_subtable_format0(
                data,
                offset,
                length,
                format,
                horizontal,
                minimum,
                cross_stream,
                override_flag,
              ) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            }
            offset = offset + length
          }
        }
      }
      Ok(KernTable::{ subtables })
    }
  }
}

///|
/// Lookup kern value for a glyph pair (horizontal format 0 only).
pub fn KernTable::kern_value(
  self : KernTable,
  left : UInt,
  right : UInt,
) -> Int? {
  let mut found = false
  let mut value = 0
  for subtable in self.subtables {
    if subtable.format != 0 || !subtable.horizontal || subtable.cross_stream {
      continue
    }
    let mut pair_value : Int? = None
    for pair in subtable.pairs {
      if pair.left == left && pair.right == right {
        pair_value = Some(pair.value)
        break
      }
    }
    match pair_value {
      None => ()
      Some(kern) => {
        if !found || subtable.override_flag {
          value = kern
        } else {
          value = value + kern
        }
        found = true
      }
    }
  }
  if found { Some(value) } else { None }
}
