///|
test "vowel constraints insert dotted circle for devanagari pair" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0905U)
  buffer.add_codepoint(0x093EU)
  preprocess_vowel_constraints(buffer)
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  inspect(cps, content="[2309, 9676, 2366]")
}

///|
test "vowel constraints insert dotted circle after devanagari ra virama" {
  let buffer = Buffer::new()
  buffer.set_script(@common.script_devanagari)
  buffer.add_codepoint(0x0930U)
  buffer.add_codepoint(0x094DU)
  buffer.add_codepoint(0x0907U)
  preprocess_vowel_constraints(buffer)
  let cps : Array[UInt] = []
  for info in buffer.infos() {
    cps.push(info.codepoint)
  }
  inspect(cps, content="[2352, 2381, 9676, 2311]")
}
