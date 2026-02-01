///|
priv struct SidGid {
  sid : Int
  gid : Int
}

let standard_encoding_to_sid : Array[Int] = [
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    1,    2,    3,    4,    5,    6,    7,    8,    9,   10,   11,   12,   13,   14,   15,   16,
    17,  18,   19,   20,   21,   22,   23,   24,   25,   26,   27,   28,   29,   30,   31,   32,
    33,  34,   35,   36,   37,   38,   39,   40,   41,   42,   43,   44,   45,   46,   47,   48,
    49,  50,   51,   52,   53,   54,   55,   56,   57,   58,   59,   60,   61,   62,   63,   64,
    65,  66,   67,   68,   69,   70,   71,   72,   73,   74,   75,   76,   77,   78,   79,   80,
    81,  82,   83,   84,   85,   86,   87,   88,   89,   90,   91,   92,   93,   94,   95,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,   96,   97,   98,   99,  100,  101,  102,  103,  104,  105,  106,  107,  108,  109,  110,
    0,  111,  112,  113,  114,    0,  115,  116,  117,  118,  119,  120,  121,  122,    0,  123,
    0,  124,  125,  126,  127,  128,  129,  130,  131,    0,  132,  133,    0,  134,  135,  136,
  137,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,   138,   0,  139,    0,    0,    0,    0,  140,  141,  142,  143,    0,    0,    0,    0,
    0,   144,   0,    0,    0,  145,    0,    0,  146,  147,  148,  149,    0,    0,    0,    0
]

