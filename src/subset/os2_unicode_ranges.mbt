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
/// Unicode range mapping for OS/2 ulUnicodeRange bits.
/// Generated from refs/harfbuzz/src/hb-ot-os2-unicode-ranges.hh; do not edit by hand.
priv struct Os2UnicodeRange {
  first : UInt
  last : UInt
  bit : Int
}

///|
let os2_unicode_ranges : Array[Os2UnicodeRange] = [
  { first: 0x0, last: 0x7F, bit: 0, },
  { first: 0x80, last: 0xFF, bit: 1, },
  { first: 0x100, last: 0x17F, bit: 2, },
  { first: 0x180, last: 0x24F, bit: 3, },
  { first: 0x250, last: 0x2AF, bit: 4, },
  { first: 0x2B0, last: 0x2FF, bit: 5, },
  { first: 0x300, last: 0x36F, bit: 6, },
  { first: 0x370, last: 0x3FF, bit: 7, },
  { first: 0x400, last: 0x4FF, bit: 9, },
  { first: 0x500, last: 0x52F, bit: 9, },
  { first: 0x530, last: 0x58F, bit: 10, },
  { first: 0x590, last: 0x5FF, bit: 11, },
  { first: 0x600, last: 0x6FF, bit: 13, },
  { first: 0x700, last: 0x74F, bit: 71, },
  { first: 0x750, last: 0x77F, bit: 13, },
  { first: 0x780, last: 0x7BF, bit: 72, },
  { first: 0x7C0, last: 0x7FF, bit: 14, },
  { first: 0x900, last: 0x97F, bit: 15, },
  { first: 0x980, last: 0x9FF, bit: 16, },
  { first: 0xA00, last: 0xA7F, bit: 17, },
  { first: 0xA80, last: 0xAFF, bit: 18, },
  { first: 0xB00, last: 0xB7F, bit: 19, },
  { first: 0xB80, last: 0xBFF, bit: 20, },
  { first: 0xC00, last: 0xC7F, bit: 21, },
  { first: 0xC80, last: 0xCFF, bit: 22, },
  { first: 0xD00, last: 0xD7F, bit: 23, },
  { first: 0xD80, last: 0xDFF, bit: 73, },
  { first: 0xE00, last: 0xE7F, bit: 24, },
  { first: 0xE80, last: 0xEFF, bit: 25, },
  { first: 0xF00, last: 0xFFF, bit: 70, },
  { first: 0x1000, last: 0x109F, bit: 74, },
  { first: 0x10A0, last: 0x10FF, bit: 26, },
  { first: 0x1100, last: 0x11FF, bit: 28, },
  { first: 0x1200, last: 0x137F, bit: 75, },
  { first: 0x1380, last: 0x139F, bit: 75, },
  { first: 0x13A0, last: 0x13FF, bit: 76, },
  { first: 0x1400, last: 0x167F, bit: 77, },
  { first: 0x1680, last: 0x169F, bit: 78, },
  { first: 0x16A0, last: 0x16FF, bit: 79, },
  { first: 0x1700, last: 0x171F, bit: 84, },
  { first: 0x1720, last: 0x173F, bit: 84, },
  { first: 0x1740, last: 0x175F, bit: 84, },
  { first: 0x1760, last: 0x177F, bit: 84, },
  { first: 0x1780, last: 0x17FF, bit: 80, },
  { first: 0x1800, last: 0x18AF, bit: 81, },
  { first: 0x1900, last: 0x194F, bit: 93, },
  { first: 0x1950, last: 0x197F, bit: 94, },
  { first: 0x1980, last: 0x19DF, bit: 95, },
  { first: 0x19E0, last: 0x19FF, bit: 80, },
  { first: 0x1A00, last: 0x1A1F, bit: 96, },
  { first: 0x1B00, last: 0x1B7F, bit: 27, },
  { first: 0x1B80, last: 0x1BBF, bit: 112, },
  { first: 0x1C00, last: 0x1C4F, bit: 113, },
  { first: 0x1C50, last: 0x1C7F, bit: 114, },
  { first: 0x1D00, last: 0x1D7F, bit: 4, },
  { first: 0x1D80, last: 0x1DBF, bit: 4, },
  { first: 0x1DC0, last: 0x1DFF, bit: 6, },
  { first: 0x1E00, last: 0x1EFF, bit: 29, },
  { first: 0x1F00, last: 0x1FFF, bit: 30, },
  { first: 0x2000, last: 0x206F, bit: 31, },
  { first: 0x2070, last: 0x209F, bit: 32, },
  { first: 0x20A0, last: 0x20CF, bit: 33, },
  { first: 0x20D0, last: 0x20FF, bit: 34, },
  { first: 0x2100, last: 0x214F, bit: 35, },
  { first: 0x2150, last: 0x218F, bit: 36, },
  { first: 0x2190, last: 0x21FF, bit: 37, },
  { first: 0x2200, last: 0x22FF, bit: 38, },
  { first: 0x2300, last: 0x23FF, bit: 39, },
  { first: 0x2400, last: 0x243F, bit: 40, },
  { first: 0x2440, last: 0x245F, bit: 41, },
  { first: 0x2460, last: 0x24FF, bit: 42, },
  { first: 0x2500, last: 0x257F, bit: 43, },
  { first: 0x2580, last: 0x259F, bit: 44, },
  { first: 0x25A0, last: 0x25FF, bit: 45, },
  { first: 0x2600, last: 0x26FF, bit: 46, },
  { first: 0x2700, last: 0x27BF, bit: 47, },
  { first: 0x27C0, last: 0x27EF, bit: 38, },
  { first: 0x27F0, last: 0x27FF, bit: 37, },
  { first: 0x2800, last: 0x28FF, bit: 82, },
  { first: 0x2900, last: 0x297F, bit: 37, },
  { first: 0x2980, last: 0x29FF, bit: 38, },
  { first: 0x2A00, last: 0x2AFF, bit: 38, },
  { first: 0x2B00, last: 0x2BFF, bit: 37, },
  { first: 0x2C00, last: 0x2C5F, bit: 97, },
  { first: 0x2C60, last: 0x2C7F, bit: 29, },
  { first: 0x2C80, last: 0x2CFF, bit: 8, },
  { first: 0x2D00, last: 0x2D2F, bit: 26, },
  { first: 0x2D30, last: 0x2D7F, bit: 98, },
  { first: 0x2D80, last: 0x2DDF, bit: 75, },
  { first: 0x2DE0, last: 0x2DFF, bit: 9, },
  { first: 0x2E00, last: 0x2E7F, bit: 31, },
  { first: 0x2E80, last: 0x2EFF, bit: 59, },
  { first: 0x2F00, last: 0x2FDF, bit: 59, },
  { first: 0x2FF0, last: 0x2FFF, bit: 59, },
  { first: 0x3000, last: 0x303F, bit: 48, },
  { first: 0x3040, last: 0x309F, bit: 49, },
  { first: 0x30A0, last: 0x30FF, bit: 50, },
  { first: 0x3100, last: 0x312F, bit: 51, },
  { first: 0x3130, last: 0x318F, bit: 52, },
  { first: 0x3190, last: 0x319F, bit: 59, },
  { first: 0x31A0, last: 0x31BF, bit: 51, },
  { first: 0x31C0, last: 0x31EF, bit: 61, },
  { first: 0x31F0, last: 0x31FF, bit: 50, },
  { first: 0x3200, last: 0x32FF, bit: 54, },
  { first: 0x3300, last: 0x33FF, bit: 55, },
  { first: 0x3400, last: 0x4DBF, bit: 59, },
  { first: 0x4DC0, last: 0x4DFF, bit: 99, },
  { first: 0x4E00, last: 0x9FFF, bit: 59, },
  { first: 0xA000, last: 0xA48F, bit: 83, },
  { first: 0xA490, last: 0xA4CF, bit: 83, },
  { first: 0xA500, last: 0xA63F, bit: 12, },
  { first: 0xA640, last: 0xA69F, bit: 9, },
  { first: 0xA700, last: 0xA71F, bit: 5, },
  { first: 0xA720, last: 0xA7FF, bit: 29, },
  { first: 0xA800, last: 0xA82F, bit: 100, },
  { first: 0xA840, last: 0xA87F, bit: 53, },
  { first: 0xA880, last: 0xA8DF, bit: 115, },
  { first: 0xA900, last: 0xA92F, bit: 116, },
  { first: 0xA930, last: 0xA95F, bit: 117, },
  { first: 0xAA00, last: 0xAA5F, bit: 118, },
  { first: 0xAC00, last: 0xD7AF, bit: 56, },
  { first: 0xD800, last: 0xDFFF, bit: 57, },
  { first: 0xE000, last: 0xF8FF, bit: 60, },
  { first: 0xF900, last: 0xFAFF, bit: 61, },
  { first: 0xFB00, last: 0xFB4F, bit: 62, },
  { first: 0xFB50, last: 0xFDFF, bit: 63, },
  { first: 0xFE00, last: 0xFE0F, bit: 91, },
  { first: 0xFE10, last: 0xFE1F, bit: 65, },
  { first: 0xFE20, last: 0xFE2F, bit: 64, },
  { first: 0xFE30, last: 0xFE4F, bit: 65, },
  { first: 0xFE50, last: 0xFE6F, bit: 66, },
  { first: 0xFE70, last: 0xFEFF, bit: 67, },
  { first: 0xFF00, last: 0xFFEF, bit: 68, },
  { first: 0xFFF0, last: 0xFFFF, bit: 69, },
  { first: 0x10000, last: 0x1007F, bit: 101, },
  { first: 0x10080, last: 0x100FF, bit: 101, },
  { first: 0x10100, last: 0x1013F, bit: 101, },
  { first: 0x10140, last: 0x1018F, bit: 102, },
  { first: 0x10190, last: 0x101CF, bit: 119, },
  { first: 0x101D0, last: 0x101FF, bit: 120, },
  { first: 0x10280, last: 0x1029F, bit: 121, },
  { first: 0x102A0, last: 0x102DF, bit: 121, },
  { first: 0x10300, last: 0x1032F, bit: 85, },
  { first: 0x10330, last: 0x1034F, bit: 86, },
  { first: 0x10380, last: 0x1039F, bit: 103, },
  { first: 0x103A0, last: 0x103DF, bit: 104, },
  { first: 0x10400, last: 0x1044F, bit: 87, },
  { first: 0x10450, last: 0x1047F, bit: 105, },
  { first: 0x10480, last: 0x104AF, bit: 106, },
  { first: 0x10800, last: 0x1083F, bit: 107, },
  { first: 0x10900, last: 0x1091F, bit: 58, },
  { first: 0x10920, last: 0x1093F, bit: 121, },
  { first: 0x10A00, last: 0x10A5F, bit: 108, },
  { first: 0x12000, last: 0x123FF, bit: 110, },
  { first: 0x12400, last: 0x1247F, bit: 110, },
  { first: 0x1D000, last: 0x1D0FF, bit: 88, },
  { first: 0x1D100, last: 0x1D1FF, bit: 88, },
  { first: 0x1D200, last: 0x1D24F, bit: 88, },
  { first: 0x1D300, last: 0x1D35F, bit: 109, },
  { first: 0x1D360, last: 0x1D37F, bit: 111, },
  { first: 0x1D400, last: 0x1D7FF, bit: 89, },
  { first: 0x1F000, last: 0x1F02F, bit: 122, },
  { first: 0x1F030, last: 0x1F09F, bit: 122, },
  { first: 0x20000, last: 0x2A6DF, bit: 59, },
  { first: 0x2F800, last: 0x2FA1F, bit: 61, },
  { first: 0xE0000, last: 0xE007F, bit: 92, },
  { first: 0xE0100, last: 0xE01EF, bit: 91, },
  { first: 0xF0000, last: 0xFFFFD, bit: 90, },
  { first: 0x100000, last: 0x10FFFD, bit: 90, },
]

