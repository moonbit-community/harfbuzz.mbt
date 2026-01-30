///|
let use_feature_tags : Array[@common.Tag] = [
  @common.Tag::from_chars('l', 'o', 'c', 'l'),
  @common.Tag::from_chars('c', 'c', 'm', 'p'),
  @common.Tag::from_chars('n', 'u', 'k', 't'),
  @common.Tag::from_chars('a', 'k', 'h', 'n'),
  @common.Tag::from_chars('r', 'p', 'h', 'f'),
  @common.Tag::from_chars('p', 'r', 'e', 'f'),
  @common.Tag::from_chars('r', 'k', 'r', 'f'),
  @common.Tag::from_chars('a', 'b', 'v', 'f'),
  @common.Tag::from_chars('b', 'l', 'w', 'f'),
  @common.Tag::from_chars('h', 'a', 'l', 'f'),
  @common.Tag::from_chars('p', 's', 't', 'f'),
  @common.Tag::from_chars('v', 'a', 't', 'u'),
  @common.Tag::from_chars('c', 'j', 'c', 't'),
  @common.Tag::from_chars('i', 's', 'o', 'l'),
  @common.Tag::from_chars('i', 'n', 'i', 't'),
  @common.Tag::from_chars('m', 'e', 'd', 'i'),
  @common.Tag::from_chars('f', 'i', 'n', 'a'),
  @common.Tag::from_chars('a', 'b', 'v', 's'),
  @common.Tag::from_chars('b', 'l', 'w', 's'),
  @common.Tag::from_chars('h', 'a', 'l', 'n'),
  @common.Tag::from_chars('p', 'r', 'e', 's'),
  @common.Tag::from_chars('p', 's', 't', 's'),
]

///|
let use_cat_r : Int = 18

///|
let use_cat_h : Int = 12

///|
let use_cat_hvm : Int = 53

///|
let use_cat_is : Int = 44

///|
let use_cat_vpre : Int = 22

///|
let use_cat_vmpre : Int = 23

///|
let use_cat_fabv : Int = 24

///|
let use_cat_fblw : Int = 25

///|
let use_cat_fpst : Int = 26

///|
let use_cat_fmabv : Int = 45

///|
let use_cat_fmblw : Int = 46

///|
let use_cat_fmpst : Int = 47

///|
let use_cat_mabv : Int = 27

///|
let use_cat_mblw : Int = 28

///|
let use_cat_mpre : Int = 30

///|
let use_cat_mpst : Int = 29

///|
let use_cat_vabv : Int = 33

///|
let use_cat_vblw : Int = 34

///|
let use_cat_vpst : Int = 35

///|
let use_cat_vmabv : Int = 37

///|
let use_cat_vmblw : Int = 38

///|
let use_cat_vmpst : Int = 39

fn use_category(codepoint : UInt) -> Int {
  use_get_category(codepoint).reinterpret_as_int()
}

fn is_halant_use(category : Int) -> Bool {
  category == use_cat_h || category == use_cat_hvm || category == use_cat_is
}

fn is_post_base_use(category : Int) -> Bool {
  category == use_cat_fabv ||
  category == use_cat_fblw ||
  category == use_cat_fpst ||
  category == use_cat_fmabv ||
  category == use_cat_fmblw ||
  category == use_cat_fmpst ||
  category == use_cat_mabv ||
  category == use_cat_mblw ||
  category == use_cat_mpst ||
  category == use_cat_mpre ||
  category == use_cat_vabv ||
  category == use_cat_vblw ||
  category == use_cat_vpst ||
  category == use_cat_vpre ||
  category == use_cat_vmabv ||
  category == use_cat_vmblw ||
  category == use_cat_vmpst ||
  category == use_cat_vmpre
}

