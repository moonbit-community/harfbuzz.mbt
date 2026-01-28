///|
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_tag(bytes : Array[Byte], tag : @common.Tag) -> Unit {
  let (b1, b2, b3, b4) = tag.bytes()
  bytes.push(b1)
  bytes.push(b2)
  bytes.push(b3)
  bytes.push(b4)
}

///|
fn build_script_list() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_tag(bytes, @common.Tag::from_chars('l', 'a', 't', 'n'))
  push_u16(bytes, 8)
  // script table (defaultLangSysOffset + langSysCount)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_feature_list() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_tag(bytes, @common.Tag::from_chars('k', 'e', 'r', 'n'))
  push_u16(bytes, 8)
  // feature table (featureParams, lookupIndexCount, lookupIndices)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_lookup_list() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 4)
  // lookup table placeholder
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_layout_table() -> Bytes {
  let script = build_script_list()
  let feature = build_feature_list()
  let lookup = build_lookup_list()
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  let script_offset = 10
  let feature_offset = script_offset + script.length()
  let lookup_offset = feature_offset + feature.length()
  push_u16(bytes, script_offset)
  push_u16(bytes, feature_offset)
  push_u16(bytes, lookup_offset)
  for b in script {
    bytes.push(b)
  }
  for b in feature {
    bytes.push(b)
  }
  for b in lookup {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
test "layout table header and lists" {
  let bytes = build_layout_table()
  let layout = match LayoutTable::parse(@blob.Blob::from_bytes(bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let header = layout.header()
  inspect(header.script_list_offset, content="10")
  inspect(header.feature_list_offset, content="22")
  inspect(header.lookup_list_offset, content="36")
  let scripts = layout.script_list().records()
  inspect(scripts.length(), content="1")
  inspect(scripts[0].tag.to_string(), content="latn")
  inspect(scripts[0].offset, content="18")
  let features = layout.feature_list().records()
  inspect(features.length(), content="1")
  inspect(features[0].tag.to_string(), content="kern")
  inspect(features[0].offset, content="30")
  let lookups = layout.lookup_list().offsets()
  inspect(lookups.length(), content="1")
  inspect(lookups[0], content="40")
}

///|
test "gsub/gpos wrappers" {
  let bytes = build_layout_table()
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(bytes)) {
    Err(err) => fail("gsub parse error: \{err}")
    Ok(value) => value
  }
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(bytes)) {
    Err(err) => fail("gpos parse error: \{err}")
    Ok(value) => value
  }
  inspect(gsub.layout().script_list().records().length(), content="1")
  inspect(gpos.layout().feature_list().records().length(), content="1")
}
