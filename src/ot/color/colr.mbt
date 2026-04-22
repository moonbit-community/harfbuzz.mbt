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
/// COLR table (v0/v1) parsed data.
pub struct ColrTable {
  version : Int
  base_glyphs : Array[ColrBaseGlyph]
  layers : Array[ColrLayer]
  base_glyph_paints : Array[BaseGlyphPaintRecord]
  layer_paint_offsets : Array[Int]
  clip_list : ClipList?
  var_idx_map : @ot_var.DeltaSetIndexMap?
  var_store : @ot_var.ItemVariationStore?
  data : BytesView
} derive(Debug, ToJson)

///|
/// Parse COLR table data.
pub fn ColrTable::parse(data : BytesView) -> Result[ColrTable, ColorError] {
  let version = read_u16_int(data, 0)
  let num_base_glyphs = read_u16_int(data, 2)
  let base_glyphs_offset = read_u32_int(data, 4)
  let layers_offset = read_u32_int(data, 8)
  let num_layers = read_u16_int(data, 12)
  match
    (version, num_base_glyphs, base_glyphs_offset, layers_offset, num_layers) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(num_base_glyphs),
      Ok(base_glyphs_offset),
      Ok(layers_offset),
      Ok(num_layers),
    ) => {
      if version < 0 || num_base_glyphs < 0 || num_layers < 0 {
        return Err(InvalidFormat)
      }
      if base_glyphs_offset < 0 || layers_offset < 0 {
        return Err(InvalidFormat)
      }
      let base_glyphs : Array[ColrBaseGlyph] = []
      if num_base_glyphs > 0 {
        let record_size = 6
        if base_glyphs_offset + num_base_glyphs * record_size > data.length() {
          return Err(UnexpectedEof)
        }
        for i in 0..<num_base_glyphs {
          let rec_offset = base_glyphs_offset + i * record_size
          let glyph_id = read_u16_int(data, rec_offset)
          let first_layer_index = read_u16_int(data, rec_offset + 2)
          let layers_count = read_u16_int(data, rec_offset + 4)
          match (glyph_id, first_layer_index, layers_count) {
            (Err(err), _, _) => return Err(err)
            (_, Err(err), _) => return Err(err)
            (_, _, Err(err)) => return Err(err)
            (Ok(glyph_id), Ok(first_layer_index), Ok(num_layers)) =>
              base_glyphs.push(ColrBaseGlyph::{
                glyph_id,
                first_layer_index,
                num_layers,
              })
          }
        }
      }
      let layers : Array[ColrLayer] = []
      if num_layers > 0 {
        let record_size = 4
        if layers_offset + num_layers * record_size > data.length() {
          return Err(UnexpectedEof)
        }
        for i in 0..<num_layers {
          let rec_offset = layers_offset + i * record_size
          let glyph_id = read_u16_int(data, rec_offset)
          let color_index = read_u16_int(data, rec_offset + 2)
          match (glyph_id, color_index) {
            (Err(err), _) => return Err(err)
            (_, Err(err)) => return Err(err)
            (Ok(glyph_id), Ok(color_index)) =>
              layers.push(ColrLayer::{ glyph_id, color_index })
          }
        }
      }

      let base_glyph_paints : Array[BaseGlyphPaintRecord] = []
      let layer_paint_offsets : Array[Int] = []
      let mut clip_list : ClipList? = None
      let mut var_idx_map : @ot_var.DeltaSetIndexMap? = None
      let mut var_store : @ot_var.ItemVariationStore? = None

      if version >= 1 {
        if data.length() < 34 {
          return Err(UnexpectedEof)
        }
        let base_glyph_list_offset = read_u32_int(data, 14)
        let layer_list_offset = read_u32_int(data, 18)
        let clip_list_offset = read_u32_int(data, 22)
        let var_idx_map_offset = read_u32_int(data, 26)
        let var_store_offset = read_u32_int(data, 30)
        match
          (
            base_glyph_list_offset, layer_list_offset, clip_list_offset, var_idx_map_offset,
            var_store_offset,
          ) {
          (Err(err), _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _) => return Err(err)
          (_, _, Err(err), _, _) => return Err(err)
          (_, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, Err(err)) => return Err(err)
          (
            Ok(base_glyph_list_offset),
            Ok(layer_list_offset),
            Ok(clip_list_offset),
            Ok(var_idx_map_offset),
            Ok(var_store_offset),
          ) => {
            if base_glyph_list_offset != 0 {
              if base_glyph_list_offset < 0 ||
                base_glyph_list_offset + 4 > data.length() {
                return Err(UnexpectedEof)
              }
              let count = read_u32_int(data, base_glyph_list_offset)
              match count {
                Err(err) => return Err(err)
                Ok(count) => {
                  if count < 0 {
                    return Err(InvalidFormat)
                  }
                  let record_size = 6
                  let records_offset = base_glyph_list_offset + 4
                  if records_offset + count * record_size > data.length() {
                    return Err(UnexpectedEof)
                  }
                  for i in 0..<count {
                    let rec_offset = records_offset + i * record_size
                    let glyph_id = read_u16_int(data, rec_offset)
                    let paint_offset = read_u32_int(data, rec_offset + 2)
                    match (glyph_id, paint_offset) {
                      (Err(err), _) => return Err(err)
                      (_, Err(err)) => return Err(err)
                      (Ok(glyph_id), Ok(paint_offset)) => {
                        if paint_offset < 0 {
                          return Err(InvalidFormat)
                        }
                        let abs_offset = base_glyph_list_offset + paint_offset
                        if abs_offset < 0 || abs_offset >= data.length() {
                          return Err(UnexpectedEof)
                        }
                        base_glyph_paints.push(BaseGlyphPaintRecord::{
                          glyph_id,
                          paint_offset: abs_offset,
                        })
                      }
                    }
                  }
                }
              }
            }
            if layer_list_offset != 0 {
              if layer_list_offset < 0 || layer_list_offset + 4 > data.length() {
                return Err(UnexpectedEof)
              }
              let count = read_u32_int(data, layer_list_offset)
              match count {
                Err(err) => return Err(err)
                Ok(count) => {
                  if count < 0 {
                    return Err(InvalidFormat)
                  }
                  let entries_offset = layer_list_offset + 4
                  if entries_offset + count * 4 > data.length() {
                    return Err(UnexpectedEof)
                  }
                  for i in 0..<count {
                    let entry_offset = entries_offset + i * 4
                    let paint_offset = read_u32_int(data, entry_offset)
                    match paint_offset {
                      Err(err) => return Err(err)
                      Ok(paint_offset) => {
                        if paint_offset < 0 {
                          return Err(InvalidFormat)
                        }
                        let abs_offset = layer_list_offset + paint_offset
                        if abs_offset < 0 || abs_offset >= data.length() {
                          return Err(UnexpectedEof)
                        }
                        layer_paint_offsets.push(abs_offset)
                      }
                    }
                  }
                }
              }
            }
            if clip_list_offset != 0 {
              if clip_list_offset < 0 {
                return Err(InvalidFormat)
              }
              let parsed = parse_clip_list(data, clip_list_offset)
              match parsed {
                Err(err) => return Err(err)
                Ok(value) => clip_list = Some(value)
              }
            }
            if var_idx_map_offset != 0 {
              if var_idx_map_offset < 0 {
                return Err(InvalidFormat)
              }
              let parsed = @ot_var.DeltaSetIndexMap::parse(
                data, var_idx_map_offset,
              )
              match parsed {
                Err(err) => return Err(ColorError::Var(err))
                Ok(value) => var_idx_map = Some(value)
              }
            }
            if var_store_offset != 0 {
              if var_store_offset < 0 || var_store_offset >= data.length() {
                return Err(UnexpectedEof)
              }
              let slice = data[var_store_offset:]
              let parsed = @ot_var.ItemVariationStore::parse(slice)
              match parsed {
                Err(err) => return Err(ColorError::Var(err))
                Ok(value) => var_store = Some(value)
              }
            }
          }
        }
      }

      Ok(ColrTable::{
        version,
        base_glyphs,
        layers,
        base_glyph_paints,
        layer_paint_offsets,
        clip_list,
        var_idx_map,
        var_store,
        data,
      })
    }
  }
}

