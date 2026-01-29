///|
test "arabic joining actions pair" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x0628U)
  let actions = arabic_joining_actions(buffer)
  inspect(actions, content="[6, 1]")
}

///|
test "arabic joining actions with transparent mark" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0628U)
  buffer.add_codepoint(0x064BU)
  buffer.add_codepoint(0x0628U)
  let actions = arabic_joining_actions(buffer)
  inspect(actions, content="[6, 7, 1]")
}
