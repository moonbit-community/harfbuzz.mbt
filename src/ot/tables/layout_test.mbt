///|
test "layout table header and lists" {
  let bytes = build_layout_table(
    build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let layout = match LayoutTable::parse(@blob.Blob::from_bytes(bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let header = layout.header()
  inspect(header.script_list_offset, content="10")
  inspect(header.feature_list_offset, content="30")
  inspect(header.lookup_list_offset, content="44")
  let scripts = layout.script_list().records()
  inspect(scripts.length(), content="1")
  inspect(scripts[0].tag.to_string(), content="latn")
  inspect(scripts[0].offset, content="18")
  let features = layout.feature_list().records()
  inspect(features.length(), content="1")
  inspect(features[0].tag.to_string(), content="liga")
  inspect(features[0].offset, content="38")
  let lookups = layout.lookup_list().offsets()
  inspect(lookups.length(), content="1")
  inspect(lookups[0], content="48")
  let selected = match layout.select_lookup_offsets(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
  ) {
    Err(err) => fail("select error: \{err}")
    Ok(value) => value
  }
  inspect(selected, content="[48]")
  let filtered = match layout.select_lookup_offsets_with_features(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
    feature_tags=[@common.Tag::from_chars('k', 'e', 'r', 'n')],
  ) {
    Err(err) => fail("select error: \{err}")
    Ok(value) => value
  }
  inspect(filtered.is_empty(), content="true")
  let single = match layout.select_lookup_offsets_for_feature(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  ) {
    Err(err) => fail("select error: \{err}")
    Ok(value) => value
  }
  inspect(single, content="[48]")
  let missing = match layout.select_lookup_offsets_for_feature(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  ) {
    Err(err) => fail("select error: \{err}")
    Ok(value) => value
  }
  inspect(missing.is_empty(), content="true")
}

///|
test "gsub/gpos wrappers" {
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(build_layout_table(
    build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  ))) {
    Err(err) => fail("gsub parse error: \{err}")
    Ok(value) => value
  }
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(build_layout_table(
    build_gpos_lookup(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  ))) {
    Err(err) => fail("gpos parse error: \{err}")
    Ok(value) => value
  }
  inspect(gsub.layout().script_list().records().length(), content="1")
  inspect(gpos.layout().feature_list().records().length(), content="1")
}
