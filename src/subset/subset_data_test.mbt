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
fn expected_unicode_label(spec : String, codepoints : Array[UInt]) -> String {
  if spec == "*" {
    return "all"
  }
  if spec == "no-unicodes" {
    return "no-unicodes"
  }
  if spec.has_prefix("U+") {
    return spec.replace_all(old="U+", new="")
  }
  codepoints_hex(codepoints)
}

fn instance_suffix(instance : String, iup_optimize : Bool) -> String {
  if instance.is_empty() {
    return ""
  }
  let replaced = instance.replace_all(old=":", new="-")
  let mut count = 0
  let sb = StringBuilder::new()
  sb.write_char('.')
  for part_view in replaced.split(",") {
    if count >= 6 {
      break
    }
    if count > 0 {
      sb.write_char(',')
    }
    sb.write_string(part_view.to_string())
    count = count + 1
  }
  if iup_optimize {
    sb.write_string(".iup_optimize")
  }
  sb.to_string()
}

///|
fn expected_key(case : SubsetDataCase, codepoints : Array[UInt]) -> String {
  let (suite_base, _) = split_extension(case.suite)
  let (font_base, font_ext) = split_extension(case.font)
  let (profile_base, _) = split_extension(case.profile)
  let unicode = expected_unicode_label(case.subset, codepoints)
  let suffix = instance_suffix(case.instance, case.iup_optimize)
  "\{suite_base}/\{font_base}.\{profile_base}.\{unicode}\{suffix}\{font_ext}"
}

