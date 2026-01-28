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
            } else if format == 2 {
              let res = apply_pair_format2(data, subtable_offset, glyphs, deltas)
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
fn apply_pair_format2(
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
    let adjust = pair_adjust_format2(data, offset, first, second)
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
fn pair_adjust_format2(
  data : BytesView,
  offset : Int,
  first : UInt,
  second : UInt,
) -> Result[PairAdjust?, OtLayoutError] {
  if offset < 0 || offset + 16 > data.length() {
    return Err(UnexpectedEof)
  }
  if first > 0xffffU || second > 0xffffU {
    return Ok(None)
  }
  let coverage_offset = read_u16_int(data, offset + 2)
  let value_format1 = read_u16_int(data, offset + 4)
  let value_format2 = read_u16_int(data, offset + 6)
  let class_def1_offset = read_u16_int(data, offset + 8)
  let class_def2_offset = read_u16_int(data, offset + 10)
  let class1_count = read_u16_int(data, offset + 12)
  let class2_count = read_u16_int(data, offset + 14)
  match (
    coverage_offset,
    value_format1,
    value_format2,
    class_def1_offset,
    class_def2_offset,
    class1_count,
    class2_count,
  ) {
    (Err(err), _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(coverage_offset),
      Ok(value_format1),
      Ok(value_format2),
      Ok(class_def1_offset),
      Ok(class_def2_offset),
      Ok(class1_count),
      Ok(class2_count),
    ) => {
      if coverage_offset == 0 || class_def1_offset == 0 || class_def2_offset == 0 {
        return Err(InvalidFormat)
      }
      if class1_count <= 0 || class2_count <= 0 {
        return Err(InvalidFormat)
      }
      let coverage_base = offset + coverage_offset
      let coverage = coverage_index(data, coverage_base, first)
      match coverage {
        Err(err) => Err(err)
        Ok(None) => Ok(None)
        Ok(Some(_)) => {
          let class1 = class_def_value(data, offset + class_def1_offset, first)
          let class2 = class_def_value(data, offset + class_def2_offset, second)
          match (class1, class2) {
            (Err(err), _) => Err(err)
            (_, Err(err)) => Err(err)
            (Ok(class1), Ok(class2)) => {
              if class1 < 0 || class1 >= class1_count {
                return Err(InvalidFormat)
              }
              if class2 < 0 || class2 >= class2_count {
                return Err(InvalidFormat)
              }
              let record_size =
                value_record_size(value_format1) + value_record_size(value_format2)
              let class1_record_size = class2_count * record_size
              let records_base = offset + 16
              let total_size = class1_count * class1_record_size
              if records_base < 0 || records_base + total_size > data.length() {
                return Err(UnexpectedEof)
              }
              let entry_base =
                records_base + class1 * class1_record_size + class2 * record_size
              let value1 = read_value_record(data, entry_base, value_format1)
              match value1 {
                Err(err) => Err(err)
                Ok((value1, next_offset)) => {
                  let value2 = read_value_record(data, next_offset, value_format2)
                  match value2 {
                    Err(err) => Err(err)
                    Ok((value2, _)) =>
                      Ok(Some(PairAdjust::{ first: value1, second: value2 }))
                  }
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

///|
fn class_def_value(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  if glyph > 0xffffU {
    return Ok(0)
  }
  if offset < 0 || offset + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) => if format == 1 {
      class_def_format1(data, offset, glyph)
    } else if format == 2 {
      class_def_format2(data, offset, glyph)
    } else {
      Err(InvalidFormat)
    }
  }
}

///|
fn class_def_format1(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let start_glyph = read_u16_int(data, offset + 2)
  let glyph_count = read_u16_int(data, offset + 4)
  match (start_glyph, glyph_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(start_glyph), Ok(glyph_count)) => {
      if glyph_count <= 0 {
        return Err(InvalidFormat)
      }
      let gid = u16_to_int(glyph)
      if gid < start_glyph || gid >= start_glyph + glyph_count {
        return Ok(0)
      }
      let index = gid - start_glyph
      let class_base = offset + 6
      if class_base < 0 || class_base + glyph_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let value = read_u16_int(data, class_base + index * 2)
      match value {
        Err(err) => Err(err)
        Ok(value) => Ok(value)
      }
    }
  }
}

///|
fn class_def_format2(
  data : BytesView,
  offset : Int,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let range_count = read_u16_int(data, offset + 2)
  match range_count {
    Err(err) => Err(err)
    Ok(range_count) => {
      if range_count < 0 {
        return Err(InvalidFormat)
      }
      let record_base = offset + 4
      if record_base < 0 || record_base + range_count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      let gid = u16_to_int(glyph)
      for i in 0..<range_count {
        let base = record_base + i * 6
        let start = read_u16_int(data, base)
        let end = read_u16_int(data, base + 2)
        let class_value = read_u16_int(data, base + 4)
        match (start, end, class_value) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start), Ok(end), Ok(class_value)) => {
            if gid >= start && gid <= end {
              return Ok(class_value)
            }
          }
        }
      }
      Ok(0)
    }
  }
}
