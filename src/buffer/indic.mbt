///|
let indic_feature_tags : Array[@common.Tag] = [
  @common.Tag::from_chars('n', 'u', 'k', 't'),
  @common.Tag::from_chars('a', 'k', 'h', 'n'),
  @common.Tag::from_chars('r', 'p', 'h', 'f'),
  @common.Tag::from_chars('r', 'k', 'r', 'f'),
  @common.Tag::from_chars('p', 'r', 'e', 'f'),
  @common.Tag::from_chars('b', 'l', 'w', 'f'),
  @common.Tag::from_chars('a', 'b', 'v', 'f'),
  @common.Tag::from_chars('h', 'a', 'l', 'f'),
  @common.Tag::from_chars('p', 's', 't', 'f'),
  @common.Tag::from_chars('v', 'a', 't', 'u'),
  @common.Tag::from_chars('c', 'j', 'c', 't'),
  @common.Tag::from_chars('i', 'n', 'i', 't'),
  @common.Tag::from_chars('p', 'r', 'e', 's'),
  @common.Tag::from_chars('a', 'b', 'v', 's'),
  @common.Tag::from_chars('b', 'l', 'w', 's'),
  @common.Tag::from_chars('p', 's', 't', 's'),
  @common.Tag::from_chars('h', 'a', 'l', 'n'),
]

///|
let indic_cat_c : Int = 1

///|
let indic_cat_cs : Int = 18

///|
let indic_cat_ra : Int = 15

///|
let indic_cat_cm : Int = 16

///|
let indic_cat_v : Int = 2

///|
let indic_cat_placeholder : Int = 10

///|
let indic_cat_dotted_circle : Int = 11

///|
let indic_cat_h : Int = 4

///|
let indic_cat_zwj : Int = 6

///|
let indic_cat_zwnj : Int = 5

///|
let indic_cat_n : Int = 3

///|
let indic_cat_rs : Int = 12

///|
let indic_cat_mpst : Int = 13

///|
let indic_cat_sm : Int = 8

///|
let indic_pos_start : Int = 0

///|
let indic_pos_pre_c : Int = 3

///|
let indic_pos_base_c : Int = 4

///|
let indic_pos_below_c : Int = 8

///|
let indic_pos_post_c : Int = 11

///|
let indic_pos_smvd : Int = 13

///|
let indic_pos_end : Int = 14

let indic_feature_rphf : Int = 2
let indic_feature_pref : Int = 4
let indic_feature_blwf : Int = 5
let indic_feature_abvf : Int = 6
let indic_feature_half : Int = 7
let indic_feature_pstf : Int = 8
let indic_feature_init : Int = 11

fn indic_blwf_pre_and_post(script : @common.Script) -> Bool {
  script != @common.script_telugu && script != @common.script_kannada
}

fn indic_reph_requires_zwj(script : @common.Script) -> Bool {
  script == @common.script_telugu
}

fn is_consonant_indic(category : Int) -> Bool {
  category == indic_cat_c ||
  category == indic_cat_cs ||
  category == indic_cat_ra ||
  category == indic_cat_cm ||
  category == indic_cat_v ||
  category == indic_cat_placeholder ||
  category == indic_cat_dotted_circle
}

fn is_joiner_or_mark_indic(category : Int) -> Bool {
  category == indic_cat_zwj ||
  category == indic_cat_zwnj ||
  category == indic_cat_n ||
  category == indic_cat_rs ||
  category == indic_cat_cm ||
  category == indic_cat_h
}

