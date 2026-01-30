///|
test "use reorder repha before post-base" {
  let buffer = Buffer::new()
  buffer.add_codepoint(10U)
  buffer.add_codepoint(11U)
  buffer.add_codepoint(12U)
  let categories : Array[Int] = [
    use_cat_r,
    1,
    use_cat_vblw,
  ]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | use_syllable_type_standard_cluster
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_use_syllables(buffer, categories, syllables)
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  inspect(result, content="[11, 10, 12]")
}

///|
test "use reorder vpre after halant" {
  let buffer = Buffer::new()
  buffer.add_codepoint(20U)
  buffer.add_codepoint(21U)
  buffer.add_codepoint(22U)
  buffer.add_codepoint(23U)
  let categories : Array[Int] = [
    1,
    use_cat_h,
    2,
    use_cat_vpre,
  ]
  let syllables : Array[Int] = []
  let syllable = (1 << 4) | use_syllable_type_standard_cluster
  for _ in 0..<categories.length() {
    syllables.push(syllable)
  }
  reorder_use_syllables(buffer, categories, syllables)
  let result : Array[UInt] = []
  for info in buffer.infos() {
    result.push(info.codepoint)
  }
  inspect(result, content="[20, 21, 23, 22]")
}

///|
test "use feature masks apply arabic isol" {
  let categories : Array[Int] = [1]
  let syllables : Array[Int] = [(1 << 4) | use_syllable_type_standard_cluster]
  let masks = build_use_feature_masks(
    categories,
    syllables,
    arabic_actions=[arabic_action_isol],
  )
  let isol_bit = 1U << use_feature_isol
  inspect((masks[0] & isol_bit) != 0U, content="true")
}
