///|
/// Text direction with HarfBuzz-compatible numeric layout.
pub struct Direction {
  raw : UInt
} derive(Eq, Show, ToJson)

///|
/// Unset direction.
pub let direction_invalid : Direction = Direction::{ raw: 0U }

///|
/// Left-to-right.
pub let direction_ltr : Direction = Direction::{ raw: 4U }

///|
/// Right-to-left.
pub let direction_rtl : Direction = Direction::{ raw: 5U }

///|
/// Top-to-bottom.
pub let direction_ttb : Direction = Direction::{ raw: 6U }

///|
/// Bottom-to-top.
pub let direction_btt : Direction = Direction::{ raw: 7U }

///|
/// Convert a string to a direction (matches by first letter).
pub fn Direction::from_string(s : String, len? : Int = -1) -> Direction {
  if s is "" || len == 0 {
    return direction_invalid
  }
  match s.get_char(0) {
    None => direction_invalid
    Some(c) => {
      let lower = c.to_ascii_lowercase()
      if lower == 'l' {
        direction_ltr
      } else if lower == 'r' {
        direction_rtl
      } else if lower == 't' {
        direction_ttb
      } else if lower == 'b' {
        direction_btt
      } else {
        direction_invalid
      }
    }
  }
}

///|
/// Convert a direction to its string name.
pub fn Direction::to_string(self : Direction) -> String {
  match self.raw {
    4U => "ltr"
    5U => "rtl"
    6U => "ttb"
    7U => "btt"
    _ => "invalid"
  }
}

///|
/// True when the direction is valid.
pub fn Direction::is_valid(self : Direction) -> Bool {
  (self.raw & 0xffff_fffcU) == 4U
}

///|
/// True when the direction is horizontal.
pub fn Direction::is_horizontal(self : Direction) -> Bool {
  (self.raw & 0xffff_fffeU) == 4U
}

///|
/// True when the direction is vertical.
pub fn Direction::is_vertical(self : Direction) -> Bool {
  (self.raw & 0xffff_fffeU) == 6U
}

///|
/// True when the direction moves forward.
pub fn Direction::is_forward(self : Direction) -> Bool {
  (self.raw & 0xffff_fffdU) == 4U
}

///|
/// True when the direction moves backward.
pub fn Direction::is_backward(self : Direction) -> Bool {
  (self.raw & 0xffff_fffdU) == 5U
}

///|
/// Reverse a valid direction; invalid stays invalid.
pub fn Direction::reverse(self : Direction) -> Direction {
  if !self.is_valid() {
    direction_invalid
  } else {
    Direction::{ raw: self.raw ^ 1U }
  }
}

///|
/// Access the raw numeric representation.
pub fn Direction::to_uint(self : Direction) -> UInt {
  self.raw
}