let expert_charset_sid_to_gid : Array[SidGid] = [
    SidGid::{ sid: 1, gid: 1 },     SidGid::{ sid: 13, gid: 12 },   SidGid::{ sid: 14, gid: 13 },   SidGid::{ sid: 15, gid: 14 },
    SidGid::{ sid: 27, gid: 26 },   SidGid::{ sid: 28, gid: 27 },   SidGid::{ sid: 99, gid: 15 },   SidGid::{ sid: 109, gid: 46 },
    SidGid::{ sid: 110, gid: 47 },  SidGid::{ sid: 150, gid: 111 }, SidGid::{ sid: 155, gid: 101 }, SidGid::{ sid: 158, gid: 100 },
    SidGid::{ sid: 163, gid: 102 }, SidGid::{ sid: 164, gid: 112 }, SidGid::{ sid: 169, gid: 113 }, SidGid::{ sid: 229, gid: 2 },
    SidGid::{ sid: 230, gid: 3 },   SidGid::{ sid: 231, gid: 4 },   SidGid::{ sid: 232, gid: 5 },   SidGid::{ sid: 233, gid: 6 },
    SidGid::{ sid: 234, gid: 7 },   SidGid::{ sid: 235, gid: 8 },   SidGid::{ sid: 236, gid: 9 },   SidGid::{ sid: 237, gid: 10 },
    SidGid::{ sid: 238, gid: 11 },  SidGid::{ sid: 239, gid: 16 },  SidGid::{ sid: 240, gid: 17 },  SidGid::{ sid: 241, gid: 18 },
    SidGid::{ sid: 242, gid: 19 },  SidGid::{ sid: 243, gid: 20 },  SidGid::{ sid: 244, gid: 21 },  SidGid::{ sid: 245, gid: 22 },
    SidGid::{ sid: 246, gid: 23 },  SidGid::{ sid: 247, gid: 24 },  SidGid::{ sid: 248, gid: 25 },  SidGid::{ sid: 249, gid: 28 },
    SidGid::{ sid: 250, gid: 29 },  SidGid::{ sid: 251, gid: 30 },  SidGid::{ sid: 252, gid: 31 },  SidGid::{ sid: 253, gid: 32 },
    SidGid::{ sid: 254, gid: 33 },  SidGid::{ sid: 255, gid: 34 },  SidGid::{ sid: 256, gid: 35 },  SidGid::{ sid: 257, gid: 36 },
    SidGid::{ sid: 258, gid: 37 },  SidGid::{ sid: 259, gid: 38 },  SidGid::{ sid: 260, gid: 39 },  SidGid::{ sid: 261, gid: 40 },
    SidGid::{ sid: 262, gid: 41 },  SidGid::{ sid: 263, gid: 42 },  SidGid::{ sid: 264, gid: 43 },  SidGid::{ sid: 265, gid: 44 },
    SidGid::{ sid: 266, gid: 45 },  SidGid::{ sid: 267, gid: 48 },  SidGid::{ sid: 268, gid: 49 },  SidGid::{ sid: 269, gid: 50 },
    SidGid::{ sid: 270, gid: 51 },  SidGid::{ sid: 271, gid: 52 },  SidGid::{ sid: 272, gid: 53 },  SidGid::{ sid: 273, gid: 54 },
    SidGid::{ sid: 274, gid: 55 },  SidGid::{ sid: 275, gid: 56 },  SidGid::{ sid: 276, gid: 57 },  SidGid::{ sid: 277, gid: 58 },
    SidGid::{ sid: 278, gid: 59 },  SidGid::{ sid: 279, gid: 60 },  SidGid::{ sid: 280, gid: 61 },  SidGid::{ sid: 281, gid: 62 },
    SidGid::{ sid: 282, gid: 63 },  SidGid::{ sid: 283, gid: 64 },  SidGid::{ sid: 284, gid: 65 },  SidGid::{ sid: 285, gid: 66 },
    SidGid::{ sid: 286, gid: 67 },  SidGid::{ sid: 287, gid: 68 },  SidGid::{ sid: 288, gid: 69 },  SidGid::{ sid: 289, gid: 70 },
    SidGid::{ sid: 290, gid: 71 },  SidGid::{ sid: 291, gid: 72 },  SidGid::{ sid: 292, gid: 73 },  SidGid::{ sid: 293, gid: 74 },
    SidGid::{ sid: 294, gid: 75 },  SidGid::{ sid: 295, gid: 76 },  SidGid::{ sid: 296, gid: 77 },  SidGid::{ sid: 297, gid: 78 },
    SidGid::{ sid: 298, gid: 79 },  SidGid::{ sid: 299, gid: 80 },  SidGid::{ sid: 300, gid: 81 },  SidGid::{ sid: 301, gid: 82 },
    SidGid::{ sid: 302, gid: 83 },  SidGid::{ sid: 303, gid: 84 },  SidGid::{ sid: 304, gid: 85 },  SidGid::{ sid: 305, gid: 86 },
    SidGid::{ sid: 306, gid: 87 },  SidGid::{ sid: 307, gid: 88 },  SidGid::{ sid: 308, gid: 89 },  SidGid::{ sid: 309, gid: 90 },
    SidGid::{ sid: 310, gid: 91 },  SidGid::{ sid: 311, gid: 92 },  SidGid::{ sid: 312, gid: 93 },  SidGid::{ sid: 313, gid: 94 },
    SidGid::{ sid: 314, gid: 95 },  SidGid::{ sid: 315, gid: 96 },  SidGid::{ sid: 316, gid: 97 },  SidGid::{ sid: 317, gid: 98 },
    SidGid::{ sid: 318, gid: 99 },  SidGid::{ sid: 319, gid: 103 }, SidGid::{ sid: 320, gid: 104 }, SidGid::{ sid: 321, gid: 105 },
    SidGid::{ sid: 322, gid: 106 }, SidGid::{ sid: 323, gid: 107 }, SidGid::{ sid: 324, gid: 108 }, SidGid::{ sid: 325, gid: 109 },
    SidGid::{ sid: 326, gid: 110 }, SidGid::{ sid: 327, gid: 114 }, SidGid::{ sid: 328, gid: 115 }, SidGid::{ sid: 329, gid: 116 },
    SidGid::{ sid: 330, gid: 117 }, SidGid::{ sid: 331, gid: 118 }, SidGid::{ sid: 332, gid: 119 }, SidGid::{ sid: 333, gid: 120 },
    SidGid::{ sid: 334, gid: 121 }, SidGid::{ sid: 335, gid: 122 }, SidGid::{ sid: 336, gid: 123 }, SidGid::{ sid: 337, gid: 124 },
    SidGid::{ sid: 338, gid: 125 }, SidGid::{ sid: 339, gid: 126 }, SidGid::{ sid: 340, gid: 127 }, SidGid::{ sid: 341, gid: 128 },
    SidGid::{ sid: 342, gid: 129 }, SidGid::{ sid: 343, gid: 130 }, SidGid::{ sid: 344, gid: 131 }, SidGid::{ sid: 345, gid: 132 },
    SidGid::{ sid: 346, gid: 133 }, SidGid::{ sid: 347, gid: 134 }, SidGid::{ sid: 348, gid: 135 }, SidGid::{ sid: 349, gid: 136 },
    SidGid::{ sid: 350, gid: 137 }, SidGid::{ sid: 351, gid: 138 }, SidGid::{ sid: 352, gid: 139 }, SidGid::{ sid: 353, gid: 140 },
    SidGid::{ sid: 354, gid: 141 }, SidGid::{ sid: 355, gid: 142 }, SidGid::{ sid: 356, gid: 143 }, SidGid::{ sid: 357, gid: 144 },
    SidGid::{ sid: 358, gid: 145 }, SidGid::{ sid: 359, gid: 146 }, SidGid::{ sid: 360, gid: 147 }, SidGid::{ sid: 361, gid: 148 },
    SidGid::{ sid: 362, gid: 149 }, SidGid::{ sid: 363, gid: 150 }, SidGid::{ sid: 364, gid: 151 }, SidGid::{ sid: 365, gid: 152 },
    SidGid::{ sid: 366, gid: 153 }, SidGid::{ sid: 367, gid: 154 }, SidGid::{ sid: 368, gid: 155 }, SidGid::{ sid: 369, gid: 156 },
    SidGid::{ sid: 370, gid: 157 }, SidGid::{ sid: 371, gid: 158 }, SidGid::{ sid: 372, gid: 159 }, SidGid::{ sid: 373, gid: 160 },
    SidGid::{ sid: 374, gid: 161 }, SidGid::{ sid: 375, gid: 162 }, SidGid::{ sid: 376, gid: 163 }, SidGid::{ sid: 377, gid: 164 },
    SidGid::{ sid: 378, gid: 165 }
]

