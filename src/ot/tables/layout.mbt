///|
pub suberror OtLayoutError {
  UnexpectedEof
  InvalidFormat
} derive(Eq, Show, ToJson)

///|
/// Layout table header (GSUB/GPOS shared).
pub struct LayoutHeader {
  version : UInt
  script_list_offset : Int
  feature_list_offset : Int
  lookup_list_offset : Int
  feature_variations_offset : Int?
} derive(Eq, Show, ToJson)

///|
/// Script record entry (offset from table start).
pub struct ScriptRecord {
  tag : @common.Tag
  offset : Int
} derive(Eq, Show, ToJson)

///|
/// Script list table.
pub struct ScriptList {
  records : Array[ScriptRecord]
} derive(Eq, Show, ToJson)

///|
pub fn ScriptList::records(self : ScriptList) -> ArrayView[ScriptRecord] {
  self.records[:]
}

///|
/// Feature record entry (offset from table start).
pub struct FeatureRecord {
  tag : @common.Tag
  offset : Int
} derive(Eq, Show, ToJson)

///|
/// Feature list table.
pub struct FeatureList {
  records : Array[FeatureRecord]
} derive(Eq, Show, ToJson)

///|
pub fn FeatureList::records(self : FeatureList) -> ArrayView[FeatureRecord] {
  self.records[:]
}

///|
/// Lookup list table (offsets from table start).
pub struct LookupList {
  offsets : Array[Int]
} derive(Eq, Show, ToJson)

///|
pub fn LookupList::offsets(self : LookupList) -> ArrayView[Int] {
  self.offsets[:]
}

///|
/// Parsed layout table (GSUB/GPOS shared).
pub struct LayoutTable {
  data : BytesView
  header : LayoutHeader
  script_list : ScriptList
  feature_list : FeatureList
  lookup_list : LookupList
} derive(Show, ToJson)

///|
pub fn LayoutTable::header(self : LayoutTable) -> LayoutHeader {
  self.header
}

///|
pub fn LayoutTable::script_list(self : LayoutTable) -> ScriptList {
  self.script_list
}

///|
pub fn LayoutTable::feature_list(self : LayoutTable) -> FeatureList {
  self.feature_list
}

///|
pub fn LayoutTable::lookup_list(self : LayoutTable) -> LookupList {
  self.lookup_list
}

///|
/// Select lookup offsets for a script/language pair using a feature allowlist.
pub fn LayoutTable::select_lookup_offsets_with_features(
  self : LayoutTable,
  script_tag : @common.Tag,
  language_tag? : @common.Tag = @common.tag_none,
  feature_tags? : Array[@common.Tag] = [],
) -> Result[Array[Int], OtLayoutError] {
  select_lookup_offsets_internal(self, script_tag, language_tag, feature_tags)
}

///|
/// Select lookup offsets for a script/language pair using the default LangSys.
pub fn LayoutTable::select_lookup_offsets(
  self : LayoutTable,
  script_tag : @common.Tag,
  language_tag? : @common.Tag = @common.tag_none,
) -> Result[Array[Int], OtLayoutError] {
  self.select_lookup_offsets_with_features(script_tag, language_tag=language_tag)
}

