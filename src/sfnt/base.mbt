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
/// Base coordinate formats.
pub enum BaseCoord {
  Format1(Int)
  Format2(Int, Int, Int)
  Format3(Int, Int)
} derive(Debug, ToJson)

///|
/// Feature min/max record.
pub struct FeatMinMaxRecord {
  tag : @common.Tag
  min_coord : BaseCoord?
  max_coord : BaseCoord?
} derive(Debug, ToJson)

///|
/// Min/max table.
pub struct MinMax {
  min_coord : BaseCoord?
  max_coord : BaseCoord?
  records : Array[FeatMinMaxRecord]
} derive(Debug, ToJson)

///|
/// Base values table.
pub struct BaseValues {
  default_index : Int
  base_coords : Array[BaseCoord?]
} derive(Debug, ToJson)

///|
/// Base language system record.
pub struct BaseLangSysRecord {
  tag : @common.Tag
  min_max : MinMax?
} derive(Debug, ToJson)

///|
/// Base script table.
pub struct BaseScript {
  base_values : BaseValues?
  default_min_max : MinMax?
  lang_sys_records : Array[BaseLangSysRecord]
} derive(Debug, ToJson)

///|
/// Base script record.
pub struct BaseScriptRecord {
  tag : @common.Tag
  base_script : BaseScript?
} derive(Debug, ToJson)

///|
/// Base script list.
pub struct BaseScriptList {
  records : Array[BaseScriptRecord]
} derive(Debug, ToJson)

///|
/// Base tag list.
pub struct BaseTagList {
  tags : Array[@common.Tag]
} derive(Debug, ToJson)

///|
/// Axis table.
pub struct Axis {
  base_tags : BaseTagList?
  base_scripts : BaseScriptList?
} derive(Debug, ToJson)

///|
/// Parsed BASE table.
pub struct BaseTable {
  major_version : Int
  minor_version : Int
  h_axis : Axis?
  v_axis : Axis?
  var_store_offset : Int?
} derive(Debug, ToJson)

///|
fn parse_base_coord(data : BytesView, offset : Int) -> Result[BaseCoord, SfntError] {
  let format = read_u16_int(data, offset)
  match format {
    Err(err) => Err(err)
    Ok(format) =>
      if format == 1 {
        match read_i16(data, offset + 2) {
          Err(err) => Err(err)
          Ok(value) => Ok(Format1(value))
        }
      } else if format == 2 {
        let coord = read_i16(data, offset + 2)
        let reference_glyph = read_u16_int(data, offset + 4)
        let coord_point = read_u16_int(data, offset + 6)
        match (coord, reference_glyph, coord_point) {
          (Err(err), _, _) => Err(err)
          (_, Err(err), _) => Err(err)
          (_, _, Err(err)) => Err(err)
          (Ok(coord), Ok(reference_glyph), Ok(coord_point)) =>
            Ok(Format2(coord, reference_glyph, coord_point))
        }
      } else if format == 3 {
        let coord = read_i16(data, offset + 2)
        let device_offset = read_u16_int(data, offset + 4)
        match (coord, device_offset) {
          (Err(err), _) => Err(err)
          (_, Err(err)) => Err(err)
          (Ok(coord), Ok(device_offset)) => {
            if device_offset < 0 {
              return Err(InvalidFormat)
            }
            if device_offset != 0 {
              let absolute = offset + device_offset
              if absolute < 0 || absolute > data.length() {
                return Err(UnexpectedEof)
              }
            }
            Ok(Format3(coord, device_offset))
          }
        }
      } else {
        Err(InvalidFormat)
      }
  }
}

