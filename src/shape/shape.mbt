///|
/// Selectable shaper names.
fn default_shapers() -> Array[String] {
  ["ot", "fallback"]
}

///|
/// Return the names of available shapers.
pub fn available_shapers() -> Array[String] {
  ["aat", "ot", "fallback"]
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
  let plan = ShapePlan::from_buffer(buffer, shapers~)
  plan.shape(font, buffer)
}
