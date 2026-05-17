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
test "aat morx contextual apply lookup" {
  let class_lookup = LookupTable::Format0([1U, 4U, 4U])
  let state_array : Array[Int] = [0, 0, 0, 0, 0]
  let entries : Array[StateEntry] = [
    StateEntry::{ new_state: 0, flags: 0, data1: 0xffff, data2: 0 },
  ]
  let table = StateTable::{
    n_classes: 5,
    class_table: ClassTable::Lookup(class_lookup),
    state_array,
    entries,
    state_array_offset: 0,
    extended: true,
  }
  let substitutions = ContextualSubstitutions::Lookups([
    LookupTable::Format0([0U, 3U, 4U]),
  ])
  let subtable = ContextualSubtable::{
    coverage_flags: 0,
    sub_feature_flags: 0U,
    table,
    substitutions,
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let clusters : Array[Int] = [0, 1]
  let changed = subtable.apply(glyphs, clusters, true)
  assert_true(changed)
  @debug.assert_eq(glyphs, [3U, 4U])
}

///|
test "aat morx ligature apply extended" {
  let class_lookup = LookupTable::Format0([1U, 4U, 4U])
  let state_array : Array[Int] = Array::make(10, 0)
  state_array[4] = 1
  state_array[9] = 2
  let entries : Array[StateEntry] = [
    StateEntry::{ new_state: 0, flags: 0, data1: 0, data2: 0 },
    StateEntry::{ new_state: 1, flags: 0x8000, data1: 0, data2: 0 },
    StateEntry::{ new_state: 0, flags: 0xa000, data1: 0, data2: 0 },
  ]
  let table = StateTable::{
    n_classes: 5,
    class_table: ClassTable::Lookup(class_lookup),
    state_array,
    entries,
    state_array_offset: 0,
    extended: true,
  }
  let subtable = LigatureSubtable::{
    coverage_flags: 0,
    sub_feature_flags: 0U,
    table,
    lig_actions: [0U, 0xC0000000U],
    components: [0U, 0U, 0U],
    ligatures: [5U],
    lig_action_offset: 0,
    component_offset_words: 0,
    ligature_offset: 0,
  }
  let glyphs : Array[UInt] = [1U, 2U]
  let clusters : Array[Int] = [0, 1]
  let changed = subtable.apply(glyphs, clusters, true)
  assert_true(changed)
  @debug.assert_eq(glyphs, [5U])
  @debug.assert_eq(clusters, [0])
}

///|
test "aat morx insertion apply" {
  let class_lookup = LookupTable::Format0([1U, 4U])
  let state_array : Array[Int] = [0, 0, 0, 0, 1]
  let entries : Array[StateEntry] = [
    StateEntry::{ new_state: 0, flags: 0, data1: 0xffff, data2: 0xffff },
    StateEntry::{ new_state: 0, flags: 0x0020, data1: 0, data2: 0xffff },
  ]
  let table = StateTable::{
    n_classes: 5,
    class_table: ClassTable::Lookup(class_lookup),
    state_array,
    entries,
    state_array_offset: 0,
    extended: true,
  }
  let subtable = InsertionSubtable::{
    coverage_flags: 0,
    sub_feature_flags: 0U,
    table,
    insertion_action: [9U],
  }
  let glyphs : Array[UInt] = [1U]
  let clusters : Array[Int] = [0]
  let changed = subtable.apply(glyphs, clusters, true)
  assert_true(changed)
  @debug.assert_eq(glyphs, [1U, 9U])
  @debug.assert_eq(clusters, [0, 0])
}
