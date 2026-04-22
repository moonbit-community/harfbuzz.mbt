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
/// Arabic joining type constants.
pub let arabic_joining_type_u : UInt = 0U

///|
pub let arabic_joining_type_l : UInt = 1U

///|
pub let arabic_joining_type_r : UInt = 2U

///|
pub let arabic_joining_type_d : UInt = 3U

///|
pub let arabic_joining_group_alaph : UInt = 4U

///|
pub let arabic_joining_group_dalath_rish : UInt = 5U

///|
pub let arabic_joining_type_t : UInt = 7U

///|
pub let arabic_joining_type_x : UInt = 8U

///|
let arabic_joining_table : Array[UInt] = [
  0U, 0U, 0U, 0U, 0U, 0U, 8U, 8U, 0U, 8U, 8U, 0U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 0U, 2U, 2U, 2U, 2U, 3U, 2U,
  3U, 2U, 3U, 3U, 3U, 3U, 3U, 2U, 2U, 2U, 2U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 3U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 3U, 8U, 2U, 2U, 2U, 0U, 2U, 2U, 2U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 2U, 2U, 2U, 2U,
  2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 3U, 2U, 2U, 2U, 2U, 2U,
  2U, 2U, 2U, 2U, 3U, 2U, 3U, 2U, 3U, 3U, 2U, 2U, 8U, 2U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 0U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 2U, 2U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 3U, 3U, 8U, 8U, 3U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 7U, 4U, 8U, 3U, 3U, 3U, 5U, 5U, 2U,
  2U, 2U, 3U, 3U, 3U, 3U, 2U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 5U, 3U,
  2U, 3U, 3U, 5U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 2U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 2U, 2U, 2U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 2U, 2U, 3U, 3U, 3U, 3U, 2U, 3U, 2U, 2U, 3U, 3U, 3U, 2U, 2U, 3U, 3U,
  3U, 3U, 3U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 2U, 3U, 3U, 3U,
  3U, 3U, 2U, 2U, 3U, 2U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 2U, 2U,
  2U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 0U, 3U, 3U, 3U, 3U, 0U, 2U, 3U, 2U, 2U, 8U,
  8U, 8U, 8U, 8U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U, 2U,
  2U, 2U, 2U, 3U, 3U, 3U, 3U, 0U, 0U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 0U, 0U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 2U, 2U, 2U, 0U, 2U, 3U, 3U, 2U, 2U, 3U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 0U, 0U,
  3U, 8U, 8U, 3U, 8U, 8U, 8U, 0U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 0U, 0U, 0U, 0U, 0U, 7U, 7U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 8U, 3U, 0U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 0U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 0U, 0U, 0U, 0U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 1U, 0U, 3U, 3U, 3U, 3U, 3U, 2U, 0U, 2U, 0U, 2U,
  2U, 0U, 0U, 1U, 2U, 2U, 2U, 2U, 2U, 3U, 3U, 3U, 3U, 1U, 3U, 3U, 3U, 3U, 3U, 2U,
  3U, 3U, 3U, 2U, 0U, 0U, 2U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 3U, 3U, 3U, 2U, 3U, 2U,
  3U, 2U, 2U, 2U, 3U, 3U, 3U, 2U, 3U, 3U, 2U, 3U, 2U, 2U, 3U, 2U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 2U,
  2U, 2U, 2U, 3U, 3U, 0U, 1U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  2U, 3U, 2U, 3U, 3U, 8U, 3U, 3U, 3U, 3U, 3U, 2U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 0U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 3U, 3U, 3U, 2U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 3U, 3U, 3U, 2U, 2U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 3U, 0U, 3U, 3U,
  2U, 2U, 2U, 0U, 3U, 2U, 2U, 3U, 3U, 2U, 3U, 3U, 0U, 3U, 2U, 2U, 3U, 0U, 0U, 0U,
  0U, 2U, 3U, 1U, 0U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 8U,
  0U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U,
  3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 3U, 8U, 8U, 8U, 8U, 8U, 8U, 8U, 7U,
]

///|
/// Return joining type from ArabicShaping data.
pub fn arabic_joining_type_raw(u : UInt) -> UInt {
  let block = (u >> 12).reinterpret_as_int()
  match block {
    0 =>
      if u >= 0x0600U && u <= 0x08E2U {
        return arabic_joining_table[(u - 0x0600U).reinterpret_as_int() + 0]
      }
    1 =>
      if u >= 0x1806U && u <= 0x18AAU {
        return arabic_joining_table[(u - 0x1806U).reinterpret_as_int() + 739]
      }
    2 =>
      if u >= 0x200CU && u <= 0x2069U {
        return arabic_joining_table[(u - 0x200CU).reinterpret_as_int() + 904]
      }
    10 =>
      if u >= 0xA840U && u <= 0xA873U {
        return arabic_joining_table[(u - 0xA840U).reinterpret_as_int() + 998]
      }
    16 => {
      if u >= 0x10AC0U && u <= 0x10AEFU {
        return arabic_joining_table[(u - 0x10AC0U).reinterpret_as_int() + 1050]
      }
      if u >= 0x10B80U && u <= 0x10BAFU {
        return arabic_joining_table[(u - 0x10B80U).reinterpret_as_int() + 1098]
      }
      if u >= 0x10D00U && u <= 0x10D23U {
        return arabic_joining_table[(u - 0x10D00U).reinterpret_as_int() + 1146]
      }
      if u >= 0x10EC2U && u <= 0x10EC7U {
        return arabic_joining_table[(u - 0x10EC2U).reinterpret_as_int() + 1182]
      }
      if u >= 0x10F30U && u <= 0x10FCBU {
        return arabic_joining_table[(u - 0x10F30U).reinterpret_as_int() + 1188]
      }
    }
    17 =>
      if u >= 0x110BDU && u <= 0x110CDU {
        return arabic_joining_table[(u - 0x110BDU).reinterpret_as_int() + 1344]
      }
    30 =>
      if u >= 0x1E900U && u <= 0x1E94BU {
        return arabic_joining_table[(u - 0x1E900U).reinterpret_as_int() + 1361]
      }
    _ => ()
  }
  arabic_joining_type_x
}

///|
/// Return joining type with transparent marks mapped to T.
pub fn arabic_joining_type(u : UInt) -> UInt {
  let raw = arabic_joining_type_raw(u)
  if raw != arabic_joining_type_x {
    return raw
  }
  let cat = general_category(u)
  if cat == gc_non_spacing_mark || cat == gc_enclosing_mark || cat == gc_format {
    arabic_joining_type_t
  } else {
    arabic_joining_type_u
  }
}
