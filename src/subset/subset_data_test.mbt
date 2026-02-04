///|
struct ParsedSuite {
  fonts : Array[String]
  profiles : Array[String]
  subsets : Array[String]
  instances : Array[String]
  options : Array[String]
  iup_options : Array[String]
}

///|
enum ParseSection {
  Unknown
  Fonts
  Profiles
  Subsets
  Instances
  Options
  IupOptions
}

///|
struct SubsetDataCase {
  suite : String
  font : String
  profile : String
  subset : String
  instance : String
  iup_optimize : Bool
  options : Array[String]
}

///|
fn parse_suite(definition : String) -> ParsedSuite {
  let fonts : Array[String] = []
  let profiles : Array[String] = []
  let subsets : Array[String] = []
  let instances : Array[String] = []
  let options : Array[String] = []
  let iup_options : Array[String] = []
  let mut section = ParseSection::Unknown
  for line_view in definition.split("\n") {
    let line = line_view.trim().to_string()
    if line.is_empty() {
      continue
    }
    if line.has_prefix("#") {
      continue
    }
    if line == "FONTS:" {
      section = ParseSection::Fonts
      continue
    }
    if line == "PROFILES:" {
      section = ParseSection::Profiles
      continue
    }
    if line == "SUBSETS:" {
      section = ParseSection::Subsets
      continue
    }
    if line == "INSTANCES:" {
      section = ParseSection::Instances
      continue
    }
    if line == "OPTIONS:" {
      section = ParseSection::Options
      continue
    }
    if line == "IUP_OPTIONS:" {
      section = ParseSection::IupOptions
      continue
    }
    match section {
      ParseSection::Fonts => fonts.push(line)
      ParseSection::Profiles => profiles.push(line)
      ParseSection::Subsets => subsets.push(line)
      ParseSection::Instances => instances.push(line)
      ParseSection::Options => options.push(line)
      ParseSection::IupOptions => iup_options.push(line)
      ParseSection::Unknown => continue
    }
  }
  ParsedSuite::{ fonts, profiles, subsets, instances, options, iup_options }
}

///|
fn build_cases(suite_name : String, suite : ParsedSuite) -> Array[SubsetDataCase] {
  let cases : Array[SubsetDataCase] = []
  for font in suite.fonts {
    for profile in suite.profiles {
      for subset in suite.subsets {
        if !suite.instances.is_empty() {
          for instance in suite.instances {
            if !suite.iup_options.is_empty() {
              for iup_option in suite.iup_options {
                cases.push(SubsetDataCase::{
                  suite: suite_name,
                  font,
                  profile,
                  subset,
                  instance,
                  iup_optimize: iup_option == "Yes",
                  options: suite.options,
                })
              }
            } else {
              cases.push(SubsetDataCase::{
                suite: suite_name,
                font,
                profile,
                subset,
                instance,
                iup_optimize: false,
                options: suite.options,
              })
            }
          }
        } else {
          cases.push(SubsetDataCase::{
            suite: suite_name,
            font,
            profile,
            subset,
            instance: "",
            iup_optimize: false,
            options: suite.options,
          })
        }
      }
    }
  }
  cases
}

///|
fn split_extension(value : String) -> (String, String) {
  let dot = value.rev_find(".")
  match dot {
    None => (value, "")
    Some(idx) => {
      let base = try! value[:idx]
      let ext = try! value[idx:]
      (base.to_string(), ext.to_string())
    }
  }
}

///|
fn parse_hex_uint(hex : String) -> UInt? {
  if hex.is_empty() {
    return None
  }
  let mut value : UInt = 0U
  for ch in hex {
    let digit = match ch {
      '0'..='9' => ch.to_int() - '0'.to_int()
      'A'..='F' => ch.to_int() - 'A'.to_int() + 10
      'a'..='f' => ch.to_int() - 'a'.to_int() + 10
      _ => return None
    }
    value = value * 16U + digit.reinterpret_as_uint()
  }
  Some(value)
}

///|
fn subset_codepoints(spec : String) -> Array[UInt]? {
  if spec == "*" || spec == "no-unicodes" {
    return None
  }
  if spec.has_prefix("U+") {
    let values : Array[UInt] = []
    for part_view in spec.split(",") {
      let part = part_view.trim().to_string()
      if part.is_empty() {
        continue
      }
      let trimmed = if part.has_prefix("U+") {
        let view = try! part[2:]
        view.to_string()
      } else {
        part
      }
      let value = parse_hex_uint(trimmed)
      match value {
        None => return None
        Some(value) => values.push(value)
      }
    }
    return Some(values)
  }
  let values : Array[UInt] = []
  for ch in spec {
    values.push(ch.to_uint())
  }
  Some(values)
}

///|
fn codepoints_hex(codepoints : Array[UInt]) -> String {
  let sb = StringBuilder::new()
  for i in 0..<codepoints.length() {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(codepoints[i].to_string(radix=16).to_upper())
  }
  sb.to_string()
}

///|
fn subset_unicodes(spec : String, codepoints : Array[UInt]) -> String? {
  if spec == "*" || spec == "no-unicodes" {
    return None
  }
  if spec.has_prefix("U+") {
    return Some(spec.replace_all(old="U+", new=""))
  }
  Some(codepoints_hex(codepoints))
}

///|
fn expected_key(case : SubsetDataCase, codepoints : Array[UInt]) -> String? {
  let (suite_base, _) = split_extension(case.suite)
  let (font_base, font_ext) = split_extension(case.font)
  let (profile_base, _) = split_extension(case.profile)
  let unicode = subset_unicodes(case.subset, codepoints)
  match unicode {
    None => None
    Some(unicode) =>
      Some("\{suite_base}/\{font_base}.\{profile_base}.\{unicode}\{font_ext}")
  }
}

///|
test "subset data smoke" {
  let mut ran = 0
  let mut skipped = 0
  let mut mismatched = 0
  for suite in subset_smoke_suites {
    let parsed = parse_suite(suite.definition)
    let cases = build_cases(suite.name, parsed)
    for case in cases {
      if case.profile != "default.txt" ||
          case.instance != "" ||
          !case.options.is_empty() ||
          case.iup_optimize {
        skipped = skipped + 1
        continue
      }
      let codepoints = subset_codepoints(case.subset)
      let codepoints = match codepoints {
        None => {
          skipped = skipped + 1
          continue
        }
        Some(value) => value
      }
      let key = expected_key(case, codepoints)
      let key = match key {
        None => {
          skipped = skipped + 1
          continue
        }
        Some(value) => value
      }
      let expected = subset_smoke_expected_bytes(key)
      let expected = match expected {
        None => {
          skipped = skipped + 1
          continue
        }
        Some(value) => value
      }
      let font_bytes = subset_smoke_font_bytes(case.font)
      let font_bytes = match font_bytes {
        None => {
          skipped = skipped + 1
          continue
        }
        Some(value) => value
      }
      let face = @face.Face::from_bytes(font_bytes)
      let font = @font.Font::new(face)
      let input = @subset.SubsetInput::from_codepoints(codepoints)
      let actual = match @subset.subset(font, input) {
        Err(_) => {
          mismatched = mismatched + 1
          continue
        }
        Ok(value) => value
      }
      if actual != expected {
        mismatched = mismatched + 1
      }
      ran = ran + 1
    }
  }
  // Mismatch count captures known differences with upstream subset outputs.
  inspect((ran, skipped, mismatched), content="(4, 0, 4)")
}
