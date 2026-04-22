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
fn build_fvar_bytes() -> Bytes {
  Bytes::from_array([
    0x00, 0x01, 0x00, 0x00, // version 1.0
    0x00, 0x10, // axis offset
    0x00, 0x02, // reserved
    0x00, 0x01, // axis count
    0x00, 0x14, // axis size
    0x00, 0x00, // instance count
    0x00, 0x08, // instance size
    0x77, 0x67, 0x68, 0x74, // 'wght'
    0xFF, 0xFF, 0x00, 0x00, // min -1.0
    0x00, 0x00, 0x00, 0x00, // default 0.0
    0x00, 0x01, 0x00, 0x00, // max 1.0
    0x00, 0x00, // flags
    0x01, 0x00, // name id
  ])
}

///|
fn build_avar_bytes() -> Bytes {
  Bytes::from_array([
    0x00, 0x01, 0x00, 0x00, // version 1.0
    0x00, 0x00, // reserved
    0x00, 0x01, // axis count
    0x00, 0x04, // segment count
    0xC0, 0x00, 0xC0, 0x00, // -1.0 -> -1.0
    0x00, 0x00, 0x00, 0x00, // 0.0 -> 0.0
    0x20, 0x00, 0x30, 0x00, // 0.5 -> 0.75
    0x40, 0x00, 0x40, 0x00, // 1.0 -> 1.0
  ])
}

///|
test "fvar parse and normalize" {
  let fvar = match FvarTable::parse(build_fvar_bytes()) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(fvar.axes.length(), content="1")
  @debug.debug_inspect(fvar.axes[0].tag.to_string(), content="wght")
  let min_thousand = (fvar.axes[0].min_value * 1000.0).round().to_int()
  let max_thousand = (fvar.axes[0].max_value * 1000.0).round().to_int()
  @debug.debug_inspect(min_thousand, content="-1000")
  @debug.debug_inspect(max_thousand, content="1000")
  let normalized = fvar.normalize_design_coords([0.5])
  @debug.debug_inspect(normalized, content="[32768]")
}

///|
test "avar map coords" {
  let avar = match AvarTable::parse(build_avar_bytes()) {
    Err(err) => fail("parse failed: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let mapped = avar.map_coords_16_16([32768])
  @debug.debug_inspect(mapped, content="[49152]")
}
