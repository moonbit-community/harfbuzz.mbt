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

///|
test "codepoint set basics" {
  let set = CodepointSet::new()
  inspect(set.is_empty(), content="true")
  assert_true(set.add_range(2U, 4U))
  set.add(10U)
  set.del(3U)
  set.del_range(10U, 11U)
  inspect(set.to_sorted_array(), content="[2, 4]")
  inspect(set.population(), content="2")
  inspect(set.get_min(), content="2")
  inspect(set.get_max(), content="4")
}

///|
test "codepoint set next and ranges" {
  let set = CodepointSet::new()
  assert_true(set.add_range(1U, 3U))
  set.add(5U)
  assert_true(set.add_range(7U, 8U))
  inspect(set.next(), content="Some(1)")
  inspect(set.next(after=2U), content="Some(3)")
  inspect(set.previous(before=7U), content="Some(5)")
  inspect(set.next_range(), content="Some((1, 3))")
  inspect(set.next_range(start=4U), content="Some((5, 5))")
  inspect(set.previous_range(end=8U), content="Some((7, 8))")
  inspect(set.intersects(2U, 4U), content="true")
  inspect(set.intersects(6U, 6U), content="false")
}

///|
test "codepoint map and bimap" {
  let map = CodepointMap::new()
  map.set(1U, 5U)
  inspect(map.get(1U), content="5")
  inspect(map.get(2U), content="\{map_value_invalid}")
  map.del(1U)
  inspect(map.get(1U), content="\{map_value_invalid}")

  let bimap = CodepointBiMap::new()
  bimap.set(3U, 9U)
  inspect(bimap.get(3U), content="9")
  inspect(bimap.backward(9U), content="3")
  bimap.del(3U)
  inspect(bimap.get(3U), content="\{map_value_invalid}")
}

///|
test "codepoint map equality" {
  let map_a = CodepointMap::new()
  map_a.set(1U, 2U)
  let map_b = map_a.copy()
  inspect(map_a.is_equal(map_b), content="true")
  map_b.set(3U, 4U)
  inspect(map_a.is_equal(map_b), content="false")
}

///|
test "codepoint incremental bimap" {
  let bimap = CodepointIncBiMap::new()
  inspect(bimap.add(10U), content="0")
  inspect(bimap.add(20U), content="1")
  inspect(bimap.skip(count=2), content="2")
  inspect(bimap.add(30U), content="4")
  inspect(bimap.backward(0U), content="10")
  inspect(bimap.backward(1U), content="20")
  inspect(bimap.backward(2U), content="\{map_value_invalid}")
  inspect(bimap.get_next_value(), content="5")
  inspect(bimap.identity(3), content="true")
  inspect(bimap.get(0U), content="0")
  inspect(bimap.get(2U), content="2")
  bimap.clear()
  ignore(bimap.add(5U))
  ignore(bimap.add(2U))
  ignore(bimap.add(9U))
  bimap.sort()
  inspect(bimap.get(2U), content="0")
  inspect(bimap.get(5U), content="1")
  inspect(bimap.get(9U), content="2")
}
