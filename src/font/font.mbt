///|
suberror FontError {
  FaceTable(@face.FaceTableError)
  Parse(@sfnt.SfntError)
  Layout(@ot_tables.OtLayoutError)
  GlyphOutOfRange
} derive(Eq, Show, ToJson)

///|
/// Font ties a face to scale metrics.
pub struct Font {
  face : @face.Face
  mut scale_x : Int
  mut scale_y : Int
  mut ppem_x : Int
  mut ppem_y : Int
  mut head : @sfnt.HeadTable?
  mut maxp : @sfnt.MaxpTable?
  mut hhea : @sfnt.HheaTable?
  mut hmtx : @sfnt.HmtxTable?
  mut cmap : @sfnt.CmapTable?
  mut loca : @sfnt.LocaTable?
  mut glyf : @sfnt.GlyfTable?
  mut os2 : @sfnt.Os2Table?
  mut name : @sfnt.NameTable?
  mut kern : @sfnt.KernTable?
  mut gsub : @ot_tables.GsubTable?
  mut gpos : @ot_tables.GposTable?
  mut gdef : @ot_tables.GdefTable?
} derive(Show, ToJson)

///|
let tag_head : @common.Tag = @common.Tag::from_chars('h', 'e', 'a', 'd')

///|
let tag_maxp : @common.Tag = @common.Tag::from_chars('m', 'a', 'x', 'p')

///|
let tag_hhea : @common.Tag = @common.Tag::from_chars('h', 'h', 'e', 'a')

///|
let tag_hmtx : @common.Tag = @common.Tag::from_chars('h', 'm', 't', 'x')

///|
let tag_cmap : @common.Tag = @common.Tag::from_chars('c', 'm', 'a', 'p')

///|
let tag_loca : @common.Tag = @common.Tag::from_chars('l', 'o', 'c', 'a')

///|
let tag_glyf : @common.Tag = @common.Tag::from_chars('g', 'l', 'y', 'f')

///|
let tag_os2 : @common.Tag = @common.Tag::from_chars('O', 'S', '/', '2')

///|
let tag_name : @common.Tag = @common.Tag::from_chars('n', 'a', 'm', 'e')

///|
let tag_kern : @common.Tag = @common.Tag::from_chars('k', 'e', 'r', 'n')

///|
let tag_gsub : @common.Tag = @common.Tag::from_chars('G', 'S', 'U', 'B')

///|
let tag_gpos : @common.Tag = @common.Tag::from_chars('G', 'P', 'O', 'S')

///|
let tag_gdef : @common.Tag = @common.Tag::from_chars('G', 'D', 'E', 'F')

///|
/// Create a font from a face.
pub fn Font::new(face : @face.Face) -> Font {
  Font::{
    face,
    scale_x: 0,
    scale_y: 0,
    ppem_x: 0,
    ppem_y: 0,
    head: None,
    maxp: None,
    hhea: None,
    hmtx: None,
    cmap: None,
    loca: None,
    glyf: None,
    os2: None,
    name: None,
    kern: None,
    gsub: None,
    gpos: None,
    gdef: None,
  }
}

///|
/// Create a font from raw bytes.
pub fn Font::from_bytes(bytes : Bytes) -> Font {
  Font::new(@face.Face::from_bytes(bytes))
}

///|
/// Access the face.
pub fn Font::get_face(self : Font) -> @face.Face {
  self.face
}

///|
/// Set scale values (in 26.6 fixed-point like HarfBuzz).
pub fn Font::set_scale(self : Font, x : Int, y : Int) -> Unit {
  self.scale_x = x
  self.scale_y = y
}

///|
/// Get scale values.
pub fn Font::get_scale(self : Font) -> (Int, Int) {
  (self.scale_x, self.scale_y)
}

///|
/// Set ppem values.
pub fn Font::set_ppem(self : Font, x : Int, y : Int) -> Unit {
  self.ppem_x = x
  self.ppem_y = y
}

///|
/// Get ppem values.
pub fn Font::get_ppem(self : Font) -> (Int, Int) {
  (self.ppem_x, self.ppem_y)
}

///|
fn Font::table_blob(
  self : Font,
  tag : @common.Tag,
) -> Result[@blob.Blob, FontError] {
  match self.face.reference_table(tag) {
    Err(err) => Err(FaceTable(err))
    Ok(blob) => Ok(blob)
  }
}

