///|
test "indic reorder by positions with joiner attach" {
  let buffer = Buffer::new()
  buffer.add_codepoint(10U)
  buffer.add_codepoint(11U)
  buffer.add_codepoint(12U)
  let categories : Array[Int] = [
    1,
    indic_cat_n,
    1,
  ]
  let positions : Array[Int] = [
    4,
    6,
    2,
  ]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | indic_syllable_type_consonant_syllable
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_indic_syllables(
    buffer,
    @common.script_devanagari,
    categories,
    positions,
    syllables,
    false,
  )
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  inspect(result, content="[10, 11, 12]")
}
