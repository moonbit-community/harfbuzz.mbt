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
test "use reorder repha before post-base" {
  let buffer = Buffer::new()
  buffer.add_codepoint(10U)
  buffer.add_codepoint(11U)
  buffer.add_codepoint(12U)
  let categories : Array[Int] = [use_cat_r, 1, use_cat_vblw]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | use_syllable_type_standard_cluster
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_use_syllables(buffer, categories, syllables)
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  @debug.debug_inspect(result, content="[11, 10, 12]")
}

///|
test "use reorder vpre after halant" {
  let buffer = Buffer::new()
  buffer.add_codepoint(20U)
  buffer.add_codepoint(21U)
  buffer.add_codepoint(22U)
  buffer.add_codepoint(23U)
  let categories : Array[Int] = [1, use_cat_h, 2, use_cat_vpre]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | use_syllable_type_standard_cluster
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_use_syllables(buffer, categories, syllables)
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  @debug.debug_inspect(result, content="[20, 21, 23, 22]")
}

///|
test "use feature masks apply arabic isol" {
  let categories : Array[Int] = [1]
  let syllables : Array[Int] = [(1 << 4) | use_syllable_type_standard_cluster]
  let masks = build_use_feature_masks(categories, syllables, arabic_actions=[
    arabic_action_isol,
  ])
  let isol_bit = 1U << use_feature_isol
  inspect((masks[0] & isol_bit) != 0U, content="true")
}

///|
test "use feature masks apply arabic init medi fina" {
  let categories : Array[Int] = [1, 1, 1, 1]
  let syllable = (1 << 4) | use_syllable_type_standard_cluster
  let syllables : Array[Int] = [syllable, syllable, syllable, syllable]
  let masks = build_use_feature_masks(categories, syllables, arabic_actions=[
    arabic_action_isol, arabic_action_init, arabic_action_medi, arabic_action_fina,
  ])
  let isol_bit = 1U << use_feature_isol
  let init_bit = 1U << use_feature_init
  let medi_bit = 1U << use_feature_medi
  let fina_bit = 1U << use_feature_fina
  inspect((masks[0] & isol_bit) != 0U, content="true")
  inspect((masks[1] & init_bit) != 0U, content="true")
  inspect((masks[2] & medi_bit) != 0U, content="true")
  inspect((masks[3] & fina_bit) != 0U, content="true")
}
