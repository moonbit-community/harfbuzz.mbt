///|
let dotted_circle_codepoint : UInt = 0x25CCU

fn insert_dotted_circle_for_syllables(
  font : @font.Font,
  buffer : Buffer,
  syllables : Array[Int],
  broken_type : Int,
) -> Result[Bool, ShapeError] {
  if buffer.infos.length() != syllables.length() || buffer.infos.is_empty() {
    return Ok(false)
  }
  let has_dotted_circle = match font.glyph_for_codepoint(dotted_circle_codepoint) {
    Err(err) => return Err(Font(err))
    Ok(None) => false
    Ok(Some(_)) => true
  }
  if !has_dotted_circle {
    return Ok(false)
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let mut inserted = false
  let mut last_syllable = -1
  for i in 0..<buffer.infos.length() {
    let syllable = syllables[i]
    if syllable != last_syllable && (syllable & 0x0f) == broken_type {
      inserted = true
      let info = buffer.infos[i]
      next_infos.push(GlyphInfo::{ codepoint: dotted_circle_codepoint, cluster: info.cluster })
      next_positions.push(GlyphPosition::{ x_advance: 0, y_advance: 0, x_offset: 0, y_offset: 0 })
    }
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    last_syllable = syllable
  }
  if inserted {
    buffer.infos = next_infos
    buffer.positions = next_positions
  }
  Ok(inserted)
}

///|
fn apply_gsub_features_for_syllables(
  font : @font.Font,
  buffer : Buffer,
  gsub : @ot_tables.GsubTable,
  feature_tags : Array[@common.Tag],
  syllables : Array[Int],
  glyph_masks? : Array[UInt] = [],
  script_tag? : @common.Tag = buffer.script.to_tag(),
) -> Result[Unit, ShapeError] {
  if syllables.is_empty() || syllables.length() != buffer.infos.length() {
    return Ok(())
  }
  let mut use_masks = !glyph_masks.is_empty()
  if use_masks && glyph_masks.length() != buffer.infos.length() {
    use_masks = false
  }
  let gdef = match font.gdef() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let script_tag = script_tag
  let lang_tag = language_to_ot_tag(buffer.language)
  let feature_lookups : Array[Array[Int]] = []
  for feature_tag in feature_tags {
    let lookup_offsets = match gsub.layout().select_lookup_offsets_for_feature(
      script_tag,
      feature_tag,
      language_tag=lang_tag,
      include_required=false,
    ) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
    feature_lookups.push(lookup_offsets)
  }
  let mut has_lookups = false
  for lookup_offsets in feature_lookups {
    if !lookup_offsets.is_empty() {
      has_lookups = true
      break
    }
  }
  if !has_lookups {
    return Ok(())
  }
  let mut current_glyphs : Array[UInt] = []
  let mut current_clusters : Array[Int] = []
  let mut current_masks : Array[UInt] = []
  for info in buffer.infos {
    current_glyphs.push(info.codepoint)
    current_clusters.push(info.cluster)
  }
  if use_masks {
    for value in glyph_masks {
      current_masks.push(value)
    }
  }
  let mut changed = false
  let mut delta = 0
  let mut i = 0
  while i < syllables.length() {
    let syllable = syllables[i]
    let mut j = i + 1
    while j < syllables.length() && syllables[j] == syllable {
      j = j + 1
    }
    let start = i + delta
    let end = j + delta
    if start < 0 || end > current_glyphs.length() || start >= end {
      i = j
      continue
    }
    let mut sub_glyphs : Array[UInt] = []
    let mut sub_clusters : Array[Int] = []
    let mut sub_masks : Array[UInt] = []
    for k in start..<end {
      sub_glyphs.push(current_glyphs[k])
      sub_clusters.push(current_clusters[k])
      if use_masks {
        sub_masks.push(current_masks[k])
      }
    }
    let mut sub_changed = false
    for feature_index in 0..<feature_lookups.length() {
      let lookup_offsets = feature_lookups[feature_index]
      if lookup_offsets.is_empty() {
        continue
      }
      let lookup_mask = 1U << feature_index
      let result = match gdef {
        None =>
          match gsub.apply_with_lookups_and_masks(
            sub_glyphs,
            sub_clusters,
            lookup_offsets[:],
            masks=sub_masks,
            lookup_mask=lookup_mask,
          ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
        Some(gdef) =>
          match gsub.apply_with_lookups_and_masks(
            sub_glyphs,
            sub_clusters,
            lookup_offsets[:],
            gdef=gdef,
            masks=sub_masks,
            lookup_mask=lookup_mask,
          ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
      }
      let (next_glyphs, next_clusters, next_masks, did_change) = result
      sub_glyphs = next_glyphs
      sub_clusters = next_clusters
      if use_masks {
        sub_masks = next_masks
      }
      if did_change {
        sub_changed = true
      }
    }
    let old_len = end - start
    let new_len = sub_glyphs.length()
    if sub_changed || new_len != old_len {
      let next_glyphs : Array[UInt] = []
      let next_clusters : Array[Int] = []
      let next_masks : Array[UInt] = []
      for k in 0..<start {
        next_glyphs.push(current_glyphs[k])
        next_clusters.push(current_clusters[k])
        if use_masks {
          next_masks.push(current_masks[k])
        }
      }
      for k in 0..<new_len {
        next_glyphs.push(sub_glyphs[k])
        next_clusters.push(sub_clusters[k])
        if use_masks {
          next_masks.push(sub_masks[k])
        }
      }
      for k in end..<current_glyphs.length() {
        next_glyphs.push(current_glyphs[k])
        next_clusters.push(current_clusters[k])
        if use_masks {
          next_masks.push(current_masks[k])
        }
      }
      current_glyphs = next_glyphs
      current_clusters = next_clusters
      if use_masks {
        current_masks = next_masks
      }
      delta = delta + new_len - old_len
      changed = true
    }
    i = j
  }
  if changed || current_glyphs.length() != buffer.infos.length() {
    let infos : Array[GlyphInfo] = []
    let positions : Array[GlyphPosition] = []
    for idx in 0..<current_glyphs.length() {
      let glyph = current_glyphs[idx]
      let pos = match default_position(buffer, font, glyph) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      infos.push(GlyphInfo::{ codepoint: glyph, cluster: current_clusters[idx] })
      positions.push(pos)
    }
    buffer.infos = infos
    buffer.positions = positions
  }
  Ok(())
}
