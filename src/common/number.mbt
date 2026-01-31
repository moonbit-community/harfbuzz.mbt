///|
fn clamp_range(start : Int, end : Int, len : Int) -> (Int, Int) {
  let mut s = start
  if s < 0 {
    s = 0
  }
  let e = if end < 0 || end > len { len } else { end }
  let s2 = if s > e { e } else { s }
  (s2, e)
}

fn digit_value(c : Char) -> Int? {
  let lower = c.to_ascii_lowercase()
  if lower.is_ascii_digit() {
    Some(lower.to_int() - '0'.to_int())
  } else if lower >= 'a' && lower <= 'z' {
    Some(10 + lower.to_int() - 'a'.to_int())
  } else {
    None
  }
}

fn parse_unsigned(
  s : StringView,
  start : Int,
  end : Int,
  base : Int,
) -> (UInt, Int, Int)? {
  if base < 2 || base > 36 {
    return None
  }
  let mut idx = start
  let mut value = 0U
  let mut count = 0
  while idx < end {
    match s.get_char(idx) {
      None => break
      Some(c) =>
        match digit_value(c) {
          None => break
          Some(digit) => {
            if digit >= base {
              break
            }
            value = value * base.reinterpret_as_uint() + digit.reinterpret_as_uint()
            idx = idx + 1
            count = count + 1
          }
        }
    }
  }
  if count == 0 {
    None
  } else {
    Some((value, idx, count))
  }
}

///|
/// Parse a signed integer from `s[start:end)`. Returns (value, next_index) on success.
pub fn parse_int(
  s : StringView,
  start? : Int = 0,
  end? : Int = -1,
  whole? : Bool = false,
) -> (Int, Int)? {
  let (start, end) = clamp_range(start, end, s.length())
  if start >= end {
    return None
  }
  let mut idx = start
  let mut sign = 1
  match s.get_char(idx) {
    Some('+') => idx = idx + 1
    Some('-') => {
      sign = -1
      idx = idx + 1
    }
    _ => ()
  }
  let parsed = parse_unsigned(s, idx, end, 10)
  match parsed {
    None => None
    Some((value, next_idx, _)) => {
      if whole && next_idx != end {
        None
      } else {
        Some((value.reinterpret_as_int() * sign, next_idx))
      }
    }
  }
}

///|
/// Parse an unsigned integer from `s[start:end)` with optional base. Returns (value, next_index).
pub fn parse_uint(
  s : StringView,
  start? : Int = 0,
  end? : Int = -1,
  whole? : Bool = false,
  base? : Int = 10,
) -> (UInt, Int)? {
  let (start, end) = clamp_range(start, end, s.length())
  if start >= end {
    return None
  }
  let mut idx = start
  match s.get_char(idx) {
    Some('+') => idx = idx + 1
    Some('-') => return None
    _ => ()
  }
  let parsed = parse_unsigned(s, idx, end, base)
  match parsed {
    None => None
    Some((value, next_idx, _)) => {
      if whole && next_idx != end {
        None
      } else {
        Some((value, next_idx))
      }
    }
  }
}

fn parse_exponent(s : StringView, start : Int, end : Int) -> (Int, Int)? {
  let mut idx = start
  if idx >= end {
    return None
  }
  let mut sign = 1
  match s.get_char(idx) {
    Some('+') => idx = idx + 1
    Some('-') => {
      sign = -1
      idx = idx + 1
    }
    _ => ()
  }
  let parsed = parse_unsigned(s, idx, end, 10)
  match parsed {
    None => None
    Some((value, next_idx, count)) => {
      if count == 0 {
        None
      } else {
        Some((value.reinterpret_as_int() * sign, next_idx))
      }
    }
  }
}

///|
/// Parse a double from `s[start:end)`. Returns (value, next_index) on success.
pub fn parse_double(
  s : StringView,
  start? : Int = 0,
  end? : Int = -1,
  whole? : Bool = false,
) -> (Double, Int)? {
  let (start, end) = clamp_range(start, end, s.length())
  if start >= end {
    return None
  }
  let mut idx = start
  let mut sign = 1.0
  match s.get_char(idx) {
    Some('+') => idx = idx + 1
    Some('-') => {
      sign = -1.0
      idx = idx + 1
    }
    _ => ()
  }
  let mut value = 0.0
  let mut int_digits = 0
  while idx < end {
    match s.get_char(idx) {
      Some(c) if c.is_ascii_digit() => {
        value = value * 10.0 + (c.to_int() - '0'.to_int()).to_double()
        idx = idx + 1
        int_digits = int_digits + 1
      }
      _ => break
    }
  }
  let mut frac_digits = 0
  if idx < end {
    match s.get_char(idx) {
      Some('.') => {
        idx = idx + 1
        let mut scale = 0.1
        while idx < end {
          match s.get_char(idx) {
            Some(c) if c.is_ascii_digit() => {
              value = value + (c.to_int() - '0'.to_int()).to_double() * scale
              scale = scale * 0.1
              idx = idx + 1
              frac_digits = frac_digits + 1
            }
            _ => break
          }
        }
      }
      _ => ()
    }
  }
  if int_digits == 0 && frac_digits == 0 {
    return None
  }
  if idx < end {
    match s.get_char(idx) {
      Some('e') | Some('E') => {
        let exp_start = idx
        idx = idx + 1
        match parse_exponent(s, idx, end) {
          None => idx = exp_start
          Some((exp, next_idx)) => {
            idx = next_idx
            if exp != 0 {
              let mut pow10 = 1.0
              let mut count = exp.abs()
              while count > 0 {
                pow10 = pow10 * 10.0
                count = count - 1
              }
              if exp < 0 {
                value = value / pow10
              } else {
                value = value * pow10
              }
            }
          }
        }
      }
      _ => ()
    }
  }
  if whole && idx != end {
    None
  } else {
    Some((value * sign, idx))
  }
}