///|
fn parse_feat_min_max_record(
  data : BytesView,
  offset : Int,
  base : Int,
) -> Result[FeatMinMaxRecord, SfntError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let tag = @common.Tag::from_bytes(
    data[offset],
    data[offset + 1],
    data[offset + 2],
    data[offset + 3],
  )
  let min_offset = read_u16_int(data, offset + 4)
  let max_offset = read_u16_int(data, offset + 6)
  match (min_offset, max_offset) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(min_offset), Ok(max_offset)) => {
      if min_offset < 0 || max_offset < 0 {
        return Err(InvalidFormat)
      }
      let min_coord = if min_offset == 0 {
        None
      } else {
        Some(match parse_base_coord(data, base + min_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let max_coord = if max_offset == 0 {
        None
      } else {
        Some(match parse_base_coord(data, base + max_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      Ok(FeatMinMaxRecord::{ tag, min_coord, max_coord })
    }
  }
}

///|
fn parse_min_max(data : BytesView, offset : Int) -> Result[MinMax, SfntError] {
  let min_offset = read_u16_int(data, offset)
  let max_offset = read_u16_int(data, offset + 2)
  let count = read_u16_int(data, offset + 4)
  match (min_offset, max_offset, count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(min_offset), Ok(max_offset), Ok(count)) => {
      if min_offset < 0 || max_offset < 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let min_coord = if min_offset == 0 {
        None
      } else {
        Some(match parse_base_coord(data, offset + min_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let max_coord = if max_offset == 0 {
        None
      } else {
        Some(match parse_base_coord(data, offset + max_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let records : Array[FeatMinMaxRecord] = []
      let record_base = offset + 6
      if record_base + count * 8 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 8
        let record = match parse_feat_min_max_record(data, record_offset, offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        records.push(record)
      }
      Ok(MinMax::{ min_coord, max_coord, records })
    }
  }
}

///|
fn parse_base_values(data : BytesView, offset : Int) -> Result[BaseValues, SfntError] {
  let default_index = read_u16_int(data, offset)
  let count = read_u16_int(data, offset + 2)
  match (default_index, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(default_index), Ok(count)) => {
      if default_index < 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let base_coords : Array[BaseCoord?] = []
      let offsets_base = offset + 4
      if offsets_base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let coord_offset = read_u16_int(data, offsets_base + i * 2)
        match coord_offset {
          Err(err) => return Err(err)
          Ok(coord_offset) => {
            if coord_offset < 0 {
              return Err(InvalidFormat)
            }
            if coord_offset == 0 {
              base_coords.push(None)
            } else {
              let coord = match parse_base_coord(data, offset + coord_offset) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              base_coords.push(Some(coord))
            }
          }
        }
      }
      Ok(BaseValues::{ default_index, base_coords })
    }
  }
}

///|
fn parse_base_lang_sys_record(
  data : BytesView,
  offset : Int,
  base : Int,
) -> Result[BaseLangSysRecord, SfntError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let tag = @common.Tag::from_bytes(
    data[offset],
    data[offset + 1],
    data[offset + 2],
    data[offset + 3],
  )
  let min_max_offset = read_u16_int(data, offset + 4)
  match min_max_offset {
    Err(err) => Err(err)
    Ok(min_max_offset) => {
      if min_max_offset < 0 {
        return Err(InvalidFormat)
      }
      let min_max = if min_max_offset == 0 {
        None
      } else {
        Some(match parse_min_max(data, base + min_max_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      Ok(BaseLangSysRecord::{ tag, min_max })
    }
  }
}

///|
fn parse_base_script(data : BytesView, offset : Int) -> Result[BaseScript, SfntError] {
  let base_values_offset = read_u16_int(data, offset)
  let default_minmax_offset = read_u16_int(data, offset + 2)
  let count = read_u16_int(data, offset + 4)
  match (base_values_offset, default_minmax_offset, count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(base_values_offset), Ok(default_minmax_offset), Ok(count)) => {
      if base_values_offset < 0 || default_minmax_offset < 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let base_values = if base_values_offset == 0 {
        None
      } else {
        Some(match parse_base_values(data, offset + base_values_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let default_min_max = if default_minmax_offset == 0 {
        None
      } else {
        Some(match parse_min_max(data, offset + default_minmax_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let lang_sys_records : Array[BaseLangSysRecord] = []
      let record_base = offset + 6
      if record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 6
        let record = match parse_base_lang_sys_record(data, record_offset, offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        lang_sys_records.push(record)
      }
      Ok(BaseScript::{ base_values, default_min_max, lang_sys_records })
    }
  }
}

///|
fn parse_base_script_list(data : BytesView, offset : Int) -> Result[BaseScriptList, SfntError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let records : Array[BaseScriptRecord] = []
      let record_base = offset + 2
      if record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let base = record_base + i * 6
        let tag = @common.Tag::from_bytes(
          data[base],
          data[base + 1],
          data[base + 2],
          data[base + 3],
        )
        let script_offset = read_u16_int(data, base + 4)
        match script_offset {
          Err(err) => return Err(err)
          Ok(script_offset) => {
            if script_offset < 0 {
              return Err(InvalidFormat)
            }
            let base_script = if script_offset == 0 {
              None
            } else {
              Some(match parse_base_script(data, offset + script_offset) {
                Err(err) => return Err(err)
                Ok(value) => value
              })
            }
            records.push(BaseScriptRecord::{ tag, base_script })
          }
        }
      }
      Ok(BaseScriptList::{ records })
    }
  }
}

///|
fn parse_base_tag_list(data : BytesView, offset : Int) -> Result[BaseTagList, SfntError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let tags : Array[@common.Tag] = []
      let tag_base = offset + 2
      if tag_base + count * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let base = tag_base + i * 4
        let tag = @common.Tag::from_bytes(
          data[base],
          data[base + 1],
          data[base + 2],
          data[base + 3],
        )
        tags.push(tag)
      }
      Ok(BaseTagList::{ tags })
    }
  }
}

///|
fn parse_axis(data : BytesView, offset : Int) -> Result[Axis, SfntError] {
  let base_tag_offset = read_u16_int(data, offset)
  let base_script_offset = read_u16_int(data, offset + 2)
  match (base_tag_offset, base_script_offset) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(base_tag_offset), Ok(base_script_offset)) => {
      if base_tag_offset < 0 || base_script_offset < 0 {
        return Err(InvalidFormat)
      }
      let base_tags = if base_tag_offset == 0 {
        None
      } else {
        Some(match parse_base_tag_list(data, offset + base_tag_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let base_scripts = if base_script_offset == 0 {
        None
      } else {
        Some(match parse_base_script_list(data, offset + base_script_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      Ok(Axis::{ base_tags, base_scripts })
    }
  }
}

///|
/// Parse BASE table bytes.
pub fn BaseTable::parse(data : BytesView) -> Result[BaseTable, SfntError] {
  if data.length() < 8 {
    return Err(UnexpectedEof)
  }
  let version = read_u32_int(data, 0)
  let h_axis_offset = read_u16_int(data, 4)
  let v_axis_offset = read_u16_int(data, 6)
  match (version, h_axis_offset, v_axis_offset) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(version), Ok(h_axis_offset), Ok(v_axis_offset)) => {
      if h_axis_offset < 0 || v_axis_offset < 0 {
        return Err(InvalidFormat)
      }
      let major = version >> 16
      let minor = version & 0xffff
      let var_store_offset = if version >= 0x00010001 {
        let value = read_u32_int(data, 8)
        match value {
          Err(err) => return Err(err)
          Ok(value) => Some(value)
        }
      } else {
        None
      }
      let h_axis = if h_axis_offset == 0 {
        None
      } else {
        Some(match parse_axis(data, h_axis_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let v_axis = if v_axis_offset == 0 {
        None
      } else {
        Some(match parse_axis(data, v_axis_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      Ok(BaseTable::{
        major_version: major,
        minor_version: minor,
        h_axis,
        v_axis,
        var_store_offset,
      })
    }
  }
}
