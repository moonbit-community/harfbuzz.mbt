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
test "unicode general category and combining class" {
  @debug.debug_inspect(general_category(0x41U), content="9")
  @debug.debug_inspect(general_category(0x20U), content="29")
  @debug.debug_inspect(combining_class(0x0301U), content="230")
  @debug.debug_inspect(is_mark(0x0301U), content="true")
  @debug.debug_inspect(is_mark(0x41U), content="false")
}

///|
test "unicode modified combining class" {
  @debug.debug_inspect(modified_combining_class(0x05B0U), content="22")
  @debug.debug_inspect(modified_combining_class(0x1A60U), content="254")
  @debug.debug_inspect(modified_combining_class(0x0F39U), content="127")
}

///|
test "unicode script and mirroring" {
  inspect(script(0x41U).to_tag().to_string(), content="Latn")
  @debug.debug_inspect(mirroring(0x28U), content="41")
  @debug.debug_inspect(mirroring(0x29U), content="40")
}

///|
test "unicode compose and decompose" {
  @debug.debug_inspect(compose(0x41U, 0x0301U), content="Some(193)")
  @debug.debug_inspect(decompose(0x00C1U), content="Some((65, 769))")
  @debug.debug_inspect(decompose(0xAC00U), content="Some((4352, 4449))")
}

///|
test "unicode emoji extended pictographic" {
  @debug.debug_inspect(is_extended_pictographic(0x1F600U), content="true")
  @debug.debug_inspect(is_extended_pictographic(0x41U), content="false")
}

///|
test "unicode emoji properties" {
  @debug.debug_inspect(is_emoji(0x1F600U), content="true")
  @debug.debug_inspect(is_emoji(0x41U), content="false")
  @debug.debug_inspect(is_emoji_presentation(0x1F600U), content="true")
  @debug.debug_inspect(is_emoji_presentation(0x263AU), content="false")
  @debug.debug_inspect(is_emoji_modifier(0x1F3FBU), content="true")
  @debug.debug_inspect(is_emoji_modifier(0x1F600U), content="false")
  @debug.debug_inspect(is_emoji_modifier_base(0x1F44DU), content="true")
  @debug.debug_inspect(is_emoji_modifier_base(0x41U), content="false")
  @debug.debug_inspect(is_emoji_component(0x200DU), content="true")
  @debug.debug_inspect(is_emoji_component(0x41U), content="false")
}

///|
test "unicode space fallback and ignorable helpers" {
  @debug.debug_inspect(space_fallback_type(0x2003U), content="SpaceEm")
  @debug.debug_inspect(space_fallback_type(0x202FU), content="SpaceNarrow")
  @debug.debug_inspect(space_fallback_type(0x1680U), content="NotSpace")
  @debug.debug_inspect(is_variation_selector(0xFE0FU), content="true")
  @debug.debug_inspect(is_variation_selector(0x180BU), content="false")
  @debug.debug_inspect(is_default_ignorable(0x00ADU), content="true")
  @debug.debug_inspect(is_default_ignorable(0x41U), content="false")
}

///|
test "unicode arabic joining type" {
  @debug.debug_inspect(arabic_joining_type_raw(0x0628U), content="3")
  @debug.debug_inspect(arabic_joining_type_raw(0x0710U), content="4")
  @debug.debug_inspect(arabic_joining_type(0x064BU), content="7")
  @debug.debug_inspect(arabic_joining_type(0x41U), content="0")
}

///|
test "unicode arabic shaping form" {
  @debug.debug_inspect(arabic_shaping_form(0x0628U, 0), content="Some(65169)")
  @debug.debug_inspect(arabic_shaping_form(0x0628U, 3), content="Some(65167)")
  @debug.debug_inspect(arabic_shaping_form(0x0628U, 9), content="None")
  @debug.debug_inspect(arabic_shaping_form(0x41U, 0), content="None")
}
