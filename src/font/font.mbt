///|
suberror FontError {
  FaceTable(@face.FaceTableError)
  Parse(@sfnt.SfntError)
  Var(@ot_var.VarError)
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
  mut vhea : @sfnt.VheaTable?
  mut vmtx : @sfnt.VmtxTable?
  mut cmap : @sfnt.CmapTable?
  mut loca : @sfnt.LocaTable?
  mut glyf : @sfnt.GlyfTable?
  mut os2 : @sfnt.Os2Table?
  mut name : @sfnt.NameTable?
  mut post : @sfnt.PostTable?
  mut gasp : @sfnt.GaspTable?
  mut meta : @sfnt.MetaTable?
  mut vorg : @sfnt.VorgTable?
  mut hdmx : @sfnt.HdmxTable?
  mut stat : @sfnt.StatTable?
  mut base : @sfnt.BaseTable?
  mut jstf : @sfnt.JstfTable?
  mut math : @sfnt.MathTable?
  mut kern : @sfnt.KernTable?
  mut gsub : @ot_tables.GsubTable?
  mut gpos : @ot_tables.GposTable?
  mut gdef : @ot_tables.GdefTable?
  mut fvar : @ot_var.FvarTable?
  mut avar : @ot_var.AvarTable?
  mut var_coords_design : Array[Double]?
  mut var_coords_norm : Array[Int]?
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
let tag_vhea : @common.Tag = @common.Tag::from_chars('v', 'h', 'e', 'a')

///|
let tag_vmtx : @common.Tag = @common.Tag::from_chars('v', 'm', 't', 'x')

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
let tag_post : @common.Tag = @common.Tag::from_chars('p', 'o', 's', 't')

///|
let tag_gasp : @common.Tag = @common.Tag::from_chars('g', 'a', 's', 'p')

///|
let tag_meta : @common.Tag = @common.Tag::from_chars('m', 'e', 't', 'a')

///|
let tag_vorg : @common.Tag = @common.Tag::from_chars('V', 'O', 'R', 'G')

///|
let tag_hdmx : @common.Tag = @common.Tag::from_chars('h', 'd', 'm', 'x')

///|
let tag_stat : @common.Tag = @common.Tag::from_chars('S', 'T', 'A', 'T')

///|
let tag_kern : @common.Tag = @common.Tag::from_chars('k', 'e', 'r', 'n')

///|
let tag_base : @common.Tag = @common.Tag::from_chars('B', 'A', 'S', 'E')

///|
let tag_jstf : @common.Tag = @common.Tag::from_chars('J', 'S', 'T', 'F')

///|
let tag_math : @common.Tag = @common.Tag::from_chars('M', 'A', 'T', 'H')

///|
let tag_gsub : @common.Tag = @common.Tag::from_chars('G', 'S', 'U', 'B')

///|
let tag_gpos : @common.Tag = @common.Tag::from_chars('G', 'P', 'O', 'S')

///|
let tag_gdef : @common.Tag = @common.Tag::from_chars('G', 'D', 'E', 'F')

///|
let tag_fvar : @common.Tag = @common.Tag::from_chars('f', 'v', 'a', 'r')

///|
let tag_avar : @common.Tag = @common.Tag::from_chars('a', 'v', 'a', 'r')

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
    vhea: None,
    vmtx: None,
    cmap: None,
    loca: None,
    glyf: None,
    os2: None,
    name: None,
    post: None,
    gasp: None,
    meta: None,
    vorg: None,
    hdmx: None,
    stat: None,
    base: None,
    jstf: None,
    math: None,
    kern: None,
    gsub: None,
    gpos: None,
    gdef: None,
    fvar: None,
    avar: None,
    var_coords_design: None,
    var_coords_norm: None,
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
              if self.scale_x == 0 {
                self.scale_x = head.units_per_em
              }
              if self.scale_y == 0 {
                self.scale_y = head.units_per_em
              }
              Ok(head)
            }
          }
      }
  }
}

///|
fn scale_value(value : Int, scale : Int, upem : Int) -> Int {
  if upem == 0 {
    return value
  }
  (value * scale) / upem
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
fn Font::ensure_vhea(self : Font) -> Result[@sfnt.VheaTable, FontError] {
  match self.vhea {
    Some(vhea) => Ok(vhea)
    None =>
      match self.table_blob(tag_vhea) {
        Err(err) => Err(err)
        Ok(blob) =>
          match @sfnt.VheaTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(vhea) => {
              self.vhea = Some(vhea)
              Ok(vhea)
            }
          }
      }
  }
}

