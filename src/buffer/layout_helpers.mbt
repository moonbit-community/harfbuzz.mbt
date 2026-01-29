///|
fn buffer_ascii_lowercase_byte(b : Byte) -> Byte {
  let v = b.to_uint()
  if v >= 0x41U && v <= 0x5AU {
    (v + 0x20U).to_byte()
  } else {
    b
  }
}

///|
fn buffer_lowercase_tag(tag : @common.Tag) -> @common.Tag {
  let (b1, b2, b3, b4) = tag.bytes()
  @common.Tag::from_bytes(
    buffer_ascii_lowercase_byte(b1),
    buffer_ascii_lowercase_byte(b2),
    buffer_ascii_lowercase_byte(b3),
    buffer_ascii_lowercase_byte(b4),
  )
}

///|
fn buffer_layout_has_script(layout : @ot_tables.LayoutTable, tag : @common.Tag) -> Bool {
  let lower = buffer_lowercase_tag(tag)
  for record in layout.script_list().records() {
    if record.tag == tag || record.tag == lower {
      return true
    }
  }
  false
}
