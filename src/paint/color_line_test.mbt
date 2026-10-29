///|
test "gradient extension keeps its JSON key" {
  let line : @paint.ColorLine = { extend_mode: 2, stops: [], }
  assert_eq(Json(line), { "extend": 2, "stops": [] })
}
