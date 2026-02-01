let coverage_vertical = 0x80000000U
let coverage_cross_stream = 0x40000000U
let coverage_variation = 0x20000000U
let coverage_backwards = 0x10000000U
let coverage_type_mask = 0xffU

///|
pub struct KerxPair {
  left : UInt
  right : UInt
  value : Int
} derive(Eq, Show, ToJson)

///|
pub struct KerxFormat2 {
  row_width : Int
  left : LookupTable
  right : LookupTable
  values : Array[Int]
} derive(Show, ToJson)

///|
pub struct KerxFormat6 {
  row_index : LookupTable
  column_index : LookupTable
  values : Array[Int]
} derive(Show, ToJson)

///|
pub struct KerxSubtableHeader {
  coverage : UInt
  tuple_count : Int
} derive(Eq, Show, ToJson)

///|
pub enum KerxSubtable {
  Format0(KerxSubtableHeader, Array[KerxPair])
  Format2(KerxSubtableHeader, KerxFormat2)
  Format6(KerxSubtableHeader, KerxFormat6)
} derive(Show, ToJson)

///|
pub struct KerxTable {
  version : Int
  subtables : Array[KerxSubtable]
} derive(Show, ToJson)

fn coverage_type(coverage : UInt) -> Int {
  (coverage & coverage_type_mask).reinterpret_as_int()
}

fn coverage_is_horizontal(coverage : UInt) -> Bool {
  (coverage & coverage_vertical) == 0U
}

fn coverage_is_cross_stream(coverage : UInt) -> Bool {
  (coverage & coverage_cross_stream) != 0U
}

fn coverage_is_variation(coverage : UInt) -> Bool {
  (coverage & coverage_variation) != 0U
}

fn coverage_is_backwards(coverage : UInt) -> Bool {
  (coverage & coverage_backwards) != 0U
}

fn parse_kerx_format0(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
) -> Result[KerxSubtable, AatError] {
  let pair_count = read_u32_non_negative(data, offset + 12)
  match pair_count {
    Err(err) => Err(err)
    Ok(pair_count) => {
      let pair_base = offset + 28
      if pair_base < 0 || pair_base + pair_count * 6 > offset + length {
        return Err(UnexpectedEof)
      }
      let pairs : Array[KerxPair] = []
      for i in 0..<pair_count {
        let rec_offset = pair_base + i * 6
        let left = read_u16(data, rec_offset)
        let right = read_u16(data, rec_offset + 2)
        let value = read_i16(data, rec_offset + 4)
        match (left, right, value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(left), Ok(right), Ok(value)) =>
            pairs.push(KerxPair::{ left, right, value })
        }
      }
      Ok(KerxSubtable::Format0(header, pairs))
    }
  }
}

