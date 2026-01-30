///|
let khmer_feature_tags : Array[@common.Tag] = [
  @common.Tag::from_chars('l', 'o', 'c', 'l'),
  @common.Tag::from_chars('c', 'c', 'm', 'p'),
  @common.Tag::from_chars('p', 'r', 'e', 'f'),
  @common.Tag::from_chars('b', 'l', 'w', 'f'),
  @common.Tag::from_chars('a', 'b', 'v', 'f'),
  @common.Tag::from_chars('p', 's', 't', 'f'),
  @common.Tag::from_chars('c', 'f', 'a', 'r'),
  @common.Tag::from_chars('p', 'r', 'e', 's'),
  @common.Tag::from_chars('a', 'b', 'v', 's'),
  @common.Tag::from_chars('b', 'l', 'w', 's'),
  @common.Tag::from_chars('p', 's', 't', 's'),
  @common.Tag::from_chars('c', 'l', 'i', 'g'),
]

///|
let khmer_cat_h : Int = 4

///|
let khmer_cat_ra : Int = 15

///|
let khmer_cat_vpre : Int = 22

fn khmer_category(codepoint : UInt) -> Int {
  indic_category(indic_get_categories(codepoint)).reinterpret_as_int()
}

fn reorder_range_by_order(
  buffer : Buffer,
  categories : Array[Int],
  start : Int,
  order : Array[Int],
) -> Array[Int] {
  let end = start + order.length()
  if start < 0 || end > buffer.infos.length() || start >= end {
    return categories
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let next_categories : Array[Int] = []
  for i in 0..<start {
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    next_categories.push(categories[i])
  }
  for rel in order {
    let idx = start + rel
    next_infos.push(buffer.infos[idx])
    next_positions.push(buffer.positions[idx])
    next_categories.push(categories[idx])
  }
  for i in end..<buffer.infos.length() {
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    next_categories.push(categories[i])
  }
  buffer.infos = next_infos
  buffer.positions = next_positions
  next_categories
}

fn reorder_consonant_syllable_khmer(
  buffer : Buffer,
  categories : Array[Int],
  start : Int,
  end : Int,
) -> Array[Int] {
  if start < 0 || end > buffer.infos.length() || start >= end {
    return categories
  }
  buffer.merge_clusters(start, end)
  let mut coeng_index = -1
  let mut num_coengs = 0
  if start + 1 < end {
    for i in (start + 1)..<end {
      if i + 1 >= end {
        break
      }
      if categories[i] == khmer_cat_h && num_coengs <= 2 {
        num_coengs = num_coengs + 1
        if categories[i + 1] == khmer_cat_ra {
          coeng_index = i
          break
        }
      }
    }
  }
  let order : Array[Int] = []
  if coeng_index >= 0 {
    order.push(coeng_index - start)
    order.push(coeng_index + 1 - start)
  }
  for i in start..<end {
    if i == coeng_index || i == coeng_index + 1 {
      continue
    }
    if categories[i] == khmer_cat_vpre {
      order.push(i - start)
    }
  }
  for i in start..<end {
    if i == coeng_index || i == coeng_index + 1 {
      continue
    }
    if categories[i] != khmer_cat_vpre {
      order.push(i - start)
    }
  }
  reorder_range_by_order(buffer, categories, start, order)
}

fn reorder_khmer_syllables(
  buffer : Buffer,
  categories : Array[Int],
  syllables : Array[Int],
) -> Unit {
  if categories.length() != buffer.infos.length() || syllables.length() != buffer.infos.length() {
    return ()
  }
  let mut current_categories = categories
  let mut i = 0
  while i < syllables.length() {
    let syllable = syllables[i]
    let mut j = i + 1
    while j < syllables.length() && syllables[j] == syllable {
      j = j + 1
    }
    let syllable_type = syllable & 0x0f
    if syllable_type == khmer_syllable_type_consonant ||
      syllable_type == khmer_syllable_type_broken {
      current_categories = reorder_consonant_syllable_khmer(buffer, current_categories, i, j)
    }
    i = j
  }
}

///|
pub fn Buffer::shape_khmer(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let categories : Array[UInt] = []
  for info in self.infos {
    categories.push(indic_category(indic_get_categories(info.codepoint)))
  }
  let syllables = find_syllables_khmer(categories)
  match insert_dotted_circle_for_syllables(
    font,
    self,
    syllables,
    khmer_syllable_type_broken,
  ) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let categories_after_u : Array[UInt] = []
  let categories_after_i : Array[Int] = []
  for info in self.infos {
    let category = khmer_category(info.codepoint)
    categories_after_i.push(category)
    categories_after_u.push(category.reinterpret_as_uint())
  }
  let syllables_after = find_syllables_khmer(categories_after_u)
  reorder_khmer_syllables(self, categories_after_i, syllables_after)
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if gsub is Some(gsub) {
    match apply_gsub_features_for_syllables(
      font,
      self,
      gsub,
      khmer_feature_tags,
      syllables_after,
    ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  apply_gpos(font, self)
}
