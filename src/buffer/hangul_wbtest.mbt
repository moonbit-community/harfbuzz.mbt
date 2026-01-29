///|
test "hangul actions classify jamo" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x1100U)
  buffer.add_codepoint(0x1161U)
  buffer.add_codepoint(0x11A8U)
  buffer.add_codepoint(0xAC00U)
  let actions = hangul_actions(buffer)
  inspect(actions, content="[0, 1, 2, 3]")
}
