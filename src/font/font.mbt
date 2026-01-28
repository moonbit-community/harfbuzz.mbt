///|
suberror FontError {
  FaceTable(@face.FaceTableError)
  Parse(@sfnt.SfntError)
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
/// Return glyph vertical advance (stub).
pub fn Font::glyph_v_advance(
  _self : Font,
  _glyph : UInt,
) -> Result[Int, FontError] {
  Ok(0)
}