fn parse_kerx_format2(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
  num_glyphs : Int,
) -> Result[KerxSubtable, AatError] {
  let row_width = read_u32_non_negative(data, offset + 12)
  let left_offset = read_u32_non_negative(data, offset + 16)
  let right_offset = read_u32_non_negative(data, offset + 20)
  let array_offset = read_u32_non_negative(data, offset + 24)
  match (row_width, left_offset, right_offset, array_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(row_width), Ok(left_offset), Ok(right_offset), Ok(array_offset)) => {
      if row_width <= 0 || (row_width & 1) != 0 {
        return Err(InvalidFormat)
      }
      let left_table = match parse_lookup(data, offset + left_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let right_table = match parse_lookup(data, offset + right_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let array_base = offset + array_offset
      if array_base < 0 || array_base > offset + length {
        return Err(UnexpectedEof)
      }
      let bytes_len = offset + length - array_base
      if bytes_len < 0 || (bytes_len & 1) != 0 {
        return Err(InvalidFormat)
      }
      let value_count = bytes_len / 2
      let values : Array[Int] = []
      for i in 0..<value_count {
        let value = read_i16(data, array_base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => values.push(value)
        }
      }
      Ok(
        KerxSubtable::Format2(
          header,
          KerxFormat2::{
            row_width,
            left: left_table,
            right: right_table,
            values,
          },
        ),
      )
    }
  }
}

fn parse_kerx_format6(
  data : BytesView,
  offset : Int,
  length : Int,
  header : KerxSubtableHeader,
  num_glyphs : Int,
) -> Result[KerxSubtable?, AatError] {
  let flags = read_u32_int(data, offset + 12)
  let row_count = read_u16_int(data, offset + 16)
  let column_count = read_u16_int(data, offset + 18)
  let row_index_offset = read_u32_non_negative(data, offset + 20)
  let column_index_offset = read_u32_non_negative(data, offset + 24)
  let array_offset = read_u32_non_negative(data, offset + 28)
  let vector_offset = read_u32_non_negative(data, offset + 32)
  match (
    flags,
    row_count,
    column_count,
    row_index_offset,
    column_index_offset,
    array_offset,
    vector_offset,
  ) {
    (Err(err), _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(flags),
      Ok(_),
      Ok(_),
      Ok(row_index_offset),
      Ok(column_index_offset),
      Ok(array_offset),
      Ok(vector_offset),
    ) => {
      if (flags & 1) != 0 {
        return Ok(None)
      }
      let row_table = match parse_lookup(data, offset + row_index_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let column_table = match parse_lookup(data, offset + column_index_offset, num_glyphs) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let array_base = offset + array_offset
      let mut array_end = offset + length
      if vector_offset > 0 && offset + vector_offset < array_end && offset + vector_offset > array_base {
        array_end = offset + vector_offset
      }
      if array_base < 0 || array_base > array_end || array_end > offset + length {
        return Err(UnexpectedEof)
      }
      let bytes_len = array_end - array_base
      if bytes_len < 0 || (bytes_len & 1) != 0 {
        return Err(InvalidFormat)
      }
      let value_count = bytes_len / 2
      let values : Array[Int] = []
      for i in 0..<value_count {
        let value = read_i16(data, array_base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => values.push(value)
        }
      }
      Ok(
        Some(
          KerxSubtable::Format6(
            header,
            KerxFormat6::{
              row_index: row_table,
              column_index: column_table,
              values,
            },
          ),
        ),
      )
    }
  }
}

fn lookup_value(lookup : LookupTable, glyph : UInt) -> Int {
  match lookup.value_for(glyph) {
    None => 0
    Some(value) => value.reinterpret_as_int()
  }
}

fn KerxSubtable::value_for(
  self : KerxSubtable,
  left : UInt,
  right : UInt,
) -> Int {
  match self {
    Format0(_, pairs) => {
      for pair in pairs {
        if pair.left == left && pair.right == right {
          return pair.value
        }
      }
      0
    }
    Format2(_, format2) => {
      let left_value = lookup_value(format2.left, left)
      let right_value = lookup_value(format2.right, right)
      let index = left_value + right_value
      if index < 0 || index >= format2.values.length() {
        0
      } else {
        format2.values[index]
      }
    }
    Format6(_, format6) => {
      let left_value = lookup_value(format6.row_index, left)
      let right_value = lookup_value(format6.column_index, right)
      let index = left_value + right_value
      if index < 0 || index >= format6.values.length() {
        0
      } else {
        format6.values[index]
      }
    }
  }
}

fn KerxSubtable::header(self : KerxSubtable) -> KerxSubtableHeader {
  match self {
    Format0(header, _) => header
    Format2(header, _) => header
    Format6(header, _) => header
  }
}

///|
pub fn KerxTable::parse(
  data : BytesView,
  num_glyphs : Int,
) -> Result[KerxTable, AatError] {
  let version = read_u16_int(data, 0)
  let table_count = read_u32_non_negative(data, 4)
  match (version, table_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(table_count)) => {
      let mut offset = 8
      let subtables : Array[KerxSubtable] = []
      for _ in 0..<table_count {
        let length = read_u32_non_negative(data, offset)
        let coverage = read_u32(data, offset + 4)
        let tuple_count = read_u32_non_negative(data, offset + 8)
        match (length, coverage, tuple_count) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(length), Ok(coverage), Ok(tuple_count)) => {
            if length < 12 || offset + length > data.length() {
              return Err(UnexpectedEof)
            }
            let header = KerxSubtableHeader::{ coverage, tuple_count }
            let sub_type = coverage_type(coverage)
            if coverage_is_variation(coverage) || tuple_count > 0 {
              offset = offset + length
              continue
            }
            if sub_type == 0 {
              let subtable = match parse_kerx_format0(data, offset, length, header) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if sub_type == 2 {
              let subtable = match parse_kerx_format2(data, offset, length, header, num_glyphs) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subtables.push(subtable)
            } else if sub_type == 6 {
              let subtable = match parse_kerx_format6(data, offset, length, header, num_glyphs) {
                Err(err) => return Err(err)
                Ok(None) => {
                  offset = offset + length
                  continue
                }
                Ok(Some(value)) => value
              }
              subtables.push(subtable)
            }
            offset = offset + length
          }
        }
      }
      Ok(KerxTable::{ version, subtables })
    }
  }
}

///|
pub fn KerxTable::has_data(self : KerxTable) -> Bool {
  self.version != 0
}

///|
pub fn KerxTable::kern_value(
  self : KerxTable,
  left : UInt,
  right : UInt,
  horizontal : Bool,
) -> Int {
  let mut value = 0
  for subtable in self.subtables {
    let header = subtable.header()
    if coverage_is_cross_stream(header.coverage) || coverage_is_backwards(header.coverage) {
      continue
    }
    if horizontal != coverage_is_horizontal(header.coverage) {
      continue
    }
    let kern = subtable.value_for(left, right)
    if kern != 0 {
      value = value + kern
    }
  }
  value
}
