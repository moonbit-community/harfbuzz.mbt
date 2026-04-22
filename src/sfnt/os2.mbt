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
/// Parsed OS/2 table (subset).
pub struct Os2Table {
  version : Int
  weight_class : Int
  width_class : Int
  fs_type : Int
  typo_ascender : Int
  typo_descender : Int
  typo_line_gap : Int
  win_ascent : Int
  win_descent : Int
  code_page_range_1 : UInt?
  code_page_range_2 : UInt?
  x_height : Int?
  cap_height : Int?
  default_char : Int?
  break_char : Int?
  max_context : Int?
  lower_optical_point_size : Int?
  upper_optical_point_size : Int?
} derive(Debug, ToJson)

///|
fn os2_required_len(version : Int) -> Int {
  if version < 0 {
    return 0
  }
  if version >= 5 {
    100
  } else if version >= 2 {
    96
  } else if version >= 1 {
    86
  } else {
    78
  }
}

///|
/// Parse OS/2 table bytes (version 0-5, subset of fields).
pub fn Os2Table::parse(data : BytesView) -> Result[Os2Table, SfntError] {
  let version = read_u16_int(data, 0)
  match version {
    Err(err) => Err(err)
    Ok(version) => {
      let required = os2_required_len(version)
      if data.length() < required {
        return Err(UnexpectedEof)
      }
      let weight_class = read_u16_int(data, 4)
      let width_class = read_u16_int(data, 6)
      let fs_type = read_u16_int(data, 8)
      let typo_ascender = read_i16(data, 68)
      let typo_descender = read_i16(data, 70)
      let typo_line_gap = read_i16(data, 72)
      let win_ascent = read_u16_int(data, 74)
      let win_descent = read_u16_int(data, 76)
      match
        (
          weight_class, width_class, fs_type, typo_ascender, typo_descender, typo_line_gap,
          win_ascent, win_descent,
        ) {
        (Err(err), _, _, _, _, _, _, _) => Err(err)
        (_, Err(err), _, _, _, _, _, _) => Err(err)
        (_, _, Err(err), _, _, _, _, _) => Err(err)
        (_, _, _, Err(err), _, _, _, _) => Err(err)
        (_, _, _, _, Err(err), _, _, _) => Err(err)
        (_, _, _, _, _, Err(err), _, _) => Err(err)
        (_, _, _, _, _, _, Err(err), _) => Err(err)
        (_, _, _, _, _, _, _, Err(err)) => Err(err)
        (
          Ok(weight_class),
          Ok(width_class),
          Ok(fs_type),
          Ok(typo_ascender),
          Ok(typo_descender),
          Ok(typo_line_gap),
          Ok(win_ascent),
          Ok(win_descent),
        ) => {
          let mut code_page_range_1 : UInt? = None
          let mut code_page_range_2 : UInt? = None
          if version >= 1 {
            let range1 = read_u32(data, 78)
            let range2 = read_u32(data, 82)
            match (range1, range2) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(range1), Ok(range2)) => {
                code_page_range_1 = Some(range1)
                code_page_range_2 = Some(range2)
              }
            }
          }
          let mut x_height : Int? = None
          let mut cap_height : Int? = None
          let mut default_char : Int? = None
          let mut break_char : Int? = None
          let mut max_context : Int? = None
          if version >= 2 {
            let x_height_val = read_i16(data, 86)
            let cap_height_val = read_i16(data, 88)
            let default_char_val = read_u16_int(data, 90)
            let break_char_val = read_u16_int(data, 92)
            let max_context_val = read_u16_int(data, 94)
            match
              (
                x_height_val, cap_height_val, default_char_val, break_char_val, max_context_val,
              ) {
              (Err(err), _, _, _, _) => return Err(err)
              (_, Err(err), _, _, _) => return Err(err)
              (_, _, Err(err), _, _) => return Err(err)
              (_, _, _, Err(err), _) => return Err(err)
              (_, _, _, _, Err(err)) => return Err(err)
              (
                Ok(x_height_val),
                Ok(cap_height_val),
                Ok(default_char_val),
                Ok(break_char_val),
                Ok(max_context_val),
              ) => {
                x_height = Some(x_height_val)
                cap_height = Some(cap_height_val)
                default_char = Some(default_char_val)
                break_char = Some(break_char_val)
                max_context = Some(max_context_val)
              }
            }
          }
          let mut lower_optical_point_size : Int? = None
          let mut upper_optical_point_size : Int? = None
          if version >= 5 {
            let lower = read_u16_int(data, 96)
            let upper = read_u16_int(data, 98)
            match (lower, upper) {
              (Err(err), _) => return Err(err)
              (_, Err(err)) => return Err(err)
              (Ok(lower), Ok(upper)) => {
                lower_optical_point_size = Some(lower)
                upper_optical_point_size = Some(upper)
              }
            }
          }
          Ok(Os2Table::{
            version,
            weight_class,
            width_class,
            fs_type,
            typo_ascender,
            typo_descender,
            typo_line_gap,
            win_ascent,
            win_descent,
            code_page_range_1,
            code_page_range_2,
            x_height,
            cap_height,
            default_char,
            break_char,
            max_context,
            lower_optical_point_size,
            upper_optical_point_size,
          })
        }
      }
    }
  }
}
