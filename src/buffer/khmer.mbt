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
  let categories_after : Array[UInt] = []
  for info in self.infos {
    categories_after.push(indic_category(indic_get_categories(info.codepoint)))
  }
  let syllables_after = find_syllables_khmer(categories_after)
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