///|
fn Font::ensure_head(self : Font) -> Result[@sfnt.HeadTable, FontError] {
  match self.head {
    Some(head) => Ok(head)
    None =>
      match self.table_blob(tag_head) {
        Err(err) => Err(err)
        Ok(blob) =>
          match @sfnt.HeadTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(head) => {
              self.head = Some(head)
              self.face.set_upem(head.units_per_em)
              Ok(head)
            }
          }
      }
  }
}

///|
fn Font::ensure_maxp(self : Font) -> Result[@sfnt.MaxpTable, FontError] {
  match self.maxp {
    Some(maxp) => Ok(maxp)
    None =>
      match self.table_blob(tag_maxp) {
        Err(err) => Err(err)
        Ok(blob) =>
          match @sfnt.MaxpTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(maxp) => {
              self.maxp = Some(maxp)
              self.face.set_glyph_count(maxp.num_glyphs)
              Ok(maxp)
            }
          }
      }
  }
}

///|
fn Font::ensure_hhea(self : Font) -> Result[@sfnt.HheaTable, FontError] {
  match self.hhea {
    Some(hhea) => Ok(hhea)
    None =>
      match self.table_blob(tag_hhea) {
        Err(err) => Err(err)
        Ok(blob) =>
          match @sfnt.HheaTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(hhea) => {
              self.hhea = Some(hhea)
              Ok(hhea)
            }
          }
      }
  }
}

///|
fn Font::ensure_hmtx(self : Font) -> Result[@sfnt.HmtxTable, FontError] {
  match self.hmtx {
    Some(hmtx) => Ok(hmtx)
    None => {
      let maxp = match self.ensure_maxp() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let hhea = match self.ensure_hhea() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      match self.table_blob(tag_hmtx) {
        Err(err) => Err(err)
        Ok(blob) =>
          match
            @sfnt.HmtxTable::parse(
              blob.as_view(),
              maxp.num_glyphs,
              hhea.number_of_hmetrics,
            ) {
            Err(err) => Err(Parse(err))
            Ok(hmtx) => {
              self.hmtx = Some(hmtx)
              Ok(hmtx)
            }
          }
      }
    }
  }
}

///|
fn Font::ensure_cmap(self : Font) -> Result[@sfnt.CmapTable, FontError] {
  match self.cmap {
    Some(cmap) => Ok(cmap)
    None =>
      match self.table_blob(tag_cmap) {
        Err(err) => Err(err)
        Ok(blob) =>
          match @sfnt.CmapTable::parse(blob) {
            Err(err) => Err(Parse(err))
            Ok(cmap) => {
              self.cmap = Some(cmap)
              Ok(cmap)
            }
          }
      }
  }
}

///|
fn Font::ensure_loca(self : Font) -> Result[@sfnt.LocaTable, FontError] {
  match self.loca {
    Some(loca) => Ok(loca)
    None => {
      let head = match self.ensure_head() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let maxp = match self.ensure_maxp() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      match self.table_blob(tag_loca) {
        Err(err) => Err(err)
        Ok(blob) =>
          match
            @sfnt.LocaTable::parse(
              blob.as_view(),
              maxp.num_glyphs,
              head.index_to_loc_format,
            ) {
            Err(err) => Err(Parse(err))
            Ok(loca) => {
              self.loca = Some(loca)
              Ok(loca)
            }
          }
      }
    }
  }
}

///|
fn Font::ensure_glyf(self : Font) -> Result[@sfnt.GlyfTable, FontError] {
  match self.glyf {
    Some(glyf) => Ok(glyf)
    None =>
      match self.table_blob(tag_glyf) {
        Err(err) => Err(err)
        Ok(blob) =>
          match @sfnt.GlyfTable::parse(blob) {
            Err(err) => Err(Parse(err))
            Ok(glyf) => {
              self.glyf = Some(glyf)
              Ok(glyf)
            }
          }
      }
  }
}

///|
pub fn Font::os2(self : Font) -> Result[@sfnt.Os2Table?, FontError] {
  match self.os2 {
    Some(os2) => Ok(Some(os2))
    None =>
      match self.face.reference_table_optional(tag_os2) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.Os2Table::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(os2) => {
              self.os2 = Some(os2)
              Ok(Some(os2))
            }
          }
      }
  }
}

