///|
/// Unicode general category constants (hb-unicode.h order).
pub let gc_control : UInt = 0U
///|
pub let gc_format : UInt = 1U
///|
pub let gc_unassigned : UInt = 2U
///|
pub let gc_private_use : UInt = 3U
///|
pub let gc_surrogate : UInt = 4U
///|
pub let gc_lowercase_letter : UInt = 5U
///|
pub let gc_modifier_letter : UInt = 6U
///|
pub let gc_other_letter : UInt = 7U
///|
pub let gc_titlecase_letter : UInt = 8U
///|
pub let gc_uppercase_letter : UInt = 9U
///|
pub let gc_spacing_mark : UInt = 10U
///|
pub let gc_enclosing_mark : UInt = 11U
///|
pub let gc_non_spacing_mark : UInt = 12U
///|
pub let gc_decimal_number : UInt = 13U
///|
pub let gc_letter_number : UInt = 14U
///|
pub let gc_other_number : UInt = 15U
///|
pub let gc_connect_punctuation : UInt = 16U
///|
pub let gc_dash_punctuation : UInt = 17U
///|
pub let gc_close_punctuation : UInt = 18U
///|
pub let gc_final_punctuation : UInt = 19U
///|
pub let gc_initial_punctuation : UInt = 20U
///|
pub let gc_other_punctuation : UInt = 21U
///|
pub let gc_open_punctuation : UInt = 22U
///|
pub let gc_currency_symbol : UInt = 23U
///|
pub let gc_modifier_symbol : UInt = 24U
///|
pub let gc_math_symbol : UInt = 25U
///|
pub let gc_other_symbol : UInt = 26U
///|
pub let gc_line_separator : UInt = 27U
///|
pub let gc_paragraph_separator : UInt = 28U
///|
pub let gc_space_separator : UInt = 29U

///|
fn u8_at(index : Int) -> Int {
  ucd_u8[index].to_int()
}

///|
fn u16_at(index : Int) -> Int {
  ucd_u16[index].to_int()
}

///|
fn i16_at(index : Int) -> Int {
  ucd_i16[index].to_int()
}

///|
fn ucd_gc(u : UInt) -> Int {
  if u >= 1114110U {
    return 2
  }
  let ui = u.reinterpret_as_int()
  let t0 = ui >> 1
  let t1 = t0 >> 3
  let t2 = t1 >> 5
  let a = u8_at(t2)
  let idx_u16 = (a << 5) + (t1 & 31)
  let b = u16_at(idx_u16)
  let idx_u8 = 2176 + ((b << 3) + (t0 & 7))
  let c = u8_at(idx_u8)
  let idx = 7920 + ((c << 1) + (ui & 1))
  u8_at(idx)
}

///|
fn ucd_ccc(u : UInt) -> Int {
  if u >= 125259U {
    return 0
  }
  let ui = u.reinterpret_as_int()
  let t0 = ui >> 2
  let t1 = t0 >> 3
  let t2 = t1 >> 4
  let a = u8_at(8302 + t2)
  let idx0 = 8548 + ((a << 4) + (t1 & 15))
  let b = u8_at(idx0)
  let idx1 = 9284 + ((b << 3) + (t0 & 7))
  let c = u8_at(idx1)
  let idx2 = 10388 + ((c << 2) + (ui & 3))
  u8_at(idx2)
}

///|
fn ucd_b4(offset : Int, index : Int) -> Int {
  let value = u8_at(offset + (index >> 1))
  (value >> ((index & 1) << 2)) & 15
}

///|
fn ucd_bmg(u : UInt) -> Int {
  if u >= 65380U {
    return 0
  }
  let ui = u.reinterpret_as_int()
  let t0 = ui >> 2
  let t1 = t0 >> 3
  let t2 = t1 >> 3
  let a = ucd_b4(10892, t2)
  let idx0 = 11020 + ((a << 3) + (t1 & 7))
  let b = u8_at(idx0)
  let idx1 = 11140 + ((b << 3) + (t0 & 7))
  let c = u8_at(idx1)
  let idx2 = (c << 2) + (ui & 3)
  i16_at(idx2)
}

///|
fn ucd_sc(u : UInt) -> Int {
  if u >= 918000U {
    return 2
  }
  let ui = u.reinterpret_as_int()
  let t0 = ui >> 3
  let t1 = t0 >> 4
  let t2 = t1 >> 4
  let a = u8_at(11476 + t2)
  let idx0 = 11926 + ((a << 4) + (t1 & 15))
  let b = u8_at(idx0)
  let idx1 = 3328 + ((b << 4) + (t0 & 15))
  let c = u16_at(idx1)
  let idx2 = 12662 + ((c << 3) + (ui & 7))
  u8_at(idx2)
}

