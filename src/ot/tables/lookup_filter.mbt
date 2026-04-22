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
fn should_ignore_glyph(
  glyph : UInt,
  lookup_flag : Int,
  gdef : GdefTable?,
  mark_filtering_set : Int?,
  masks? : Array[UInt] = [],
  index? : Int = -1,
  lookup_mask? : UInt = 0xFFFFFFFFU,
) -> Result[Bool, OtLayoutError] {
  if !masks.is_empty() && index >= 0 {
    if (masks[index] & lookup_mask) == 0U {
      return Ok(true)
    }
  }
  if lookup_flag == 0 {
    return Ok(false)
  }
  match gdef {
    None => Ok(false)
    Some(gdef) => {
      let glyph_class = gdef.glyph_class(glyph)
      match glyph_class {
        Err(err) => Err(err)
        Ok(glyph_class) => {
          if glyph_class == 1 && (lookup_flag & 0x0002) != 0 {
            return Ok(true)
          }
          if glyph_class == 2 && (lookup_flag & 0x0004) != 0 {
            return Ok(true)
          }
          if glyph_class == 3 {
            if (lookup_flag & 0x0008) != 0 {
              return Ok(true)
            }
            let attach_type = (lookup_flag >> 8) & 0xff
            if attach_type != 0 {
              let mark_class = gdef.mark_attach_class(glyph)
              match mark_class {
                Err(err) => return Err(err)
                Ok(mark_class) =>
                  if mark_class != attach_type {
                    return Ok(true)
                  }
              }
            }
            if (lookup_flag & 0x0010) != 0 {
              match mark_filtering_set {
                None => ()
                Some(set_index) => {
                  let in_set = gdef.mark_glyph_set_contains(set_index, glyph)
                  match in_set {
                    Err(err) => return Err(err)
                    Ok(false) => return Ok(true)
                    Ok(true) => ()
                  }
                }
              }
            }
          }
          Ok(false)
        }
      }
    }
  }
}

///|
fn collect_forward_indices(
  glyphs : ArrayView[UInt],
  start_index : Int,
  count : Int,
  lookup_flag : Int,
  gdef : GdefTable?,
  mark_filtering_set : Int?,
  masks? : Array[UInt] = [],
  lookup_mask? : UInt = 0xFFFFFFFFU,
  allow_ignored_start? : Bool = false,
) -> Result[Array[Int]?, OtLayoutError] {
  if count <= 0 {
    return Err(InvalidFormat)
  }
  if start_index < 0 || start_index >= glyphs.length() {
    return Ok(None)
  }
  let mut cursor = start_index
  if allow_ignored_start {
    while cursor < glyphs.length() {
      let ignored = should_ignore_glyph(
        glyphs[cursor],
        lookup_flag,
        gdef,
        mark_filtering_set,
        masks~,
        index=cursor,
        lookup_mask~,
      )
      match ignored {
        Err(err) => return Err(err)
        Ok(false) => break
        Ok(true) => cursor = cursor + 1
      }
    }
    if cursor >= glyphs.length() {
      return Ok(None)
    }
  }
  let first_ignored = should_ignore_glyph(
    glyphs[cursor],
    lookup_flag,
    gdef,
    mark_filtering_set,
    masks~,
    index=cursor,
    lookup_mask~,
  )
  match first_ignored {
    Err(err) => Err(err)
    Ok(true) => Ok(None)
    Ok(false) => {
      let indices : Array[Int] = []
      indices.push(cursor)
      cursor = cursor + 1
      while indices.length() < count {
        if cursor >= glyphs.length() {
          return Ok(None)
        }
        let ignored = should_ignore_glyph(
          glyphs[cursor],
          lookup_flag,
          gdef,
          mark_filtering_set,
          masks~,
          index=cursor,
          lookup_mask~,
        )
        match ignored {
          Err(err) => return Err(err)
          Ok(true) => cursor = cursor + 1
          Ok(false) => {
            indices.push(cursor)
            cursor = cursor + 1
          }
        }
      }
      Ok(Some(indices))
    }
  }
}

///|
fn collect_backward_indices(
  glyphs : ArrayView[UInt],
  start_index : Int,
  count : Int,
  lookup_flag : Int,
  gdef : GdefTable?,
  mark_filtering_set : Int?,
  masks? : Array[UInt] = [],
  lookup_mask? : UInt = 0xFFFFFFFFU,
) -> Result[Array[Int]?, OtLayoutError] {
  if count < 0 {
    return Err(InvalidFormat)
  }
  if count == 0 {
    return Ok(Some([]))
  }
  let indices : Array[Int] = []
  let mut cursor = start_index - 1
  while indices.length() < count {
    if cursor < 0 {
      return Ok(None)
    }
    let ignored = should_ignore_glyph(
      glyphs[cursor],
      lookup_flag,
      gdef,
      mark_filtering_set,
      masks~,
      index=cursor,
      lookup_mask~,
    )
    match ignored {
      Err(err) => return Err(err)
      Ok(true) => cursor = cursor - 1
      Ok(false) => {
        indices.push(cursor)
        cursor = cursor - 1
      }
    }
  }
  Ok(Some(indices))
}