///|
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
pub fn Font::post(self : Font) -> Result[@sfnt.PostTable?, FontError] {
  match self.post {
    Some(post) => Ok(Some(post))
    None =>
      match self.face.reference_table_optional(tag_post) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.PostTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(post) => {
              self.post = Some(post)
              Ok(Some(post))
            }
          }
      }
  }
}

///|
pub fn Font::gasp(self : Font) -> Result[@sfnt.GaspTable?, FontError] {
  match self.gasp {
    Some(gasp) => Ok(Some(gasp))
    None =>
      match self.face.reference_table_optional(tag_gasp) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.GaspTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(gasp) => {
              self.gasp = Some(gasp)
              Ok(Some(gasp))
            }
          }
      }
  }
}

///|
pub fn Font::meta(self : Font) -> Result[@sfnt.MetaTable?, FontError] {
  match self.meta {
    Some(meta) => Ok(Some(meta))
    None =>
      match self.face.reference_table_optional(tag_meta) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.MetaTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(meta) => {
              self.meta = Some(meta)
              Ok(Some(meta))
            }
          }
      }
  }
}

///|
pub fn Font::vorg(self : Font) -> Result[@sfnt.VorgTable?, FontError] {
  match self.vorg {
    Some(vorg) => Ok(Some(vorg))
    None =>
      match self.face.reference_table_optional(tag_vorg) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.VorgTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(vorg) => {
              self.vorg = Some(vorg)
              Ok(Some(vorg))
            }
          }
      }
  }
}

///|
pub fn Font::hdmx(self : Font) -> Result[@sfnt.HdmxTable?, FontError] {
  match self.hdmx {
    Some(hdmx) => Ok(Some(hdmx))
    None =>
      match self.face.reference_table_optional(tag_hdmx) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.HdmxTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(hdmx) => {
              self.hdmx = Some(hdmx)
              Ok(Some(hdmx))
            }
          }
      }
  }
}

///|
pub fn Font::stat(self : Font) -> Result[@sfnt.StatTable?, FontError] {
  match self.stat {
    Some(stat) => Ok(Some(stat))
    None =>
      match self.face.reference_table_optional(tag_stat) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.StatTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(stat) => {
              self.stat = Some(stat)
              Ok(Some(stat))
            }
          }
      }
  }
}

///|
pub fn Font::vhea(self : Font) -> Result[@sfnt.VheaTable?, FontError] {
  match self.vhea {
    Some(vhea) => Ok(Some(vhea))
    None =>
      match self.face.reference_table_optional(tag_vhea) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.VheaTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(vhea) => {
              self.vhea = Some(vhea)
              Ok(Some(vhea))
            }
          }
      }
  }
}

///|
pub fn Font::vmtx(self : Font) -> Result[@sfnt.VmtxTable?, FontError] {
  match self.vmtx {
    Some(vmtx) => Ok(Some(vmtx))
    None =>
      match self.face.reference_table_optional(tag_vmtx) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) => {
          let maxp = match self.ensure_maxp() {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let vhea = match self.ensure_vhea() {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          match
            @sfnt.VmtxTable::parse(
              blob.as_view(),
              maxp.num_glyphs,
              vhea.number_of_vmetrics,
            ) {
            Err(err) => Err(Parse(err))
            Ok(vmtx) => {
              self.vmtx = Some(vmtx)
              Ok(Some(vmtx))
            }
          }
        }
      }
  }
}

///|
pub fn Font::base(self : Font) -> Result[@sfnt.BaseTable?, FontError] {
  match self.base {
    Some(base) => Ok(Some(base))
    None =>
      match self.face.reference_table_optional(tag_base) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.BaseTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(base) => {
              self.base = Some(base)
              Ok(Some(base))
            }
          }
      }
  }
}

///|
pub fn Font::jstf(self : Font) -> Result[@sfnt.JstfTable?, FontError] {
  match self.jstf {
    Some(jstf) => Ok(Some(jstf))
    None =>
      match self.face.reference_table_optional(tag_jstf) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.JstfTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(jstf) => {
              self.jstf = Some(jstf)
              Ok(Some(jstf))
            }
          }
      }
  }
}