///|
fn ucd_dm(u : UInt) -> Int {
  if u >= 195102U {
    return 0
  }
  let ui = u.reinterpret_as_int()
  let t0 = ui >> 4
  let t1 = t0 >> 5
  let a = u8_at(18590 + t1)
  let idx0 = 18972 + ((a << 5) + (t0 & 31))
  let b = u8_at(idx0)
  let idx1 = 7408 + ((b << 4) + (ui & 15))
  u16_at(idx1)
}

///|
fn encode3_11_7_14(a : UInt, b : UInt, c : UInt) -> UInt {
  ((a & 0x07FFU) << 21) | ((b & 0x007FU) << 14) | (c & 0x3FFFU)
}

///|
fn decode3_11_7_14_1(v : UInt) -> UInt {
  v >> 21
}

///|
fn decode3_11_7_14_2(v : UInt) -> UInt {
  ((v >> 14) & 0x007FU) | 0x0300U
}

///|
fn decode3_11_7_14_3(v : UInt) -> UInt {
  v & 0x3FFFU
}

///|
fn encode3_u64(a : UInt, b : UInt, c : UInt) -> UInt64 {
  (UInt64::extend_uint(a) << 42) | (UInt64::extend_uint(b) << 21) | UInt64::extend_uint(c)
}

///|
fn decode3_1(v : UInt64) -> UInt {
  (v >> 42).to_uint()
}

///|
fn decode3_2(v : UInt64) -> UInt {
  let mask = UInt64::extend_uint(0x1FFFFFU)
  ((v >> 21) & mask).to_uint()
}

///|
fn decode3_3(v : UInt64) -> UInt {
  let mask = UInt64::extend_uint(0x1FFFFFU)
  (v & mask).to_uint()
}

///|
fn bsearch_dm2_u32(key : UInt) -> UInt? {
  let mask = encode3_11_7_14(0x07FFU, 0x007FU, 0U)
  let mut low = 0
  let mut high = ucd_dm2_u32.length()
  while low < high {
    let mid = (low + high) / 2
    let v = ucd_dm2_u32[mid]
    let masked = v & mask
    if masked < key {
      low = mid + 1
    } else if masked > key {
      high = mid
    } else {
      return Some(v)
    }
  }
  None
}

///|
fn bsearch_dm2_u64(key : UInt64) -> UInt64? {
  let mask = encode3_u64(0x1FFFFFU, 0x1FFFFFU, 0U)
  let mut low = 0
  let mut high = ucd_dm2_u64.length()
  while low < high {
    let mid = (low + high) / 2
    let v = ucd_dm2_u64[mid]
    let masked = v & mask
    if masked < key {
      low = mid + 1
    } else if masked > key {
      high = mid
    } else {
      return Some(v)
    }
  }
  None
}

///|
fn decompose_hangul(ab : UInt) -> (UInt, UInt)? {
  let sbase = 0xAC00U
  let lbase = 0x1100U
  let vbase = 0x1161U
  let tbase = 0x11A7U
  let scount = 11172U
  let vcount = 21U
  let tcount = 28U
  let ncount = vcount * tcount
  if ab < sbase || ab >= sbase + scount {
    return None
  }
  let si = ab - sbase
  if (si % tcount) != 0U {
    let a = sbase + (si / tcount) * tcount
    let b = tbase + (si % tcount)
    return Some((a, b))
  }
  let a = lbase + (si / ncount)
  let b = vbase + (si % ncount) / tcount
  Some((a, b))
}

///|
fn compose_hangul(a : UInt, b : UInt) -> UInt? {
  let sbase = 0xAC00U
  let lbase = 0x1100U
  let vbase = 0x1161U
  let tbase = 0x11A7U
  let scount = 11172U
  let lcount = 19U
  let vcount = 21U
  let tcount = 28U
  let ncount = vcount * tcount
  if a >= sbase && a < (sbase + scount) &&
    b > tbase && b < (tbase + tcount) &&
    ((a - sbase) % tcount) == 0U {
    return Some(a + (b - tbase))
  }
  if a >= lbase && a < (lbase + lcount) && b >= vbase && b < (vbase + vcount) {
    let li = a - lbase
    let vi = b - vbase
    return Some(sbase + li * ncount + vi * tcount)
  }
  None
}

///|
/// Get Unicode general category value for a codepoint.
pub fn general_category(u : UInt) -> UInt {
  ucd_gc(u).reinterpret_as_uint()
}

