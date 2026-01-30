///|
let myanmar_feature_tags : Array[@common.Tag] = [
  @common.Tag::from_chars('l', 'o', 'c', 'l'),
  @common.Tag::from_chars('c', 'c', 'm', 'p'),
  @common.Tag::from_chars('r', 'p', 'h', 'f'),
  @common.Tag::from_chars('p', 'r', 'e', 'f'),
  @common.Tag::from_chars('b', 'l', 'w', 'f'),
  @common.Tag::from_chars('p', 's', 't', 'f'),
  @common.Tag::from_chars('p', 'r', 'e', 's'),
  @common.Tag::from_chars('a', 'b', 'v', 's'),
  @common.Tag::from_chars('b', 'l', 'w', 's'),
  @common.Tag::from_chars('p', 's', 't', 's'),
]

///|
let myanmar_cat_c : Int = 1

///|
let myanmar_cat_cs : Int = 18

///|
let myanmar_cat_ra : Int = 15

///|
let myanmar_cat_iv : Int = 2

///|
let myanmar_cat_gb : Int = 10

///|
let myanmar_cat_dotted_circle : Int = 11

///|
let myanmar_cat_as : Int = 32

///|
let myanmar_cat_h : Int = 4

///|
let myanmar_cat_mr : Int = 36

///|
let myanmar_cat_vpre : Int = 22

///|
let myanmar_cat_vs : Int = 40

///|
let myanmar_cat_vblw : Int = 21

///|
let myanmar_cat_a : Int = 9

///|
let myanmar_pos_start : Int = 0

///|
let myanmar_pos_pre_m : Int = 2

///|
let myanmar_pos_pre_c : Int = 3

///|
let myanmar_pos_base_c : Int = 4

///|
let myanmar_pos_after_main : Int = 5

///|
let myanmar_pos_before_sub : Int = 7

///|
let myanmar_pos_below_c : Int = 8

///|
let myanmar_pos_after_sub : Int = 9

///|
let myanmar_pos_end : Int = 14

fn myanmar_category(codepoint : UInt) -> Int {
  indic_category(indic_get_categories(codepoint)).reinterpret_as_int()
}

fn is_consonant_myanmar(category : Int) -> Bool {
  category == myanmar_cat_c ||
  category == myanmar_cat_cs ||
  category == myanmar_cat_ra ||
  category == myanmar_cat_iv ||
  category == myanmar_cat_gb ||
  category == myanmar_cat_dotted_circle
}

fn reverse_range(buffer : Buffer, start : Int, end : Int) -> Unit {
  if start < 0 || end > buffer.infos.length() || start >= end {
    return ()
  }
  let mut i = start
  let mut j = end - 1
  while i < j {
    let tmp = buffer.infos[i]
    buffer.infos[i] = buffer.infos[j]
    buffer.infos[j] = tmp
    let tmp_pos = buffer.positions[i]
    buffer.positions[i] = buffer.positions[j]
    buffer.positions[j] = tmp_pos
    i = i + 1
    j = j - 1
  }
}