///|
/// True if COLRv0 data exists.
pub fn ColrTable::has_v0(self : ColrTable) -> Bool {
  self.base_glyphs.length() > 0
}

///|
/// True if COLRv1 data exists.
pub fn ColrTable::has_v1(self : ColrTable) -> Bool {
  self.version >= 1 && self.base_glyph_paints.length() > 0
}

///|
/// Get COLRv0 layers for a glyph.
pub fn ColrTable::glyph_layers(
  self : ColrTable,
  glyph_id : Int,
) -> Array[ColrLayer]? {
  for record in self.base_glyphs {
    if record.glyph_id == glyph_id {
      let start = record.first_layer_index
      let end = start + record.num_layers
      if start < 0 || end > self.layers.length() {
        return None
      }
      let out : Array[ColrLayer] = []
      for i in start..<end {
        out.push(self.layers[i])
      }
      return Some(out)
    }
  }
  None
}

///|
/// Parse a paint table at an absolute offset.
pub fn ColrTable::paint_at(
  self : ColrTable,
  offset : Int,
) -> Result[@paint.Paint, ColorError] {
  if offset < 0 || offset >= self.data.length() {
    return Err(UnexpectedEof)
  }
  parse_paint_root(self.data, offset)
}

///|
/// Get COLRv1 paint for a glyph, if present.
pub fn ColrTable::paint_for_glyph(
  self : ColrTable,
  glyph_id : Int,
) -> Result[@paint.Paint?, ColorError] {
  for record in self.base_glyph_paints {
    if record.glyph_id == glyph_id {
      let paint = self.paint_at(record.paint_offset)
      match paint {
        Err(err) => return Err(err)
        Ok(value) => return Ok(Some(value))
      }
    }
  }
  Ok(None)
}

