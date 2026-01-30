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
pub fn Buffer::shape_myanmar(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  if gsub is Some(gsub) {
    let script_tag = self.script.to_tag()
    let mym2_tag = @common.Tag::from_chars('m', 'y', 'm', '2')
    let dflt_tag = @common.Tag::from_chars('D', 'F', 'L', 'T')
    let latn_tag = @common.Tag::from_chars('l', 'a', 't', 'n')
    if !buffer_layout_has_script(gsub.layout(), mym2_tag) {
      if buffer_layout_has_script(gsub.layout(), script_tag) ||
        buffer_layout_has_script(gsub.layout(), dflt_tag) ||
        buffer_layout_has_script(gsub.layout(), latn_tag) {
        return self.shape_ot(font)
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
  let categories_after : Array[UInt] = []
  for info in self.infos {
    categories_after.push(indic_category(indic_get_categories(info.codepoint)))
  }
  let syllables_after = find_syllables_myanmar(categories_after)
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
    ) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  apply_gpos(font, self)
}
