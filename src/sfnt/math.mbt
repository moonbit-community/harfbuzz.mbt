// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Math value record with optional device table offset.
pub struct MathValueRecord {
  value : Int
  device_offset : Int
} derive(Eq, Debug, ToJson)

///|
/// Math constants table.
pub struct MathConstants {
  percent_scale_down : Array[Int]
  min_height : Array[Int]
  math_values : Array[MathValueRecord]
  radical_degree_bottom_raise_percent : Int
} derive(Debug, ToJson)

///|
/// Italics correction info.
pub struct MathItalicsCorrectionInfo {
  coverage_offset : Int
  records : Array[MathValueRecord]
} derive(Debug, ToJson)

///|
/// Top accent attachment info.
pub struct MathTopAccentAttachment {
  coverage_offset : Int
  records : Array[MathValueRecord]
} derive(Debug, ToJson)

///|
/// Math kern table.
pub struct MathKern {
  height_count : Int
  records : Array[MathValueRecord]
} derive(Debug, ToJson)

///|
/// Math kern info record (four corners).
pub struct MathKernInfoRecord {
  math_kerns : Array[MathKern?]
} derive(Debug, ToJson)

///|
/// Math kern info table.
pub struct MathKernInfo {
  coverage_offset : Int
  records : Array[MathKernInfoRecord]
} derive(Debug, ToJson)

///|
/// Math glyph info table.
pub struct MathGlyphInfo {
  italics_correction : MathItalicsCorrectionInfo?
  top_accent_attachment : MathTopAccentAttachment?
  extended_shape_coverage_offset : Int
  math_kern_info : MathKernInfo?
} derive(Debug, ToJson)

///|
/// Math glyph variant record.
pub struct MathGlyphVariantRecord {
  variant_glyph : Int
  advance : Int
} derive(Debug, ToJson)

///|
/// Math glyph part record.
pub struct MathGlyphPartRecord {
  glyph : Int
  start_connector_length : Int
  end_connector_length : Int
  full_advance : Int
  flags : Int
} derive(Debug, ToJson)

///|
/// Math glyph assembly table.
pub struct MathGlyphAssembly {
  italics_correction : MathValueRecord
  parts : Array[MathGlyphPartRecord]
} derive(Debug, ToJson)

///|
/// Math glyph construction table.
pub struct MathGlyphConstruction {
  glyph_assembly : MathGlyphAssembly?
  variants : Array[MathGlyphVariantRecord]
} derive(Debug, ToJson)

///|
/// Math variants table.
pub struct MathVariants {
  min_connector_overlap : Int
  vert_coverage_offset : Int
  horiz_coverage_offset : Int
  vert_glyph_count : Int
  horiz_glyph_count : Int
  constructions : Array[MathGlyphConstruction?]
} derive(Debug, ToJson)

///|
/// Parsed MATH table.
pub struct MathTable {
  major_version : Int
  minor_version : Int
  constants : MathConstants?
  glyph_info : MathGlyphInfo?
  variants : MathVariants?
} derive(Debug, ToJson)

///|
fn read_math_value_record(
  data : BytesView,
  offset : Int,
  base : Int,
) -> Result[MathValueRecord, SfntError] {
  let value = read_i16(data, offset)
  let device_offset = read_u16_int(data, offset + 2)
  match (value, device_offset) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(value), Ok(device_offset)) => {
      if device_offset < 0 {
        return Err(InvalidFormat)
      }
      if device_offset != 0 {
        let absolute = base + device_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      Ok(MathValueRecord::{ value, device_offset })
    }
  }
}

