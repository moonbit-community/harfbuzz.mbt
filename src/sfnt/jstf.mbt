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
/// Justification modification list.
pub struct JstfModList {
  indices : Array[Int]
} derive(Debug, ToJson)

///|
/// Justification max table (offsets to GPOS lookups).
pub struct JstfMax {
  lookup_offsets : Array[Int]
} derive(Debug, ToJson)

///|
/// Justification priority table.
pub struct JstfPriority {
  shrinkage_enable_gsub : JstfModList?
  shrinkage_disable_gsub : JstfModList?
  shrinkage_enable_gpos : JstfModList?
  shrinkage_disable_gpos : JstfModList?
  shrinkage_jstf_max : JstfMax?
  extension_enable_gsub : JstfModList?
  extension_disable_gsub : JstfModList?
  extension_enable_gpos : JstfModList?
  extension_disable_gpos : JstfModList?
  extension_jstf_max : JstfMax?
} derive(Debug, ToJson)

///|
/// Justification language system table.
pub struct JstfLangSys {
  priorities : Array[JstfPriority?]
} derive(Debug, ToJson)

///|
/// Justification language system record.
pub struct JstfLangSysRecord {
  tag : @common.Tag
  lang_sys : JstfLangSys?
} derive(Debug, ToJson)

///|
/// Justification script table.
pub struct JstfScript {
  extender_glyphs : Array[Int]
  default_lang_sys : JstfLangSys?
  lang_sys_records : Array[JstfLangSysRecord]
} derive(Debug, ToJson)

///|
/// Justification script record.
pub struct JstfScriptRecord {
  tag : @common.Tag
  script : JstfScript?
} derive(Debug, ToJson)

///|
/// Parsed JSTF table.
pub struct JstfTable {
  major_version : Int
  minor_version : Int
  scripts : Array[JstfScriptRecord]
} derive(Debug, ToJson)

///|
fn parse_jstf_mod_list(data : BytesView, offset : Int) -> Result[JstfModList, SfntError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let indices : Array[Int] = []
      let base = offset + 2
      if base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let index = read_u16_int(data, base + i * 2)
        match index {
          Err(err) => return Err(err)
          Ok(index) => indices.push(index)
        }
      }
      Ok(JstfModList::{ indices })
    }
  }
}

///|
fn parse_jstf_max(data : BytesView, offset : Int) -> Result[JstfMax, SfntError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let offsets : Array[Int] = []
      let base = offset + 2
      if base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let value = read_u16_int(data, base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => offsets.push(value)
        }
      }
      Ok(JstfMax::{ lookup_offsets: offsets })
    }
  }
}

///|
fn parse_jstf_mod_optional(
  data : BytesView,
  base : Int,
  value : Int,
) -> Result[JstfModList?, SfntError] {
  if value < 0 {
    return Err(InvalidFormat)
  }
  if value == 0 {
    Ok(None)
  } else {
    match parse_jstf_mod_list(data, base + value) {
      Err(err) => Err(err)
      Ok(list) => Ok(Some(list))
    }
  }
}

///|
fn parse_jstf_max_optional(
  data : BytesView,
  base : Int,
  value : Int,
) -> Result[JstfMax?, SfntError] {
  if value < 0 {
    return Err(InvalidFormat)
  }
  if value == 0 {
    Ok(None)
  } else {
    match parse_jstf_max(data, base + value) {
      Err(err) => Err(err)
      Ok(list) => Ok(Some(list))
    }
  }
}

