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
/// Generated from refs/harfbuzz/src/hb-ot-shaper-khmer-machine.hh.
///
let khmer_syllable_type_consonant : Int = 0

///|
let khmer_syllable_type_broken : Int = 1

///|
let khmer_syllable_type_non_khmer : Int = 2

///|
let khmer_machine_start : Int = 21

///|
let khmer_machine_trans_keys : Array[Int] = [
  5, 26, 5, 26, 1, 15, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 5,
  26, 5, 26, 1, 15, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 5, 26, 1, 27, 4, 27,
  1, 15, 4, 27, 4, 27, 27, 27, 4, 27, 4, 27, 4, 27, 4, 27, 4, 27, 4, 27, 1, 15, 4,
  27, 4, 27, 27, 27, 4, 27, 4, 27, 4, 27, 4, 27, 4, 27, 5, 26, 0,
]

///|
let khmer_machine_key_spans : Array[Int] = [
  22, 22, 15, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 15, 22, 22, 22, 22, 22, 22,
  22, 27, 24, 15, 24, 24, 1, 24, 24, 24, 24, 24, 24, 15, 24, 24, 1, 24, 24, 24, 24,
  24, 22,
]

///|
let khmer_machine_index_offsets : Array[Int] = [
  0, 23, 46, 62, 85, 108, 131, 154, 177, 200, 223, 246, 269, 292, 308, 331, 354,
  377, 400, 423, 446, 469, 497, 522, 538, 563, 588, 590, 615, 640, 665, 690, 715,
  740, 756, 781, 806, 808, 833, 858, 883, 908, 933,
]

///|
let khmer_machine_indicies : Array[Int] = [
  1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 3, 4, 0, 1, 1, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 5, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 5, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0,
  0, 0, 4, 0, 6, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
  7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 9, 9, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 10, 0, 9, 9, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 11, 11, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 12, 0, 11, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
  0, 0, 0, 0, 13, 4, 0, 15, 15, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  16, 14, 14, 14, 14, 17, 18, 14, 15, 15, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
  19, 19, 19, 19, 19, 19, 19, 19, 19, 18, 19, 20, 20, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 20, 14, 15, 15, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 16, 14, 14, 14, 14, 14, 18, 14, 21, 21, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 16, 14, 22, 22, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 23, 14, 24, 24, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 16, 14, 14, 14, 14, 14, 25, 14, 24,
  24, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  25, 14, 26, 26, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 16, 14, 14,
  14, 14, 14, 27, 14, 26, 26, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 27, 14, 29, 29, 28, 30, 31, 31, 28, 28, 28, 13, 13, 28,
  28, 28, 29, 28, 28, 28, 28, 16, 25, 27, 23, 28, 17, 18, 20, 28, 33, 34, 34, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 12, 8, 32, 13, 4, 5, 32,
  35, 35, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 35, 32, 33, 36, 36, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 12, 8, 32, 3, 4, 5, 32,
  37, 38, 38, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 12, 8, 32,
  32, 4, 5, 32, 5, 32, 37, 6, 6, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 32, 32, 32, 8, 32, 32, 2, 5, 32, 37, 7, 7, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 8, 5, 32, 37, 39, 39, 32, 32, 32, 32,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 32, 32, 8, 32, 32, 10, 5, 32, 37, 40, 40,
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 32, 8, 32, 32, 12, 5,
  32, 33, 38, 38, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 2, 10, 12,
  8, 32, 32, 4, 5, 32, 33, 38, 38, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
  32, 2, 10, 12, 8, 32, 3, 4, 5, 32, 42, 42, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 42, 41, 30, 43, 43, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 16, 25, 27, 23, 41, 17, 18, 20, 41, 44, 45, 45, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 41, 41, 41, 16, 25, 27, 23, 41, 41, 18, 20, 41, 20, 41, 44, 21, 21,
  41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 23, 41, 41, 16,
  20, 41, 44, 22, 22, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 41, 23, 20, 41, 44, 46, 46, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
  41, 41, 41, 16, 41, 41, 23, 41, 41, 25, 20, 41, 44, 47, 47, 41, 41, 41, 41, 41,
  41, 41, 41, 41, 41, 41, 41, 41, 16, 25, 41, 23, 41, 41, 27, 20, 41, 30, 45, 45,
  41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 16, 25, 27, 23, 41, 41, 18,
  20, 41, 15, 15, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 16, 48, 48,
  48, 48, 48, 18, 48, 0,
]

///|
let khmer_machine_trans_targs : Array[Int] = [
  21, 1, 27, 31, 25, 26, 4, 5, 28, 7, 29, 9, 30, 32, 21, 12, 37, 41, 35, 21, 36,
  15, 16, 38, 18, 39, 20, 40, 21, 22, 33, 42, 21, 23, 10, 24, 0, 2, 3, 6, 8, 21,
  34, 11, 13, 14, 17, 19, 21,
]