///|
fn parse_math_constants(
  data : BytesView,
  offset : Int,
) -> Result[MathConstants, SfntError] {
  if offset < 0 || offset + 214 > data.length() {
    return Err(UnexpectedEof)
  }
  let percent0 = read_i16(data, offset)
  let percent1 = read_i16(data, offset + 2)
  let min0 = read_u16_int(data, offset + 4)
  let min1 = read_u16_int(data, offset + 6)
  match (percent0, percent1, min0, min1) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(percent0), Ok(percent1), Ok(min0), Ok(min1)) => {
      let percent_scale_down : Array[Int] = [percent0, percent1]
      let min_height : Array[Int] = [min0, min1]
      let math_values : Array[MathValueRecord] = []
      let mut cursor = offset + 8
      for _ in 0..<51 {
        let record = match read_math_value_record(data, cursor, offset) {
          Err(err) => return Err(err)
          Ok(record) => record
        }
        math_values.push(record)
        cursor = cursor + 4
      }
      let radical = read_i16(data, offset + 212)
      match radical {
        Err(err) => Err(err)
        Ok(radical) =>
          Ok(MathConstants::{
            percent_scale_down,
            min_height,
            math_values,
            radical_degree_bottom_raise_percent: radical,
          })
      }
    }
  }
}

///|
fn parse_math_italics_correction(
  data : BytesView,
  offset : Int,
) -> Result[MathItalicsCorrectionInfo, SfntError] {
  let coverage_offset = read_u16_int(data, offset)
  let count = read_u16_int(data, offset + 2)
  match (coverage_offset, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset < 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset != 0 {
        let absolute = offset + coverage_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      let records : Array[MathValueRecord] = []
      let record_base = offset + 4
      if record_base + count * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 4
        let record = match read_math_value_record(data, record_offset, offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        records.push(record)
      }
      Ok(MathItalicsCorrectionInfo::{ coverage_offset, records })
    }
  }
}

///|
fn parse_math_top_accent_attachment(
  data : BytesView,
  offset : Int,
) -> Result[MathTopAccentAttachment, SfntError] {
  let coverage_offset = read_u16_int(data, offset)
  let count = read_u16_int(data, offset + 2)
  match (coverage_offset, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset < 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset != 0 {
        let absolute = offset + coverage_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      let records : Array[MathValueRecord] = []
      let record_base = offset + 4
      if record_base + count * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 4
        let record = match read_math_value_record(data, record_offset, offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        records.push(record)
      }
      Ok(MathTopAccentAttachment::{ coverage_offset, records })
    }
  }
}

///|
fn parse_math_kern(
  data : BytesView,
  offset : Int,
) -> Result[MathKern, SfntError] {
  let height_count = read_u16_int(data, offset)
  match height_count {
    Err(err) => Err(err)
    Ok(height_count) => {
      if height_count < 0 {
        return Err(InvalidFormat)
      }
      let total = height_count * 2 + 1
      let record_base = offset + 2
      if record_base + total * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      let records : Array[MathValueRecord] = []
      for i in 0..<total {
        let record_offset = record_base + i * 4
        let record = match read_math_value_record(data, record_offset, offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        records.push(record)
      }
      Ok(MathKern::{ height_count, records })
    }
  }
}

///|
fn parse_math_kern_info(
  data : BytesView,
  offset : Int,
) -> Result[MathKernInfo, SfntError] {
  let coverage_offset = read_u16_int(data, offset)
  let count = read_u16_int(data, offset + 2)
  match (coverage_offset, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(coverage_offset), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset < 0 {
        return Err(InvalidFormat)
      }
      if coverage_offset != 0 {
        let absolute = offset + coverage_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      let records : Array[MathKernInfoRecord] = []
      let record_base = offset + 4
      if record_base + count * 8 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let base = record_base + i * 8
        let math_kerns : Array[MathKern?] = []
        for j in 0..<4 {
          let kern_offset = read_u16_int(data, base + j * 2)
          match kern_offset {
            Err(err) => return Err(err)
            Ok(kern_offset) => {
              if kern_offset < 0 {
                return Err(InvalidFormat)
              }
              if kern_offset == 0 {
                math_kerns.push(None)
              } else {
                let absolute = offset + kern_offset
                let kern = match parse_math_kern(data, absolute) {
                  Err(err) => return Err(err)
                  Ok(value) => value
                }
                math_kerns.push(Some(kern))
              }
            }
          }
        }
        records.push(MathKernInfoRecord::{ math_kerns, })
      }
      Ok(MathKernInfo::{ coverage_offset, records })
    }
  }
}

