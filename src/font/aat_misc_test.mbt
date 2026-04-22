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
fn build_bsln_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  for i in 0..<32 {
    push_i16(bytes, i)
  }
  Bytes::from_array(bytes)
}

///|
fn build_feat_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u32(bytes, 0)
  push_u16(bytes, 5)
  push_u16(bytes, 2)
  push_u32(bytes, 24)
  push_u16(bytes, 0xC001)
  push_i16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 10)
  push_u16(bytes, 1)
  push_u16(bytes, 11)
  Bytes::from_array(bytes)
}

///|
fn build_ltag_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 1)
  push_u32(bytes, 0)
  push_u32(bytes, 2)
  push_u16(bytes, 20)
  push_u16(bytes, 2)
  push_u16(bytes, 22)
  push_u16(bytes, 7)
  bytes.push(b'e')
  bytes.push(b'n')
  bytes.push(b'z')
  bytes.push(b'h')
  bytes.push(b'-')
  bytes.push(b'H')
  bytes.push(b'a')
  bytes.push(b'n')
  bytes.push(b's')
  Bytes::from_array(bytes)
}

///|
fn build_opbd_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 12)
  push_u16(bytes, 12)
  push_i16(bytes, -10)
  push_i16(bytes, 20)
  push_i16(bytes, 30)
  push_i16(bytes, -40)
  Bytes::from_array(bytes)
}

///|
fn build_just_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_aat_misc() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('b', 's', 'l', 'n'), build_bsln_table()),
    (@common.Tag::from_chars('f', 'e', 'a', 't'), build_feat_table()),
    (@common.Tag::from_chars('l', 't', 'a', 'g'), build_ltag_table()),
    (@common.Tag::from_chars('o', 'p', 'b', 'd'), build_opbd_table()),
    (@common.Tag::from_chars('j', 'u', 's', 't'), build_just_table()),
  ]
  build_sfnt(tables)
}

///|
test "aat misc tables parse" {
  let font = Font::from_bytes(build_font_bytes_aat_misc())
  let bsln = match font.bsln() {
    Err(err) => fail("bsln parse failed: \{@debug.to_string(err)}")
    Ok(None) => fail("bsln table missing")
    Ok(Some(bsln)) => bsln
  }
  assert_eq(bsln.format, 0)
  match bsln.data {
    @aat.BslnData::Format0(deltas) =>
      @debug.debug_inspect(deltas[0], content="0")
    _ => fail("unexpected bsln format")
  }

  let feat = match font.feat() {
    Err(err) => fail("feat parse failed: \{@debug.to_string(err)}")
    Ok(None) => fail("feat table missing")
    Ok(Some(feat)) => feat
  }
  @debug.debug_inspect(feat.features.length(), content="1")
  @debug.debug_inspect(feat.features[0].settings.length(), content="2")

  let ltag = match font.ltag() {
    Err(err) => fail("ltag parse failed: \{@debug.to_string(err)}")
    Ok(None) => fail("ltag table missing")
    Ok(Some(ltag)) => ltag
  }
  @debug.debug_inspect(ltag.tags().length(), content="2")

  let opbd = match font.opbd() {
    Err(err) => fail("opbd parse failed: \{@debug.to_string(err)}")
    Ok(None) => fail("opbd table missing")
    Ok(Some(opbd)) => opbd
  }
  let bounds = match opbd.bounds(0U) {
    Err(err) => fail("opbd bounds failed: \{@debug.to_string(err)}")
    Ok(None) => fail("opbd bounds missing")
    Ok(Some(bounds)) => bounds
  }
  @debug.debug_inspect(bounds.left, content="-10")
  @debug.debug_inspect(bounds.top, content="20")
  @debug.debug_inspect(bounds.right, content="30")
  @debug.debug_inspect(bounds.bottom, content="-40")

  let just = match font.just() {
    Err(err) => fail("just parse failed: \{@debug.to_string(err)}")
    Ok(None) => fail("just table missing")
    Ok(Some(just)) => just
  }
  assert_eq(just.format, 0)
}
