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
priv struct SidGid {
  sid : Int
  gid : Int
}

///|
let standard_encoding_to_sid : Array[Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
  40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
  80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 0,
  111, 112, 113, 114, 0, 115, 116, 117, 118, 119, 120, 121, 122, 0, 123, 0, 124,
  125, 126, 127, 128, 129, 130, 131, 0, 132, 133, 0, 134, 135, 136, 137, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0, 139, 0, 0, 0, 0, 140, 141, 142,
  143, 0, 0, 0, 0, 0, 144, 0, 0, 0, 145, 0, 0, 146, 147, 148, 149, 0, 0, 0, 0,
]

///|
let expert_charset_sid_to_gid : Array[SidGid] = [
  { sid: 1, gid: 1 },
  { sid: 13, gid: 12 },
  { sid: 14, gid: 13 },
  { sid: 15, gid: 14 },
  { sid: 27, gid: 26 },
  { sid: 28, gid: 27 },
  { sid: 99, gid: 15 },
  { sid: 109, gid: 46 },
  { sid: 110, gid: 47 },
  { sid: 150, gid: 111 },
  { sid: 155, gid: 101 },
  { sid: 158, gid: 100 },
  { sid: 163, gid: 102 },
  { sid: 164, gid: 112 },
  { sid: 169, gid: 113 },
  { sid: 229, gid: 2 },
  { sid: 230, gid: 3 },
  { sid: 231, gid: 4 },
  { sid: 232, gid: 5 },
  { sid: 233, gid: 6 },
  { sid: 234, gid: 7 },
  { sid: 235, gid: 8 },
  { sid: 236, gid: 9 },
  { sid: 237, gid: 10 },
  { sid: 238, gid: 11 },
  { sid: 239, gid: 16 },
  { sid: 240, gid: 17 },
  { sid: 241, gid: 18 },
  { sid: 242, gid: 19 },
  { sid: 243, gid: 20 },
  { sid: 244, gid: 21 },
  { sid: 245, gid: 22 },
  { sid: 246, gid: 23 },
  { sid: 247, gid: 24 },
  { sid: 248, gid: 25 },
  { sid: 249, gid: 28 },
  { sid: 250, gid: 29 },
  { sid: 251, gid: 30 },
  { sid: 252, gid: 31 },
  { sid: 253, gid: 32 },
  { sid: 254, gid: 33 },
  { sid: 255, gid: 34 },
  { sid: 256, gid: 35 },
  { sid: 257, gid: 36 },
  { sid: 258, gid: 37 },
  { sid: 259, gid: 38 },
  { sid: 260, gid: 39 },
  { sid: 261, gid: 40 },
  { sid: 262, gid: 41 },
  { sid: 263, gid: 42 },
  { sid: 264, gid: 43 },
  { sid: 265, gid: 44 },
  { sid: 266, gid: 45 },
  { sid: 267, gid: 48 },
  { sid: 268, gid: 49 },
  { sid: 269, gid: 50 },
  { sid: 270, gid: 51 },
  { sid: 271, gid: 52 },
  { sid: 272, gid: 53 },
  { sid: 273, gid: 54 },
  { sid: 274, gid: 55 },
  { sid: 275, gid: 56 },
  { sid: 276, gid: 57 },
  { sid: 277, gid: 58 },
  { sid: 278, gid: 59 },
  { sid: 279, gid: 60 },
  { sid: 280, gid: 61 },
  { sid: 281, gid: 62 },
  { sid: 282, gid: 63 },
  { sid: 283, gid: 64 },
  { sid: 284, gid: 65 },
  { sid: 285, gid: 66 },
  { sid: 286, gid: 67 },
  { sid: 287, gid: 68 },
  { sid: 288, gid: 69 },
  { sid: 289, gid: 70 },
  { sid: 290, gid: 71 },
  { sid: 291, gid: 72 },
  { sid: 292, gid: 73 },
  { sid: 293, gid: 74 },
  { sid: 294, gid: 75 },
  { sid: 295, gid: 76 },
  { sid: 296, gid: 77 },
  { sid: 297, gid: 78 },
  { sid: 298, gid: 79 },
  { sid: 299, gid: 80 },
  { sid: 300, gid: 81 },
  { sid: 301, gid: 82 },
  { sid: 302, gid: 83 },
  { sid: 303, gid: 84 },
  { sid: 304, gid: 85 },
  { sid: 305, gid: 86 },
  { sid: 306, gid: 87 },
  { sid: 307, gid: 88 },
  { sid: 308, gid: 89 },
  { sid: 309, gid: 90 },
  { sid: 310, gid: 91 },
  { sid: 311, gid: 92 },
  { sid: 312, gid: 93 },
  { sid: 313, gid: 94 },
  { sid: 314, gid: 95 },
  { sid: 315, gid: 96 },
  { sid: 316, gid: 97 },
  { sid: 317, gid: 98 },
  { sid: 318, gid: 99 },
  { sid: 319, gid: 103 },
  { sid: 320, gid: 104 },
  { sid: 321, gid: 105 },
  { sid: 322, gid: 106 },
  { sid: 323, gid: 107 },
  { sid: 324, gid: 108 },
  { sid: 325, gid: 109 },
  { sid: 326, gid: 110 },
  { sid: 327, gid: 114 },
  { sid: 328, gid: 115 },
  { sid: 329, gid: 116 },
  { sid: 330, gid: 117 },
  { sid: 331, gid: 118 },
  { sid: 332, gid: 119 },
  { sid: 333, gid: 120 },
  { sid: 334, gid: 121 },
  { sid: 335, gid: 122 },
  { sid: 336, gid: 123 },
  { sid: 337, gid: 124 },
  { sid: 338, gid: 125 },
  { sid: 339, gid: 126 },
  { sid: 340, gid: 127 },
  { sid: 341, gid: 128 },
  { sid: 342, gid: 129 },
  { sid: 343, gid: 130 },
  { sid: 344, gid: 131 },
  { sid: 345, gid: 132 },
  { sid: 346, gid: 133 },
  { sid: 347, gid: 134 },
  { sid: 348, gid: 135 },
  { sid: 349, gid: 136 },
  { sid: 350, gid: 137 },
  { sid: 351, gid: 138 },
  { sid: 352, gid: 139 },
  { sid: 353, gid: 140 },
  { sid: 354, gid: 141 },
  { sid: 355, gid: 142 },
  { sid: 356, gid: 143 },
  { sid: 357, gid: 144 },
  { sid: 358, gid: 145 },
  { sid: 359, gid: 146 },
  { sid: 360, gid: 147 },
  { sid: 361, gid: 148 },
  { sid: 362, gid: 149 },
  { sid: 363, gid: 150 },
  { sid: 364, gid: 151 },
  { sid: 365, gid: 152 },
  { sid: 366, gid: 153 },
  { sid: 367, gid: 154 },
  { sid: 368, gid: 155 },
  { sid: 369, gid: 156 },
  { sid: 370, gid: 157 },
  { sid: 371, gid: 158 },
  { sid: 372, gid: 159 },
  { sid: 373, gid: 160 },
  { sid: 374, gid: 161 },
  { sid: 375, gid: 162 },
  { sid: 376, gid: 163 },
  { sid: 377, gid: 164 },
  { sid: 378, gid: 165 },
]

