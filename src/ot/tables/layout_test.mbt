///|
test "layout table header and lists" {
  let bytes = build_layout_table(build_gsub_lookup())
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
  inspect(features[0].tag.to_string(), content="dumy")
  inspect(features[0].offset, content="30")
  let lookups = layout.lookup_list().offsets()
  inspect(lookups.length(), content="1")
  inspect(lookups[0], content="40")
}

///|
test "gsub/gpos wrappers" {
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(build_layout_table(build_gsub_lookup()))) {
    Err(err) => fail("gsub parse error: \{err}")
    Ok(value) => value
  }
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(build_layout_table(build_gpos_lookup()))) {
    Err(err) => fail("gpos parse error: \{err}")
    Ok(value) => value
  }
  inspect(gsub.layout().script_list().records().length(), content="1")
  inspect(gpos.layout().feature_list().records().length(), content="1")
}