///|
let khmer_machine_trans_actions : Array[Int] = [
  1, 0, 2, 2, 2, 0, 0, 0, 2, 0, 2, 0, 2, 2, 3, 0, 2, 4, 4, 5, 0, 0, 0, 2, 0, 2, 0,
  2, 8, 2, 0, 9, 10, 0, 0, 2, 0, 0, 0, 0, 0, 11, 4, 0, 0, 0, 0, 0, 12,
]

///|
let khmer_machine_to_state_actions : Array[Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
]

///|
let khmer_machine_from_state_actions : Array[Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
]

///|
let khmer_machine_eof_trans : Array[Int] = [
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 15, 20, 15, 15, 15, 15, 15, 15, 15, 15, 0, 33,
  33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 42, 42, 42, 42, 42, 42, 42, 42, 42, 49,
]

///|
fn find_syllables_khmer(categories : Array[UInt]) -> Array[Int] {
  let len = categories.length()
  let syllables : Array[Int] = Array::make(len, 0)
  let mut cs = khmer_machine_start
  let mut ts = 0
  let mut te = 0
  let mut act = 0
  let mut p = 0
  let pe = len
  let eof = len
  let mut syllable_serial = 1
  fn found_syllable(start : Int, end : Int, syllable_type : Int) -> Unit {
    if start < 0 || end > len || start >= end {
      return ()
    }
    for i in start..<end {
      syllables[i] = (syllable_serial << 4) | syllable_type
    }
    syllable_serial = syllable_serial + 1
    if syllable_serial == 16 {
      syllable_serial = 1
    }
  }

  while true {
    if p == pe {
      break
    }
    if khmer_machine_from_state_actions[cs] == 7 {
      ts = p
    }
    let keys_index = cs << 1
    let slen = khmer_machine_key_spans[cs]
    let inds_index = khmer_machine_index_offsets[cs]
    let category = categories[p].reinterpret_as_int()
    let mut trans = 0
    if slen > 0 &&
      khmer_machine_trans_keys[keys_index] <= category &&
      category <= khmer_machine_trans_keys[keys_index + 1] {
      trans = khmer_machine_indicies[inds_index +
        (category - khmer_machine_trans_keys[keys_index])]
    } else {
      trans = khmer_machine_indicies[inds_index + slen]
    }
    cs = khmer_machine_trans_targs[trans]
    let action = khmer_machine_trans_actions[trans]
    if action != 0 {
      match action {
        2 => te = p + 1
        8 => {
          te = p + 1
          found_syllable(ts, te, khmer_syllable_type_non_khmer)
        }
        10 => {
          te = p
          p = p - 1
          found_syllable(ts, te, khmer_syllable_type_consonant)
        }
        11 => {
          te = p
          p = p - 1
          found_syllable(ts, te, khmer_syllable_type_broken)
        }
        12 => {
          te = p
          p = p - 1
          found_syllable(ts, te, khmer_syllable_type_non_khmer)
        }
        1 => {
          p = te - 1
          found_syllable(ts, te, khmer_syllable_type_consonant)
        }
        3 => {
          p = te - 1
          found_syllable(ts, te, khmer_syllable_type_broken)
        }
        5 =>
          match act {
            2 => {
              p = te - 1
              found_syllable(ts, te, khmer_syllable_type_broken)
            }
            3 => {
              p = te - 1
              found_syllable(ts, te, khmer_syllable_type_non_khmer)
            }
            _ => ()
          }
        4 => {
          te = p + 1
          act = 2
        }
        9 => {
          te = p + 1
          act = 3
        }
        _ => ()
      }
    }
    if khmer_machine_to_state_actions[cs] == 6 {
      ts = 0
    }
    p = p + 1
  }
  if p == eof {
    let eof_trans = khmer_machine_eof_trans[cs]
    if eof_trans > 0 {
      let trans = eof_trans - 1
      cs = khmer_machine_trans_targs[trans]
      let action = khmer_machine_trans_actions[trans]
      if action != 0 {
        match action {
          2 => te = p + 1
          8 => {
            te = p + 1
            found_syllable(ts, te, khmer_syllable_type_non_khmer)
          }
          10 => {
            te = p
            p = p - 1
            found_syllable(ts, te, khmer_syllable_type_consonant)
          }
          11 => {
            te = p
            p = p - 1
            found_syllable(ts, te, khmer_syllable_type_broken)
          }
          12 => {
            te = p
            p = p - 1
            found_syllable(ts, te, khmer_syllable_type_non_khmer)
          }
          1 => {
            p = te - 1
            found_syllable(ts, te, khmer_syllable_type_consonant)
          }
          3 => {
            p = te - 1
            found_syllable(ts, te, khmer_syllable_type_broken)
          }
          5 =>
            match act {
              2 => {
                p = te - 1
                found_syllable(ts, te, khmer_syllable_type_broken)
              }
              3 => {
                p = te - 1
                found_syllable(ts, te, khmer_syllable_type_non_khmer)
              }
              _ => ()
            }
          4 => {
            te = p + 1
            act = 2
          }
          9 => {
            te = p + 1
            act = 3
          }
          _ => ()
        }
      }
      if khmer_machine_to_state_actions[cs] == 6 {
        ts = 0
      }
    }
  }
  syllables
}
