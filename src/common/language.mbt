///|
/// Language tag (BCP 47), stored in canonical lowercase form.
pub struct Language {
  tag : String
} derive(Eq, Show, ToJson)

///|
/// Invalid language value.
pub let language_invalid : Language = Language::{ tag: "" }

///|
/// Canonicalize an ASCII language tag.
fn canonicalize_language_char(c : Char) -> Char? {
  if c.is_ascii_digit() {
    Some(c)
  } else if c.is_ascii_alphabetic() {
    Some(c.to_ascii_lowercase())
  } else if c == '-' || c == '_' {
    Some('-')
  } else {
    None
  }
}

///|
/// Convert a string to a language value.
pub fn Language::from_string(s : String, len? : Int = -1) -> Language {
  if s is "" || len == 0 {
    return language_invalid
  }
  let max_len = if len < 0 { s.length() } else if len > 63 { 63 } else { len }
  let sb = StringBuilder::new(size_hint=max_len)
  let mut count = 0
  for c in s {
    if count >= max_len {
      break
    }
    match canonicalize_language_char(c) {
      None => break
      Some(mapped) => sb.write_char(mapped)
    }
    count = count + 1
  }
  let tag = sb.to_string()
  if tag is "" {
    language_invalid
  } else {
    Language::{ tag, }
  }
}

///|
/// Return the canonical string, or None for invalid.
pub fn Language::to_string(self : Language) -> String? {
  if self.tag is "" {
    None
  } else {
    Some(self.tag)
  }
}

///|
/// True when the language is valid.
pub fn Language::is_valid(self : Language) -> Bool {
  self.tag != ""
}

///|
/// Check whether `specific` is the same or more specific than `self`.
pub fn Language::matches(self : Language, specific : Language) -> Bool {
  if self.tag == specific.tag {
    return true
  }
  if self.tag is "" || specific.tag is "" {
    return false
  }
  let base = self.tag
  let spec = specific.tag
  if base.length() > spec.length() {
    return false
  }
  if !spec.has_prefix(base[:]) {
    return false
  }
  if base.length() == spec.length() {
    true
  } else {
    spec.get_char(base.length()) == Some('-')
  }
}

///|
/// Access the canonical language tag.
pub fn Language::as_string(self : Language) -> String {
  self.tag
}
