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
test "indic reorder by positions with joiner attach" {
  let buffer = Buffer::new()
  buffer.add_codepoint(10U)
  buffer.add_codepoint(11U)
  buffer.add_codepoint(12U)
  let categories : Array[Int] = [1, indic_cat_n, 1]
  let positions : Array[Int] = [4, 6, 2]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | indic_syllable_type_consonant_syllable
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_indic_syllables(
    buffer,
    @common.script_devanagari,
    categories,
    positions,
    syllables,
    None,
    [],
    [],
  )
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  inspect(result, content="[10, 11, 12]")
}