let expert_subset_charset_sid_to_gid : Array[SidGid] = [
  SidGid::{ sid: 1, gid: 1 },       SidGid::{ sid: 13, gid: 8 },      SidGid::{ sid: 14, gid: 9 },      SidGid::{ sid: 15, gid: 10 },
  SidGid::{ sid: 27, gid: 22 },     SidGid::{ sid: 28, gid: 23 },     SidGid::{ sid: 99, gid: 11 },     SidGid::{ sid: 109, gid: 41 },
  SidGid::{ sid: 110, gid: 42 },    SidGid::{ sid: 150, gid: 64 },    SidGid::{ sid: 155, gid: 55 },    SidGid::{ sid: 158, gid: 54 },
  SidGid::{ sid: 163, gid: 56 },    SidGid::{ sid: 164, gid: 65 },    SidGid::{ sid: 169, gid: 66 },    SidGid::{ sid: 231, gid: 2 },
  SidGid::{ sid: 232, gid: 3 },     SidGid::{ sid: 235, gid: 4 },     SidGid::{ sid: 236, gid: 5 },     SidGid::{ sid: 237, gid: 6 },
  SidGid::{ sid: 238, gid: 7 },     SidGid::{ sid: 239, gid: 12 },    SidGid::{ sid: 240, gid: 13 },    SidGid::{ sid: 241, gid: 14 },
  SidGid::{ sid: 242, gid: 15 },    SidGid::{ sid: 243, gid: 16 },    SidGid::{ sid: 244, gid: 17 },    SidGid::{ sid: 245, gid: 18 },
  SidGid::{ sid: 246, gid: 19 },    SidGid::{ sid: 247, gid: 20 },    SidGid::{ sid: 248, gid: 21 },    SidGid::{ sid: 249, gid: 24 },
  SidGid::{ sid: 250, gid: 25 },    SidGid::{ sid: 251, gid: 26 },    SidGid::{ sid: 253, gid: 27 },    SidGid::{ sid: 254, gid: 28 },
  SidGid::{ sid: 255, gid: 29 },    SidGid::{ sid: 256, gid: 30 },    SidGid::{ sid: 257, gid: 31 },    SidGid::{ sid: 258, gid: 32 },
  SidGid::{ sid: 259, gid: 33 },    SidGid::{ sid: 260, gid: 34 },    SidGid::{ sid: 261, gid: 35 },    SidGid::{ sid: 262, gid: 36 },
  SidGid::{ sid: 263, gid: 37 },    SidGid::{ sid: 264, gid: 38 },    SidGid::{ sid: 265, gid: 39 },    SidGid::{ sid: 266, gid: 40 },
  SidGid::{ sid: 267, gid: 43 },    SidGid::{ sid: 268, gid: 44 },    SidGid::{ sid: 269, gid: 45 },    SidGid::{ sid: 270, gid: 46 },
  SidGid::{ sid: 272, gid: 47 },    SidGid::{ sid: 300, gid: 48 },    SidGid::{ sid: 301, gid: 49 },    SidGid::{ sid: 302, gid: 50 },
  SidGid::{ sid: 305, gid: 51 },    SidGid::{ sid: 314, gid: 52 },    SidGid::{ sid: 315, gid: 53 },    SidGid::{ sid: 320, gid: 57 },
  SidGid::{ sid: 321, gid: 58 },    SidGid::{ sid: 322, gid: 59 },    SidGid::{ sid: 323, gid: 60 },    SidGid::{ sid: 324, gid: 61 },
  SidGid::{ sid: 325, gid: 62 },    SidGid::{ sid: 326, gid: 63 },    SidGid::{ sid: 327, gid: 67 },    SidGid::{ sid: 328, gid: 68 },
  SidGid::{ sid: 329, gid: 69 },    SidGid::{ sid: 330, gid: 70 },    SidGid::{ sid: 331, gid: 71 },    SidGid::{ sid: 332, gid: 72 },
  SidGid::{ sid: 333, gid: 73 },    SidGid::{ sid: 334, gid: 74 },    SidGid::{ sid: 335, gid: 75 },    SidGid::{ sid: 336, gid: 76 },
  SidGid::{ sid: 337, gid: 77 },    SidGid::{ sid: 338, gid: 78 },    SidGid::{ sid: 339, gid: 79 },    SidGid::{ sid: 340, gid: 80 },
  SidGid::{ sid: 341, gid: 81 },    SidGid::{ sid: 342, gid: 82 },    SidGid::{ sid: 343, gid: 83 },    SidGid::{ sid: 344, gid: 84 },
  SidGid::{ sid: 345, gid: 85 },    SidGid::{ sid: 346, gid: 86 }
]

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
      if value <= 0 || value >= glyph_count { None } else { Some(value) }
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
      let nleft =
        if format == 1 { read_u8_int(data, pos + 2) } else { read_u16_int(data, pos + 2) }
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
