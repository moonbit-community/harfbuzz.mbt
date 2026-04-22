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
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  let v = value & 0xffff
  bytes.push(((v >> 8) & 0xff).to_byte())
  bytes.push((v & 0xff).to_byte())
}

///|
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let v = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, v)
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  let v = value.reinterpret_as_uint()
  bytes.push(((v >> 24) & 0xffU).to_byte())
  bytes.push(((v >> 16) & 0xffU).to_byte())
  bytes.push(((v >> 8) & 0xffU).to_byte())
  bytes.push((v & 0xffU).to_byte())
}

///|
fn push_i32(bytes : Array[Byte], value : Int) -> Unit {
  push_u32(bytes, value)
}

///|
fn build_kerx_format0() -> Bytes {
  let bytes : Array[Byte] = []
  // kerx header
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u32(bytes, 1)
  // subtable header
  push_u32(bytes, 34)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  // binsearch header (len=1)
  push_u32(bytes, 1)
  push_u32(bytes, 16)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  // pair record
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_i16(bytes, -50)
  Bytes::from_array(bytes)
}

///|
fn build_kerx_format1() -> Bytes {
  let bytes : Array[Byte] = []
  // kerx header
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u32(bytes, 1)
  // subtable header (length = 82)
  push_u32(bytes, 82)
  push_u32(bytes, 1)
  push_u32(bytes, 0)
  // state table header (extended)
  push_u32(bytes, 5) // nClasses
  push_u32(bytes, 58) // classTableOffset
  push_u32(bytes, 20) // stateArrayOffset
  push_u32(bytes, 40) // entryTableOffset
  // kernAction offset
  push_u32(bytes, 68)
  // state array (2 states * 5 classes)
  let state_values : Array[Int] = [0, 0, 0, 0, 1, 0, 0, 0, 0, 2]
  for value in state_values {
    push_u16(bytes, value)
  }
  // entry table (3 entries)
  // entry 0
  push_u16(bytes, 0) // new state
  push_u16(bytes, 0) // flags
  push_u16(bytes, 0xffff) // no action
  // entry 1
  push_u16(bytes, 1) // new state
  push_u16(bytes, 0x8000) // push
  push_u16(bytes, 0xffff) // no action
  // entry 2
  push_u16(bytes, 0) // new state
  push_u16(bytes, 0) // flags
  push_u16(bytes, 0) // action index
  // class table (lookup format8)
  push_u16(bytes, 8)
  push_u16(bytes, 1) // first glyph
  push_u16(bytes, 2) // count
  push_u16(bytes, 4) // glyph 1 class
  push_u16(bytes, 4) // glyph 2 class
  // action table: one value, odd marks end of list
  push_i16(bytes, -49)
  Bytes::from_array(bytes)
}

///|
fn build_kerx_format4() -> Bytes {
  let bytes : Array[Byte] = []
  // kerx header
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u32(bytes, 1)
  // subtable header (length = 84)
  push_u32(bytes, 84)
  push_u32(bytes, 4)
  push_u32(bytes, 0)
  // state table header (extended)
  push_u32(bytes, 5) // nClasses
  push_u32(bytes, 58) // classTableOffset
  push_u32(bytes, 20) // stateArrayOffset
  push_u32(bytes, 40) // entryTableOffset
  // flags (action type 1, offset 68)
  push_u32(bytes, 0x40000044)
  // state array
  let state_values : Array[Int] = [0, 0, 0, 0, 1, 0, 0, 0, 0, 2]
  for value in state_values {
    push_u16(bytes, value)
  }
  // entry table
  // entry 0
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0xffff)
  // entry 1
  push_u16(bytes, 1)
  push_u16(bytes, 0x8000) // mark
  push_u16(bytes, 0xffff)
  // entry 2
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0) // action index
  // class table (lookup format8)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 4)
  push_u16(bytes, 4)
  // action table (mark anchor, current anchor)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_kerx_format4_control_points() -> Bytes {
  let bytes : Array[Byte] = []
  // kerx header
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u32(bytes, 1)
  // subtable header (length = 84)
  push_u32(bytes, 84)
  push_u32(bytes, 4)
  push_u32(bytes, 0)
  // state table header (extended)
  push_u32(bytes, 5) // nClasses
  push_u32(bytes, 58) // classTableOffset
  push_u32(bytes, 20) // stateArrayOffset
  push_u32(bytes, 40) // entryTableOffset
  // flags (action type 0, offset 68)
  push_u32(bytes, 0x00000044)
  // state array
  let state_values : Array[Int] = [0, 0, 0, 0, 1, 0, 0, 0, 0, 2]
  for value in state_values {
    push_u16(bytes, value)
  }
  // entry table
  // entry 0
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0xffff)
  // entry 1
  push_u16(bytes, 1)
  push_u16(bytes, 0x8000) // mark
  push_u16(bytes, 0xffff)
  // entry 2
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0) // action index
  // class table (lookup format8)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 4)
  push_u16(bytes, 4)
  // action table (mark point, current point)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  Bytes::from_array(bytes)
}

