// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