///|
fn parse_jstf_priority(data : BytesView, offset : Int) -> Result[JstfPriority, SfntError] {
  let offsets : Array[Int] = []
  for i in 0..<10 {
    let value = read_u16_int(data, offset + i * 2)
    match value {
      Err(err) => return Err(err)
      Ok(value) => offsets.push(value)
    }
  }
  let shrinkage_enable_gsub = match parse_jstf_mod_optional(data, offset, offsets[0]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let shrinkage_disable_gsub = match parse_jstf_mod_optional(data, offset, offsets[1]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let shrinkage_enable_gpos = match parse_jstf_mod_optional(data, offset, offsets[2]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let shrinkage_disable_gpos = match parse_jstf_mod_optional(data, offset, offsets[3]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let shrinkage_jstf_max = match parse_jstf_max_optional(data, offset, offsets[4]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_enable_gsub = match parse_jstf_mod_optional(data, offset, offsets[5]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_disable_gsub = match parse_jstf_mod_optional(data, offset, offsets[6]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_enable_gpos = match parse_jstf_mod_optional(data, offset, offsets[7]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_disable_gpos = match parse_jstf_mod_optional(data, offset, offsets[8]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_jstf_max = match parse_jstf_max_optional(data, offset, offsets[9]) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  Ok(JstfPriority::{
    shrinkage_enable_gsub,
    shrinkage_disable_gsub,
    shrinkage_enable_gpos,
    shrinkage_disable_gpos,
    shrinkage_jstf_max,
    extension_enable_gsub,
    extension_disable_gsub,
    extension_enable_gpos,
    extension_disable_gpos,
    extension_jstf_max,
  })
}

///|
fn parse_jstf_lang_sys(data : BytesView, offset : Int) -> Result[JstfLangSys, SfntError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let priorities : Array[JstfPriority?] = []
      let base = offset + 2
      if base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let value = read_u16_int(data, base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => {
            if value < 0 {
              return Err(InvalidFormat)
            }
            if value == 0 {
              priorities.push(None)
            } else {
              let priority = match parse_jstf_priority(data, offset + value) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              priorities.push(Some(priority))
            }
          }
        }
      }
      Ok(JstfLangSys::{ priorities })
    }
  }
}

///|
fn parse_extender_glyphs(data : BytesView, offset : Int) -> Result[Array[Int], SfntError] {
  let count = read_u16_int(data, offset)
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let glyphs : Array[Int] = []
      let base = offset + 2
      if base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let glyph = read_u16_int(data, base + i * 2)
        match glyph {
          Err(err) => return Err(err)
          Ok(glyph) => glyphs.push(glyph)
        }
      }
      Ok(glyphs)
    }
  }
}

///|
fn parse_jstf_lang_sys_record(
  data : BytesView,
  offset : Int,
  base : Int,
) -> Result[JstfLangSysRecord, SfntError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let tag = @common.Tag::from_bytes(
    data[offset],
    data[offset + 1],
    data[offset + 2],
    data[offset + 3],
  )
  let lang_sys_offset = read_u16_int(data, offset + 4)
  match lang_sys_offset {
    Err(err) => Err(err)
    Ok(lang_sys_offset) => {
      if lang_sys_offset < 0 {
        return Err(InvalidFormat)
      }
      let lang_sys = if lang_sys_offset == 0 {
        None
      } else {
        Some(match parse_jstf_lang_sys(data, base + lang_sys_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      Ok(JstfLangSysRecord::{ tag, lang_sys })
    }
  }
}

///|
fn parse_jstf_script(data : BytesView, offset : Int) -> Result[JstfScript, SfntError] {
  let extender_offset = read_u16_int(data, offset)
  let default_lang_sys_offset = read_u16_int(data, offset + 2)
  let count = read_u16_int(data, offset + 4)
  match (extender_offset, default_lang_sys_offset, count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(extender_offset), Ok(default_lang_sys_offset), Ok(count)) => {
      if extender_offset < 0 || default_lang_sys_offset < 0 || count < 0 {
        return Err(InvalidFormat)
      }
      let extender_glyphs : Array[Int] = if extender_offset == 0 {
        []
      } else {
        match parse_extender_glyphs(data, offset + extender_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      }
      let default_lang_sys = if default_lang_sys_offset == 0 {
        None
      } else {
        Some(match parse_jstf_lang_sys(data, offset + default_lang_sys_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        })
      }
      let lang_sys_records : Array[JstfLangSysRecord] = []
      let record_base = offset + 6
      if record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 6
        let record = match parse_jstf_lang_sys_record(data, record_offset, offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        lang_sys_records.push(record)
      }
      Ok(JstfScript::{ extender_glyphs, default_lang_sys, lang_sys_records })
    }
  }
}

///|
/// Parse JSTF table bytes.
pub fn JstfTable::parse(data : BytesView) -> Result[JstfTable, SfntError] {
  if data.length() < 6 {
    return Err(UnexpectedEof)
  }
  let version = read_u32_int(data, 0)
  let count = read_u16_int(data, 4)
  match (version, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(version), Ok(count)) => {
      if count < 0 {
        return Err(InvalidFormat)
      }
      let major = version >> 16
      let minor = version & 0xffff
      let scripts : Array[JstfScriptRecord] = []
      let record_base = 6
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
            let script = if script_offset == 0 {
              None
            } else {
              Some(match parse_jstf_script(data, script_offset) {
                Err(err) => return Err(err)
                Ok(value) => value
              })
            }
            scripts.push(JstfScriptRecord::{ tag, script })
          }
        }
      }
      Ok(JstfTable::{ major_version: major, minor_version: minor, scripts })
    }
  }
}
