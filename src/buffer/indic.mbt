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
pub fn Buffer::shape_indic(
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
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if gsub is Some(gsub) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let script_tag = self.script.to_tag()
    let lang_tag = language_to_ot_tag(self.language)
    let mut current_glyphs : Array[UInt] = []
    let mut current_clusters : Array[Int] = []
    for info in self.infos {
      current_glyphs.push(info.codepoint)
      current_clusters.push(info.cluster)
    }
    let mut changed = false
    for feature_tag in indic_feature_tags {
      let lookup_offsets = match gsub.layout().select_lookup_offsets_for_feature(
        script_tag,
        feature_tag,
        language_tag=lang_tag,
        include_required=false,
      ) {
        Err(err) => return Err(Layout(err))
        Ok(value) => value
      }
      if lookup_offsets.is_empty() {
        continue
      }
      let result = match gdef {
        None =>
          match gsub.apply_with_lookups(
            current_glyphs,
            current_clusters,
            lookup_offsets[:],
          ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
        Some(gdef) =>
          match gsub.apply_with_lookups(
            current_glyphs,
            current_clusters,
            lookup_offsets[:],
            gdef=gdef,
          ) {
            Err(err) => return Err(Layout(err))
            Ok(value) => value
          }
      }
      let (next_glyphs, next_clusters, did_change) = result
      current_glyphs = next_glyphs
      current_clusters = next_clusters
      if did_change {
        changed = true
      }
    }
    if changed || current_glyphs.length() != self.infos.length() {
      let infos : Array[GlyphInfo] = []
      let positions : Array[GlyphPosition] = []
      for i in 0..<current_glyphs.length() {
        let glyph = current_glyphs[i]
        let pos = match default_position(self, font, glyph) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        infos.push(GlyphInfo::{ codepoint: glyph, cluster: current_clusters[i] })
        positions.push(pos)
      }
      self.infos = infos
      self.positions = positions
    }
  }
  apply_gpos(font, self)
}
