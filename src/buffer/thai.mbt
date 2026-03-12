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
let thai_consonant_nc : Int = 0

///|
let thai_consonant_ac : Int = 1

///|
let thai_consonant_rc : Int = 2

///|
let thai_consonant_dc : Int = 3

///|
let thai_consonant_not : Int = 4

///|
let thai_mark_av : Int = 0

///|
let thai_mark_bv : Int = 1

///|
let thai_mark_t : Int = 2

///|
let thai_mark_not : Int = 3

///|
let thai_action_nop : Int = 0

///|
let thai_action_sd : Int = 1

///|
let thai_action_sl : Int = 2

///|
let thai_action_sdl : Int = 3

///|
let thai_action_rd : Int = 4

///|
let thai_above_t0 : Int = 0

///|
let thai_above_t1 : Int = 1

///|
let thai_above_t2 : Int = 2

///|
let thai_above_t3 : Int = 3

///|
let thai_below_b0 : Int = 0

///|
let thai_below_b1 : Int = 1

///|
let thai_below_b2 : Int = 2

///|
priv struct ThaiStateEdge {
  action : Int
  next_state : Int
}

///|
let thai_above_start_state : Array[Int] = [
  thai_above_t0,
  thai_above_t1,
  thai_above_t0,
  thai_above_t0,
  thai_above_t3,
]

///|
let thai_below_start_state : Array[Int] = [
  thai_below_b0,
  thai_below_b0,
  thai_below_b1,
  thai_below_b2,
  thai_below_b2,
]

///|
let thai_above_state_machine : Array[Array[ThaiStateEdge]] = [
  [
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t3 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t0 },
    ThaiStateEdge::{ action: thai_action_sd, next_state: thai_above_t3 },
  ],
  [
    ThaiStateEdge::{ action: thai_action_sl, next_state: thai_above_t2 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t1 },
    ThaiStateEdge::{ action: thai_action_sdl, next_state: thai_above_t2 },
  ],
  [
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t3 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t2 },
    ThaiStateEdge::{ action: thai_action_sl, next_state: thai_above_t3 },
  ],
  [
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t3 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t3 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_above_t3 },
  ],
]

///|
let thai_below_state_machine : Array[Array[ThaiStateEdge]] = [
  [
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b0 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b2 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b0 },
  ],
  [
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b1 },
    ThaiStateEdge::{ action: thai_action_rd, next_state: thai_below_b2 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b1 },
  ],
  [
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b2 },
    ThaiStateEdge::{ action: thai_action_sd, next_state: thai_below_b2 },
    ThaiStateEdge::{ action: thai_action_nop, next_state: thai_below_b2 },
  ],
]

///|
priv struct ThaiPuaMapping {
  u : UInt
  win_pua : UInt
  mac_pua : UInt
}

///|
let thai_pua_sd : Array[ThaiPuaMapping] = [
  ThaiPuaMapping::{ u: 0x0E48U, win_pua: 0xF70AU, mac_pua: 0xF88BU },
  ThaiPuaMapping::{ u: 0x0E49U, win_pua: 0xF70BU, mac_pua: 0xF88EU },
  ThaiPuaMapping::{ u: 0x0E4AU, win_pua: 0xF70CU, mac_pua: 0xF891U },
  ThaiPuaMapping::{ u: 0x0E4BU, win_pua: 0xF70DU, mac_pua: 0xF894U },
  ThaiPuaMapping::{ u: 0x0E4CU, win_pua: 0xF70EU, mac_pua: 0xF897U },
  ThaiPuaMapping::{ u: 0x0E38U, win_pua: 0xF718U, mac_pua: 0xF89BU },
  ThaiPuaMapping::{ u: 0x0E39U, win_pua: 0xF719U, mac_pua: 0xF89CU },
  ThaiPuaMapping::{ u: 0x0E3AU, win_pua: 0xF71AU, mac_pua: 0xF89DU },
]

///|
let thai_pua_sdl : Array[ThaiPuaMapping] = [
  ThaiPuaMapping::{ u: 0x0E48U, win_pua: 0xF705U, mac_pua: 0xF88CU },
  ThaiPuaMapping::{ u: 0x0E49U, win_pua: 0xF706U, mac_pua: 0xF88FU },
  ThaiPuaMapping::{ u: 0x0E4AU, win_pua: 0xF707U, mac_pua: 0xF892U },
  ThaiPuaMapping::{ u: 0x0E4BU, win_pua: 0xF708U, mac_pua: 0xF895U },
  ThaiPuaMapping::{ u: 0x0E4CU, win_pua: 0xF709U, mac_pua: 0xF898U },
]