///|
fn os2_unicode_range_bit(cp : UInt) -> Int? {
  if os2_unicode_ranges.is_empty() {
    return None
  }
  let mut low = 0
  let mut high = os2_unicode_ranges.length() - 1
  while low <= high {
    let mid = low + (high - low) / 2
    let range = os2_unicode_ranges[mid]
    if cp < range.first {
      high = mid - 1
    } else if cp > range.last {
      low = mid + 1
    } else {
      return Some(range.bit)
    }
  }
  None
}

///|
fn os2_unicode_ranges_from_codepoints(
  codepoints : ArrayView[(UInt, Int)],
) -> (UInt, UInt, UInt, UInt) {
  let mut bits1 : UInt = 0U
  let mut bits2 : UInt = 0U
  let mut bits3 : UInt = 0U
  let mut bits4 : UInt = 0U
  for pair in codepoints {
    let cp = pair.0
    match os2_unicode_range_bit(cp) {
      None => ()
      Some(bit) =>
        if bit < 32 {
          bits1 = bits1 | (1U << bit)
        } else if bit < 64 {
          bits2 = bits2 | (1U << (bit - 32))
        } else if bit < 96 {
          bits3 = bits3 | (1U << (bit - 64))
        } else if bit < 128 {
          bits4 = bits4 | (1U << (bit - 96))
        }
    }
  }
  (bits1, bits2, bits3, bits4)
}
