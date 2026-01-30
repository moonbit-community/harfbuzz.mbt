test "use machine symbol cluster for other" {
  let categories : Array[UInt] = [use_syllable_machine_ex_O]
  let marks : Array[Bool] = [false]
  let syllables = find_syllables_use(categories, marks)
  inspect(syllables.length(), content="1")
  let syllable_type = syllables[0] & 0x0f
  inspect(syllable_type, content="\{use_syllable_type_symbol_cluster}")
}
