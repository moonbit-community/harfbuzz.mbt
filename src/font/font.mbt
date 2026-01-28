///|
/// Font ties a face to scale metrics.
pub struct Font {
  face : @face.Face
  mut scale_x : Int
  mut scale_y : Int
  mut ppem_x : Int
  mut ppem_y : Int
} derive(Show, ToJson)

///|
/// Create a font from a face.
pub fn Font::new(face : @face.Face) -> Font {
  Font::{ face, scale_x: 0, scale_y: 0, ppem_x: 0, ppem_y: 0 }
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
/// Return glyph horizontal advance (stub; returns 0).
pub fn Font::glyph_h_advance(_self : Font, _glyph : UInt) -> Int {
  0
}

///|
/// Return glyph vertical advance (stub; returns 0).
pub fn Font::glyph_v_advance(_self : Font, _glyph : UInt) -> Int {
  0
}