///|
pub fn Font::name(self : Font) -> Result[@sfnt.NameTable?, FontError] {
  match self.name {
    Some(name) => Ok(Some(name))
    None =>
      match self.face.reference_table_optional(tag_name) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.NameTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(name) => {
              self.name = Some(name)
              Ok(Some(name))
            }
          }
      }
  }
}

///|
pub fn Font::gsub(self : Font) -> Result[@ot_tables.GsubTable?, FontError] {
  match self.gsub {
    Some(gsub) => Ok(Some(gsub))
    None =>
      match self.face.reference_table_optional(tag_gsub) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @ot_tables.GsubTable::parse(blob) {
            Err(err) => Err(Layout(err))
            Ok(gsub) => {
              self.gsub = Some(gsub)
              Ok(Some(gsub))
            }
          }
      }
  }
}

///|
pub fn Font::kern(self : Font) -> Result[@sfnt.KernTable?, FontError] {
  match self.kern {
    Some(kern) => Ok(Some(kern))
    None =>
      match self.face.reference_table_optional(tag_kern) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.KernTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(kern) => {
              self.kern = Some(kern)
              Ok(Some(kern))
            }
          }
      }
  }
}

///|
pub fn Font::gpos(self : Font) -> Result[@ot_tables.GposTable?, FontError] {
  match self.gpos {
    Some(gpos) => Ok(Some(gpos))
    None =>
      match self.face.reference_table_optional(tag_gpos) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @ot_tables.GposTable::parse(blob) {
            Err(err) => Err(Layout(err))
            Ok(gpos) => {
              self.gpos = Some(gpos)
              Ok(Some(gpos))
            }
          }
      }
  }
}

///|
pub fn Font::gdef(self : Font) -> Result[@ot_tables.GdefTable?, FontError] {
  match self.gdef {
    Some(gdef) => Ok(Some(gdef))
    None =>
      match self.face.reference_table_optional(tag_gdef) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @ot_tables.GdefTable::parse(blob) {
            Err(err) => Err(Layout(err))
            Ok(gdef) => {
              self.gdef = Some(gdef)
              Ok(Some(gdef))
            }
          }
      }
  }
}

///|
/// Map a codepoint to a glyph id.
pub fn Font::glyph_for_codepoint(
  self : Font,
  codepoint : UInt,
) -> Result[UInt?, FontError] {
  match self.ensure_cmap() {
    Err(err) => Err(err)
    Ok(cmap) =>
      match cmap.glyph_for(codepoint) {
        Err(err) => Err(Parse(err))
        Ok(value) => Ok(value)
      }
  }
}

///|
/// Return glyph horizontal advance.
pub fn Font::glyph_h_advance(
  self : Font,
  glyph : UInt,
) -> Result[Int, FontError] {
  let hmtx = match self.ensure_hmtx() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let index = glyph.reinterpret_as_int()
  if index < 0 || index >= hmtx.advances.length() {
    return Err(GlyphOutOfRange)
  }
  Ok(hmtx.advances[index])
}

///|
/// Return glyph bounds from glyf header (font units).
pub fn Font::glyph_bounds(
  self : Font,
  glyph : UInt,
) -> Result[@sfnt.GlyphBounds?, FontError] {
  let maxp = match self.ensure_maxp() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let index = glyph.reinterpret_as_int()
  if index < 0 || index >= maxp.num_glyphs {
    return Err(GlyphOutOfRange)
  }
  let loca = match self.ensure_loca() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let glyf = match self.ensure_glyf() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let offsets = loca.offsets
  if index + 1 >= offsets.length() {
    return Err(GlyphOutOfRange)
  }
  let start = offsets[index]
  let end = offsets[index + 1]
  let length = end - start
  match glyf.glyph_bounds(start, length) {
    Err(err) => Err(Parse(err))
    Ok(bounds) => Ok(bounds)
  }
}

///|
/// Return glyph vertical advance (stub).
pub fn Font::glyph_v_advance(
  _self : Font,
  _glyph : UInt,
) -> Result[Int, FontError] {
  Ok(0)
}
