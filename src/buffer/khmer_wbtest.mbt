///|
test "khmer reorder coeng ro and vpre" {
  let buffer = Buffer::new()
  buffer.add_codepoint(10U)
  buffer.add_codepoint(11U)
  buffer.add_codepoint(12U)
  buffer.add_codepoint(13U)
  buffer.add_codepoint(14U)
  let categories : Array[Int] = [
    1,
    khmer_cat_h,
    khmer_cat_ra,
    khmer_cat_vpre,
    1,
  ]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | khmer_syllable_type_consonant
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_khmer_syllables(buffer, categories, syllables)
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  inspect(result, content="[11, 12, 13, 10, 14]")
}