fn read_u16_dbg(data : BytesView, offset : Int) -> Int? {
  if offset < 0 || offset + 2 > data.length() {
    return None
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  Some((b0 << 8) | b1)
}

fn read_u32_dbg(data : BytesView, offset : Int) -> Int? {
  if offset < 0 || offset + 4 > data.length() {
    return None
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  let b2 = data[offset + 2].to_int()
  let b3 = data[offset + 3].to_int()
  Some((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

fn read_tag_dbg(data : BytesView, offset : Int) -> String? {
  if offset < 0 || offset + 4 > data.length() {
    return None
  }
  let sb = StringBuilder::new()
  for i in 0..<4 {
    sb.write_char(data[offset + i].to_int().unsafe_to_char())
  }
  Some(sb.to_string())
}

fn table_slice(data : Bytes, tag : String) -> Bytes? {
  let num_tables = read_u16_dbg(data[:], 4)
  match num_tables {
    None => None
    Some(num_tables) => {
      for i in 0..<num_tables {
        let base = 12 + i * 16
        let rec_tag = read_tag_dbg(data[:], base)
        let offset = read_u32_dbg(data[:], base + 8)
        let length = read_u32_dbg(data[:], base + 12)
        match (rec_tag, offset, length) {
          (Some(rec_tag), Some(offset), Some(length)) =>
            if rec_tag == tag && offset >= 0 && length >= 0 &&
               offset + length <= data.length() {
              return Some(data[offset:offset + length].to_bytes())
            }
          _ => ()
        }
      }
      None
    }
  }
}

fn dump_table_diff(expected : Bytes, actual : Bytes) -> Unit {
  let num_tables = read_u16_dbg(expected[:], 4)
  match num_tables {
    None => ()
    Some(num_tables) => {
      for i in 0..<num_tables {
        let base = 12 + i * 16
        let tag = read_tag_dbg(expected[:], base)
        match tag {
          None => ()
          Some(tag) => {
            let exp = table_slice(expected, tag)
            let act = table_slice(actual, tag)
            match (exp, act) {
              (Some(exp), Some(act)) =>
                if exp != act {
                  println("  table diff \{tag} len exp=\{exp.length()} act=\{act.length()}")
                }
              (Some(exp), None) =>
                println("  table missing \{tag} exp len=\{exp.length()}")
              (None, Some(act)) =>
                println("  table extra \{tag} act len=\{act.length()}")
              _ => ()
            }
          }
        }
      }
    }
  }
}

fn table_tags_string(data : Bytes) -> String {
  let num_tables = read_u16_dbg(data[:], 4)
  let tags : Array[String] = []
  match num_tables {
    None => ()
    Some(num_tables) => {
      for i in 0..<num_tables {
        let base = 12 + i * 16
        let tag = read_tag_dbg(data[:], base)
        match tag {
          None => ()
          Some(tag) => tags.push(tag)
        }
      }
    }
  }
  tags.sort()
  tags.join(",")
}

fn table_diff_tags(expected : Bytes, actual : Bytes) -> String {
  let num_tables = read_u16_dbg(expected[:], 4)
  let diffs : Array[String] = []
  match num_tables {
    None => ()
    Some(num_tables) => {
      for i in 0..<num_tables {
        let base = 12 + i * 16
        let tag = read_tag_dbg(expected[:], base)
        match tag {
          None => ()
          Some(tag) => {
            let exp = table_slice(expected, tag)
            let act = table_slice(actual, tag)
            match (exp, act) {
              (Some(exp), Some(act)) =>
                if exp != act {
                  diffs.push(tag)
                }
              (Some(_), None) => diffs.push(tag)
              (None, Some(_)) => diffs.push(tag)
              _ => ()
            }
          }
        }
      }
    }
  }
  diffs.sort()
  diffs.join(",")
}

fn cmap_summary(data : Bytes) -> String {
  let cmap = table_slice(data, "cmap")
  match cmap {
    None => "none"
    Some(cmap) => {
      let view = cmap[:]
      let num_tables = read_u16_dbg(view, 2)
      let entries : Array[String] = []
      match num_tables {
        None => ()
        Some(num_tables) => {
          for i in 0..<num_tables {
            let rec_base = 4 + i * 8
            let platform = read_u16_dbg(view, rec_base)
            let encoding = read_u16_dbg(view, rec_base + 2)
            let offset = read_u32_dbg(view, rec_base + 4)
            match (platform, encoding, offset) {
              (Some(platform), Some(encoding), Some(offset)) => {
                let format = read_u16_dbg(view, offset)
                match format {
                  None => ()
                  Some(format) => {
                    entries.push("\{platform}/\{encoding}:\{format}")
                  }
                }
              }
              _ => ()
            }
          }
        }
      }
      entries.sort()
      entries.join(",")
    }
  }
}

fn cmap_record_order(data : Bytes) -> String {
  let cmap = table_slice(data, "cmap")
  match cmap {
    None => "none"
    Some(cmap) => {
      let view = cmap[:]
      let num_tables = read_u16_dbg(view, 2)
      let entries : Array[String] = []
      match num_tables {
        None => ()
        Some(num_tables) => {
          for i in 0..<num_tables {
            let rec_base = 4 + i * 8
            let platform = read_u16_dbg(view, rec_base)
            let encoding = read_u16_dbg(view, rec_base + 2)
            let offset = read_u32_dbg(view, rec_base + 4)
            match (platform, encoding, offset) {
              (Some(platform), Some(encoding), Some(offset)) => {
                let format = read_u16_dbg(view, offset)
                match format {
                  None => ()
                  Some(format) => entries.push("\{platform}/\{encoding}:\{format}")
                }
              }
              _ => ()
            }
          }
        }
      }
      entries.join(",")
    }
  }
}
fn cmap_length_summary(data : Bytes) -> String {
  let cmap = table_slice(data, "cmap")
  match cmap {
    None => "none"
    Some(cmap) => {
      let view = cmap[:]
      let num_tables = read_u16_dbg(view, 2)
      let entries : Array[String] = []
      match num_tables {
        None => ()
        Some(num_tables) => {
          for i in 0..<num_tables {
            let rec_base = 4 + i * 8
            let platform = read_u16_dbg(view, rec_base)
            let encoding = read_u16_dbg(view, rec_base + 2)
            let offset = read_u32_dbg(view, rec_base + 4)
            match (platform, encoding, offset) {
              (Some(platform), Some(encoding), Some(offset)) => {
                let format = read_u16_dbg(view, offset)
                match format {
                  None => ()
                  Some(format) => {
                    let length = if format == 14 {
                      read_u32_dbg(view, offset + 2)
                    } else if format == 12 {
                      read_u32_dbg(view, offset + 4)
                    } else if format == 4 {
                      let short_len = read_u16_dbg(view, offset + 2)
                      short_len
                    } else {
                      None
                    }
                    match length {
                      None => ()
                      Some(length) =>
                        entries.push("\{platform}/\{encoding}:\{format}:\{length}")
                    }
                  }
                }
              }
              _ => ()
            }
          }
        }
      }
      entries.sort()
      entries.join(",")
    }
  }
}

fn cmap_header_summary(data : Bytes) -> String {
  let cmap = table_slice(data, "cmap")
  match cmap {
    None => "none"
    Some(cmap) => {
      let view = cmap[:]
      let version = read_u16_dbg(view, 0)
      let num_tables = read_u16_dbg(view, 2)
      let entries : Array[String] = []
      match num_tables {
        None => ()
        Some(num_tables) => {
          for i in 0..<num_tables {
            let rec_base = 4 + i * 8
            let platform = read_u16_dbg(view, rec_base)
            let encoding = read_u16_dbg(view, rec_base + 2)
            let offset = read_u32_dbg(view, rec_base + 4)
            match (platform, encoding, offset) {
              (Some(platform), Some(encoding), Some(offset)) =>
                entries.push("\{platform}/\{encoding}@\{offset}")
              _ => ()
            }
          }
        }
      }
      let ver = match version {
        None => "?"
        Some(value) => value.to_string()
      }
      let num = match num_tables {
        None => "?"
        Some(value) => value.to_string()
      }
      let joined = entries.join(",")
      "\{ver}|\{num}|\{joined}"
    }
  }
}
fn cmap_records(data : Bytes) -> Array[(Int, Int, Int, Bytes)] {
  let cmap = table_slice(data, "cmap")
  let records : Array[(Int, Int, Int, Bytes)] = []
  match cmap {
    None => ()
    Some(cmap) => {
      let view = cmap[:]
      let num_tables = read_u16_dbg(view, 2)
      match num_tables {
        None => ()
        Some(num_tables) => {
          for i in 0..<num_tables {
            let rec_base = 4 + i * 8
            let platform = read_u16_dbg(view, rec_base)
            let encoding = read_u16_dbg(view, rec_base + 2)
            let offset = read_u32_dbg(view, rec_base + 4)
            match (platform, encoding, offset) {
              (Some(platform), Some(encoding), Some(offset)) => {
                let format = read_u16_dbg(view, offset)
                match format {
                  None => ()
                  Some(format) => {
                    let length = if format == 14 {
                      read_u32_dbg(view, offset + 2)
                    } else if format == 12 {
                      read_u32_dbg(view, offset + 4)
                    } else if format == 4 {
                      read_u16_dbg(view, offset + 2)
                    } else {
                      None
                    }
                    match length {
                      None => ()
                      Some(length) =>
                        if offset + length <= cmap.length() {
                          let bytes = cmap[offset:offset + length].to_bytes()
                          records.push((platform, encoding, format, bytes))
                        }
                    }
                  }
                }
              }
              _ => ()
            }
          }
        }
      }
    }
  }
  records
}

fn cmap_diff_records(expected : Bytes, actual : Bytes) -> String {
  let actual_map : Map[String, Bytes] = {}
  for entry in cmap_records(actual) {
    let (platform, encoding, format, bytes) = entry
    let key = "\{platform}/\{encoding}:\{format}"
    actual_map[key] = bytes
  }
  let diffs : Array[String] = []
  for entry in cmap_records(expected) {
    let (platform, encoding, format, bytes) = entry
    let key = "\{platform}/\{encoding}:\{format}"
    match actual_map.get(key) {
      None => diffs.push(key)
      Some(act_bytes) =>
        if act_bytes != bytes {
          diffs.push(key)
        }
    }
  }
  diffs.sort()
  diffs.join(",")
}

fn cblc_summary(data : Bytes) -> String {
  let cblc = table_slice(data, "CBLC")
  match cblc {
    None => "none"
    Some(cblc) => {
      if cblc.length() < 8 {
        return "invalid"
      }
      let major = read_u16_dbg(cblc[:], 0)
      let minor = read_u16_dbg(cblc[:], 2)
      let num_sizes = read_u32_dbg(cblc[:], 4)
      let major_str = match major {
        None => "?"
        Some(value) => value.to_string()
      }
      let minor_str = match minor {
        None => "?"
        Some(value) => value.to_string()
      }
      let size_str = match num_sizes {
        None => "?"
        Some(value) => value.to_string()
      }
      let entries : Array[String] = []
      match num_sizes {
        None => ()
        Some(num_sizes) => {
          let size_base = 8
          let size_len = 48
          if size_base + num_sizes * size_len > cblc.length() {
            return "\{major_str}.\{minor_str} sizes=\{size_str} invalid"
          }
          for i in 0..<num_sizes {
            let rec_offset = size_base + i * size_len
            let list_offset = read_u32_dbg(cblc[:], rec_offset)
            let list_size = read_u32_dbg(cblc[:], rec_offset + 4)
            let subtable_count = read_u32_dbg(cblc[:], rec_offset + 8)
            let mut detail = "\{i}:"
            match (list_offset, list_size, subtable_count) {
              (Some(list_offset), Some(list_size), Some(subtable_count)) => {
                detail = "\{detail}list=\{list_size} subtables=\{subtable_count}"
                if list_offset + list_size <= cblc.length() && list_size >= 8 {
                  let ranges : Array[String] = []
                  for j in 0..<subtable_count {
                    let sub_rec = list_offset + j * 8
                    let first = read_u16_dbg(cblc[:], sub_rec)
                    let last = read_u16_dbg(cblc[:], sub_rec + 2)
                    let sub_offset = read_u32_dbg(cblc[:], sub_rec + 4)
                    match (first, last, sub_offset) {
                      (Some(first), Some(last), Some(sub_offset)) => {
                        let mut range = "\{first}-\{last}@\{sub_offset}"
                        let sub_base = list_offset + sub_offset
                        if sub_base + 8 <= cblc.length() {
                          let index_format = read_u16_dbg(cblc[:], sub_base)
                          let image_format = read_u16_dbg(cblc[:], sub_base + 2)
                          match (index_format, image_format) {
                            (Some(index_format), Some(image_format)) =>
                              range = "\{range}(\{index_format}/\{image_format})"
                            _ => ()
                          }
                        }
                        ranges.push(range)
                      }
                      _ => ()
                    }
                  }
                  let ranges_joined = ranges.join(",")
                  detail = "\{detail} ranges=\{ranges_joined}"
                }
              }
              _ => ()
            }
            entries.push(detail)
          }
        }
      }
      let joined = entries.join(";")
      "\{major_str}.\{minor_str} sizes=\{size_str} \{joined}"
    }
  }
}
fn dump_dir_checksum_diff(expected : Bytes, actual : Bytes) -> Unit {
  let num_tables = read_u16_dbg(expected[:], 4)
  match num_tables {
    None => ()
    Some(num_tables) => {
      for i in 0..<num_tables {
        let base = 12 + i * 16
        let tag = read_tag_dbg(expected[:], base)
        let exp_checksum = read_u32_dbg(expected[:], base + 4)
        match tag {
          None => ()
          Some(tag) => {
            let act_num_tables = read_u16_dbg(actual[:], 4)
            match act_num_tables {
              None => ()
              Some(act_num_tables) => {
                for j in 0..<act_num_tables {
                  let act_base = 12 + j * 16
                  let act_tag = read_tag_dbg(actual[:], act_base)
                  if act_tag == Some(tag) {
                    let act_checksum = read_u32_dbg(actual[:], act_base + 4)
                    if exp_checksum != act_checksum {
                      println(
                        "  dir checksum diff \{tag} exp=\{exp_checksum} act=\{act_checksum}",
                      )
                    }
                    break
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

fn dump_dir_offset_diff(expected : Bytes, actual : Bytes) -> Unit {
  let num_tables = read_u16_dbg(expected[:], 4)
  match num_tables {
    None => ()
    Some(num_tables) => {
      for i in 0..<num_tables {
        let base = 12 + i * 16
        let tag = read_tag_dbg(expected[:], base)
        let exp_offset = read_u32_dbg(expected[:], base + 8)
        let exp_len = read_u32_dbg(expected[:], base + 12)
        match tag {
          None => ()
          Some(tag) => {
            let act_num_tables = read_u16_dbg(actual[:], 4)
            match act_num_tables {
              None => ()
              Some(act_num_tables) => {
                for j in 0..<act_num_tables {
                  let act_base = 12 + j * 16
                  let act_tag = read_tag_dbg(actual[:], act_base)
                  if act_tag == Some(tag) {
                    let act_offset = read_u32_dbg(actual[:], act_base + 8)
                    let act_len = read_u32_dbg(actual[:], act_base + 12)
                    if exp_offset != act_offset || exp_len != act_len {
                      println(
                        "  dir offset diff \{tag} exp=\{exp_offset}/\{exp_len} act=\{act_offset}/\{act_len}",
                      )
                    }
                    break
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

fn dump_tag_diff(expected : Bytes, actual : Bytes) -> Unit {
  let exp_tags : Map[String, Bool] = {}
  let exp_count = read_u16_dbg(expected[:], 4)
  match exp_count {
    None => ()
    Some(exp_count) => {
      for i in 0..<exp_count {
        let base = 12 + i * 16
        let tag = read_tag_dbg(expected[:], base)
        match tag {
          None => ()
          Some(tag) => exp_tags[tag] = true
        }
      }
    }
  }
  let act_count = read_u16_dbg(actual[:], 4)
  match act_count {
    None => ()
    Some(act_count) => {
      for i in 0..<act_count {
        let base = 12 + i * 16
        let tag = read_tag_dbg(actual[:], base)
        match tag {
          None => ()
          Some(tag) =>
            if exp_tags.get(tag) is None {
              println("  extra table \{tag}")
            }
        }
      }
    }
  }
}

///|
test "subset data fixtures" {
  let mut ran = 0
  let mut skipped = 0
  let mut mismatched = 0
  for suite in subset_data_suites {
    let parsed = parse_suite(suite.definition)
    let cases = build_cases(suite.name, parsed)
    for case in cases {
      if !case.options.is_empty() {
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
      let expected = subset_data_expected_bytes(key)
      let expected = match expected {
        None => {
          skipped = skipped + 1
          continue
        }
        Some(value) => value
      }
      let font_bytes = subset_data_font_bytes(case.font)
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
        Err(err) => {
          if case.suite == "cbdt.tests" {
            fail(
              "subset error \{case.suite} \{case.font} \{case.profile} \{case.subset} \{@debug.to_string(err)}",
            )
          }
          mismatched = mismatched + 1
          continue
        }
        Ok(value) => value
      }
      if actual != expected {
        if case.suite == "cbdt.tests" {
          let exp_cblc = table_slice(expected, "CBLC")
          let act_cblc = table_slice(actual, "CBLC")
          let exp_cbdt = table_slice(expected, "CBDT")
          let act_cbdt = table_slice(actual, "CBDT")
          let exp_tags = table_tags_string(expected)
          let act_tags = table_tags_string(actual)
          let diff_tags = table_diff_tags(expected, actual)
          let exp_cblc_summary = cblc_summary(expected)
          let act_cblc_summary = cblc_summary(actual)
          let exp_cmap = cmap_summary(expected)
          let act_cmap = cmap_summary(actual)
          let exp_cmap_order = cmap_record_order(expected)
          let act_cmap_order = cmap_record_order(actual)
          let exp_cmap_header = cmap_header_summary(expected)
          let act_cmap_header = cmap_header_summary(actual)
          let exp_cmap_len = cmap_length_summary(expected)
          let act_cmap_len = cmap_length_summary(actual)
          let cmap_record_diff = cmap_diff_records(expected, actual)
          let exp_cblc_len = match exp_cblc {
            None => -1
            Some(bytes) => bytes.length()
          }
          let act_cblc_len = match act_cblc {
            None => -1
            Some(bytes) => bytes.length()
          }
          let exp_cbdt_len = match exp_cbdt {
            None => -1
            Some(bytes) => bytes.length()
          }
          let act_cbdt_len = match act_cbdt {
            None => -1
            Some(bytes) => bytes.length()
          }
          fail(
            "subset mismatch \{case.suite} \{case.font} \{case.profile} \{case.subset} CBLC \{exp_cblc_len}/\{act_cblc_len} CBDT \{exp_cbdt_len}/\{act_cbdt_len} cblc exp=\{exp_cblc_summary} act=\{act_cblc_summary} diff=\{diff_tags} cmap exp=\{exp_cmap} act=\{act_cmap} cmap_order exp=\{exp_cmap_order} act=\{act_cmap_order} cmap_len exp=\{exp_cmap_len} act=\{act_cmap_len} cmap_diff=\{cmap_record_diff} cmap_header exp=\{exp_cmap_header} act=\{act_cmap_header} tags exp=\{exp_tags} act=\{act_tags}",
          )
        }
        println(
          "mismatch \{case.suite} \{case.font} \{case.profile} \{case.subset}",
        )
        dump_tag_diff(expected, actual)
        dump_dir_checksum_diff(expected, actual)
        dump_dir_offset_diff(expected, actual)
        dump_table_diff(expected, actual)
        mismatched = mismatched + 1
      }
      ran = ran + 1
    }
  }
  let expected = "(\{subset_data_case_count}, 0, 0)"
  @debug.debug_inspect((ran, skipped, mismatched), content=expected)
}