fn reorder_by_positions(
  buffer : Buffer,
  positions : Array[Int],
  start : Int,
  end : Int,
) -> Array[Int] {
  if start < 0 || end > buffer.infos.length() || start >= end {
    return positions
  }
  let range_len = end - start
  let order : Array[Int] = []
  for pos in myanmar_pos_start..=myanmar_pos_end {
    for rel in 0..<range_len {
      if positions[start + rel] == pos {
        order.push(rel)
      }
    }
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let next_pos_values : Array[Int] = []
  for i in 0..<start {
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    next_pos_values.push(positions[i])
  }
  for rel in order {
    let idx = start + rel
    next_infos.push(buffer.infos[idx])
    next_positions.push(buffer.positions[idx])
    next_pos_values.push(positions[idx])
  }
  for i in end..<buffer.infos.length() {
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    next_pos_values.push(positions[i])
  }
  buffer.infos = next_infos
  buffer.positions = next_positions
  next_pos_values
}

fn reorder_consonant_syllable_myanmar(
  buffer : Buffer,
  categories : Array[Int],
  start : Int,
  end : Int,
) -> Unit {
  if start < 0 || end > buffer.infos.length() || start >= end {
    return ()
  }
  buffer.merge_clusters(start, end)
  let mut base = end
  let mut has_reph = false
  let mut limit = start
  if start + 3 <= end &&
    categories[start] == myanmar_cat_ra &&
    categories[start + 1] == myanmar_cat_as &&
    categories[start + 2] == myanmar_cat_h {
    limit = limit + 3
    base = start
    has_reph = true
  }
  if !has_reph {
    base = limit
  }
  for i in limit..<end {
    if is_consonant_myanmar(categories[i]) {
      base = i
      break
    }
  }
  let pos_values : Array[Int] = Array::make(buffer.infos.length(), myanmar_pos_start)
  let reph_limit = if has_reph { start + 3 } else { start }
  for i in start..<reph_limit {
    pos_values[i] = myanmar_pos_after_main
  }
  for i in reph_limit..<base {
    pos_values[i] = myanmar_pos_pre_c
  }
  if base < end {
    pos_values[base] = myanmar_pos_base_c
  }
  let mut pos = myanmar_pos_after_main
  for i in (base + 1)..<end {
    let category = categories[i]
    if category == myanmar_cat_mr {
      pos_values[i] = myanmar_pos_pre_c
      continue
    }
    if category == myanmar_cat_vpre {
      pos_values[i] = myanmar_pos_pre_m
      continue
    }
    if category == myanmar_cat_vs {
      pos_values[i] = pos_values[i - 1]
      continue
    }
    if pos == myanmar_pos_after_main && category == myanmar_cat_vblw {
      pos = myanmar_pos_below_c
      pos_values[i] = pos
      continue
    }
    if pos == myanmar_pos_below_c && category == myanmar_cat_a {
      pos_values[i] = myanmar_pos_before_sub
      continue
    }
    if pos == myanmar_pos_below_c && category == myanmar_cat_vblw {
      pos_values[i] = pos
      continue
    }
    if pos == myanmar_pos_below_c && category != myanmar_cat_a {
      pos = myanmar_pos_after_sub
      pos_values[i] = pos
      continue
    }
    pos_values[i] = pos
  }
  let pos_values = reorder_by_positions(buffer, pos_values, start, end)
  let mut first_left = end
  let mut last_left = end
  for i in start..<end {
    if pos_values[i] == myanmar_pos_pre_m {
      if first_left == end {
        first_left = i
      }
      last_left = i
    }
  }
  if first_left < last_left {
    reverse_range(buffer, first_left, last_left + 1)
    let mut i = first_left
    for j in i..=last_left {
      let category = myanmar_category(buffer.infos[j].codepoint)
      if category == myanmar_cat_vpre {
        reverse_range(buffer, i, j + 1)
        i = j + 1
      }
    }
  }
}

fn reorder_myanmar_syllables(
  buffer : Buffer,
  categories : Array[Int],
  syllables : Array[Int],
) -> Unit {
  if categories.length() != buffer.infos.length() || syllables.length() != buffer.infos.length() {
    return ()
  }
  let mut i = 0
  while i < syllables.length() {
    let syllable = syllables[i]
    let mut j = i + 1
    while j < syllables.length() && syllables[j] == syllable {
      j = j + 1
    }
    let syllable_type = syllable & 0x0f
    if syllable_type == myanmar_syllable_type_consonant ||
      syllable_type == myanmar_syllable_type_broken {
      reorder_consonant_syllable_myanmar(buffer, categories, i, j)
    }
    i = j
  }
}

///|
pub fn Buffer::shape_myanmar(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let script_tag = self.script.to_tag()
  let mym2_tag = @common.Tag::from_chars('m', 'y', 'm', '2')
  let mut selected_script_tag = script_tag
  if gsub is Some(gsub) && buffer_layout_has_script(gsub.layout(), mym2_tag) {
    selected_script_tag = mym2_tag
  }
  if gsub is Some(gsub) {
    let dflt_tag = @common.Tag::from_chars('D', 'F', 'L', 'T')
    let latn_tag = @common.Tag::from_chars('l', 'a', 't', 'n')
    if !buffer_layout_has_script(gsub.layout(), mym2_tag) {
      if buffer_layout_has_script(gsub.layout(), script_tag) ||
        buffer_layout_has_script(gsub.layout(), dflt_tag) ||
        buffer_layout_has_script(gsub.layout(), latn_tag) {
        return self.shape_ot_with_options(
          font,
          fallback_position=false,
          zero_width_marks=ZeroWidthMarks::ByGdefEarly,
        )
      }
    }
  }
  let categories : Array[UInt] = []
  for info in self.infos {
    categories.push(indic_category(indic_get_categories(info.codepoint)))
  }
  let syllables = find_syllables_myanmar(categories)
  match insert_dotted_circle_for_syllables(
    font,
    self,
    syllables,
    myanmar_syllable_type_broken,
  ) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let categories_after_u : Array[UInt] = []
  let categories_after_i : Array[Int] = []
  for info in self.infos {
    let category = myanmar_category(info.codepoint)
    categories_after_i.push(category)
    categories_after_u.push(category.reinterpret_as_uint())
  }
  let syllables_after = find_syllables_myanmar(categories_after_u)
  reorder_myanmar_syllables(self, categories_after_i, syllables_after)
  let (unicode_mark_flags, combining_classes) = collect_mark_fallback_data(self.infos)
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if gsub is Some(gsub) {
    match apply_gsub_features_for_syllables(
      font,
      self,
      gsub,
      myanmar_feature_tags,
      syllables_after,
      script_tag=selected_script_tag,
    ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  apply_gpos(
    font,
    self,
    zero_width_marks=ZeroWidthMarks::ByGdefEarly,
    fallback_position=false,
    unicode_mark_flags=unicode_mark_flags,
    combining_classes=combining_classes,
  )
}