///|
fn build_kerx_format6_long() -> Bytes {
  let bytes : Array[Byte] = []
  // kerx header
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u32(bytes, 1)
  // subtable header (length = 76)
  push_u32(bytes, 76)
  push_u32(bytes, 6)
  push_u32(bytes, 0)
  // format6 header
  push_u32(bytes, 1) // long values
  push_u16(bytes, 3)
  push_u16(bytes, 3)
  push_u32(bytes, 36) // row index offset
  push_u32(bytes, 50) // column index offset
  push_u32(bytes, 64) // array offset
  push_u32(bytes, 0) // vector offset
  // row index lookup (format0, u32 values)
  push_u16(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  // column index lookup (format0, u32 values)
  push_u16(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 1)
  push_u32(bytes, 2)
  // kerning values (int32)
  push_i32(bytes, 1000)
  push_i32(bytes, -2000)
  push_i32(bytes, 3000)
  Bytes::from_array(bytes)
}

///|
fn build_ankr_for_kerx() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0) // version
  push_u16(bytes, 0) // flags
  push_u32(bytes, 12) // lookup offset
  push_u32(bytes, 24) // anchor offset
  // lookup table (format8)
  push_u16(bytes, 8)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 0) // glyph1 offset
  push_u16(bytes, 8) // glyph2 offset
  // padding to anchor offset
  push_u16(bytes, 0)
  // anchor data for glyph1
  push_u32(bytes, 1)
  push_i16(bytes, 10)
  push_i16(bytes, 20)
  // anchor data for glyph2
  push_u32(bytes, 1)
  push_i16(bytes, 15)
  push_i16(bytes, 5)
  Bytes::from_array(bytes)
}

///|
test "aat kerx format0" {
  let data = build_kerx_format0()
  let kerx = match KerxTable::parse(data[:], 10) {
    Err(err) => fail("kerx parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  assert_true(kerx.has_data())
  @debug.debug_inspect(kerx.kern_value(1U, 2U, true), content="-50")
  @debug.debug_inspect(kerx.kern_value(2U, 1U, true), content="0")
}

///|
test "aat kerx format1" {
  let data = build_kerx_format1()
  let kerx = match KerxTable::parse(data[:], 10) {
    Err(err) => fail("kerx parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let adjustments = kerx.apply_scaled(glyphs, true, 1, 1, 1, None)
  @debug.debug_inspect(adjustments[0].x_advance, content="-50")
  @debug.debug_inspect(adjustments[0].x_offset, content="-50")
  @debug.debug_inspect(adjustments[1].x_advance, content="0")
}

///|
test "aat kerx format4 anchor" {
  let data = build_kerx_format4()
  let kerx = match KerxTable::parse(data[:], 10) {
    Err(err) => fail("kerx parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let ankr = match AnkrTable::parse(build_ankr_for_kerx()[:], 10) {
    Err(err) => fail("ankr parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let adjustments = kerx.apply_scaled(glyphs, true, 1, 1, 1, Some(ankr))
  @debug.debug_inspect(adjustments[1].x_offset, content="-5")
  @debug.debug_inspect(adjustments[1].y_offset, content="15")
}

///|
test "aat kerx format4 control points" {
  let data = build_kerx_format4_control_points()
  let kerx = match KerxTable::parse(data[:], 10) {
    Err(err) => fail("kerx parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let contour_point = (glyph, point_index) => {
    if glyph == 1U && point_index == 0 {
      Some((0, 0))
    } else if glyph == 2U && point_index == 1 {
      Some((10, 5))
    } else {
      None
    }
  }
  let adjustments = kerx.apply_scaled(
    glyphs,
    true,
    1,
    1,
    1,
    None,
    contour_point~,
  )
  @debug.debug_inspect(adjustments[1].x_offset, content="-10")
  @debug.debug_inspect(adjustments[1].y_offset, content="-5")
}

///|
test "aat kerx format6 long values" {
  let data = build_kerx_format6_long()
  let kerx = match KerxTable::parse(data[:], 3) {
    Err(err) => fail("kerx parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let adjustments = kerx.apply_scaled(glyphs, true, 1, 1, 1, None)
  @debug.debug_inspect(adjustments[0].x_advance, content="1500")
  @debug.debug_inspect(adjustments[1].x_advance, content="1500")
  @debug.debug_inspect(adjustments[1].x_offset, content="1500")
}