///|
pub fn Font::math(self : Font) -> Result[@sfnt.MathTable?, FontError] {
  match self.math {
    Some(math) => Ok(Some(math))
    None =>
      match self.face.reference_table_optional(tag_math) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @sfnt.MathTable::parse(blob.as_view()) {
            Err(err) => Err(Parse(err))
            Ok(math) => {
              self.math = Some(math)
              Ok(Some(math))
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
pub fn Font::fvar(self : Font) -> Result[@ot_var.FvarTable?, FontError] {
  match self.fvar {
    Some(fvar) => Ok(Some(fvar))
    None =>
      match self.face.reference_table_optional(tag_fvar) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @ot_var.FvarTable::parse(blob.as_view()) {
            Err(err) => Err(Var(err))
            Ok(fvar) => {
              self.fvar = Some(fvar)
              Ok(Some(fvar))
            }
          }
      }
  }
}

///|
pub fn Font::avar(self : Font) -> Result[@ot_var.AvarTable?, FontError] {
  match self.avar {
    Some(avar) => Ok(Some(avar))
    None =>
      match self.face.reference_table_optional(tag_avar) {
        Err(err) => Err(FaceTable(err))
        Ok(None) => Ok(None)
        Ok(Some(blob)) =>
          match @ot_var.AvarTable::parse(blob.as_view()) {
            Err(err) => Err(Var(err))
            Ok(avar) => {
              self.avar = Some(avar)
              Ok(Some(avar))
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
/// Map a codepoint + variation selector to a glyph id, if supported.
pub fn Font::variation_glyph_for(
  self : Font,
  codepoint : UInt,
  selector : UInt,
) -> Result[(Bool, UInt?), FontError] {
  match self.ensure_cmap() {
    Err(err) => Err(err)
    Ok(cmap) =>
      match cmap.variation_mapping(codepoint, selector) {
        Err(err) => Err(Parse(err))
        Ok(value) => Ok(value)
      }
  }
}

///|
pub fn Font::set_variations(
  self : Font,
  variations : Array[@ot_var.AxisCoord],
) -> Result[Unit, FontError] {
  let fvar = match self.fvar() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match fvar {
    None => {
      self.var_coords_design = None
      self.var_coords_norm = None
      Ok(())
    }
    Some(fvar) => {
      let axis_count = fvar.axes.length()
      let design_coords : Array[Double] = Array::make(axis_count, 0.0)
      for i in 0..<axis_count {
        design_coords[i] = fvar.axes[i].default_value
      }
      for variation in variations {
        match fvar.axis_index(variation.tag) {
          None => ()
          Some(index) => if index >= 0 && index < axis_count {
            design_coords[index] = variation.value
          }
        }
      }
      let mut normalized = fvar.normalize_design_coords(design_coords.copy())
      match self.avar() {
        Err(err) => return Err(err)
        Ok(None) => ()
        Ok(Some(avar)) => normalized = avar.map_coords_16_16(normalized)
      }
      self.var_coords_design = Some(design_coords)
      self.var_coords_norm = Some(normalized)
      Ok(())
    }
  }
}

///|
pub fn Font::variation_coords(self : Font) -> Array[Int] {
  match self.var_coords_norm {
    None => []
    Some(coords) => coords.copy()
  }
}

///|
/// Return glyph horizontal advance.
pub fn Font::glyph_h_advance(
  self : Font,
  glyph : UInt,
) -> Result[Int, FontError] {
  let head = match self.ensure_head() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hmtx = match self.ensure_hmtx() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let index = glyph.reinterpret_as_int()
  if index < 0 || index >= hmtx.advances.length() {
    return Err(GlyphOutOfRange)
  }
  Ok(scale_value(hmtx.advances[index], self.scale_x, head.units_per_em))
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
/// Return glyph vertical advance.
pub fn Font::glyph_v_advance(
  self : Font,
  glyph : UInt,
) -> Result[Int, FontError] {
  let head = match self.ensure_head() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let vmtx = match self.vmtx() {
    Err(err) => return Err(err)
    Ok(None) => return Ok(0)
    Ok(Some(value)) => value
  }
  let index = glyph.reinterpret_as_int()
  if index < 0 || index >= vmtx.advances.length() {
    return Err(GlyphOutOfRange)
  }
  Ok(-scale_value(vmtx.advances[index], self.scale_y, head.units_per_em))
}