///|
fn select_lookup_offsets_internal(
  layout : LayoutTable,
  script_tag : @common.Tag,
  language_tag : @common.Tag,
  feature_tags : Array[@common.Tag],
) -> Result[Array[Int], OtLayoutError] {
  let normalized_script = lowercase_tag(script_tag)
  let script_offset = match find_script_offset(layout.script_list.records, normalized_script) {
    Some(offset) => Some(offset)
    None => if normalized_script != script_tag {
        find_script_offset(layout.script_list.records, script_tag)
      } else {
        None
      }
  }
  let script_offset = match script_offset {
    Some(offset) => Some(offset)
    None => find_script_offset(
      layout.script_list.records,
      @common.Tag::from_chars('D', 'F', 'L', 'T'),
    )
  }
  let resolved_script_offset = match script_offset {
    Some(offset) => offset
    None =>
      if layout.script_list.records.is_empty() {
        return Ok([])
      } else {
        layout.script_list.records[0].offset
      }
  }
  let (default_lang, lang_records) = match parse_script_table(
    layout.data,
    resolved_script_offset,
  ) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let lang_offset = if language_tag != @common.tag_none {
    find_lang_sys_offset(lang_records, language_tag)
  } else {
    None
  }
  let resolved_lang_offset = match lang_offset {
    Some(offset) => Some(offset)
    None => default_lang
  }
  let final_lang_offset = match resolved_lang_offset {
    Some(offset) => offset
    None =>
      if lang_records.is_empty() {
        return Ok([])
      } else {
        lang_records[0].1
      }
  }
  let (required_feature, feature_indices) = match parse_lang_sys_table(
    layout.data,
    final_lang_offset,
  ) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let has_filter = !feature_tags.is_empty()
  let selected_features : Array[Int] = []
  match required_feature {
    None => ()
    Some(feature) => push_unique_int(selected_features, feature)
  }
  for feature in feature_indices {
    if !has_filter {
      push_unique_int(selected_features, feature)
    } else {
      if feature < 0 || feature >= layout.feature_list.records.length() {
        return Err(InvalidFormat)
      }
      let record = layout.feature_list.records[feature]
      if tag_in_list(record.tag, feature_tags) {
        push_unique_int(selected_features, feature)
      }
    }
  }
  let lookup_indices : Array[Int] = []
  for feature_index in selected_features {
    if feature_index < 0 || feature_index >= layout.feature_list.records.length() {
      return Err(InvalidFormat)
    }
    let record = layout.feature_list.records[feature_index]
    let lookup_list = match parse_feature_table(layout.data, record.offset) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    for lookup_index in lookup_list {
      push_unique_int(lookup_indices, lookup_index)
    }
  }
  let lookup_offsets : Array[Int] = []
  for lookup_index in lookup_indices {
    if lookup_index < 0 || lookup_index >= layout.lookup_list.offsets.length() {
      return Err(InvalidFormat)
    }
    lookup_offsets.push(layout.lookup_list.offsets[lookup_index])
  }
  Ok(lookup_offsets)
}

///|
/// GSUB table wrapper.
pub struct GsubTable {
  layout : LayoutTable
} derive(Show, ToJson)

///|
pub fn GsubTable::parse(blob : @blob.Blob) -> Result[GsubTable, OtLayoutError] {
  match LayoutTable::parse(blob) {
    Err(err) => Err(err)
    Ok(layout) => Ok(GsubTable::{ layout })
  }
}

///|
pub fn GsubTable::layout(self : GsubTable) -> LayoutTable {
  self.layout
}

///|
/// GPOS table wrapper.
pub struct GposTable {
  layout : LayoutTable
} derive(Show, ToJson)

///|
pub fn GposTable::parse(blob : @blob.Blob) -> Result[GposTable, OtLayoutError] {
  match LayoutTable::parse(blob) {
    Err(err) => Err(err)
    Ok(layout) => Ok(GposTable::{ layout })
  }
}

///|
pub fn GposTable::layout(self : GposTable) -> LayoutTable {
  self.layout
}

///|
/// Parse a GSUB/GPOS layout table.
pub fn LayoutTable::parse(
  blob : @blob.Blob,
) -> Result[LayoutTable, OtLayoutError] {
  let data = blob.as_view()
  let version = read_u32(data, 0)
  let script_offset = read_u16_int(data, 4)
  let feature_offset = read_u16_int(data, 6)
  let lookup_offset = read_u16_int(data, 8)
  match (version, script_offset, feature_offset, lookup_offset) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(script_offset), Ok(feature_offset), Ok(lookup_offset)) => {
      if version < 0x00010000U {
        return Err(InvalidFormat)
      }
      if script_offset == 0 || feature_offset == 0 || lookup_offset == 0 {
        return Err(InvalidFormat)
      }
      let feature_variations_offset =
        if version >= 0x00010001U {
          match read_u32_int(data, 10) {
            Err(err) => return Err(err)
            Ok(value) => if value == 0 { None } else { Some(value) }
          }
        } else {
          None
        }
      let script_list = match parse_script_list(data, script_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let feature_list = match parse_feature_list(data, feature_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lookup_list = match parse_lookup_list(data, lookup_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let header = LayoutHeader::{
        version,
        script_list_offset: script_offset,
        feature_list_offset: feature_offset,
        lookup_list_offset: lookup_offset,
        feature_variations_offset,
      }
      Ok(LayoutTable::{ data, header, script_list, feature_list, lookup_list })
    }
  }
}

///|
fn parse_script_list(
  data : BytesView,
  base : Int,
) -> Result[ScriptList, OtLayoutError] {
  if base < 0 || base + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, base)
  let records : Array[ScriptRecord] = []
  let record_base = base + 2
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if record_base < 0 || record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 6
        let tag = match read_tag(data, record_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let offset = read_u16_int(data, record_offset + 4)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            if offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = base + offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            records.push(ScriptRecord::{ tag, offset: abs_offset })
          }
        }
      }
      Ok(ScriptList::{ records })
    }
  }
}