///|
/// Get Unicode combining class value for a codepoint.
pub fn combining_class(u : UInt) -> UInt {
  ucd_ccc(u).reinterpret_as_uint()
}

///|
/// Get modified combining class (reorders specific marks for shaping).
pub fn modified_combining_class(u : UInt) -> UInt {
  if u == 0x1A60U {
    return 254U
  }
  if u == 0x0FC6U {
    return 254U
  }
  if u == 0x0F39U {
    return 127U
  }
  let cc = combining_class(u)
  let idx = cc.reinterpret_as_int()
  if idx < 0 || idx >= modified_combining_class_map.length() {
    cc
  } else {
    modified_combining_class_map[idx].to_uint()
  }
}

///|
/// Map a codepoint to its mirrored counterpart (if any).
pub fn mirroring(u : UInt) -> UInt {
  let offset = ucd_bmg(u)
  let result = u.reinterpret_as_int() + offset
  if result < 0 { u } else { result.reinterpret_as_uint() }
}

///|
/// Map a codepoint to a Unicode script.
pub fn script(u : UInt) -> @common.Script {
  let idx = ucd_sc(u)
  if idx < 0 || idx >= ucd_sc_map.length() {
    @common.script_unknown
  } else {
    ucd_sc_map[idx]
  }
}

///|
/// Compose two codepoints (canonical composition). Returns None if not composable.
pub fn compose(a : UInt, b : UInt) -> UInt? {
  if a == 0U || b == 0U {
    return None
  }
  match compose_hangul(a, b) {
    Some(value) => return Some(value)
    None => ()
  }
  if (a & 0xFFFFF800U) == 0U && (b & 0xFFFFFF80U) == 0x0300U {
    let key = encode3_11_7_14(a, b, 0U)
    match bsearch_dm2_u32(key) {
      None => None
      Some(value) => {
        let composed = decode3_11_7_14_3(value)
        if composed == 0U { None } else { Some(composed) }
      }
    }
  } else {
    let key = encode3_u64(a, b, 0U)
    match bsearch_dm2_u64(key) {
      None => None
      Some(value) => {
        let composed = decode3_3(value)
        if composed == 0U { None } else { Some(composed) }
      }
    }
  }
}

///|
/// Decompose a codepoint (canonical decomposition). Returns None if no decomposition.
pub fn decompose(ab : UInt) -> (UInt, UInt)? {
  match decompose_hangul(ab) {
    Some(value) => return Some(value)
    None => ()
  }
  let index = ucd_dm(ab)
  if index == 0 {
    return None
  }
  let mut i = index - 1
  if i < ucd_dm1_p0.length() + ucd_dm1_p2.length() {
    if i < ucd_dm1_p0.length() {
      let a = ucd_dm1_p0[i].to_uint()
      return Some((a, 0U))
    }
    i = i - ucd_dm1_p0.length()
    let a = 0x20000U | ucd_dm1_p2[i].to_uint()
    return Some((a, 0U))
  }
  i = i - ucd_dm1_p0.length() - ucd_dm1_p2.length()
  if i < ucd_dm2_u32.length() {
    let v = ucd_dm2_u32[i]
    let a = decode3_11_7_14_1(v)
    let b = decode3_11_7_14_2(v)
    return Some((a, b))
  }
  i = i - ucd_dm2_u32.length()
  let v = ucd_dm2_u64[i]
  let a = decode3_1(v)
  let b = decode3_2(v)
  Some((a, b))
}

///|
fn emoji_u8_at(index : Int) -> Int {
  emoji_u8[index].to_int()
}

///|
fn emoji_b4(offset : Int, index : Int) -> Int {
  let value = emoji_u8_at(offset + (index >> 1))
  (value >> ((index & 1) << 2)) & 15
}

///|
fn emoji_b1(offset : Int, index : Int) -> Int {
  let value = emoji_u8_at(offset + (index >> 3))
  (value >> (index & 7)) & 1
}

///|
/// True when the codepoint is Extended_Pictographic (emoji data table).
pub fn is_extended_pictographic(u : UInt) -> Bool {
  if u >= 131070U {
    return false
  }
  let ui = u.reinterpret_as_int()
  let t0 = ui >> 6
  let t1 = t0 >> 4
  let a = emoji_b4(0, t1)
  let idx0 = 64 + ((a << 4) + (t0 & 15))
  let b = emoji_u8_at(idx0)
  let idx1 = (b << 6) + (ui & 63)
  emoji_b1(224, idx1) == 1
}
