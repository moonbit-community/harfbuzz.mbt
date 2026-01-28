///|
test "tag construction" {
  let tag = Tag::from_chars('A', 'B', 'C', 'D')
  inspect(tag.to_string(), content="ABCD")
  let padded = Tag::from_string("a")
  inspect(padded.to_string(), content="a   ")
  let long = Tag::from_string("abcde")
  inspect(long.to_string(), content="abcd")
}

///|
test "direction parsing and helpers" {
  let dir = Direction::from_string("left-to-right")
  inspect(dir.to_string(), content="ltr")
  assert_true(dir.is_horizontal())
  assert_true(dir.is_forward())
  let rev = dir.reverse()
  inspect(rev.to_string(), content="rtl")
  assert_true(rev.is_backward())
}

///|
test "language canonicalization" {
  let lang = Language::from_string("en-US")
  inspect(lang.to_string(), content="Some(\"en-us\")")
  let base = Language::from_string("en")
  assert_true(base.matches(lang))
  assert_true(!lang.matches(base))
  let zh = Language::from_string("zh_Hant")
  inspect(zh.to_string(), content="Some(\"zh-hant\")")
}

///|
test "script aliases and direction" {
  let latin = Script::from_string("Latn")
  inspect(latin.to_tag().to_string(), content="Latn")
  let hans = Script::from_string("HANS")
  inspect(hans.to_tag().to_string(), content="Hani")
  let inherited = Script::from_iso15924_tag(Tag::from_chars('Q', 'a', 'a', 'i'))
  inspect(inherited.to_tag().to_string(), content="Zinh")
  let arabic = Script::from_string("Arab")
  inspect(arabic.horizontal_direction().to_string(), content="rtl")
}

///|
test "script horizontal direction mapping" {
  inspect(
    script_old_italic.horizontal_direction().to_string(),
    content="invalid",
  )
  inspect(script_tifinagh.horizontal_direction().to_string(), content="invalid")
  inspect(script_adlam.horizontal_direction().to_string(), content="rtl")
  inspect(script_latin.horizontal_direction().to_string(), content="ltr")
}
