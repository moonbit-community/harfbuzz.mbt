///|
/// Value record for GPOS adjustments.
pub struct ValueRecord {
  x_placement : Int
  y_placement : Int
  x_advance : Int
  y_advance : Int
} derive(Eq, Show, ToJson)

///|
/// Pair adjustment result.
pub struct PairAdjust {
  first : ValueRecord
  second : ValueRecord
} derive(Eq, Show, ToJson)

///|
fn value_record_zero() -> ValueRecord {
  ValueRecord::{ x_placement: 0, y_placement: 0, x_advance: 0, y_advance: 0 }
}

///|
fn add_value_record(a : ValueRecord, b : ValueRecord) -> ValueRecord {
  ValueRecord::{
    x_placement: a.x_placement + b.x_placement,
    y_placement: a.y_placement + b.y_placement,
    x_advance: a.x_advance + b.x_advance,
    y_advance: a.y_advance + b.y_advance,
  }
}

///|\n/// Compute pair adjustment deltas for a glyph sequence.
pub fn GposTable::pair_adjust_deltas(
  self : GposTable,
  glyphs : ArrayView[UInt],
) -> Result[Array[ValueRecord], OtLayoutError] {
  let layout = self.layout
  self.pair_adjust_deltas_with_lookups(glyphs, layout.lookup_list.offsets[:])
}

///|
pub fn GposTable::pair_adjust_deltas_with_lookups(
  self : GposTable,
  glyphs : ArrayView[UInt],
  lookup_offsets : ArrayView[Int],
) -> Result[Array[ValueRecord], OtLayoutError] {
  let deltas : Array[ValueRecord] = Array::make(
    glyphs.length(),
    value_record_zero(),
  )
  let data = self.layout.data
  for lookup_offset in lookup_offsets {
    let parsed = parse_lookup(data, lookup_offset)
    match parsed {
      Err(err) => return Err(err)
      Ok((lookup_type, subtable_offsets)) => {
        if lookup_type != 2 {
          continue
        }
        for subtable_offset in subtable_offsets {
          let format = read_u16_int(data, subtable_offset)
          match format {
            Err(err) => return Err(err)
            Ok(format) => if format == 1 {
              let res = apply_pair_format1(data, subtable_offset, glyphs, deltas)
              match res {
                Err(err) => return Err(err)
                Ok(_) => ()
              }
            } else {
              continue
            }
          }
        }
      }
    }
  }
  Ok(deltas)
}

///|
fn apply_pair_format1(
  data : BytesView,
  offset : Int,
  glyphs : ArrayView[UInt],
  deltas : Array[ValueRecord],
) -> Result[Unit, OtLayoutError] {
  if glyphs.length() < 2 {
    return Ok(())
  }
  for i in 0..<(glyphs.length() - 1) {
    let first = glyphs[i]
    let second = glyphs[i + 1]
    let adjust = pair_adjust_format1(data, offset, first, second)
    match adjust {
      Err(err) => return Err(err)
      Ok(None) => ()
      Ok(Some(adjust)) => {
        deltas[i] = add_value_record(deltas[i], adjust.first)
        deltas[i + 1] = add_value_record(deltas[i + 1], adjust.second)
      }
    }
  }
  Ok(())
}

///|
fn pair_adjust_format1(
  data : BytesView,
  offset : Int,
  first : UInt,
  second : UInt,
) -> Result[PairAdjust?, OtLayoutError] {
  if offset < 0 || offset + 10 > data.length() {
    return Err(UnexpectedEof)
  }
  if second > 0xffffU {
    return Ok(None)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let value_format1 = read_u16_int(data, offset + 4)
  let value_format2 = read_u16_int(data, offset + 6)
  let pair_set_count = read_u16_int(data, offset + 8)
  match (coverage_offset, value_format1, value_format2, pair_set_count) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(value_format1), Ok(value_format2), Ok(pair_set_count)) => {
      let coverage_base = offset + coverage_offset
      let index = coverage_index(data, coverage_base, first)
      match index {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(index)) => {
          if index < 0 || index >= pair_set_count {
            return Err(InvalidFormat)
          }
          let pair_offset_base = offset + 10
          let pair_offset = read_u16_int(data, pair_offset_base + index * 2)
          match pair_offset {
            Err(err) => Err(err)
            Ok(pair_offset) => {
              let pair_base = offset + pair_offset
              if pair_base < 0 || pair_base + 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let value_count = read_u16_int(data, pair_base)
              match value_count {
                Err(err) => Err(err)
                Ok(value_count) => {
                  let record_size = 2 +
                    value_record_size(value_format1) +
                    value_record_size(value_format2)
                  let record_base = pair_base + 2
                  if record_base < 0 || record_base + value_count * record_size > data.length() {
                    return Err(UnexpectedEof)
                  }
                  for i in 0..<value_count {
                    let entry_base = record_base + i * record_size
                    let second_glyph = read_u16_int(data, entry_base)
                    match second_glyph {
                      Err(err) => return Err(err)
                      Ok(second_glyph) => {
                        if second_glyph == u16_to_int(second) {
                          let value1 = read_value_record(
                            data,
                            entry_base + 2,
                            value_format1,
                          )
                          match value1 {
                            Err(err) => return Err(err)
                            Ok((value1, next_offset)) => {
                              let value2 = read_value_record(
                                data,
                                next_offset,
                                value_format2,
                              )
                              match value2 {
                                Err(err) => return Err(err)
                                Ok((value2, _)) =>
                                  return Ok(
                                    Some(PairAdjust::{
                                      first: value1,
                                      second: value2,
                                    }),
                                  )
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  Ok(None)
                }
              }
            }
          }
        }
      }
    }
  }
}

///|
fn value_record_size(format : Int) -> Int {
  let mut size = 0
  if (format & 0x0001) != 0 { size = size + 2 }
  if (format & 0x0002) != 0 { size = size + 2 }
  if (format & 0x0004) != 0 { size = size + 2 }
  if (format & 0x0008) != 0 { size = size + 2 }
  if (format & 0x0010) != 0 { size = size + 2 }
  if (format & 0x0020) != 0 { size = size + 2 }
  if (format & 0x0040) != 0 { size = size + 2 }
  if (format & 0x0080) != 0 { size = size + 2 }
  size
}

///|
fn read_value_record(
  data : BytesView,
  offset : Int,
  format : Int,
) -> Result[(ValueRecord, Int), OtLayoutError] {
  let mut current = offset
  let mut record = value_record_zero()
  if (format & 0x0001) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: value,
        y_placement: record.y_placement,
        x_advance: record.x_advance,
        y_advance: record.y_advance,
      }
    }
    current = current + 2
  }
  if (format & 0x0002) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: record.x_placement,
        y_placement: value,
        x_advance: record.x_advance,
        y_advance: record.y_advance,
      }
    }
    current = current + 2
  }
  if (format & 0x0004) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: record.x_placement,
        y_placement: record.y_placement,
        x_advance: value,
        y_advance: record.y_advance,
      }
    }
    current = current + 2
  }
  if (format & 0x0008) != 0 {
    let value = read_i16(data, current)
    match value {
      Err(err) => return Err(err)
      Ok(value) => record = ValueRecord::{
        x_placement: record.x_placement,
        y_placement: record.y_placement,
        x_advance: record.x_advance,
        y_advance: value,
      }
    }
    current = current + 2
  }
  if (format & 0x0010) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  if (format & 0x0020) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  if (format & 0x0040) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  if (format & 0x0080) != 0 {
    let skip = read_u16_int(data, current)
    match skip {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    current = current + 2
  }
  Ok((record, current))
}
