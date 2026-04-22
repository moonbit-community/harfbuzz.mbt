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
/// Shape a buffer using AAT tables (morx, kerx, trak).
pub fn shape(
  font : @font.Font,
  buffer : @buffer.Buffer,
) -> Result[Unit, @buffer.ShapeError] {
  buffer.guess_segment_properties()
  buffer.normalize()
  match buffer.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match buffer.apply_morx(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  buffer.merge_combining_mark_clusters()
  let has_kerx = match buffer.has_kerx(font) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if has_kerx {
    match buffer.apply_kerx(font) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  } else {
    match
      buffer.apply_gpos(
        font,
        include_all_features=true,
        adjust_mark_offsets=false,
      ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  buffer.apply_trak(font)
}
