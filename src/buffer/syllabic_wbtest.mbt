test "syllabic insert dotted circle for leading mark" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x0301U)
  let inserted = insert_dotted_circle_for_broken_syllables(buffer)
  inspect(inserted, content="true")
  let infos = buffer.infos()
  inspect(infos.length(), content="2")
  inspect(infos[0].codepoint, content="9676")
  inspect(infos[1].codepoint, content="769")
}

test "syllabic no dotted circle after base" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x0301U)
  let inserted = insert_dotted_circle_for_broken_syllables(buffer)
  inspect(inserted, content="false")
  let infos = buffer.infos()
  inspect(infos.length(), content="2")
  inspect(infos[0].codepoint, content="65")
  inspect(infos[1].codepoint, content="769")
}

test "syllabic insert dotted circle after separator" {
  let buffer = Buffer::new()
  buffer.add_codepoint(0x41U)
  buffer.add_codepoint(0x20U)
  buffer.add_codepoint(0x0301U)
  let inserted = insert_dotted_circle_for_broken_syllables(buffer)
  inspect(inserted, content="true")
  let infos = buffer.infos()
  inspect(infos.length(), content="4")
  inspect(infos[2].codepoint, content="9676")
  inspect(infos[3].codepoint, content="769")
}