fn reorder_range_by_positions_indic(
  buffer : Buffer,
  categories : Array[Int],
  positions : Array[Int],
  start : Int,
  end : Int,
) -> (Array[Int], Array[Int]) {
  if start < 0 || end > buffer.infos.length() || start >= end {
    return (categories, positions)
  }
  let range_len = end - start
  let order : Array[Int] = []
  for pos in indic_pos_start..=indic_pos_end {
    for rel in 0..<range_len {
      if positions[start + rel] == pos {
        order.push(rel)
      }
    }
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let next_categories : Array[Int] = []
  let next_pos_values : Array[Int] = []
  for i in 0..<start {
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    next_categories.push(categories[i])
    next_pos_values.push(positions[i])
  }
  for rel in order {
    let idx = start + rel
    next_infos.push(buffer.infos[idx])
    next_positions.push(buffer.positions[idx])
    next_categories.push(categories[idx])
    next_pos_values.push(positions[idx])
  }
  for i in end..<buffer.infos.length() {
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    next_categories.push(categories[i])
    next_pos_values.push(positions[i])
  }
  buffer.infos = next_infos
  buffer.positions = next_positions
  (next_categories, next_pos_values)
}

fn reorder_indic_syllables(
  buffer : Buffer,
  categories : Array[Int],
  positions : Array[Int],
  syllables : Array[Int],
) -> Unit {
  if categories.length() != buffer.infos.length() ||
    positions.length() != buffer.infos.length() ||
    syllables.length() != buffer.infos.length() {
    return ()
  }
  let mut current_categories = categories
  let mut current_positions = positions
  let mut i = 0
  while i < syllables.length() {
    let syllable = syllables[i]
    let mut j = i + 1
    while j < syllables.length() && syllables[j] == syllable {
      j = j + 1
    }
    buffer.merge_clusters(i, j)
    let mut base = j
    let mut seen_below = false
    let mut k = j
    while k > i {
      k = k - 1
      if is_consonant_indic(current_categories[k]) {
        if current_positions[k] != indic_pos_below_c &&
          (current_positions[k] != indic_pos_post_c || seen_below) {
          base = k
          break
        }
        if current_positions[k] == indic_pos_below_c {
          seen_below = true
        }
        base = k
      } else if k > i &&
        current_categories[k] == indic_cat_zwj &&
        current_categories[k - 1] == indic_cat_h {
        break
      }
    }
    for k in i..<base {
      if current_positions[k] > indic_pos_pre_c {
        current_positions[k] = indic_pos_pre_c
      }
    }
    if base < j {
      current_positions[base] = indic_pos_base_c
    }
    let mut last_pos = indic_pos_start
    for k in i..<j {
      if is_joiner_or_mark_indic(current_categories[k]) {
        current_positions[k] = last_pos
        if current_categories[k] == indic_cat_h &&
          current_positions[k] == indic_pos_smvd {
          let mut prev = k
          while prev > i {
            if current_positions[prev - 1] != indic_pos_smvd {
              current_positions[k] = current_positions[prev - 1]
              break
            }
            prev = prev - 1
          }
        }
      } else if current_positions[k] != indic_pos_smvd {
        if current_categories[k] == indic_cat_mpst &&
          k > i &&
          current_categories[k - 1] == indic_cat_sm {
          current_positions[k - 1] = current_positions[k]
        }
        last_pos = current_positions[k]
      }
    }
    let (next_categories, next_positions) = reorder_range_by_positions_indic(
      buffer,
      current_categories,
      current_positions,
      i,
      j,
    )
    current_categories = next_categories
    current_positions = next_positions
    i = j
  }
}

fn find_base_indic(
  categories : Array[Int],
  positions : Array[Int],
  start : Int,
  end : Int,
) -> Int {
  if start < 0 || end > categories.length() || start >= end {
    return start
  }
  let mut base = end
  let mut seen_below = false
  let mut k = end
  while k > start {
    k = k - 1
    if is_consonant_indic(categories[k]) {
      if positions[k] != indic_pos_below_c &&
        (positions[k] != indic_pos_post_c || seen_below) {
        return k
      }
      if positions[k] == indic_pos_below_c {
        seen_below = true
      }
      base = k
    } else if k > start &&
      categories[k] == indic_cat_zwj &&
      categories[k - 1] == indic_cat_h {
      break
    }
  }
  if base < end {
    return base
  }
  start
}

fn indic_would_substitute(
  gsub : @ot_tables.GsubTable?,
  lookup_offsets : Array[Int],
  glyphs : Array[UInt],
  start : Int,
  length : Int,
) -> Bool {
  if lookup_offsets.is_empty() || length <= 0 || start < 0 ||
    start + length > glyphs.length() {
    return false
  }
  let gsub = match gsub {
    None => return false
    Some(value) => value
  }
  let sub_glyphs : Array[UInt] = []
  for i in start..<(start + length) {
    sub_glyphs.push(glyphs[i])
  }
  let sub_clusters = Array::make(length, 0)
  let sub_masks = Array::make(length, 1U)
  match gsub.apply_with_lookups(
    sub_glyphs,
    sub_clusters,
    lookup_offsets[:],
    masks=sub_masks,
    lookup_mask=1U,
  ) {
    Err(_) => false
    Ok((_, _, changed)) => changed
  }
}

fn build_indic_feature_masks(
  script : @common.Script,
  categories : Array[Int],
  positions : Array[Int],
  syllables : Array[Int],
  glyphs : Array[UInt],
  gsub : @ot_tables.GsubTable?,
  rphf_lookups : Array[Int],
  pref_lookups : Array[Int],
) -> Array[UInt] {
  let len = categories.length()
  let masks = Array::make(len, 0U)
  let rphf_bit = 1U << indic_feature_rphf
  let pref_bit = 1U << indic_feature_pref
  let blwf_bit = 1U << indic_feature_blwf
  let abvf_bit = 1U << indic_feature_abvf
  let half_bit = 1U << indic_feature_half
  let pstf_bit = 1U << indic_feature_pstf
  let init_bit = 1U << indic_feature_init
  let blwf_pre_and_post = indic_blwf_pre_and_post(script)
  let reph_requires_zwj = indic_reph_requires_zwj(script)
  let mut i = 0
  while i < syllables.length() {
    let syllable = syllables[i]
    let mut j = i + 1
    while j < syllables.length() && syllables[j] == syllable {
      j = j + 1
    }
    let base = find_base_indic(categories, positions, i, j)
    if i + 1 < j &&
      categories[i] == indic_cat_ra &&
      categories[i + 1] == indic_cat_h {
      let mut reph_len = 2
      if reph_requires_zwj {
        if i + 2 < j && categories[i + 2] == indic_cat_zwj {
          reph_len = 3
        } else {
          reph_len = 0
        }
      }
      if reph_len > 0 &&
        indic_would_substitute(gsub, rphf_lookups, glyphs, i, reph_len) {
        masks[i] = masks[i] | rphf_bit
      }
    }
    let mut pre_mask = half_bit
    if blwf_pre_and_post {
      pre_mask = pre_mask | blwf_bit
    }
    for k in i..<base {
      masks[k] = masks[k] | pre_mask
    }
    if base >= i && base < j {
      masks[base] = masks[base] | init_bit
    }
    for k in (base + 1)..<j {
      masks[k] = masks[k] | blwf_bit | abvf_bit | pstf_bit
    }
    if !pref_lookups.is_empty() {
      let mut k = base + 1
      while k + 1 < j {
        if categories[k] == indic_cat_h && categories[k + 1] == indic_cat_ra {
          if indic_would_substitute(gsub, pref_lookups, glyphs, k, 2) {
            masks[k] = masks[k] | pref_bit
            masks[k + 1] = masks[k + 1] | pref_bit
            break
          }
        }
        k = k + 1
      }
    }
    let mut z = i + 1
    while z < j {
      if categories[z] == indic_cat_zwnj {
        let mut p = z - 1
        while p >= i {
          if is_consonant_indic(categories[p]) {
            masks[p] = masks[p] & (0xFFFFFFFFU - half_bit)
            break
          }
          if p == 0 {
            break
          }
          p = p - 1
        }
      }
      z = z + 1
    }
    i = j
  }
  masks
}

///|
pub fn Buffer::shape_indic(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let script_tag = self.script.to_tag()
  if gsub is Some(gsub) {
    let dflt_tag = @common.Tag::from_chars('D', 'F', 'L', 'T')
    let latn_tag = @common.Tag::from_chars('l', 'a', 't', 'n')
    if !buffer_layout_has_script(gsub.layout(), script_tag) &&
      (buffer_layout_has_script(gsub.layout(), dflt_tag) ||
        buffer_layout_has_script(gsub.layout(), latn_tag)) {
      return self.shape_ot(font)
    }
  }
  let categories : Array[UInt] = []
  for info in self.infos {
    categories.push(indic_category(indic_get_categories(info.codepoint)))
  }
  let syllables = find_syllables_indic(categories)
  match insert_dotted_circle_for_syllables(
    font,
    self,
    syllables,
    indic_syllable_type_broken_cluster,
  ) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let categories_after_u : Array[UInt] = []
  let categories_after_i : Array[Int] = []
  let positions_after : Array[Int] = []
  for info in self.infos {
    let packed = indic_get_categories(info.codepoint)
    categories_after_u.push(indic_category(packed))
    categories_after_i.push(indic_category(packed).reinterpret_as_int())
    positions_after.push(indic_position(packed))
  }
  let syllables_after = find_syllables_indic(categories_after_u)
  reorder_indic_syllables(self, categories_after_i, positions_after, syllables_after)
  let reordered_categories : Array[Int] = []
  let reordered_positions : Array[Int] = []
  for info in self.infos {
    let packed = indic_get_categories(info.codepoint)
    reordered_categories.push(indic_category(packed).reinterpret_as_int())
    reordered_positions.push(indic_position(packed))
  }
  let mut rphf_lookups : Array[Int] = []
  let mut pref_lookups : Array[Int] = []
  if gsub is Some(gsub) {
    let lang_tag = language_to_ot_tag(self.language)
    rphf_lookups = match gsub.layout().select_lookup_offsets_for_feature(
      script_tag,
      indic_feature_tags[indic_feature_rphf],
      language_tag=lang_tag,
      include_required=false,
    ) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
    pref_lookups = match gsub.layout().select_lookup_offsets_for_feature(
      script_tag,
      indic_feature_tags[indic_feature_pref],
      language_tag=lang_tag,
      include_required=false,
    ) {
      Err(err) => return Err(Layout(err))
      Ok(value) => value
    }
  }
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let glyphs : Array[UInt] = []
  for info in self.infos {
    glyphs.push(info.codepoint)
  }
  let glyph_masks = build_indic_feature_masks(
    self.script,
    reordered_categories,
    reordered_positions,
    syllables_after,
    glyphs,
    gsub,
    rphf_lookups,
    pref_lookups,
  )
  if gsub is Some(gsub) {
    match apply_gsub_features_for_syllables(
      font,
      self,
      gsub,
      indic_feature_tags,
      syllables_after,
      glyph_masks=glyph_masks,
    ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  apply_gpos(font, self)
}