///|
let thai_pua_sl : Array[ThaiPuaMapping] = [
  ThaiPuaMapping::{ u: 0x0E48U, win_pua: 0xF713U, mac_pua: 0xF88AU },
  ThaiPuaMapping::{ u: 0x0E49U, win_pua: 0xF714U, mac_pua: 0xF88DU },
  ThaiPuaMapping::{ u: 0x0E4AU, win_pua: 0xF715U, mac_pua: 0xF890U },
  ThaiPuaMapping::{ u: 0x0E4BU, win_pua: 0xF716U, mac_pua: 0xF893U },
  ThaiPuaMapping::{ u: 0x0E4CU, win_pua: 0xF717U, mac_pua: 0xF896U },
  ThaiPuaMapping::{ u: 0x0E31U, win_pua: 0xF710U, mac_pua: 0xF884U },
  ThaiPuaMapping::{ u: 0x0E34U, win_pua: 0xF701U, mac_pua: 0xF885U },
  ThaiPuaMapping::{ u: 0x0E35U, win_pua: 0xF702U, mac_pua: 0xF886U },
  ThaiPuaMapping::{ u: 0x0E36U, win_pua: 0xF703U, mac_pua: 0xF887U },
  ThaiPuaMapping::{ u: 0x0E37U, win_pua: 0xF704U, mac_pua: 0xF888U },
  ThaiPuaMapping::{ u: 0x0E47U, win_pua: 0xF712U, mac_pua: 0xF889U },
  ThaiPuaMapping::{ u: 0x0E4DU, win_pua: 0xF711U, mac_pua: 0xF899U },
]

///|
let thai_pua_rd : Array[ThaiPuaMapping] = [
  ThaiPuaMapping::{ u: 0x0E0DU, win_pua: 0xF70FU, mac_pua: 0xF89AU },
  ThaiPuaMapping::{ u: 0x0E10U, win_pua: 0xF700U, mac_pua: 0xF89EU },
]

///|
fn mask_thai_lao(u : UInt) -> UInt {
  u & 0xFFFFFF7FU
}

///|
fn is_sara_am(u : UInt) -> Bool {
  mask_thai_lao(u) == 0x0E33U
}

///|
fn nikhahit_from_sara_am(u : UInt) -> UInt {
  u - 0x0E33U + 0x0E4DU
}

///|
fn sara_aa_from_sara_am(u : UInt) -> UInt {
  u - 1U
}

///|
fn is_above_base_mark(u : UInt) -> Bool {
  let v = mask_thai_lao(u)
  (v >= 0x0E34U && v <= 0x0E37U) ||
  (v >= 0x0E47U && v <= 0x0E4EU) ||
  v == 0x0E31U ||
  v == 0x0E3BU
}

///|
fn get_consonant_type(u : UInt) -> Int {
  let v = mask_thai_lao(u)
  if v == 0x0E1BU || v == 0x0E1DU || v == 0x0E1FU {
    return thai_consonant_ac
  }
  if v == 0x0E0DU || v == 0x0E10U {
    return thai_consonant_rc
  }
  if v == 0x0E0EU || v == 0x0E0FU {
    return thai_consonant_dc
  }
  if v >= 0x0E01U && v <= 0x0E2EU {
    return thai_consonant_nc
  }
  thai_consonant_not
}

///|
fn get_mark_type(u : UInt) -> Int {
  let v = mask_thai_lao(u)
  if v == 0x0E31U || (v >= 0x0E34U && v <= 0x0E37U) ||
    v == 0x0E47U || (v >= 0x0E4DU && v <= 0x0E4EU) {
    return thai_mark_av
  }
  if v >= 0x0E38U && v <= 0x0E3AU {
    return thai_mark_bv
  }
  if v >= 0x0E48U && v <= 0x0E4CU {
    return thai_mark_t
  }
  thai_mark_not
}

///|
fn merge_clusters_range(infos : Array[GlyphInfo], start : Int, end : Int) -> Unit {
  if start < 0 || start >= end || end > infos.length() {
    return ()
  }
  let mut min_cluster = infos[start].cluster
  for i in (start + 1)..<end {
    let value = infos[i].cluster
    if value < min_cluster {
      min_cluster = value
    }
  }
  for i in start..<end {
    let info = infos[i]
    infos[i] = GlyphInfo::{ codepoint: info.codepoint, cluster: min_cluster, unicode: info.unicode }
  }
}

