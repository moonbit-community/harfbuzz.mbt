///|
pub fn Buffer::shape_hebrew(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  let (unicode_mark_flags, combining_classes) = collect_mark_fallback_data(self.infos)
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let script_tag = self.script.to_tag()
  let lang_tag = language_to_ot_tag(self.language)
  let map = match @ot_map.OtMap::new(
    gsub,
    None,
    script_tag,
    language_tag=lang_tag,
    gsub_features=self.gsub_features,
    gpos_features=self.gpos_features,
  ) {
    Err(err) => return Err(Layout(err))
    Ok(value) => value
  }
  if gsub is Some(gsub) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let glyphs : Array[UInt] = []
    let clusters : Array[Int] = []
    for info in self.infos {
      glyphs.push(info.codepoint)
      clusters.push(info.cluster)
    }
    let result = match gdef {
      None =>
        match gsub.apply_with_lookups(
          glyphs,
          clusters,
          map.gsub_lookups(),
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gsub.apply_with_lookups(
          glyphs,
          clusters,
          map.gsub_lookups(),
          gdef=gdef,
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
    }
    let (next_glyphs, next_clusters, changed) = result
    if changed || next_glyphs.length() != self.infos.length() {
      let same_len = next_glyphs.length() == self.infos.length()
      let new_infos : Array[GlyphInfo] = []
      let new_positions : Array[GlyphPosition] = []
      for i in 0..<next_glyphs.length() {
        let glyph = next_glyphs[i]
        let cluster = next_clusters[i]
        let pos = match default_position(self, font, glyph) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let unicode = if same_len { self.infos[i].unicode } else { 0U }
        new_infos.push(GlyphInfo::{ codepoint: glyph, cluster, unicode })
        new_positions.push(pos)
      }
      self.infos = new_infos
      self.positions = new_positions
    }
  }
  let hebr_tag = @common.Tag::from_chars('h', 'e', 'b', 'r')
  apply_gpos(
    font,
    self,
    zero_width_marks=ZeroWidthMarks::ByGdefLate,
    fallback_position=true,
    unicode_mark_flags=unicode_mark_flags,
    combining_classes=combining_classes,
    gpos_tag=Some(hebr_tag),
  )
}
