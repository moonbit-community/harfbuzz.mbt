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
pub(all) enum BufferSerializeFormat {
  Invalid
  Text
  Json
} derive(Eq, Debug)

///|
pub(all) enum BufferSerializeMode {
  Glyphs
  Unicode
} derive(Eq, Debug)

///|
pub fn BufferSerializeMode::from_string(
  s : String,
  len? : Int = -1,
) -> BufferSerializeMode {
  if s is "" || len == 0 {
    return BufferSerializeMode::Glyphs
  }
  let max_len = if len < 0 || len > s.length() { s.length() } else { len }
  let sb = StringBuilder::new(size_hint=max_len)
  let mut count = 0
  for c in s {
    if count >= max_len {
      break
    }
    sb.write_char(c.to_ascii_lowercase())
    count = count + 1
  }
  let normalized = sb.to_string()
  if normalized == "unicode" {
    BufferSerializeMode::Unicode
  } else {
    BufferSerializeMode::Glyphs
  }
}

///|
pub fn BufferSerializeFormat::from_string(
  s : String,
  len? : Int = -1,
) -> BufferSerializeFormat {
  if s is "" || len == 0 {
    return BufferSerializeFormat::Invalid
  }
  let max_len = if len < 0 || len > s.length() { s.length() } else { len }
  let sb = StringBuilder::new(size_hint=max_len)
  let mut count = 0
  for c in s {
    if count >= max_len {
      break
    }
    sb.write_char(c.to_ascii_lowercase())
    count = count + 1
  }
  let normalized = sb.to_string()
  if normalized == "text" {
    BufferSerializeFormat::Text
  } else if normalized == "json" {
    BufferSerializeFormat::Json
  } else {
    BufferSerializeFormat::Invalid
  }
}

///|
pub fn BufferSerializeFormat::to_string(
  self : BufferSerializeFormat,
) -> String? {
  match self {
    BufferSerializeFormat::Text => Some("text")
    BufferSerializeFormat::Json => Some("json")
    BufferSerializeFormat::Invalid => None
  }
}

///|
fn hex_digit(value : Int) -> Char {
  let code = if value < 10 { 48 + value } else { 55 + value }
  code.unsafe_to_char()
}

///|
fn format_hex(value : UInt, min_width : Int) -> String {
  let digits : Array[Char] = []
  let mut v = value
  if v == 0U {
    digits.push('0')
  } else {
    while v > 0U {
      let d = (v & 0xFU).reinterpret_as_int()
      digits.push(hex_digit(d))
      v = v >> 4
    }
  }
  while digits.length() < min_width {
    digits.push('0')
  }
  let len = digits.length()
  let sb = StringBuilder::new(size_hint=len)
  for i in 0..<len {
    let idx = len - 1 - i
    sb.write_char(digits[idx])
  }
  sb.to_string()
}

///|
fn append_int(sb : StringBuilder, value : Int) -> Unit {
  sb.write_string("\{value}")
}

///|
fn append_uint(sb : StringBuilder, value : UInt) -> Unit {
  sb.write_string("\{value}")
}

///|
fn serialize_text(
  buffer : Buffer,
  mode : BufferSerializeMode,
  start : Int,
  end : Int,
  include_clusters : Bool,
  include_positions : Bool,
  include_advances : Bool,
) -> String {
  let sb = StringBuilder::new()
  let mut x = 0
  let mut y = 0
  let open = if mode == BufferSerializeMode::Glyphs { '[' } else { '<' }
  let close = if mode == BufferSerializeMode::Glyphs { ']' } else { '>' }
  sb.write_char(open)
  for i in start..<end {
    if i > start {
      sb.write_char('|')
    }
    let info = buffer.infos[i]
    if mode == BufferSerializeMode::Glyphs {
      append_uint(sb, info.codepoint)
    } else {
      sb.write_string("U+")
      sb.write_string(format_hex(info.unicode, 4))
    }
    if include_clusters {
      sb.write_char('=')
      append_int(sb, info.cluster)
    }
    if include_positions {
      let pos = buffer.positions[i]
      let dx = x + pos.x_offset
      let dy = y + pos.y_offset
      if dx != 0 || dy != 0 {
        sb.write_char('@')
        append_int(sb, dx)
        sb.write_char(',')
        append_int(sb, dy)
      }
      if include_advances {
        sb.write_char('+')
        append_int(sb, pos.x_advance)
        if pos.y_advance != 0 {
          sb.write_char(',')
          append_int(sb, pos.y_advance)
        }
      } else {
        x = x + pos.x_advance
        y = y + pos.y_advance
      }
    }
  }
  sb.write_char(close)
  sb.to_string()
}

///|
fn serialize_json(
  buffer : Buffer,
  mode : BufferSerializeMode,
  start : Int,
  end : Int,
  include_clusters : Bool,
  include_positions : Bool,
  include_advances : Bool,
) -> String {
  let sb = StringBuilder::new()
  let mut x = 0
  let mut y = 0
  sb.write_char('[')
  for i in start..<end {
    if i > start {
      sb.write_char(',')
    }
    sb.write_char('{')
    let info = buffer.infos[i]
    if mode == BufferSerializeMode::Glyphs {
      sb.write_string("\"g\":")
      append_uint(sb, info.codepoint)
    } else {
      sb.write_string("\"u\":")
      append_uint(sb, info.unicode)
    }
    if include_clusters {
      sb.write_string(",\"cl\":")
      append_int(sb, info.cluster)
    }
    if include_positions {
      let pos = buffer.positions[i]
      let dx = x + pos.x_offset
      let dy = y + pos.y_offset
      sb.write_string(",\"dx\":")
      append_int(sb, dx)
      sb.write_string(",\"dy\":")
      append_int(sb, dy)
      if include_advances {
        sb.write_string(",\"ax\":")
        append_int(sb, pos.x_advance)
        sb.write_string(",\"ay\":")
        append_int(sb, pos.y_advance)
      } else {
        x = x + pos.x_advance
        y = y + pos.y_advance
      }
    }
    sb.write_char('}')
  }
  sb.write_char(']')
  sb.to_string()
}

///|
pub fn Buffer::serialize(
  self : Buffer,
  format? : BufferSerializeFormat = BufferSerializeFormat::Text,
  mode? : BufferSerializeMode = BufferSerializeMode::Glyphs,
  start? : Int = 0,
  end? : Int = -1,
  no_positions? : Bool = false,
  no_clusters? : Bool = false,
  no_advances? : Bool = false,
) -> String {
  let len = self.infos.length()
  let mut start = start
  let end = if end < 0 || end > len { len } else { end }
  if start < 0 {
    start = 0
  }
  if start > end {
    start = end
  }
  if start >= end {
    return ""
  }
  let include_positions = !no_positions
  let include_advances = include_positions && !no_advances
  let include_clusters = !no_clusters
  match format {
    BufferSerializeFormat::Text =>
      serialize_text(
        self, mode, start, end, include_clusters, include_positions, include_advances,
      )
    BufferSerializeFormat::Json =>
      serialize_json(
        self, mode, start, end, include_clusters, include_positions, include_advances,
      )
    BufferSerializeFormat::Invalid => ""
  }
}