///|
let expert_subset_charset_sid_to_gid : Array[SidGid] = [
  { sid: 1, gid: 1 },
  { sid: 13, gid: 8 },
  { sid: 14, gid: 9 },
  { sid: 15, gid: 10 },
  { sid: 27, gid: 22 },
  { sid: 28, gid: 23 },
  { sid: 99, gid: 11 },
  { sid: 109, gid: 41 },
  { sid: 110, gid: 42 },
  { sid: 150, gid: 64 },
  { sid: 155, gid: 55 },
  { sid: 158, gid: 54 },
  { sid: 163, gid: 56 },
  { sid: 164, gid: 65 },
  { sid: 169, gid: 66 },
  { sid: 231, gid: 2 },
  { sid: 232, gid: 3 },
  { sid: 235, gid: 4 },
  { sid: 236, gid: 5 },
  { sid: 237, gid: 6 },
  { sid: 238, gid: 7 },
  { sid: 239, gid: 12 },
  { sid: 240, gid: 13 },
  { sid: 241, gid: 14 },
  { sid: 242, gid: 15 },
  { sid: 243, gid: 16 },
  { sid: 244, gid: 17 },
  { sid: 245, gid: 18 },
  { sid: 246, gid: 19 },
  { sid: 247, gid: 20 },
  { sid: 248, gid: 21 },
  { sid: 249, gid: 24 },
  { sid: 250, gid: 25 },
  { sid: 251, gid: 26 },
  { sid: 253, gid: 27 },
  { sid: 254, gid: 28 },
  { sid: 255, gid: 29 },
  { sid: 256, gid: 30 },
  { sid: 257, gid: 31 },
  { sid: 258, gid: 32 },
  { sid: 259, gid: 33 },
  { sid: 260, gid: 34 },
  { sid: 261, gid: 35 },
  { sid: 262, gid: 36 },
  { sid: 263, gid: 37 },
  { sid: 264, gid: 38 },
  { sid: 265, gid: 39 },
  { sid: 266, gid: 40 },
  { sid: 267, gid: 43 },
  { sid: 268, gid: 44 },
  { sid: 269, gid: 45 },
  { sid: 270, gid: 46 },
  { sid: 272, gid: 47 },
  { sid: 300, gid: 48 },
  { sid: 301, gid: 49 },
  { sid: 302, gid: 50 },
  { sid: 305, gid: 51 },
  { sid: 314, gid: 52 },
  { sid: 315, gid: 53 },
  { sid: 320, gid: 57 },
  { sid: 321, gid: 58 },
  { sid: 322, gid: 59 },
  { sid: 323, gid: 60 },
  { sid: 324, gid: 61 },
  { sid: 325, gid: 62 },
  { sid: 326, gid: 63 },
  { sid: 327, gid: 67 },
  { sid: 328, gid: 68 },
  { sid: 329, gid: 69 },
  { sid: 330, gid: 70 },
  { sid: 331, gid: 71 },
  { sid: 332, gid: 72 },
  { sid: 333, gid: 73 },
  { sid: 334, gid: 74 },
  { sid: 335, gid: 75 },
  { sid: 336, gid: 76 },
  { sid: 337, gid: 77 },
  { sid: 338, gid: 78 },
  { sid: 339, gid: 79 },
  { sid: 340, gid: 80 },
  { sid: 341, gid: 81 },
  { sid: 342, gid: 82 },
  { sid: 343, gid: 83 },
  { sid: 344, gid: 84 },
  { sid: 345, gid: 85 },
  { sid: 346, gid: 86 },
]