///|
/// Get COLRv1 layer paint by index.
pub fn ColrTable::layer_paint(
  self : ColrTable,
  index : Int,
) -> Result[@paint.Paint?, ColorError] {
  if index < 0 || index >= self.layer_paint_offsets.length() {
    return Ok(None)
  }
  let offset = self.layer_paint_offsets[index]
  let paint = self.paint_at(offset)
  match paint {
    Err(err) => Err(err)
    Ok(value) => Ok(Some(value))
  }
}

///|
/// Get COLRv1 clip box for a glyph, if present.
pub fn ColrTable::clip_box_for_glyph(
  self : ColrTable,
  glyph_id : Int,
) -> ClipBox? {
  match self.clip_list {
    None => None
    Some(list) => {
      for record in list.records {
        if glyph_id >= record.start_glyph_id && glyph_id <= record.end_glyph_id {
          return Some(record.clip_box)
        }
      }
      None
    }
  }
}

///|
/// Get COLRv1 clip extents for a glyph, applying variation if available.
pub fn ColrTable::clip_extents_for_glyph(
  self : ColrTable,
  glyph_id : Int,
  coords? : Array[Int] = [],
) -> ClipExtents? {
  let clip_box = self.clip_box_for_glyph(glyph_id)
  match clip_box {
    None => None
    Some(box) => {
      let mut x_min = box.x_min
      let mut y_min = box.y_min
      let mut x_max = box.x_max
      let mut y_max = box.y_max
      if coords.length() > 0 {
        let instancer = self.var_instancer(coords)
        x_min = x_min + instancer.delta(box.var_idx_base, 0).round().to_int()
        y_min = y_min + instancer.delta(box.var_idx_base, 1).round().to_int()
        x_max = x_max + instancer.delta(box.var_idx_base, 2).round().to_int()
        y_max = y_max + instancer.delta(box.var_idx_base, 3).round().to_int()
      }
      Some(ClipExtents::{
        x_bearing: x_min,
        y_bearing: y_max,
        width: x_max - x_min,
        height: y_min - y_max,
      })
    }
  }
}

///|
fn parse_clip_box(
  data : BytesView,
  offset : Int,
) -> Result[ClipBox, ColorError] {
  let format = read_u8_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      match format {
        1 => {
          let x_min = read_i16(data, offset + 1)
          let y_min = read_i16(data, offset + 3)
          let x_max = read_i16(data, offset + 5)
          let y_max = read_i16(data, offset + 7)
          match (x_min, y_min, x_max, y_max) {
            (Err(err), _, _, _) => Err(err)
            (_, Err(err), _, _) => Err(err)
            (_, _, Err(err), _) => Err(err)
            (_, _, _, Err(err)) => Err(err)
            (Ok(x_min), Ok(y_min), Ok(x_max), Ok(y_max)) =>
              Ok(ClipBox::{
                format,
                x_min,
                y_min,
                x_max,
                y_max,
                var_idx_base: None,
              })
          }
        }
        2 => {
          let x_min = read_i16(data, offset + 1)
          let y_min = read_i16(data, offset + 3)
          let x_max = read_i16(data, offset + 5)
          let y_max = read_i16(data, offset + 7)
          let var_idx = read_u32(data, offset + 9)
          match (x_min, y_min, x_max, y_max, var_idx) {
            (Err(err), _, _, _, _) => Err(err)
            (_, Err(err), _, _, _) => Err(err)
            (_, _, Err(err), _, _) => Err(err)
            (_, _, _, Err(err), _) => Err(err)
            (_, _, _, _, Err(err)) => Err(err)
            (Ok(x_min), Ok(y_min), Ok(x_max), Ok(y_max), Ok(var_idx)) =>
              Ok(ClipBox::{
                format,
                x_min,
                y_min,
                x_max,
                y_max,
                var_idx_base: Some(var_idx),
              })
          }
        }
        _ => Err(InvalidFormat)
      }
  }
}

///|
fn parse_clip_list(
  data : BytesView,
  offset : Int,
) -> Result[ClipList, ColorError] {
  let format = read_u8_int(data, offset)
  let count = read_u32_int(data, offset + 1)
  match (format, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(format), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let record_size = 7
      let records_offset = offset + 5
      if records_offset + count * record_size > data.length() {
        return Err(UnexpectedEof)
      }
      let records : Array[ClipRecord] = []
      for i in 0..<count {
        let rec_offset = records_offset + i * record_size
        let start_gid = read_u16_int(data, rec_offset)
        let end_gid = read_u16_int(data, rec_offset + 2)
        let clip_offset = read_u24_int(data, rec_offset + 4)
        match (start_gid, end_gid, clip_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(start_gid), Ok(end_gid), Ok(clip_offset)) => {
            let clip_abs = match resolve_offset(offset, clip_offset, data) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            let clip_box = parse_clip_box(data, clip_abs)
            match clip_box {
              Err(err) => return Err(err)
              Ok(clip_box) =>
                records.push(ClipRecord::{
                  start_glyph_id: start_gid,
                  end_glyph_id: end_gid,
                  clip_box,
                })
            }
          }
        }
      }
      Ok(ClipList::{ format, records })
    }
  }
}