///|
fn preprocess_thai_sara_am(buffer : Buffer) -> Unit {
  if buffer.infos.is_empty() {
    return ()
  }
  let infos : Array[GlyphInfo] = []
  let positions : Array[GlyphPosition] = []
  for i in 0..<buffer.infos.length() {
    let info = buffer.infos[i]
    let pos = buffer.positions[i]
    if !is_sara_am(info.codepoint) {
      infos.push(info)
      positions.push(pos)
      continue
    }
    let nikhahit = nikhahit_from_sara_am(info.codepoint)
    infos.push(GlyphInfo::{ codepoint: nikhahit, cluster: info.cluster, unicode: nikhahit })
    positions.push(pos)
    let sara_aa = sara_aa_from_sara_am(info.codepoint)
    infos.push(GlyphInfo::{ codepoint: sara_aa, cluster: info.cluster, unicode: sara_aa })
    positions.push(pos)
    let end = infos.length()
    let mut start = end - 2
    while start > 0 && is_above_base_mark(infos[start - 1].codepoint) {
      start = start - 1
    }
    if start + 2 < end {
      let n_info = infos[end - 2]
      let n_pos = positions[end - 2]
      let mut j = end - 2
      while j > start {
        infos[j] = infos[j - 1]
        positions[j] = positions[j - 1]
        j = j - 1
      }
      infos[start] = n_info
      positions[start] = n_pos
      merge_clusters_range(infos, start, end)
    } else if start > 0 {
      merge_clusters_range(infos, start - 1, end)
    }
  }
  ignore(buffer.replace_glyphs(infos, positions=positions))
}

///|
fn thai_pua_shape(
  u : UInt,
  action : Int,
  font : @font.Font,
) -> Result[UInt, ShapeError] {
  let mappings = if action == thai_action_sd {
    thai_pua_sd
  } else if action == thai_action_sdl {
    thai_pua_sdl
  } else if action == thai_action_sl {
    thai_pua_sl
  } else if action == thai_action_rd {
    thai_pua_rd
  } else {
    []
  }
  if mappings.is_empty() {
    return Ok(u)
  }
  for mapping in mappings {
    if mapping.u == u {
      match font.glyph_for_codepoint(mapping.win_pua) {
        Err(err) => return Err(Font(err))
        Ok(None) => ()
        Ok(Some(_)) => return Ok(mapping.win_pua)
      }
      match font.glyph_for_codepoint(mapping.mac_pua) {
        Err(err) => return Err(Font(err))
        Ok(None) => ()
        Ok(Some(_)) => return Ok(mapping.mac_pua)
      }
      break
    }
  }
  Ok(u)
}

///|
fn apply_thai_pua_shaping(
  buffer : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let mut above_state = thai_above_start_state[thai_consonant_not]
  let mut below_state = thai_below_start_state[thai_consonant_not]
  let mut base = 0
  for i in 0..<buffer.infos.length() {
    let info = buffer.infos[i]
    let mark_type = get_mark_type(info.codepoint)
    if mark_type == thai_mark_not {
      let consonant_type = get_consonant_type(info.codepoint)
      above_state = thai_above_start_state[consonant_type]
      below_state = thai_below_start_state[consonant_type]
      base = i
      continue
    }
    let above_edge = thai_above_state_machine[above_state][mark_type]
    let below_edge = thai_below_state_machine[below_state][mark_type]
    above_state = above_edge.next_state
    below_state = below_edge.next_state
    let action = if above_edge.action != thai_action_nop {
      above_edge.action
    } else {
      below_edge.action
    }
    if action == thai_action_nop {
      continue
    }
    if action == thai_action_rd {
      let base_info = buffer.infos[base]
      let new_codepoint = match thai_pua_shape(base_info.codepoint, action, font) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      buffer.infos[base] = GlyphInfo::{
        codepoint: new_codepoint,
        cluster: base_info.cluster,
        unicode: new_codepoint,
      }
    } else {
      let new_codepoint = match thai_pua_shape(info.codepoint, action, font) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      buffer.infos[i] = GlyphInfo::{ codepoint: new_codepoint, cluster: info.cluster, unicode: new_codepoint }
    }
  }
  Ok(())
}

///|
pub fn Buffer::shape_thai(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  preprocess_thai_sara_am(self)
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let mut apply_pua = false
  if self.script == @common.script_thai {
    match gsub {
      None => apply_pua = true
      Some(gsub) => {
        let script_tag = self.script.to_tag()
        if !buffer_layout_has_script(gsub.layout(), script_tag) {
          apply_pua = true
        }
      }
    }
  }
  if apply_pua {
    match apply_thai_pua_shaping(self, font) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  self.shape_ot(font, fallback_position=false)
}
