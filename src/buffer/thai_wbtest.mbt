///|
test "thai preprocess sara am reorder" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_thai)
  buffer.add_codepoint(0x0E14U)
  buffer.add_codepoint(0x0E4BU)
  buffer.add_codepoint(0x0E33U)
  preprocess_thai_sara_am(buffer)
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  inspect(cps, content="[3604, 3661, 3659, 3634]")
}
