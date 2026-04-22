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
/// CPAL color palette table.
pub struct CpalTable {
  version : Int
  num_colors : Int
  num_palettes : Int
  num_color_records : Int
  color_records : Array[@paint.Color]
  color_record_indices : Array[Int]
  palette_flags : Array[UInt]?
  palette_labels : Array[Int]?
  color_labels : Array[Int]?
} derive(Debug, ToJson)

///|
/// Parse CPAL table data.
pub fn CpalTable::parse(data : BytesView) -> Result[CpalTable, ColorError] {
  let version = read_u16_int(data, 0)
  let num_colors = read_u16_int(data, 2)
  let num_palettes = read_u16_int(data, 4)
  let num_color_records = read_u16_int(data, 6)
  let color_records_offset = read_u32_int(data, 8)
  match
    (version, num_colors, num_palettes, num_color_records, color_records_offset) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(num_colors),
      Ok(num_palettes),
      Ok(num_color_records),
      Ok(color_records_offset),
    ) => {
      if version < 0 ||
        num_colors < 0 ||
        num_palettes < 0 ||
        num_color_records < 0 {
        return Err(InvalidFormat)
      }
      if version != 0 && version != 1 {
        return Err(InvalidFormat)
      }
      if color_records_offset < 0 {
        return Err(InvalidFormat)
      }
      let indices_offset = 12
      let indices_len = num_palettes * 2
      if indices_offset + indices_len > data.length() {
        return Err(UnexpectedEof)
      }
      let color_record_indices : Array[Int] = []
      for i in 0..<num_palettes {
        let idx = read_u16_int(data, indices_offset + i * 2)
        match idx {
          Err(err) => return Err(err)
          Ok(value) => color_record_indices.push(value)
        }
      }
      let record_size = 4
      let records_len = num_color_records * record_size
      if color_records_offset + records_len > data.length() {
        return Err(UnexpectedEof)
      }
      let color_records : Array[@paint.Color] = []
      for i in 0..<num_color_records {
        let base = color_records_offset + i * record_size
        let b = data[base].to_int()
        let g = data[base + 1].to_int()
        let r = data[base + 2].to_int()
        let a = data[base + 3].to_int()
        color_records.push(@paint.Color::from_bgra(b, g, r, a))
      }
      let mut palette_flags : Array[UInt]? = None
      let mut palette_labels : Array[Int]? = None
      let mut color_labels : Array[Int]? = None
      if version == 1 {
        let tail_offset = indices_offset + indices_len
        if tail_offset + 12 > data.length() {
          return Err(UnexpectedEof)
        }
        let palette_flags_offset = read_u32_int(data, tail_offset)
        let palette_labels_offset = read_u32_int(data, tail_offset + 4)
        let color_labels_offset = read_u32_int(data, tail_offset + 8)
        match
          (palette_flags_offset, palette_labels_offset, color_labels_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(flags_offset), Ok(labels_offset), Ok(colors_offset)) => {
            if flags_offset != 0 {
              if flags_offset < 0 ||
                flags_offset + num_palettes * 4 > data.length() {
                return Err(UnexpectedEof)
              }
              let flags : Array[UInt] = []
              for i in 0..<num_palettes {
                let value = read_u32(data, flags_offset + i * 4)
                match value {
                  Err(err) => return Err(err)
                  Ok(v) => flags.push(v)
                }
              }
              palette_flags = Some(flags)
            }
            if labels_offset != 0 {
              if labels_offset < 0 ||
                labels_offset + num_palettes * 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let labels : Array[Int] = []
              for i in 0..<num_palettes {
                let value = read_u16_int(data, labels_offset + i * 2)
                match value {
                  Err(err) => return Err(err)
                  Ok(v) => labels.push(v)
                }
              }
              palette_labels = Some(labels)
            }
            if colors_offset != 0 {
              if colors_offset < 0 ||
                colors_offset + num_colors * 2 > data.length() {
                return Err(UnexpectedEof)
              }
              let labels : Array[Int] = []
              for i in 0..<num_colors {
                let value = read_u16_int(data, colors_offset + i * 2)
                match value {
                  Err(err) => return Err(err)
                  Ok(v) => labels.push(v)
                }
              }
              color_labels = Some(labels)
            }
          }
        }
      }
      Ok(CpalTable::{
        version,
        num_colors,
        num_palettes,
        num_color_records,
        color_records,
        color_record_indices,
        palette_flags,
        palette_labels,
        color_labels,
      })
    }
  }
}

///|
/// Get palette colors for the given palette index.
pub fn CpalTable::palette_colors(
  self : CpalTable,
  palette_index : Int,
) -> Array[@paint.Color] {
  if palette_index < 0 || palette_index >= self.num_palettes {
    return []
  }
  let start = self.color_record_indices[palette_index]
  if start < 0 {
    return []
  }
  let end = start + self.num_colors
  if end > self.color_records.length() {
    return []
  }
  let colors : Array[@paint.Color] = []
  for i in start..<end {
    colors.push(self.color_records[i])
  }
  colors
}