///|
fn parse_feature_list(
  data : BytesView,
  base : Int,
) -> Result[FeatureList, OtLayoutError] {
  if base < 0 || base + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, base)
  let records : Array[FeatureRecord] = []
  let record_base = base + 2
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if record_base < 0 || record_base + count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 6
        let tag = match read_tag(data, record_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let offset = read_u16_int(data, record_offset + 4)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            if offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = base + offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            records.push(FeatureRecord::{ tag, offset: abs_offset })
          }
        }
      }
      Ok(FeatureList::{ records })
    }
  }
}

///|
fn parse_lookup_list(
  data : BytesView,
  base : Int,
) -> Result[LookupList, OtLayoutError] {
  if base < 0 || base + 2 > data.length() {
    return Err(UnexpectedEof)
  }
  let count = read_u16_int(data, base)
  let offsets : Array[Int] = []
  let record_base = base + 2
  match count {
    Err(err) => Err(err)
    Ok(count) => {
      if record_base < 0 || record_base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      for i in 0..<count {
        let record_offset = record_base + i * 2
        let offset = read_u16_int(data, record_offset)
        match offset {
          Err(err) => return Err(err)
          Ok(offset) => {
            if offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = base + offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            offsets.push(abs_offset)
          }
        }
      }
      Ok(LookupList::{ offsets })
    }
  }
}

///|
fn find_script_offset(
  records : Array[ScriptRecord],
  tag : @common.Tag,
) -> Int? {
  for record in records {
    if record.tag == tag {
      return Some(record.offset)
    }
  }
  None
}

///|
fn find_lang_sys_offset(
  records : Array[(@common.Tag, Int)],
  tag : @common.Tag,
) -> Int? {
  for record in records {
    let (record_tag, offset) = record
    if record_tag == tag {
      return Some(offset)
    }
  }
  None
}

///|
fn parse_script_table(
  data : BytesView,
  offset : Int,
) -> Result[(Int?, Array[(@common.Tag, Int)]), OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let default_offset = read_u16_int(data, offset)
  let lang_count = read_u16_int(data, offset + 2)
  match (default_offset, lang_count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(default_offset), Ok(lang_count)) => {
      let record_base = offset + 4
      if record_base < 0 || record_base + lang_count * 6 > data.length() {
        return Err(UnexpectedEof)
      }
      let records : Array[(@common.Tag, Int)] = []
      for i in 0..<lang_count {
        let record_offset = record_base + i * 6
        let tag = match read_tag(data, record_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let lang_offset = read_u16_int(data, record_offset + 4)
        match lang_offset {
          Err(err) => return Err(err)
          Ok(lang_offset) => {
            if lang_offset == 0 {
              return Err(InvalidFormat)
            }
            let abs_offset = offset + lang_offset
            if abs_offset < 0 || abs_offset >= data.length() {
              return Err(UnexpectedEof)
            }
            records.push((tag, abs_offset))
          }
        }
      }
      let default_lang = if default_offset == 0 {
        None
      } else {
        let abs_offset = offset + default_offset
        if abs_offset < 0 || abs_offset >= data.length() {
          return Err(UnexpectedEof)
        }
        Some(abs_offset)
      }
      Ok((default_lang, records))
    }
  }
}

