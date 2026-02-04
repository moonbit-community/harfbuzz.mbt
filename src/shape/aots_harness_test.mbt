///|
fn serialize_glyphs(
  infos : ArrayView[@buffer.GlyphInfo],
  positions : ArrayView[@buffer.GlyphPosition],
  no_positions : Bool,
  no_advances : Bool,
) -> String {
  let sb = StringBuilder::new()
  let mut x = 0
  let mut y = 0
  let len = infos.length()
  if len == 0 {
    return "[]"
  }
  for i in 0..<len {
    if i == 0 {
      sb.write_char('[')
    } else {
      sb.write_char('|')
    }
    sb.write_object(infos[i].codepoint)
    if !no_positions {
      let pos = positions[i]
      let px = x + pos.x_offset
      let py = y + pos.y_offset
      if px != 0 || py != 0 {
        sb.write_char('@')
        sb.write_object(px)
        sb.write_char(',')
        sb.write_object(py)
      }
      if !no_advances {
        sb.write_char('+')
        sb.write_object(pos.x_advance)
        if pos.y_advance != 0 {
          sb.write_char(',')
          sb.write_object(pos.y_advance)
        }
      } else {
        x = x + pos.x_advance
        y = y + pos.y_advance
      }
    }
    if i == len - 1 {
      sb.write_char(']')
    }
  }
  sb.to_string()
}

///|
fn run_aots_case(case : AotsTestCase) -> Result[String, String] {
  let bytes = match aots_font_bytes(case.font) {
    None => return Err("missing font: \{case.font}")
    Some(value) => value
  }
  let face = @face.Face::from_bytes(bytes)
  let font = @font.Font::new(face)
  let buffer = @buffer.Buffer::new()
  for cp in case.input {
    buffer.add_codepoint(cp)
  }
  let feature = @common.Tag::from_chars('t', 'e', 's', 't')
  buffer.set_gsub_features([feature])
  buffer.set_gpos_features([feature])
  match buffer.shape_ot(font) {
    Err(err) => return Err("shape error for \{case.font}: \{err}")
    Ok(_) => ()
  }
  Ok(serialize_glyphs(
    buffer.infos(),
    buffer.positions(),
    case.no_positions,
    case.no_advances,
  ))
}

///|
test "shape aots fixtures" {
  let mut skipped = 0
  let mut mismatched = 0
  for case in aots_test_cases {
    match run_aots_case(case) {
      Err(_) => {
        skipped = skipped + 1
      }
      Ok(actual) =>
        if actual != case.expected {
          mismatched = mismatched + 1
        }
    }
  }
  inspect((aots_skipped_cases, skipped, mismatched), content="(3, 0, 0)")
}
