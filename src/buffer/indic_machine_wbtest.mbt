test "indic machine non-indic cluster for other" {
  let categories : Array[UInt] = [0U]
  let syllables = find_syllables_indic(categories)
  inspect(syllables.length(), content="1")
  let syllable_type = syllables[0] & 0x0f
  inspect(syllable_type, content="\{indic_syllable_type_non_cluster}")
}
