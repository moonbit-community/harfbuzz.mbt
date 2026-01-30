///|
test "myanmar reorder prebase and left matra" {
  let buffer = Buffer::new()
  buffer.add_codepoint(10U)
  buffer.add_codepoint(11U)
  buffer.add_codepoint(12U)
  buffer.add_codepoint(13U)
  let categories : Array[Int] = [
    myanmar_cat_c,
    myanmar_cat_mr,
    myanmar_cat_vpre,
    myanmar_cat_vblw,
  ]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | myanmar_syllable_type_consonant
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_myanmar_syllables(buffer, categories, syllables)
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  inspect(result, content="[12, 11, 10, 13]")
}
