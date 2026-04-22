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
test "layout table header and lists" {
  let bytes = build_layout_table(
    build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  )
  let layout = match LayoutTable::parse(@blob.Blob::from_bytes(bytes)) {
    Err(err) => fail("parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let header = layout.header()
  @debug.debug_inspect(header.script_list_offset, content="10")
  @debug.debug_inspect(header.feature_list_offset, content="30")
  @debug.debug_inspect(header.lookup_list_offset, content="44")
  let scripts = layout.script_list().records()
  @debug.debug_inspect(scripts.length(), content="1")
  @debug.debug_inspect(scripts[0].tag.to_string(), content="latn")
  @debug.debug_inspect(scripts[0].offset, content="18")
  let features = layout.feature_list().records()
  @debug.debug_inspect(features.length(), content="1")
  @debug.debug_inspect(features[0].tag.to_string(), content="liga")
  @debug.debug_inspect(features[0].offset, content="38")
  let lookups = layout.lookup_list().offsets()
  @debug.debug_inspect(lookups.length(), content="1")
  @debug.debug_inspect(lookups[0], content="48")
  let selected = match layout.select_lookup_offsets(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
  ) {
    Err(err) => fail("select error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(selected, content="[48]")
  let filtered = match layout.select_lookup_offsets_with_features(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
    feature_tags=[@common.Tag::from_chars('k', 'e', 'r', 'n')],
  ) {
    Err(err) => fail("select error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(filtered.is_empty(), content="true")
  let single = match layout.select_lookup_offsets_for_feature(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  ) {
    Err(err) => fail("select error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(single, content="[48]")
  let missing = match layout.select_lookup_offsets_for_feature(
    @common.Tag::from_chars('l', 'a', 't', 'n'),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  ) {
    Err(err) => fail("select error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(missing.is_empty(), content="true")
}

///|
test "gsub/gpos wrappers" {
  let gsub = match GsubTable::parse(@blob.Blob::from_bytes(build_layout_table(
    build_gsub_lookup(),
    @common.Tag::from_chars('l', 'i', 'g', 'a'),
  ))) {
    Err(err) => fail("gsub parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  let gpos = match GposTable::parse(@blob.Blob::from_bytes(build_layout_table(
    build_gpos_lookup(),
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  ))) {
    Err(err) => fail("gpos parse error: \{@debug.to_string(err)}")
    Ok(value) => value
  }
  @debug.debug_inspect(gsub.layout().script_list().records().length(), content="1")
  @debug.debug_inspect(gpos.layout().feature_list().records().length(), content="1")
}
