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

///|
fn expect_parse_int(result : (Int, Int)?, value : Int, idx : Int) -> Unit raise {
  match result {
    None => fail("expected int parse")
    Some((parsed, next_idx)) => {
      inspect(parsed, content="\{value}")
      inspect(next_idx, content="\{idx}")
    }
  }
}

///|
fn expect_parse_uint(result : (UInt, Int)?, value : UInt, idx : Int) -> Unit raise {
  match result {
    None => fail("expected uint parse")
    Some((parsed, next_idx)) => {
      inspect(parsed, content="\{value}")
      inspect(next_idx, content="\{idx}")
    }
  }
}

///|
fn expect_parse_double(result : (Double, Int)?, thousand : Int, idx : Int) -> Unit raise {
  match result {
    None => fail("expected double parse")
    Some((parsed, next_idx)) => {
      let rounded = (parsed * 1000.0).round().to_int()
      inspect(rounded, content="\{thousand}")
      inspect(next_idx, content="\{idx}")
    }
  }
}

///|
test "number parse int and uint" {
  expect_parse_int(parse_int("123", end=3), 123, 3)
  expect_parse_uint(parse_uint("123", end=3), 123U, 3)
  expect_parse_uint(parse_uint("12F", end=3, whole=true, base=16), 0x12FU, 3)
  let whole_fail = parse_uint("12Fq", end=4, whole=true, base=16)
  inspect(whole_fail is None, content="true")
  expect_parse_uint(parse_uint("12Fq", end=4, base=16), 0x12FU, 3)
  expect_parse_int(parse_int("-123", end=4), -123, 4)
  expect_parse_uint(parse_uint("123V", end=4), 123U, 3)
}

///|
test "number parse double" {
  expect_parse_double(parse_double(".123", end=4), 123, 4)
  expect_parse_double(parse_double("0.123", end=5, whole=true), 123, 5)
  expect_parse_double(parse_double("0.123e0", end=7, whole=true), 123, 7)
  expect_parse_double(parse_double("123e-3", end=6, whole=true), 123, 6)
  expect_parse_double(parse_double(".000123e+3", end=10, whole=true), 123, 10)
  expect_parse_double(parse_double("-.000000123e6", end=13, whole=true), -123, 13)
  expect_parse_double(parse_double("-1.23E-1", end=8, whole=true), -123, 8)
}
