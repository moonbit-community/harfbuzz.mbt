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
fn has_vowel_constraints(script : @common.Script) -> Bool {
  script == @common.script_devanagari ||
  script == @common.script_bengali ||
  script == @common.script_gurmukhi ||
  script == @common.script_gujarati ||
  script == @common.script_oriya ||
  script == @common.script_tamil ||
  script == @common.script_telugu ||
  script == @common.script_kannada ||
  script == @common.script_malayalam ||
  script == @common.script_sinhala ||
  script == @common.script_brahmi ||
  script == @common.script_khojki ||
  script == @common.script_khudawadi ||
  script == @common.script_tirhuta ||
  script == @common.script_modi ||
  script == @common.script_takri
}

///|
fn vowel_constraint_match(
  script : @common.Script,
  infos : Array[GlyphInfo],
  i : Int,
) -> Int {
  let len = infos.length()
  if i + 1 >= len {
    return 0
  }
  let cp = infos[i].codepoint
  let cp1 = infos[i + 1].codepoint
  if script == @common.script_devanagari {
    if cp == 0x0930U &&
      i + 2 < len &&
      cp1 == 0x094DU &&
      infos[i + 2].codepoint == 0x0907U {
      3
    } else if cp == 0x0905U {
      let matched = match cp1 {
        0x093AU
        | 0x093BU
        | 0x093EU
        | 0x0945U
        | 0x0946U
        | 0x0949U
        | 0x094AU
        | 0x094BU
        | 0x094CU
        | 0x094FU
        | 0x0956U
        | 0x0957U => true
        _ => false
      }
      if matched {
        2
      } else {
        0
      }
    } else if cp == 0x0906U {
      let matched = match cp1 {
        0x093AU | 0x0945U | 0x0946U | 0x0947U | 0x0948U => true
        _ => false
      }
      if matched {
        2
      } else {
        0
      }
    } else if cp == 0x0909U {
      if cp1 == 0x0941U {
        2
      } else {
        0
      }
    } else if cp == 0x090FU {
      let matched = match cp1 {
        0x0945U | 0x0946U | 0x0947U => true
        _ => false
      }
      if matched {
        2
      } else {
        0
      }
    } else {
      0
    }
  } else if script == @common.script_bengali {
    let matched = if cp == 0x0985U {
      cp1 == 0x09BEU
    } else if cp == 0x098BU {
      cp1 == 0x09C3U
    } else if cp == 0x098CU {
      cp1 == 0x09E2U
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_gurmukhi {
    let matched = if cp == 0x0A05U {
      match cp1 {
        0x0A3EU | 0x0A48U | 0x0A4CU => true
        _ => false
      }
    } else if cp == 0x0A72U {
      match cp1 {
        0x0A3FU | 0x0A40U | 0x0A47U => true
        _ => false
      }
    } else if cp == 0x0A73U {
      match cp1 {
        0x0A41U | 0x0A42U | 0x0A4BU => true
        _ => false
      }
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_gujarati {
    let matched = if cp == 0x0A85U {
      match cp1 {
        0x0ABEU | 0x0AC5U | 0x0AC7U | 0x0AC8U | 0x0AC9U | 0x0ACBU | 0x0ACCU =>
          true
        _ => false
      }
    } else {
      cp == 0x0AC5U && cp1 == 0x0ABEU
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_oriya {
    let matched = if cp == 0x0B05U {
      cp1 == 0x0B3EU
    } else if cp == 0x0B0FU || cp == 0x0B13U {
      cp1 == 0x0B57U
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_tamil {
    if cp == 0x0B85U && cp1 == 0x0BC2U {
      2
    } else {
      0
    }
  } else if script == @common.script_telugu {
    let matched = if cp == 0x0C12U {
      cp1 == 0x0C4CU || cp1 == 0x0C55U
    } else if cp == 0x0C3FU || cp == 0x0C46U || cp == 0x0C4AU {
      cp1 == 0x0C55U
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_kannada {
    let matched = if cp == 0x0C89U || cp == 0x0C8BU {
      cp1 == 0x0CBEU
    } else {
      cp == 0x0C92U && cp1 == 0x0CCCU
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_malayalam {
    let matched = if cp == 0x0D07U || cp == 0x0D09U {
      cp1 == 0x0D57U
    } else if cp == 0x0D0EU {
      cp1 == 0x0D46U
    } else if cp == 0x0D12U {
      cp1 == 0x0D3EU || cp1 == 0x0D57U
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_sinhala {
    let matched = if cp == 0x0D85U {
      match cp1 {
        0x0DCFU | 0x0DD0U | 0x0DD1U => true
        _ => false
      }
    } else if cp == 0x0D8BU || cp == 0x0D8FU || cp == 0x0D94U {
      cp1 == 0x0DDFU
    } else if cp == 0x0D8DU {
      cp1 == 0x0DD8U
    } else if cp == 0x0D91U {
      match cp1 {
        0x0DCAU | 0x0DD9U | 0x0DDAU | 0x0DDCU | 0x0DDDU | 0x0DDEU => true
        _ => false
      }
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_brahmi {
    let matched = if cp == 0x11005U {
      cp1 == 0x11038U
    } else if cp == 0x1100BU {
      cp1 == 0x1103EU
    } else if cp == 0x1100FU {
      cp1 == 0x11042U
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_khojki {
    let matched = if cp == 0x11200U {
      cp1 == 0x1122CU || cp1 == 0x11231U || cp1 == 0x11233U
    } else if cp == 0x11206U {
      cp1 == 0x1122CU
    } else if cp == 0x1122CU {
      cp1 == 0x11230U || cp1 == 0x11231U
    } else {
      cp == 0x11240U && cp1 == 0x1122EU
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_khudawadi {
    let matched = if cp == 0x112B0U {
      match cp1 {
        0x112E0U | 0x112E5U | 0x112E6U | 0x112E7U | 0x112E8U => true
        _ => false
      }
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_tirhuta {
    let matched = if cp == 0x11481U {
      cp1 == 0x114B0U
    } else if cp == 0x1148BU || cp == 0x1148DU {
      cp1 == 0x114BAU
    } else if cp == 0x114AAU {
      cp1 == 0x114B5U || cp1 == 0x114B6U
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_modi {
    let matched = if cp == 0x11600U || cp == 0x11601U {
      cp1 == 0x11639U || cp1 == 0x1163AU
    } else {
      false
    }
    if matched {
      2
    } else {
      0
    }
  } else if script == @common.script_takri {
    let matched = if cp == 0x11680U {
      cp1 == 0x116ADU || cp1 == 0x116B4U || cp1 == 0x116B5U
    } else {
      cp == 0x11686U && cp1 == 0x116B2U
    }
    if matched {
      2
    } else {
      0
    }
  } else {
    0
  }
}

///|
fn preprocess_vowel_constraints(buffer : Buffer) -> Unit {
  if !has_vowel_constraints(buffer.script) {
    return ()
  }
  let infos = buffer.infos
  if infos.length() < 2 {
    return ()
  }
  let positions = buffer.positions
  let dotted_position = GlyphPosition::{
    x_advance: 0,
    y_advance: 0,
    x_offset: 0,
    y_offset: 0,
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let mut i = 0
  while i < infos.length() {
    let match_len = vowel_constraint_match(buffer.script, infos, i)
    if match_len == 3 {
      next_infos.push(infos[i])
      next_positions.push(positions[i])
      next_infos.push(infos[i + 1])
      next_positions.push(positions[i + 1])
      let cluster = infos[i + 2].cluster
      next_infos.push(GlyphInfo::{
        codepoint: dotted_circle_codepoint,
        cluster,
        unicode: dotted_circle_codepoint,
      })
      next_positions.push(dotted_position)
      next_infos.push(infos[i + 2])
      next_positions.push(positions[i + 2])
      i = i + 3
      continue
    }
    if match_len == 2 {
      next_infos.push(infos[i])
      next_positions.push(positions[i])
      let cluster = infos[i + 1].cluster
      next_infos.push(GlyphInfo::{
        codepoint: dotted_circle_codepoint,
        cluster,
        unicode: dotted_circle_codepoint,
      })
      next_positions.push(dotted_position)
      next_infos.push(infos[i + 1])
      next_positions.push(positions[i + 1])
      i = i + 2
      continue
    }
    next_infos.push(infos[i])
    next_positions.push(positions[i])
    i = i + 1
  }
  buffer.infos = next_infos
  buffer.positions = next_positions
}
