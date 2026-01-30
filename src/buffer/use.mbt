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
  let categories_after : Array[UInt] = []
  let marks_after : Array[Bool] = []
  for info in self.infos {
    categories_after.push(use_get_category(info.codepoint))
    marks_after.push(@unicode.is_mark(info.codepoint))
  }
  let syllables_after = find_syllables_use(categories_after, marks_after)
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
