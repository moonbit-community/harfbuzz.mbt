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