///|
fn lookup_sid_to_gid(pairs : Array[SidGid], sid : Int) -> Int? {
  let mut lo = 0
  let mut hi = pairs.length()
  while lo < hi {
    let mid = (lo + hi) / 2
    let entry = pairs[mid]
    if sid < entry.sid {
      hi = mid
    } else if sid > entry.sid {
      lo = mid + 1
    } else {
      return Some(entry.gid)
    }
  }
  None
}

///|
pub fn cff1_standard_sid(code : Int) -> Int? {
  if code < 0 || code >= standard_encoding_to_sid.length() {
    return None
  }
  let sid = standard_encoding_to_sid[code]
  if sid == 0 {
    return None
  }
  Some(sid)
}

///|
pub fn cff1_sid_to_gid(
  charset_offset : Int,
  charset_map : Map[Int, Int]?,
  sid : Int,
  glyph_count : Int,
) -> Int? {
  if sid < 0 {
    return None
  }
  let mut gid : Int? = None
  if charset_offset == 0 {
    if sid <= 228 && sid < glyph_count {
      gid = Some(sid)
    }
  } else if charset_offset == 1 {
    gid = lookup_sid_to_gid(expert_charset_sid_to_gid, sid)
  } else if charset_offset == 2 {
    gid = lookup_sid_to_gid(expert_subset_charset_sid_to_gid, sid)
  } else {
    match charset_map {
      None => ()
      Some(map) => gid = map.get(sid)
    }
  }
  match gid {
    None => None
    Some(value) =>
      if value <= 0 || value >= glyph_count {
        None
      } else {
        Some(value)
      }
  }
}

///|
fn assign_gid_sids(
  pairs : Array[SidGid],
  glyph_count : Int,
  gids : Array[Int],
) -> Unit {
  for entry in pairs {
    if entry.gid >= 0 && entry.gid < glyph_count {
      gids[entry.gid] = entry.sid
    }
  }
}

///|
fn build_gid_to_sid_map(
  charset_offset : Int,
  charset_map : Map[Int, Int]?,
  glyph_count : Int,
) -> Result[Array[Int], CffError] {
  if glyph_count < 0 {
    return Err(InvalidFormat)
  }
  let gids : Array[Int] = Array::make(glyph_count, -1)
  if glyph_count == 0 {
    return Ok(gids)
  }
  gids[0] = 0
  if glyph_count == 1 {
    return Ok(gids)
  }
  if charset_offset == 0 {
    for gid in 1..<glyph_count {
      if gid > 228 {
        return Err(InvalidFormat)
      }
      gids[gid] = gid
    }
    return Ok(gids)
  }
  if charset_offset == 1 {
    assign_gid_sids(expert_charset_sid_to_gid, glyph_count, gids)
    return Ok(gids)
  }
  if charset_offset == 2 {
    assign_gid_sids(expert_subset_charset_sid_to_gid, glyph_count, gids)
    return Ok(gids)
  }
  match charset_map {
    None => Err(InvalidFormat)
    Some(map) => {
      map.eachi((_, sid, gid) => {
        if gid >= 0 && gid < glyph_count {
          gids[gid] = sid
        }
      })
      Ok(gids)
    }
  }
}

///|
pub fn parse_cff1_charset(
  data : BytesView,
  offset : Int,
  glyph_count : Int,
) -> Result[Map[Int, Int], CffError] {
  let values : Map[Int, Int] = {}
  values[0] = 0
  if glyph_count <= 1 {
    return Ok(values)
  }
  let format = read_u8_int(data, offset)
  let format = match format {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mut pos = offset + 1
  let mut gid = 1
  if format == 0 {
    while gid < glyph_count {
      let sid = read_u16_int(data, pos)
      let sid = match sid {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      values[sid] = gid
      gid = gid + 1
      pos = pos + 2
    }
    return Ok(values)
  }
  if format == 1 || format == 2 {
    while gid < glyph_count {
      let first = read_u16_int(data, pos)
      let nleft = if format == 1 {
        read_u8_int(data, pos + 2)
      } else {
        read_u16_int(data, pos + 2)
      }
      let first = match first {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let nleft = match nleft {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut sid = first
      let mut count = nleft
      while count >= 0 && gid < glyph_count {
        values[sid] = gid
        sid = sid + 1
        gid = gid + 1
        count = count - 1
      }
      let step = if format == 1 { 3 } else { 4 }
      pos = pos + step
    }
    return Ok(values)
  }
  Err(InvalidFormat)
}
