///|
test "unicode general category and combining class" {
  inspect(general_category(0x41U), content="9")
  inspect(general_category(0x20U), content="29")
  inspect(combining_class(0x0301U), content="230")
  inspect(is_mark(0x0301U), content="true")
  inspect(is_mark(0x41U), content="false")
}

///|
test "unicode modified combining class" {
  inspect(modified_combining_class(0x05B0U), content="22")
  inspect(modified_combining_class(0x1A60U), content="254")
  inspect(modified_combining_class(0x0F39U), content="127")
}

///|
test "unicode script and mirroring" {
  inspect(script(0x41U).to_tag().to_string(), content="Latn")
  inspect(mirroring(0x28U), content="41")
  inspect(mirroring(0x29U), content="40")
}

///|
test "unicode compose and decompose" {
  inspect(compose(0x41U, 0x0301U), content="Some(193)")
  inspect(decompose(0x00C1U), content="Some((65, 769))")
  inspect(decompose(0xAC00U), content="Some((4352, 4449))")
}

///|
test "unicode emoji extended pictographic" {
  inspect(is_extended_pictographic(0x1F600U), content="true")
  inspect(is_extended_pictographic(0x41U), content="false")
}

///|
test "unicode emoji properties" {
  inspect(is_emoji(0x1F600U), content="true")
  inspect(is_emoji(0x41U), content="false")
  inspect(is_emoji_presentation(0x1F600U), content="true")
  inspect(is_emoji_presentation(0x263AU), content="false")
  inspect(is_emoji_modifier(0x1F3FBU), content="true")
  inspect(is_emoji_modifier(0x1F600U), content="false")
  inspect(is_emoji_modifier_base(0x1F44DU), content="true")
  inspect(is_emoji_modifier_base(0x41U), content="false")
  inspect(is_emoji_component(0x200DU), content="true")
  inspect(is_emoji_component(0x41U), content="false")
}

///|
test "unicode space fallback and ignorable helpers" {
  inspect(space_fallback_type(0x2003U), content="SpaceEm")
  inspect(space_fallback_type(0x202FU), content="SpaceNarrow")
  inspect(space_fallback_type(0x1680U), content="NotSpace")
  inspect(is_variation_selector(0xFE0FU), content="true")
  inspect(is_variation_selector(0x180BU), content="false")
  inspect(is_default_ignorable(0x00ADU), content="true")
  inspect(is_default_ignorable(0x41U), content="false")
}

///|
test "unicode arabic joining type" {
  inspect(arabic_joining_type_raw(0x0628U), content="3")
  inspect(arabic_joining_type_raw(0x0710U), content="4")
  inspect(arabic_joining_type(0x064BU), content="7")
  inspect(arabic_joining_type(0x41U), content="0")
}

///|
test "unicode arabic shaping form" {
  inspect(arabic_shaping_form(0x0628U, 0), content="Some(65169)")
  inspect(arabic_shaping_form(0x0628U, 3), content="Some(65167)")
  inspect(arabic_shaping_form(0x0628U, 9), content="None")
  inspect(arabic_shaping_form(0x41U, 0), content="None")
}
