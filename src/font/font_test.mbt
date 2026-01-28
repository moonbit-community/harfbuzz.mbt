///|
test "font basics" {
  let font = Font::from_bytes([0x00, 0x01])
  let (sx, sy) = font.get_scale()
  inspect((sx, sy), content="(0, 0)")
  font.set_scale(1000, 2000)
  inspect(font.get_scale(), content="(1000, 2000)")
  font.set_ppem(12, 14)
  inspect(font.get_ppem(), content="(12, 14)")
}

///|
test "font face access" {
  let font = Font::from_bytes([0x00])
  let face = font.get_face()
  inspect(face.get_index(), content="0")
}