fn move_index_use(
  buffer : Buffer,
  categories : Array[Int],
  from : Int,
  to : Int,
) -> Array[Int] {
  if from == to || from < 0 || to < 0 || from >= buffer.infos.length() || to >= buffer.infos.length() {
    return categories
  }
  let info = buffer.infos[from]
  let pos = buffer.positions[from]
  let cat = categories[from]
  let next_categories = categories
  if from < to {
    let mut i = from
    while i < to {
      buffer.infos[i] = buffer.infos[i + 1]
      buffer.positions[i] = buffer.positions[i + 1]
      next_categories[i] = next_categories[i + 1]
      i = i + 1
    }
    buffer.infos[to] = info
    buffer.positions[to] = pos
    next_categories[to] = cat
  } else {
    let mut i = from
    while i > to {
      buffer.infos[i] = buffer.infos[i - 1]
      buffer.positions[i] = buffer.positions[i - 1]
      next_categories[i] = next_categories[i - 1]
      i = i - 1
    }
    buffer.infos[to] = info
    buffer.positions[to] = pos
    next_categories[to] = cat
  }
  next_categories
}

fn reorder_syllable_use(
  buffer : Buffer,
  categories : Array[Int],
  start : Int,
  end : Int,
) -> Array[Int] {
  if start < 0 || end > buffer.infos.length() || start >= end {
    return categories
  }
  let mut next_categories = categories
  if next_categories[start] == use_cat_r && end - start > 1 {
    let mut target = end - 1
    for i in (start + 1)..<end {
      let cat = next_categories[i]
      let is_post_base = is_post_base_use(cat) || is_halant_use(cat)
      if is_post_base || i == end - 1 {
        target = if is_post_base { i - 1 } else { i }
        break
      }
    }
    buffer.merge_clusters(start, target + 1)
    next_categories = move_index_use(buffer, next_categories, start, target)
  }
  let mut j = start
  let mut i = start
  while i < end {
    let cat = next_categories[i]
    if is_halant_use(cat) {
      j = i + 1
    } else if (cat == use_cat_vpre || cat == use_cat_vmpre) && j < i {
      buffer.merge_clusters(j, i + 1)
      next_categories = move_index_use(buffer, next_categories, i, j)
      j = j + 1
    }
    i = i + 1
  }
  next_categories
}

fn reorder_use_syllables(
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
    let allowed = syllable_type == use_syllable_type_virama_terminated_cluster ||
      syllable_type == use_syllable_type_sakot_terminated_cluster ||
      syllable_type == use_syllable_type_standard_cluster ||
      syllable_type == use_syllable_type_symbol_cluster ||
      syllable_type == use_syllable_type_broken_cluster
    if allowed {
      current_categories = reorder_syllable_use(buffer, current_categories, i, j)
    }
    i = j
  }
}

///|
pub fn Buffer::shape_use(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if gsub is Some(gsub) {
    let script_tag = self.script.to_tag()
    let dflt_tag = @common.Tag::from_chars('D', 'F', 'L', 'T')
    let latn_tag = @common.Tag::from_chars('l', 'a', 't', 'n')
    if !buffer_layout_has_script(gsub.layout(), script_tag) &&
      (buffer_layout_has_script(gsub.layout(), dflt_tag) ||
        buffer_layout_has_script(gsub.layout(), latn_tag)) {
      return self.shape_ot(font)
    }
  }
  let categories : Array[UInt] = []
  let marks : Array[Bool] = []
  for info in self.infos {
    categories.push(use_get_category(info.codepoint))
    marks.push(@unicode.is_mark(info.codepoint))
  }
  let syllables = find_syllables_use(categories, marks)
  match insert_dotted_circle_for_syllables(
    font,
    self,
    syllables,
    use_syllable_type_broken_cluster,
  ) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let categories_after_u : Array[UInt] = []
  let categories_after_i : Array[Int] = []
  let marks_after : Array[Bool] = []
  for info in self.infos {
    let category = use_category(info.codepoint)
    categories_after_i.push(category)
    categories_after_u.push(category.reinterpret_as_uint())
    marks_after.push(@unicode.is_mark(info.codepoint))
  }
  let syllables_after = find_syllables_use(categories_after_u, marks_after)
  reorder_use_syllables(self, categories_after_i, syllables_after)
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if gsub is Some(gsub) {
    match apply_gsub_features_for_syllables(
      font,
      self,
      gsub,
      use_feature_tags,
      syllables_after,
    ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  apply_gpos(font, self)
}
