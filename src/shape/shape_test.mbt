///|
test "shape available shapers" {
  inspect(available_shapers(), content="[\"ot\", \"aat\", \"fallback\"]")
}

///|
test "shape plan selection" {
  let buffer = @buffer.Buffer::new()
  buffer.set_script(@common.script_latin)
  buffer.set_language(@common.Language::from_string("en"))
  buffer.set_direction(@common.direction_ltr)
  let aat = ShapePlan::from_buffer(buffer, shapers=["aat"])
  inspect(aat.shaper, content="aat")
  let plan = ShapePlan::from_buffer(buffer, shapers=["ot"])
  inspect(plan.shaper, content="ot")
  let fallback = ShapePlan::from_buffer(buffer, shapers=["unknown", "fallback"])
  inspect(fallback.shaper, content="fallback")
}