///|
fn parse_lang_sys_table(
  data : BytesView,
  offset : Int,
) -> Result[(Int?, Array[Int]), OtLayoutError] {
  if offset < 0 || offset + 6 > data.length() {
    return Err(UnexpectedEof)
  }
  let lookup_order = read_u16_int(data, offset)
  let req_feature = read_u16_int(data, offset + 2)
  let feature_count = read_u16_int(data, offset + 4)
  match (lookup_order, req_feature, feature_count) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(_), Ok(req_feature), Ok(feature_count)) => {
      let list_base = offset + 6
      if list_base < 0 || list_base + feature_count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let indices : Array[Int] = []
      for i in 0..<feature_count {
        let value = read_u16_int(data, list_base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => indices.push(value)
        }
      }
      let required = if req_feature == 0xffff { None } else { Some(req_feature) }
      Ok((required, indices))
    }
  }
}

///|
fn parse_feature_table(
  data : BytesView,
  offset : Int,
) -> Result[Array[Int], OtLayoutError] {
  if offset < 0 || offset + 4 > data.length() {
    return Err(UnexpectedEof)
  }
  let params_offset = read_u16_int(data, offset)
  let count = read_u16_int(data, offset + 2)
  match (params_offset, count) {
    (Err(err), _) => Err(err)
    (_, Err(err)) => Err(err)
    (Ok(_), Ok(count)) => {
      let list_base = offset + 4
      if list_base < 0 || list_base + count * 2 > data.length() {
        return Err(UnexpectedEof)
      }
      let indices : Array[Int] = []
      for i in 0..<count {
        let value = read_u16_int(data, list_base + i * 2)
        match value {
          Err(err) => return Err(err)
          Ok(value) => indices.push(value)
        }
      }
      Ok(indices)
    }
  }
}

///|
fn push_unique_int(values : Array[Int], value : Int) -> Unit {
  for entry in values {
    if entry == value {
      return
    }
  }
  values.push(value)
}

///|
fn tag_in_list(tag : @common.Tag, tags : Array[@common.Tag]) -> Bool {
  for entry in tags {
    if entry == tag {
      return true
    }
  }
  false
}

///|
fn lowercase_tag(tag : @common.Tag) -> @common.Tag {
  let (b1, b2, b3, b4) = tag.bytes()
  @common.Tag::from_bytes(
    ascii_lowercase_byte(b1),
    ascii_lowercase_byte(b2),
    ascii_lowercase_byte(b3),
    ascii_lowercase_byte(b4),
  )
}

///|
fn ascii_lowercase_byte(b : Byte) -> Byte {
  let v = b.to_uint()
  if v >= 0x41U && v <= 0x5aU {
    (v + 0x20U).to_byte()
  } else {
    b
  }
}

///|
fn check_range(
  data : BytesView,
  offset : Int,
  size : Int,
) -> Result[Unit, OtLayoutError] {
  if offset < 0 || size < 0 || offset + size > data.length() {
    Err(UnexpectedEof)
  } else {
    Ok(())
  }
}

///|
fn read_u16(data : BytesView, offset : Int) -> Result[UInt, OtLayoutError] {
  match check_range(data, offset, 2) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  Ok((b0 << 8) | b1)
}

///|
fn read_u32(data : BytesView, offset : Int) -> Result[UInt, OtLayoutError] {
  match check_range(data, offset, 4) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

///|
fn u16_to_int(value : UInt) -> Int {
  let v = value.reinterpret_as_int()
  if v < 0 {
    v + 0x10000
  } else {
    v
  }
}

///|
fn read_u16_int(data : BytesView, offset : Int) -> Result[Int, OtLayoutError] {
  match read_u16(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(u16_to_int(value))
  }
}

///|
fn read_u32_int(data : BytesView, offset : Int) -> Result[Int, OtLayoutError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => {
      let v = value.reinterpret_as_int()
      if v < 0 {
        Err(InvalidFormat)
      } else {
        Ok(v)
      }
    }
  }
}

///|
fn read_i16(data : BytesView, offset : Int) -> Result[Int, OtLayoutError] {
  match read_u16_int(data, offset) {
    Err(err) => Err(err)
    Ok(value) => if value >= 0x8000 { Ok(value - 0x10000) } else { Ok(value) }
  }
}

///|
fn read_tag(data : BytesView, offset : Int) -> Result[@common.Tag, OtLayoutError] {
  match check_range(data, offset, 4) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  Ok(
    @common.Tag::from_bytes(
      data[offset],
      data[offset + 1],
      data[offset + 2],
      data[offset + 3],
    ),
  )
}
