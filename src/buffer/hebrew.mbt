///|
fn hebrew_lowercase_tag(tag : @common.Tag) -> @common.Tag {
  let (b1, b2, b3, b4) = tag.bytes()
  @common.Tag::from_bytes(
    hebrew_ascii_lowercase_byte(b1),
    hebrew_ascii_lowercase_byte(b2),
    hebrew_ascii_lowercase_byte(b3),
    hebrew_ascii_lowercase_byte(b4),
  )
}

///|
fn hebrew_ascii_lowercase_byte(b : Byte) -> Byte {
  let v = b.to_uint()
  if v >= 0x41U && v <= 0x5AU {
    (v + 0x20U).to_byte()
  } else {
    b
  }
}

///|
fn hebrew_layout_has_script(layout : @ot_tables.LayoutTable, tag : @common.Tag) -> Bool {
  let lower = hebrew_lowercase_tag(tag)
  for record in layout.script_list().records() {
    if record.tag == tag || record.tag == lower {
      return true
    }
  }
  false
}

///|
pub fn Buffer::shape_hebrew(
  self : Buffer,
  font : @font.Font,
) -> Result[Unit, ShapeError] {
  match self.shape_basic(font) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  let gsub = match font.gsub() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let gpos = match font.gpos() {
    Err(err) => return Err(Font(err))
    Ok(value) => value
  }
  let script_tag = self.script.to_tag()
  let lang_tag = language_to_ot_tag(self.language)
  let map = match @ot_map.OtMap::new(
    gsub,
    gpos,
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
      let new_infos : Array[GlyphInfo] = []
      let new_positions : Array[GlyphPosition] = []
      for i in 0..<next_glyphs.length() {
        let glyph = next_glyphs[i]
        let cluster = next_clusters[i]
        let pos = match default_position(self, font, glyph) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        new_infos.push(GlyphInfo::{ codepoint: glyph, cluster })
        new_positions.push(pos)
      }
      self.infos = new_infos
      self.positions = new_positions
    }
  }
  let mut selected_gpos : @ot_tables.GposTable? = None
  let hebr_tag = @common.Tag::from_chars('h', 'e', 'b', 'r')
  if gpos is Some(gpos) {
    if hebrew_layout_has_script(gpos.layout(), hebr_tag) {
      selected_gpos = Some(gpos)
    }
  }
  if selected_gpos is Some(gpos) {
    let gdef = match font.gdef() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    let glyphs : Array[UInt] = []
    for info in self.infos {
      glyphs.push(info.codepoint)
    }
    let deltas = match gdef {
      None =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          map.gpos_lookups(),
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
      Some(gdef) =>
        match gpos.position_deltas_with_lookups(
          glyphs[:],
          map.gpos_lookups(),
          gdef=gdef,
        ) {
          Err(err) => return Err(Layout(err))
          Ok(value) => value
        }
    }
    let new_positions : Array[GlyphPosition] = []
    for i in 0..<self.positions.length() {
      let pos = self.positions[i]
      let delta = deltas[i]
      new_positions.push(GlyphPosition::{
        x_advance: pos.x_advance + delta.x_advance,
        y_advance: pos.y_advance + delta.y_advance,
        x_offset: pos.x_offset + delta.x_placement,
        y_offset: pos.y_offset + delta.y_placement,
      })
    }
    self.positions = new_positions
  } else if self.direction.is_horizontal() {
    let kern = match font.kern() {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    if kern is Some(kern) {
      let new_positions : Array[GlyphPosition] = []
      for pos in self.positions {
        new_positions.push(pos)
      }
      if new_positions.length() >= 2 {
        for i in 0..<(new_positions.length() - 1) {
          let left = self.infos[i].codepoint
          let right = self.infos[i + 1].codepoint
          match kern.kern_value(left, right) {
            None => ()
            Some(value) => {
              let pos = new_positions[i]
              new_positions[i] = GlyphPosition::{
                x_advance: pos.x_advance + value,
                y_advance: pos.y_advance,
                x_offset: pos.x_offset,
                y_offset: pos.y_offset,
              }
            }
          }
        }
      }
      self.positions = new_positions
    }
  }
  Ok(())
}
