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
/// Selectable shaper names.
fn default_shapers() -> Array[String] {
  ["ot", "fallback"]
}

///|
/// Return the names of available shapers.
pub fn available_shapers() -> Array[String] {
  ["ot", "aat", "fallback"]
}

let shape_plan_cache : Map[String, ShapePlan] = {}

fn shape_plan_key(
  buffer : @buffer.Buffer,
  shapers : Array[String],
) -> String {
  let sb = StringBuilder::new()
  sb.write_view(shapers.join(","))
  sb.write_char('|')
  sb.write_view(buffer.get_direction().to_string())
  sb.write_char('|')
  sb.write_view(buffer.get_script().to_tag().to_string())
  sb.write_char('|')
  match buffer.get_language().to_string() {
    None => sb.write_view("und")
    Some(value) => sb.write_view(value)
  }
  sb.to_string()
}

///|
/// Shape plan for a buffer.
pub struct ShapePlan {
  shaper : String
  direction : @common.Direction
  script : @common.Script
  language : @common.Language
}

///|
/// Build a shape plan from buffer properties.
pub fn ShapePlan::from_buffer(
  buffer : @buffer.Buffer,
  shapers? : Array[String] = [],
) -> ShapePlan {
  let names = if shapers.is_empty() { default_shapers() } else { shapers }
  let mut selected = "fallback"
  for name in names {
    if name == "ot" || name == "fallback" || name == "aat" {
      selected = name
      break
    }
  }
  ShapePlan::{
    shaper: selected,
    direction: buffer.get_direction(),
    script: buffer.get_script(),
    language: buffer.get_language(),
  }
}

///|
/// Apply shaping using the plan's shaper.
pub fn ShapePlan::shape(
  self : ShapePlan,
  font : @font.Font,
  buffer : @buffer.Buffer,
) -> Result[Unit, @buffer.ShapeError] {
  match self.shaper {
    "aat" => @aat_shape.shape(font, buffer)
    "ot" => @ot_shape.shape(font, buffer)
    "fallback" => buffer.shape_basic(font)
    _ => buffer.shape_basic(font)
  }
}

///|
/// Shape a buffer using the default shaper list.
pub fn shape(
  font : @font.Font,
  buffer : @buffer.Buffer,
  shapers? : Array[String] = [],
) -> Result[Unit, @buffer.ShapeError] {
  buffer.guess_segment_properties()
  let names = if shapers.is_empty() { default_shapers() } else { shapers }
  let key = shape_plan_key(buffer, names)
  let plan = match shape_plan_cache.get(key) {
    None => {
      let next = ShapePlan::from_buffer(buffer, shapers=names)
      shape_plan_cache[key] = next
      next
    }
    Some(value) => value
  }
  plan.shape(font, buffer)
}
