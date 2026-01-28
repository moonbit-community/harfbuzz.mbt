///|
/// Script tag (ISO 15924), stored as a Tag.
pub struct Script {
  tag : Tag
} derive(Eq, Show, ToJson)

///|
fn canonicalize_script_tag(tag : Tag) -> Tag {
  let (b1, b2, b3, b4) = tag.bytes()
  let u1 = b1.to_uint()
  let u2 = b2.to_uint()
  let u3 = b3.to_uint()
  let u4 = b4.to_uint()
  Tag::from_bytes(
    (u1 & 0xdfU).to_byte(),
    ((u2 & 0xdfU) | 0x20U).to_byte(),
    ((u3 & 0xdfU) | 0x20U).to_byte(),
    ((u4 & 0xdfU) | 0x20U).to_byte(),
  )
}

///|
fn byte_is_ascii_upper(b : Byte) -> Bool {
  let v = b.to_int()
  v >= 0x41 && v <= 0x5a
}

///|
fn byte_is_ascii_lower(b : Byte) -> Bool {
  let v = b.to_int()
  v >= 0x61 && v <= 0x7a
}

///|
fn looks_like_script_tag(tag : Tag) -> Bool {
  let (b1, b2, b3, b4) = tag.bytes()
  byte_is_ascii_upper(b1) &&
  byte_is_ascii_lower(b2) &&
  byte_is_ascii_lower(b3) &&
  byte_is_ascii_lower(b4)
}

///|
/// Convert an ISO 15924 tag to a script.
pub fn Script::from_iso15924_tag(tag : Tag) -> Script {
  if tag == tag_none {
    return script_invalid
  }
  let canonical = canonicalize_script_tag(tag)
  if canonical == Tag::from_chars('Q', 'a', 'a', 'i') {
    return script_inherited
  }
  if canonical == Tag::from_chars('Q', 'a', 'a', 'c') {
    return script_coptic
  }
  if canonical == Tag::from_chars('A', 'r', 'a', 'n') {
    return script_arabic
  }
  if canonical == Tag::from_chars('C', 'y', 'r', 's') {
    return script_cyrillic
  }
  if canonical == Tag::from_chars('G', 'e', 'o', 'k') {
    return script_georgian
  }
  if canonical == Tag::from_chars('H', 'a', 'n', 's') {
    return script_han
  }
  if canonical == Tag::from_chars('H', 'a', 'n', 't') {
    return script_han
  }
  if canonical == Tag::from_chars('J', 'a', 'm', 'o') {
    return script_hangul
  }
  if canonical == Tag::from_chars('L', 'a', 't', 'f') {
    return script_latin
  }
  if canonical == Tag::from_chars('L', 'a', 't', 'g') {
    return script_latin
  }
  if canonical == Tag::from_chars('S', 'y', 'r', 'e') {
    return script_syriac
  }
  if canonical == Tag::from_chars('S', 'y', 'r', 'j') {
    return script_syriac
  }
  if canonical == Tag::from_chars('S', 'y', 'r', 'n') {
    return script_syriac
  }
  if looks_like_script_tag(canonical) {
    Script::{ tag: canonical }
  } else {
    script_unknown
  }
}

///|
/// Convert an ISO 15924 string to a script.
pub fn Script::from_string(s : String, len? : Int = -1) -> Script {
  Script::from_iso15924_tag(Tag::from_string(s, len~))
}

///|
/// Convert a script to its ISO 15924 tag.
pub fn Script::to_iso15924_tag(self : Script) -> Tag {
  self.tag
}

///|
fn is_rtl_tag(tag : Tag) -> Bool {
  tag == script_arabic.tag ||
  tag == script_hebrew.tag ||
  tag == script_syriac.tag ||
  tag == script_thaana.tag ||
  tag == script_cypriot.tag ||
  tag == script_kharoshthi.tag ||
  tag == script_phoenician.tag ||
  tag == script_nko.tag ||
  tag == script_lydian.tag ||
  tag == script_avestan.tag ||
  tag == script_imperial_aramaic.tag ||
  tag == script_inscriptional_pahlavi.tag ||
  tag == script_inscriptional_parthian.tag ||
  tag == script_old_south_arabian.tag ||
  tag == script_old_turkic.tag ||
  tag == script_samaritan.tag ||
  tag == script_mandaic.tag ||
  tag == script_meroitic_cursive.tag ||
  tag == script_meroitic_hieroglyphs.tag ||
  tag == script_manichaean.tag ||
  tag == script_mende_kikakui.tag ||
  tag == script_nabataean.tag ||
  tag == script_old_north_arabian.tag ||
  tag == script_palmyrene.tag ||
  tag == script_psalter_pahlavi.tag ||
  tag == script_hatran.tag ||
  tag == script_adlam.tag ||
  tag == script_hanifi_rohingya.tag ||
  tag == script_old_sogdian.tag ||
  tag == script_sogdian.tag ||
  tag == script_elymaic.tag ||
  tag == script_chorasmian.tag ||
  tag == script_yezidi.tag ||
  tag == script_old_uyghur.tag ||
  tag == script_garay.tag ||
  tag == script_sidetic.tag
}

///|
fn is_horizontal_ambiguous_tag(tag : Tag) -> Bool {
  tag == script_old_hungarian.tag ||
  tag == script_old_italic.tag ||
  tag == script_runic.tag ||
  tag == script_tifinagh.tag
}

///|
/// Fetch the horizontal direction for the script.
pub fn Script::horizontal_direction(self : Script) -> Direction {
  let tag = self.tag
  if is_rtl_tag(tag) {
    direction_rtl
  } else if is_horizontal_ambiguous_tag(tag) {
    direction_invalid
  } else {
    direction_ltr
  }
}

///|
/// Access the underlying tag.
pub fn Script::to_tag(self : Script) -> Tag {
  self.tag
}
