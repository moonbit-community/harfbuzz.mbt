///|
test "buffer basics" {
  let buffer = Buffer::new()
  assert_true(buffer.is_empty())
  buffer.add_codepoint(65U)
  buffer.add_codepoint(66U, cluster=10)
  inspect(buffer.len(), content="2")
  let infos = buffer.infos()
  inspect(infos[0].codepoint, content="65")
  inspect(infos[1].cluster, content="10")
}

///|
test "buffer add string" {
  let buffer = Buffer::new()
  buffer.add_string("ab")
  let infos = buffer.infos()
  inspect(buffer.len(), content="2")
  inspect(infos[0].cluster, content="0")
  inspect(infos[1].cluster, content="1")
}

///|
test "buffer properties" {
  let buffer = Buffer::new()
  buffer.set_direction(@common.direction_ltr)
  buffer.set_script(@common.script_latin)
  buffer.set_language(@common.Language::from_string("en"))
  inspect(buffer.get_direction().to_string(), content="ltr")
  inspect(buffer.get_script().to_tag().to_string(), content="Latn")
  inspect(buffer.get_language().to_string(), content="Some(\"en\")")
}