///|
fn parse_math_glyph_info(
  data : BytesView,
  offset : Int,
) -> Result[MathGlyphInfo, SfntError] {
  let italics_offset = read_u16_int(data, offset)
  let top_offset = read_u16_int(data, offset + 2)
  let extended_offset = read_u16_int(data, offset + 4)
  let kern_offset = read_u16_int(data, offset + 6)
  match (italics_offset, top_offset, extended_offset, kern_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(italics_offset), Ok(top_offset), Ok(extended_offset), Ok(kern_offset)) => {
      if italics_offset < 0 ||
        top_offset < 0 ||
        extended_offset < 0 ||
        kern_offset < 0 {
        return Err(InvalidFormat)
      }
      let italics_correction = if italics_offset == 0 {
        None
      } else {
        let absolute = offset + italics_offset
        Some(
          match parse_math_italics_correction(data, absolute) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      let top_accent_attachment = if top_offset == 0 {
        None
      } else {
        let absolute = offset + top_offset
        Some(
          match parse_math_top_accent_attachment(data, absolute) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      if extended_offset != 0 {
        let absolute = offset + extended_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      let math_kern_info = if kern_offset == 0 {
        None
      } else {
        let absolute = offset + kern_offset
        Some(
          match parse_math_kern_info(data, absolute) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      Ok(MathGlyphInfo::{
        italics_correction,
        top_accent_attachment,
        extended_shape_coverage_offset: extended_offset,
        math_kern_info,
      })
    }
  }
}

///|
fn parse_math_glyph_assembly(
  data : BytesView,
  offset : Int,
) -> Result[MathGlyphAssembly, SfntError] {
  let italics = match read_math_value_record(data, offset, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let count = read_u16_int(data, offset + 4)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let parts : Array[MathGlyphPartRecord] = []
      let record_base = offset + 6
      if record_base + count * 10 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let base = record_base + i * 10
        let glyph = read_u16_int(data, base)
        let start_connector_length = read_u16_int(data, base + 2)
        let end_connector_length = read_u16_int(data, base + 4)
        let full_advance = read_u16_int(data, base + 6)
        let flags = read_u16_int(data, base + 8)
        match
          (
            glyph, start_connector_length, end_connector_length, full_advance, flags,
          ) {
          (Err(err), _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _) => return Err(err)
          (_, _, Err(err), _, _) => return Err(err)
          (_, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, Err(err)) => return Err(err)
          (
            Ok(glyph),
            Ok(start_connector_length),
            Ok(end_connector_length),
            Ok(full_advance),
            Ok(flags),
          ) =>
            parts.push(MathGlyphPartRecord::{
              glyph,
              start_connector_length,
              end_connector_length,
              full_advance,
              flags,
            })
        }
      }
      Ok(MathGlyphAssembly::{ italics_correction: italics, parts })
    }
  }
}

///|
fn parse_math_glyph_construction(
  data : BytesView,
  offset : Int,
) -> Result[MathGlyphConstruction, SfntError] {
  let assembly_offset = read_u16_int(data, offset)
  let variant_count = read_u16_int(data, offset + 2)
  match (assembly_offset, variant_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(assembly_offset), Ok(variant_count)) => {
      if assembly_offset < 0 || variant_count < 0 {
        return Err(InvalidFormat)
      }
      let glyph_assembly = if assembly_offset == 0 {
        None
      } else {
        let absolute = offset + assembly_offset
        Some(
          match parse_math_glyph_assembly(data, absolute) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      let variants : Array[MathGlyphVariantRecord] = []
      let record_base = offset + 4
      if record_base + variant_count * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<variant_count {
        let base = record_base + i * 4
        let glyph = read_u16_int(data, base)
        let advance = read_u16_int(data, base + 2)
        match (glyph, advance) {
          (Err(err), _) => return Err(err)
          (_, Err(err)) => return Err(err)
          (Ok(glyph), Ok(advance)) =>
            variants.push(MathGlyphVariantRecord::{
              variant_glyph: glyph,
              advance,
            })
        }
      }
      Ok(MathGlyphConstruction::{ glyph_assembly, variants })
    }
  }
}

///|
fn parse_math_variants(
  data : BytesView,
  offset : Int,
) -> Result[MathVariants, SfntError] {
  let min_connector_overlap = read_u16_int(data, offset)
  let vert_coverage_offset = read_u16_int(data, offset + 2)
  let horiz_coverage_offset = read_u16_int(data, offset + 4)
  let vert_count = read_u16_int(data, offset + 6)
  let horiz_count = read_u16_int(data, offset + 8)
  match
    (
      min_connector_overlap, vert_coverage_offset, horiz_coverage_offset, vert_count,
      horiz_count,
    ) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(min_connector_overlap),
      Ok(vert_coverage_offset),
      Ok(horiz_coverage_offset),
      Ok(vert_count),
      Ok(horiz_count),
    ) => {
      if vert_coverage_offset < 0 ||
        horiz_coverage_offset < 0 ||
        vert_count < 0 ||
        horiz_count < 0 {
        return Err(InvalidFormat)
      }
      if vert_coverage_offset != 0 {
        let absolute = offset + vert_coverage_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      if horiz_coverage_offset != 0 {
        let absolute = offset + horiz_coverage_offset
        if absolute < 0 || absolute > data.length() {
          return Err(UnexpectedEof)
        }
      }
      let total = vert_count + horiz_count
      let constructions : Array[MathGlyphConstruction?] = []
      let offsets_base = offset + 10
      if offsets_base + total * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<total {
        let construction_offset = read_u16_int(data, offsets_base + i * 2)
        match construction_offset {
          Err(err) => return Err(err)
          Ok(construction_offset) => {
            if construction_offset < 0 {
              return Err(InvalidFormat)
            }
            if construction_offset == 0 {
              constructions.push(None)
            } else {
              let absolute = offset + construction_offset
              let construction = match
                parse_math_glyph_construction(data, absolute) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              constructions.push(Some(construction))
            }
          }
        }
      }
      Ok(MathVariants::{
        min_connector_overlap,
        vert_coverage_offset,
        horiz_coverage_offset,
        vert_glyph_count: vert_count,
        horiz_glyph_count: horiz_count,
        constructions,
      })
    }
  }
}

///|
/// Parse MATH table bytes.
pub fn MathTable::parse(data : BytesView) -> Result[MathTable, SfntError] {
  if data.length() < 10 {
    return Err(UnexpectedEof)
  }
  let version = read_u32_int(data, 0)
  let constants_offset = read_u16_int(data, 4)
  let glyph_info_offset = read_u16_int(data, 6)
  let variants_offset = read_u16_int(data, 8)
  match (version, constants_offset, glyph_info_offset, variants_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(constants_offset),
      Ok(glyph_info_offset),
      Ok(variants_offset),
    ) => {
      if constants_offset < 0 || glyph_info_offset < 0 || variants_offset < 0 {
        return Err(InvalidFormat)
      }
      let major = version >> 16
      let minor = version & 0xffff
      let constants = if constants_offset == 0 {
        None
      } else {
        Some(
          match parse_math_constants(data, constants_offset) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      let glyph_info = if glyph_info_offset == 0 {
        None
      } else {
        let absolute = glyph_info_offset
        Some(
          match parse_math_glyph_info(data, absolute) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      let variants = if variants_offset == 0 {
        None
      } else {
        let absolute = variants_offset
        Some(
          match parse_math_variants(data, absolute) {
            Err(err) => return Err(err)
            Ok(value) => value
          },
        )
      }
      Ok(MathTable::{
        major_version: major,
        minor_version: minor,
        constants,
        glyph_info,
        variants,
      })
    }
  }
}
