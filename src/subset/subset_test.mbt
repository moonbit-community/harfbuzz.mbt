///|
fn push_u16(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16(bytes, adjusted)
}

///|
fn read_u16(data : BytesView, offset : Int) -> Int? {
  if offset + 2 > data.length() {
    return None
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  Some((b0 << 8) | b1)
}

///|
fn read_i16(data : BytesView, offset : Int) -> Int? {
  match read_u16(data, offset) {
    None => None
    Some(value) => if value >= 0x8000 { Some(value - 0x10000) } else { Some(value) }
  }
}

///|
fn read_u32(data : BytesView, offset : Int) -> Int? {
  if offset + 4 > data.length() {
    return None
  }
  let b0 = data[offset].to_int()
  let b1 = data[offset + 1].to_int()
  let b2 = data[offset + 2].to_int()
  let b3 = data[offset + 3].to_int()
  Some((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

///|
fn find_cmap_subtable(
  data : BytesView,
  platform : Int,
  encoding : Int,
) -> Int? {
  let count = read_u16(data, 2)
  match count {
    None => None
    Some(count) => {
      let mut i = 0
      while i < count {
        let base = 4 + i * 8
        let plat = read_u16(data, base)
        let enc = read_u16(data, base + 2)
        let offset = read_u32(data, base + 4)
        match (plat, enc, offset) {
          (Some(plat), Some(enc), Some(offset)) => {
            if plat == platform && enc == encoding {
              return Some(offset)
            }
          }
          _ => ()
        }
        i = i + 1
      }
      None
    }
  }
}

///|
fn push_u32(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn build_sfnt(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, tables.length())
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  let mut offset = 12 + tables.length() * 16
  let records : Array[(@common.Tag, Int, Int)] = []
  for entry in tables {
    let (tag, table) = entry
    records.push((tag, offset, table.length()))
    offset = offset + table.length()
  }
  for entry in records {
    let (tag, table_offset, length) = entry
    let (b1, b2, b3, b4) = tag.bytes()
    bytes.push(b1)
    bytes.push(b2)
    bytes.push(b3)
    bytes.push(b4)
    push_u32(bytes, 0)
    push_u32(bytes, table_offset)
    push_u32(bytes, length)
  }
  for entry in tables {
    let (_, table) = entry
    for b in table {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

///|
fn build_head(upem : Int, loc_format : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(54, b'\x00')
  bytes[18] = ((upem >> 8) & 0xff).to_byte()
  bytes[19] = (upem & 0xff).to_byte()
  bytes[50] = ((loc_format >> 8) & 0xff).to_byte()
  bytes[51] = (loc_format & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_maxp(num_glyphs : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(6, b'\x00')
  bytes[4] = ((num_glyphs >> 8) & 0xff).to_byte()
  bytes[5] = (num_glyphs & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_hhea(number_of_hmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_hmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_hmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_os2() -> Bytes {
  let bytes : Array[Byte] = Array::make(78, b'\x00')
  bytes[64] = 0x00
  bytes[65] = 0x41
  bytes[66] = 0x00
  bytes[67] = 0x42
  Bytes::from_array(bytes)
}

///|
fn build_cpal() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u32(bytes, 14)
  push_u16(bytes, 0)
  bytes.push(b'\x10')
  bytes.push(b'\x20')
  bytes.push(b'\x30')
  bytes.push(b'\x40')
  Bytes::from_array(bytes)
}

///|
fn build_post_table_v2() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00020000)
  push_u32(bytes, 0)
  push_i16(bytes, -50)
  push_i16(bytes, 20)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 258)
  push_u16(bytes, 2)
  bytes.push(3)
  bytes.push(b'f')
  bytes.push(b'o')
  bytes.push(b'o')
  Bytes::from_array(bytes)
}

///|
fn build_vorg_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_i16(bytes, 800)
  push_u16(bytes, 2)
  push_u16(bytes, 2)
  push_i16(bytes, 700)
  push_u16(bytes, 3)
  push_i16(bytes, 750)
  Bytes::from_array(bytes)
}

///|
fn build_kern_table() -> Bytes {
  let subtable0 = build_kern_subtable_format0()
  let subtable2 = build_kern_subtable_format2()
  let subtable3 = build_kern_subtable_format3()
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 3)
  for b in subtable0 {
    bytes.push(b)
  }
  for b in subtable2 {
    bytes.push(b)
  }
  for b in subtable3 {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_kern_subtable_format0() -> Bytes {
  let bytes : Array[Byte] = []
  let pair_count = 3
  let length = 14 + pair_count * 6
  push_u16(bytes, 0)
  push_u16(bytes, length)
  push_u16(bytes, 0x0001)
  push_u16(bytes, pair_count)
  push_u16(bytes, 12)
  push_u16(bytes, 1)
  push_u16(bytes, 6)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_i16(bytes, -20)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_i16(bytes, -30)
  push_u16(bytes, 2)
  push_u16(bytes, 3)
  push_i16(bytes, -50)
  Bytes::from_array(bytes)
}

///|
fn build_kern_subtable_format2() -> Bytes {
  let left_classes : Array[Int] = [0, 1, 1, 0]
  let right_classes : Array[Int] = [0, 1, 0, 1]
  let left_offset = 14
  let left_size = 4 + left_classes.length() * 2
  let right_offset = left_offset + left_size
  let right_size = 4 + right_classes.length() * 2
  let array_offset = right_offset + right_size
  let right_class_count = 2
  let row_width = right_class_count * 2
  let values : Array[Int] = [0, -20, -30, -40]
  let length = array_offset + values.length() * 2
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, length)
  push_u16(bytes, 0x0201)
  push_u16(bytes, row_width)
  push_u16(bytes, left_offset)
  push_u16(bytes, right_offset)
  push_u16(bytes, array_offset)
  push_u16(bytes, 0)
  push_u16(bytes, left_classes.length())
  for value in left_classes {
    push_u16(bytes, value)
  }
  push_u16(bytes, 0)
  push_u16(bytes, right_classes.length())
  for value in right_classes {
    push_u16(bytes, value)
  }
  for value in values {
    push_i16(bytes, value)
  }
  Bytes::from_array(bytes)
}

///|
fn build_kern_subtable_format3() -> Bytes {
  let glyph_count = 4
  let kern_values : Array[Int] = [0, -10, -50]
  let left_class : Array[Int] = [0, 1, 1, 0]
  let right_class : Array[Int] = [0, 1, 0, 1]
  let kern_index : Array[Int] = [0, 1, 1, 2]
  let kern_value_count = kern_values.length()
  let left_class_count = 2
  let right_class_count = 2
  let values_len = kern_values.length() * 2
  let left_len = glyph_count
  let right_len = glyph_count
  let index_len = left_class_count * right_class_count
  let length = 12 + values_len + left_len + right_len + index_len
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, length)
  push_u16(bytes, 0x0301)
  push_u16(bytes, glyph_count)
  bytes.push(kern_value_count.to_byte())
  bytes.push(left_class_count.to_byte())
  bytes.push(right_class_count.to_byte())
  bytes.push(0)
  for value in kern_values {
    push_i16(bytes, value)
  }
  for value in left_class {
    bytes.push(value.to_byte())
  }
  for value in right_class {
    bytes.push(value.to_byte())
  }
  for value in kern_index {
    bytes.push(value.to_byte())
  }
  Bytes::from_array(bytes)
}

///|
fn build_colr_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 3)
  push_u32(bytes, 14)
  push_u32(bytes, 32)
  push_u16(bytes, 4)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 3)
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)
  push_u16(bytes, 2)
  push_u16(bytes, 0)
  push_u16(bytes, 3)
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  Bytes::from_array(bytes)
}

///|
fn build_class_def_format1(start_glyph : Int, classes : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, start_glyph)
  push_u16(bytes, classes.length())
  for value in classes {
    push_u16(bytes, value)
  }
  Bytes::from_array(bytes)
}

///|
fn build_coverage_format1(glyphs : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, glyphs.length())
  for glyph in glyphs {
    push_u16(bytes, glyph)
  }
  Bytes::from_array(bytes)
}

///|
fn build_attach_list() -> Bytes {
  let coverage = build_coverage_format1([1, 3])
  let attach1 : Array[Byte] = []
  push_u16(attach1, 1)
  push_u16(attach1, 7)
  let attach2 : Array[Byte] = []
  push_u16(attach2, 2)
  push_u16(attach2, 3)
  push_u16(attach2, 4)
  let header_len = 4 + 2 * 2
  let cursor = header_len + coverage.length()
  let offsets : Array[Int] = [cursor, cursor + attach1.length()]
  let bytes : Array[Byte] = []
  push_u16(bytes, header_len)
  push_u16(bytes, 2)
  for offset in offsets {
    push_u16(bytes, offset)
  }
  for b in coverage {
    bytes.push(b)
  }
  for b in attach1 {
    bytes.push(b)
  }
  for b in attach2 {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_device_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_caret_value_format1(coord : Int) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_i16(bytes, coord)
  Bytes::from_array(bytes)
}

///|
fn build_caret_value_format2(point : Int) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2)
  push_u16(bytes, point)
  Bytes::from_array(bytes)
}

///|
fn build_caret_value_format3(coord : Int) -> Bytes {
  let device = build_device_table()
  let bytes : Array[Byte] = []
  push_u16(bytes, 3)
  push_i16(bytes, coord)
  push_u16(bytes, 6)
  for b in device {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_lig_glyph(carets : Array[Bytes]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, carets.length())
  let mut cursor = 2 + carets.length() * 2
  let offsets : Array[Int] = []
  for caret in carets {
    offsets.push(cursor)
    cursor = cursor + caret.length()
  }
  for offset in offsets {
    push_u16(bytes, offset)
  }
  for caret in carets {
    for b in caret {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

///|
fn build_lig_caret_list() -> Bytes {
  let coverage = build_coverage_format1([2, 3])
  let lig1 = build_lig_glyph([build_caret_value_format1(100)])
  let lig2 = build_lig_glyph([
    build_caret_value_format2(5),
    build_caret_value_format3(200),
  ])
  let header_len = 4 + 2 * 2
  let cursor = header_len + coverage.length()
  let offsets : Array[Int] = [cursor, cursor + lig1.length()]
  let bytes : Array[Byte] = []
  push_u16(bytes, header_len)
  push_u16(bytes, 2)
  for offset in offsets {
    push_u16(bytes, offset)
  }
  for b in coverage {
    bytes.push(b)
  }
  for b in lig1 {
    bytes.push(b)
  }
  for b in lig2 {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_mark_glyph_sets() -> Bytes {
  let coverage = build_coverage_format1([2, 3])
  let bytes : Array[Byte] = []
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 6)
  for b in coverage {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gdef_table() -> Bytes {
  let bytes : Array[Byte] = []
  let glyph_class = build_class_def_format1(0, [0, 1, 2, 0])
  let attach_list = build_attach_list()
  let lig_caret_list = build_lig_caret_list()
  let mark_attach = build_class_def_format1(0, [0, 0, 1, 2])
  let mark_sets = build_mark_glyph_sets()
  let header_len = 14
  let glyph_class_offset = header_len
  let attach_list_offset = glyph_class_offset + glyph_class.length()
  let lig_caret_list_offset = attach_list_offset + attach_list.length()
  let mark_attach_offset = lig_caret_list_offset + lig_caret_list.length()
  let mark_sets_offset = mark_attach_offset + mark_attach.length()
  push_u32(bytes, 0x00010002)
  push_u16(bytes, glyph_class_offset)
  push_u16(bytes, attach_list_offset)
  push_u16(bytes, lig_caret_list_offset)
  push_u16(bytes, mark_attach_offset)
  push_u16(bytes, mark_sets_offset)
  for b in glyph_class {
    bytes.push(b)
  }
  for b in attach_list {
    bytes.push(b)
  }
  for b in lig_caret_list {
    bytes.push(b)
  }
  for b in mark_attach {
    bytes.push(b)
  }
  for b in mark_sets {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gsub_single() -> Bytes {
  let single_subtable : Array[Byte] = []
  push_u16(single_subtable, 2)
  let single_coverage = build_coverage_format1([2])
  push_u16(single_subtable, 8)
  push_u16(single_subtable, 1)
  push_u16(single_subtable, 3)
  for b in single_coverage {
    single_subtable.push(b)
  }
  let single_lookup : Array[Byte] = []
  push_u16(single_lookup, 1)
  push_u16(single_lookup, 0)
  push_u16(single_lookup, 1)
  push_u16(single_lookup, 8)
  for b in single_subtable {
    single_lookup.push(b)
  }

  let multiple_subtable : Array[Byte] = []
  push_u16(multiple_subtable, 1)
  push_u16(multiple_subtable, 14)
  push_u16(multiple_subtable, 1)
  push_u16(multiple_subtable, 8)
  push_u16(multiple_subtable, 2)
  push_u16(multiple_subtable, 3)
  push_u16(multiple_subtable, 2)
  let multiple_coverage = build_coverage_format1([2])
  for b in multiple_coverage {
    multiple_subtable.push(b)
  }
  let multiple_lookup : Array[Byte] = []
  push_u16(multiple_lookup, 2)
  push_u16(multiple_lookup, 0)
  push_u16(multiple_lookup, 1)
  push_u16(multiple_lookup, 8)
  for b in multiple_subtable {
    multiple_lookup.push(b)
  }

  let alternate_subtable : Array[Byte] = []
  push_u16(alternate_subtable, 1)
  push_u16(alternate_subtable, 12)
  push_u16(alternate_subtable, 1)
  push_u16(alternate_subtable, 8)
  push_u16(alternate_subtable, 1)
  push_u16(alternate_subtable, 3)
  let alternate_coverage = build_coverage_format1([2])
  for b in alternate_coverage {
    alternate_subtable.push(b)
  }
  let alternate_lookup : Array[Byte] = []
  push_u16(alternate_lookup, 3)
  push_u16(alternate_lookup, 0)
  push_u16(alternate_lookup, 1)
  push_u16(alternate_lookup, 8)
  for b in alternate_subtable {
    alternate_lookup.push(b)
  }

  let ligature_subtable : Array[Byte] = []
  push_u16(ligature_subtable, 1)
  push_u16(ligature_subtable, 18)
  push_u16(ligature_subtable, 1)
  push_u16(ligature_subtable, 8)
  push_u16(ligature_subtable, 1)
  push_u16(ligature_subtable, 4)
  push_u16(ligature_subtable, 2)
  push_u16(ligature_subtable, 2)
  push_u16(ligature_subtable, 2)
  let ligature_coverage = build_coverage_format1([2])
  for b in ligature_coverage {
    ligature_subtable.push(b)
  }
  let ligature_lookup : Array[Byte] = []
  push_u16(ligature_lookup, 4)
  push_u16(ligature_lookup, 0)
  push_u16(ligature_lookup, 1)
  push_u16(ligature_lookup, 8)
  for b in ligature_subtable {
    ligature_lookup.push(b)
  }

  let contextual_rule : Array[Byte] = []
  push_u16(contextual_rule, 2)
  push_u16(contextual_rule, 1)
  push_u16(contextual_rule, 3)
  push_u16(contextual_rule, 1)
  push_u16(contextual_rule, 0)
  let contextual_set : Array[Byte] = []
  push_u16(contextual_set, 1)
  push_u16(contextual_set, 4)
  for b in contextual_rule {
    contextual_set.push(b)
  }
  let contextual_coverage = build_coverage_format1([2])
  let contextual_subtable : Array[Byte] = []
  push_u16(contextual_subtable, 1)
  let contextual_header_len = 8
  let contextual_coverage_offset = contextual_header_len + contextual_set.length()
  push_u16(contextual_subtable, contextual_coverage_offset)
  push_u16(contextual_subtable, 1)
  push_u16(contextual_subtable, contextual_header_len)
  for b in contextual_set {
    contextual_subtable.push(b)
  }
  for b in contextual_coverage {
    contextual_subtable.push(b)
  }
  let contextual_lookup : Array[Byte] = []
  push_u16(contextual_lookup, 5)
  push_u16(contextual_lookup, 0)
  push_u16(contextual_lookup, 1)
  push_u16(contextual_lookup, 8)
  for b in contextual_subtable {
    contextual_lookup.push(b)
  }

  let chaining_rule : Array[Byte] = []
  push_u16(chaining_rule, 1)
  push_u16(chaining_rule, 2)
  push_u16(chaining_rule, 2)
  push_u16(chaining_rule, 2)
  push_u16(chaining_rule, 1)
  push_u16(chaining_rule, 2)
  push_u16(chaining_rule, 1)
  push_u16(chaining_rule, 1)
  push_u16(chaining_rule, 0)
  let chaining_set : Array[Byte] = []
  push_u16(chaining_set, 1)
  push_u16(chaining_set, 4)
  for b in chaining_rule {
    chaining_set.push(b)
  }
  let chaining_coverage = build_coverage_format1([2])
  let chaining_subtable : Array[Byte] = []
  push_u16(chaining_subtable, 1)
  let chaining_header_len = 8
  let chaining_coverage_offset = chaining_header_len + chaining_set.length()
  push_u16(chaining_subtable, chaining_coverage_offset)
  push_u16(chaining_subtable, 1)
  push_u16(chaining_subtable, chaining_header_len)
  for b in chaining_set {
    chaining_subtable.push(b)
  }
  for b in chaining_coverage {
    chaining_subtable.push(b)
  }
  let chaining_lookup : Array[Byte] = []
  push_u16(chaining_lookup, 6)
  push_u16(chaining_lookup, 0)
  push_u16(chaining_lookup, 1)
  push_u16(chaining_lookup, 8)
  for b in chaining_subtable {
    chaining_lookup.push(b)
  }

  let extension_subtable : Array[Byte] = []
  push_u16(extension_subtable, 1)
  push_u16(extension_subtable, 1)
  push_u32(extension_subtable, 8)
  for b in single_subtable {
    extension_subtable.push(b)
  }
  let extension_lookup : Array[Byte] = []
  push_u16(extension_lookup, 7)
  push_u16(extension_lookup, 0)
  push_u16(extension_lookup, 1)
  push_u16(extension_lookup, 8)
  for b in extension_subtable {
    extension_lookup.push(b)
  }

  let reverse_subtable : Array[Byte] = []
  let reverse_coverage = build_coverage_format1([2])
  let reverse_backtrack = build_coverage_format1([2])
  let reverse_lookahead = build_coverage_format1([2])
  let reverse_header_len = 16
  let reverse_coverage_offset = reverse_header_len
  let reverse_backtrack_offset = reverse_coverage_offset + reverse_coverage.length()
  let reverse_lookahead_offset = reverse_backtrack_offset + reverse_backtrack.length()
  push_u16(reverse_subtable, 1)
  push_u16(reverse_subtable, reverse_coverage_offset)
  push_u16(reverse_subtable, 1)
  push_u16(reverse_subtable, reverse_backtrack_offset)
  push_u16(reverse_subtable, 1)
  push_u16(reverse_subtable, reverse_lookahead_offset)
  push_u16(reverse_subtable, 1)
  push_u16(reverse_subtable, 2)
  for b in reverse_coverage {
    reverse_subtable.push(b)
  }
  for b in reverse_backtrack {
    reverse_subtable.push(b)
  }
  for b in reverse_lookahead {
    reverse_subtable.push(b)
  }
  let reverse_lookup : Array[Byte] = []
  push_u16(reverse_lookup, 8)
  push_u16(reverse_lookup, 0)
  push_u16(reverse_lookup, 1)
  push_u16(reverse_lookup, 8)
  for b in reverse_subtable {
    reverse_lookup.push(b)
  }

  let lookup_list : Array[Byte] = []
  let lookup_count = 8
  let lookup_header_len = 2 + lookup_count * 2
  push_u16(lookup_list, lookup_count)
  let second_offset = lookup_header_len + single_lookup.length()
  let third_offset = second_offset + multiple_lookup.length()
  let fourth_offset = third_offset + alternate_lookup.length()
  let fifth_offset = fourth_offset + ligature_lookup.length()
  let sixth_offset = fifth_offset + contextual_lookup.length()
  let seventh_offset = sixth_offset + chaining_lookup.length()
  let eighth_offset = seventh_offset + extension_lookup.length()
  push_u16(lookup_list, lookup_header_len)
  push_u16(lookup_list, second_offset)
  push_u16(lookup_list, third_offset)
  push_u16(lookup_list, fourth_offset)
  push_u16(lookup_list, fifth_offset)
  push_u16(lookup_list, sixth_offset)
  push_u16(lookup_list, seventh_offset)
  push_u16(lookup_list, eighth_offset)
  for b in single_lookup {
    lookup_list.push(b)
  }
  for b in multiple_lookup {
    lookup_list.push(b)
  }
  for b in alternate_lookup {
    lookup_list.push(b)
  }
  for b in ligature_lookup {
    lookup_list.push(b)
  }
  for b in contextual_lookup {
    lookup_list.push(b)
  }
  for b in chaining_lookup {
    lookup_list.push(b)
  }
  for b in extension_lookup {
    lookup_list.push(b)
  }
  for b in reverse_lookup {
    lookup_list.push(b)
  }

  let feature : Array[Byte] = []
  push_u16(feature, 0)
  push_u16(feature, 8)
  push_u16(feature, 0)
  push_u16(feature, 1)
  push_u16(feature, 2)
  push_u16(feature, 3)
  push_u16(feature, 4)
  push_u16(feature, 5)
  push_u16(feature, 6)
  push_u16(feature, 7)
  let feature_list : Array[Byte] = []
  push_u16(feature_list, 1)
  feature_list.push(b'l')
  feature_list.push(b'i')
  feature_list.push(b'g')
  feature_list.push(b'a')
  push_u16(feature_list, 8)
  for b in feature {
    feature_list.push(b)
  }
  let lang_sys : Array[Byte] = []
  push_u16(lang_sys, 0)
  push_u16(lang_sys, 0xFFFF)
  push_u16(lang_sys, 1)
  push_u16(lang_sys, 0)
  let script : Array[Byte] = []
  push_u16(script, 4)
  push_u16(script, 0)
  for b in lang_sys {
    script.push(b)
  }
  let script_list : Array[Byte] = []
  push_u16(script_list, 1)
  script_list.push(b'D')
  script_list.push(b'F')
  script_list.push(b'L')
  script_list.push(b'T')
  push_u16(script_list, 8)
  for b in script {
    script_list.push(b)
  }
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  let script_offset = 10
  let feature_offset = script_offset + script_list.length()
  let lookup_offset = feature_offset + feature_list.length()
  push_u16(bytes, script_offset)
  push_u16(bytes, feature_offset)
  push_u16(bytes, lookup_offset)
  for b in script_list {
    bytes.push(b)
  }
  for b in feature_list {
    bytes.push(b)
  }
  for b in lookup_list {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_vhea(number_of_vmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_vmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_vmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_hmtx(advances : Array[Int], lsbs : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for i in 0..<advances.length() {
    push_u16(bytes, advances[i])
    push_i16(bytes, lsbs[i])
  }
  Bytes::from_array(bytes)
}

///|
fn build_vmtx(advances : Array[Int], tsbs : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for i in 0..<advances.length() {
    push_u16(bytes, advances[i])
    push_i16(bytes, tsbs[i])
  }
  Bytes::from_array(bytes)
}

///|
fn build_loca_long(offsets : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for offset in offsets {
    push_u32(bytes, offset)
  }
  Bytes::from_array(bytes)
}

///|
fn build_simple_glyph() -> Array[Byte] {
  let bytes : Array[Byte] = []
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_u16(bytes, 0)
  bytes
}

///|
fn build_composite_glyph(component_gid : Int) -> Array[Byte] {
  let bytes : Array[Byte] = []
  push_i16(bytes, -1)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  push_u16(bytes, 0x0003)
  push_u16(bytes, component_gid)
  push_i16(bytes, 0)
  push_i16(bytes, 0)
  bytes
}

///|
fn build_glyf_table() -> Bytes {
  let bytes : Array[Byte] = []
  let glyph1 = build_simple_glyph()
  let glyph2 = build_composite_glyph(3)
  let glyph3 = build_simple_glyph()
  for b in glyph1 {
    bytes.push(b)
  }
  for b in glyph2 {
    bytes.push(b)
  }
  for b in glyph3 {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_table(subtable : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, 1)
  push_u16(bytes, 3)
  push_u16(bytes, 10)
  push_u32(bytes, 12)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format12(start : UInt, end : UInt, start_gid : UInt) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 12)
  push_u16(bytes, 0)
  push_u32(bytes, 28)
  push_u32(bytes, 0)
  push_u32(bytes, 1)
  push_u32(bytes, start.reinterpret_as_int())
  push_u32(bytes, end.reinterpret_as_int())
  push_u32(bytes, start_gid.reinterpret_as_int())
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_subset_fixture() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_long([0, 0, 12, 30, 42])
  let cmap = build_cmap_table(build_cmap_format12(0x41U, 0x42U, 1U))
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 1)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(4)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(4)),
    (@common.Tag::from_chars('O', 'S', '/', '2'), build_os2()),
    (@common.Tag::from_chars('C', 'P', 'A', 'L'), build_cpal()),
    (@common.Tag::from_chars('p', 'o', 's', 't'), build_post_table_v2()),
    (@common.Tag::from_chars('V', 'O', 'R', 'G'), build_vorg_table()),
    (@common.Tag::from_chars('k', 'e', 'r', 'n'), build_kern_table()),
    (@common.Tag::from_chars('C', 'O', 'L', 'R'), build_colr_table()),
    (@common.Tag::from_chars('G', 'D', 'E', 'F'), build_gdef_table()),
    (@common.Tag::from_chars('G', 'S', 'U', 'B'), build_gsub_single()),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx([500, 600, 700, 800], [0, 10, 20, 30])),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(4)),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx([900, 910, 920, 930], [5, 6, 7, 8])),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (@common.Tag::from_chars('c', 'm', 'a', 'p'), cmap),
  ]
  build_sfnt(tables)
}

///|
test "subset drops unused glyphs" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gid = match subset_font.glyph_for_codepoint(0x41U) {
    Err(err) => fail("glyph lookup failed: \{err}")
    Ok(value) => value
  }
  assert_true(gid is Some(1U))
  let missing = match subset_font.glyph_for_codepoint(0x42U) {
    Err(err) => fail("glyph lookup failed: \{err}")
    Ok(value) => value
  }
  assert_true(missing is None)
  let maxp = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('m', 'a', 'x', 'p'),
  ) {
    Err(err) => fail("maxp table missing: \{err}")
    Ok(None) => fail("maxp table missing")
    Ok(Some(blob)) =>
      match @sfnt.MaxpTable::parse(blob.as_view()) {
        Err(err) => fail("maxp parse failed: \{err}")
        Ok(value) => value
      }
  }
  inspect(maxp.num_glyphs, content="2")
}

///|
test "subset preserves os2" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let os2_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('O', 'S', '/', '2'),
  ) {
    Err(err) => fail("OS/2 table missing: \{err}")
    Ok(None) => fail("OS/2 table missing")
    Ok(Some(blob)) => blob
  }
  match @sfnt.Os2Table::parse(os2_blob.as_view()) {
    Err(err) => fail("OS/2 parse failed: \{err}")
    Ok(_) => ()
  }
  let os2_data = os2_blob.as_view()
  let first = match read_u16(os2_data, 64) {
    None => fail("OS/2 firstCharIndex missing")
    Some(value) => value
  }
  let last = match read_u16(os2_data, 66) {
    None => fail("OS/2 lastCharIndex missing")
    Some(value) => value
  }
  inspect((first, last), content="(65, 65)")
}

///|
test "subset preserves cpal" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let cpal_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('C', 'P', 'A', 'L'),
  ) {
    Err(err) => fail("CPAL table missing: \{err}")
    Ok(None) => fail("CPAL table missing")
    Ok(Some(blob)) => blob
  }
  inspect(cpal_blob.as_view().length(), content="18")
}

///|
test "subset rebuilds post table when remapped" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let post_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('p', 'o', 's', 't'),
  ) {
    Err(err) => fail("post lookup failed: \{err}")
    Ok(None) => fail("post table missing from remapped subset")
    Ok(Some(blob)) => blob
  }
  let post = match @sfnt.PostTable::parse(post_blob.as_view()) {
    Err(err) => fail("post parse failed: \{err}")
    Ok(value) => value
  }
  let indices = match post.glyph_name_indices {
    None => fail("missing name indices")
    Some(value) => value
  }
  let names = match post.custom_names {
    None => fail("missing custom names")
    Some(value) => value
  }
  inspect(indices, content="[0, 258, 2]")
  inspect(names, content="[b\"foo\"]")
}

///|
test "subset preserves post table for identity subset" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U, 0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let post_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('p', 'o', 's', 't'),
  ) {
    Err(err) => fail("post lookup failed: \{err}")
    Ok(None) => fail("post table missing from identity subset")
    Ok(Some(blob)) => blob
  }
  let post = match @sfnt.PostTable::parse(post_blob.as_view()) {
    Err(err) => fail("post parse failed: \{err}")
    Ok(value) => value
  }
  inspect(post.version, content="131072")
}

///|
test "subset rebuilds vorg" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let vorg_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('V', 'O', 'R', 'G'),
  ) {
    Err(err) => fail("vorg lookup failed: \{err}")
    Ok(None) => fail("VORG table missing from subset")
    Ok(Some(blob)) => blob
  }
  let vorg = match @sfnt.VorgTable::parse(vorg_blob.as_view()) {
    Err(err) => fail("vorg parse failed: \{err}")
    Ok(value) => value
  }
  inspect(vorg.origin_y_override(0), content="None")
  inspect(vorg.origin_y_override(1), content="Some(700)")
  inspect(vorg.origin_y_override(2), content="Some(750)")
}

///|
test "subset rebuilds kern" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let kern_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('k', 'e', 'r', 'n'),
  ) {
    Err(err) => fail("kern lookup failed: \{err}")
    Ok(None) => fail("kern table missing from subset")
    Ok(Some(blob)) => blob
  }
  let kern = match @sfnt.KernTable::parse(kern_blob.as_view()) {
    Err(err) => fail("kern parse failed: \{err}")
    Ok(value) => value
  }
  inspect(kern.subtables.length(), content="3")
  let subtable = kern.subtables[0]
  inspect(subtable.format, content="0")
  inspect(subtable.pairs.length(), content="1")
  let pair = subtable.pairs[0]
  inspect(
    (
      pair.left.reinterpret_as_int(),
      pair.right.reinterpret_as_int(),
      pair.value,
    ),
    content="(1, 2, -50)",
  )
  let subtable2 = kern.subtables[1]
  inspect(subtable2.format, content="0")
  let pairs2 : Array[(Int, Int, Int)] = []
  for pair in subtable2.pairs {
    pairs2.push((
      pair.left.reinterpret_as_int(),
      pair.right.reinterpret_as_int(),
      pair.value,
    ))
  }
  inspect(
    pairs2,
    content="[(0, 2, -20), (1, 0, -30), (1, 1, -30), (1, 2, -40), (2, 2, -20)]",
  )
  let subtable3 = kern.subtables[2]
  inspect(subtable3.format, content="0")
  let pairs3 : Array[(Int, Int, Int)] = []
  for pair in subtable3.pairs {
    pairs3.push((
      pair.left.reinterpret_as_int(),
      pair.right.reinterpret_as_int(),
      pair.value,
    ))
  }
  inspect(
    pairs3,
    content="[(0, 2, -10), (1, 0, -10), (1, 1, -10), (1, 2, -50), (2, 2, -10)]",
  )
}

///|
test "subset rebuilds gsub single" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup_count = match read_u16(data, lookup_offset) {
    None => fail("GSUB lookup count missing")
    Some(value) => value
  }
  let lookup0_offset = match read_u16(data, lookup_offset + 2) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup1_offset = match read_u16(data, lookup_offset + 4) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup0_base = lookup_offset + lookup0_offset
  let lookup_type = match read_u16(data, lookup0_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup0_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup0_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup0_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let glyph_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB glyph count missing")
    Some(value) => value
  }
  let substitute = match read_u16(data, sub_base + 6) {
    None => fail("GSUB substitute missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect((lookup_count, lookup_type, sub_count, sub_format), content="(8, 1, 1, 2)")
  inspect((glyph_count, cov_format, cov_count, cov_glyph, substitute), content="(1, 1, 1, 1, 2)")
  inspect(lookup1_offset, content="40")
}

///|
test "subset rebuilds gsub multiple" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup1_offset = match read_u16(data, lookup_offset + 4) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup1_base = lookup_offset + lookup1_offset
  let lookup_type = match read_u16(data, lookup1_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup1_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup1_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup1_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let seq_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB sequence count missing")
    Some(value) => value
  }
  let seq_offset = match read_u16(data, sub_base + 6) {
    None => fail("GSUB sequence offset missing")
    Some(value) => value
  }
  let seq_base = sub_base + seq_offset
  let seq_glyph_count = match read_u16(data, seq_base) {
    None => fail("GSUB sequence glyph count missing")
    Some(value) => value
  }
  let seq_glyph1 = match read_u16(data, seq_base + 2) {
    None => fail("GSUB sequence glyph missing")
    Some(value) => value
  }
  let seq_glyph2 = match read_u16(data, seq_base + 4) {
    None => fail("GSUB sequence glyph missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect((lookup_type, sub_count, sub_format, seq_count), content="(2, 1, 1, 1)")
  inspect((seq_glyph_count, seq_glyph1, seq_glyph2), content="(2, 2, 1)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
}

///|
test "subset rebuilds gsub alternate" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup_count = match read_u16(data, lookup_offset) {
    None => fail("GSUB lookup count missing")
    Some(value) => value
  }
  let lookup2_offset = match read_u16(data, lookup_offset + 6) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup2_base = lookup_offset + lookup2_offset
  let lookup_type = match read_u16(data, lookup2_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup2_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup2_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup2_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let alt_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB alternate count missing")
    Some(value) => value
  }
  let alt_offset = match read_u16(data, sub_base + 6) {
    None => fail("GSUB alternate offset missing")
    Some(value) => value
  }
  let alt_base = sub_base + alt_offset
  let alt_glyph_count = match read_u16(data, alt_base) {
    None => fail("GSUB alternate glyph count missing")
    Some(value) => value
  }
  let alt_glyph = match read_u16(data, alt_base + 2) {
    None => fail("GSUB alternate glyph missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect(lookup_count, content="8")
  inspect((lookup_type, sub_count, sub_format), content="(3, 1, 1)")
  inspect((alt_count, alt_glyph_count, alt_glyph), content="(1, 1, 2)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
}

///|
test "subset rebuilds gsub ligature" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup3_offset = match read_u16(data, lookup_offset + 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup3_base = lookup_offset + lookup3_offset
  let lookup_type = match read_u16(data, lookup3_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup3_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup3_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup3_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let set_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB ligature set count missing")
    Some(value) => value
  }
  let set_offset = match read_u16(data, sub_base + 6) {
    None => fail("GSUB ligature set offset missing")
    Some(value) => value
  }
  let set_base = sub_base + set_offset
  let lig_count = match read_u16(data, set_base) {
    None => fail("GSUB ligature count missing")
    Some(value) => value
  }
  let lig_offset = match read_u16(data, set_base + 2) {
    None => fail("GSUB ligature offset missing")
    Some(value) => value
  }
  let lig_base = set_base + lig_offset
  let lig_glyph = match read_u16(data, lig_base) {
    None => fail("GSUB ligature glyph missing")
    Some(value) => value
  }
  let comp_count = match read_u16(data, lig_base + 2) {
    None => fail("GSUB ligature component count missing")
    Some(value) => value
  }
  let comp_glyph = match read_u16(data, lig_base + 4) {
    None => fail("GSUB ligature component glyph missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect((lookup_type, sub_count, sub_format), content="(4, 1, 1)")
  inspect((set_count, lig_count, lig_glyph, comp_count, comp_glyph), content="(1, 1, 1, 2, 1)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
}

///|
test "subset rebuilds gsub contextual" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup4_offset = match read_u16(data, lookup_offset + 10) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup4_base = lookup_offset + lookup4_offset
  let lookup_type = match read_u16(data, lookup4_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup4_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup4_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup4_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let set_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB contextual set count missing")
    Some(value) => value
  }
  let set_offset = match read_u16(data, sub_base + 6) {
    None => fail("GSUB contextual set offset missing")
    Some(value) => value
  }
  let set_base = sub_base + set_offset
  let rule_count = match read_u16(data, set_base) {
    None => fail("GSUB contextual rule count missing")
    Some(value) => value
  }
  let rule_offset = match read_u16(data, set_base + 2) {
    None => fail("GSUB contextual rule offset missing")
    Some(value) => value
  }
  let rule_base = set_base + rule_offset
  let glyph_count = match read_u16(data, rule_base) {
    None => fail("GSUB contextual glyph count missing")
    Some(value) => value
  }
  let subst_count = match read_u16(data, rule_base + 2) {
    None => fail("GSUB contextual subst count missing")
    Some(value) => value
  }
  let input_glyph = match read_u16(data, rule_base + 4) {
    None => fail("GSUB contextual input glyph missing")
    Some(value) => value
  }
  let seq_index = match read_u16(data, rule_base + 6) {
    None => fail("GSUB contextual sequence index missing")
    Some(value) => value
  }
  let lookup_index = match read_u16(data, rule_base + 8) {
    None => fail("GSUB contextual lookup index missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect((lookup_type, sub_count, sub_format), content="(5, 1, 1)")
  inspect((set_count, rule_count, glyph_count, subst_count), content="(1, 1, 2, 1)")
  inspect((input_glyph, seq_index, lookup_index), content="(2, 1, 0)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
}

///|
test "subset rebuilds gsub chaining" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup5_offset = match read_u16(data, lookup_offset + 12) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup5_base = lookup_offset + lookup5_offset
  let lookup_type = match read_u16(data, lookup5_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup5_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup5_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup5_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let set_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB chaining set count missing")
    Some(value) => value
  }
  let set_offset = match read_u16(data, sub_base + 6) {
    None => fail("GSUB chaining set offset missing")
    Some(value) => value
  }
  let set_base = sub_base + set_offset
  let rule_count = match read_u16(data, set_base) {
    None => fail("GSUB chaining rule count missing")
    Some(value) => value
  }
  let rule_offset = match read_u16(data, set_base + 2) {
    None => fail("GSUB chaining rule offset missing")
    Some(value) => value
  }
  let rule_base = set_base + rule_offset
  let backtrack_count = match read_u16(data, rule_base) {
    None => fail("GSUB chaining backtrack count missing")
    Some(value) => value
  }
  let backtrack_glyph = match read_u16(data, rule_base + 2) {
    None => fail("GSUB chaining backtrack glyph missing")
    Some(value) => value
  }
  let input_count = match read_u16(data, rule_base + 4) {
    None => fail("GSUB chaining input count missing")
    Some(value) => value
  }
  let input_glyph = match read_u16(data, rule_base + 6) {
    None => fail("GSUB chaining input glyph missing")
    Some(value) => value
  }
  let lookahead_count = match read_u16(data, rule_base + 8) {
    None => fail("GSUB chaining lookahead count missing")
    Some(value) => value
  }
  let lookahead_glyph = match read_u16(data, rule_base + 10) {
    None => fail("GSUB chaining lookahead glyph missing")
    Some(value) => value
  }
  let subst_count = match read_u16(data, rule_base + 12) {
    None => fail("GSUB chaining subst count missing")
    Some(value) => value
  }
  let seq_index = match read_u16(data, rule_base + 14) {
    None => fail("GSUB chaining sequence index missing")
    Some(value) => value
  }
  let lookup_index = match read_u16(data, rule_base + 16) {
    None => fail("GSUB chaining lookup index missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect((lookup_type, sub_count, sub_format), content="(6, 1, 1)")
  inspect(
    (set_count, rule_count, backtrack_count, input_count, lookahead_count, subst_count),
    content="(1, 1, 1, 2, 1, 1)",
  )
  inspect((backtrack_glyph, input_glyph, lookahead_glyph), content="(1, 1, 1)")
  inspect((seq_index, lookup_index), content="(1, 0)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
}

///|
test "subset rebuilds gsub extension" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup6_offset = match read_u16(data, lookup_offset + 14) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup6_base = lookup_offset + lookup6_offset
  let lookup_type = match read_u16(data, lookup6_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup6_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup6_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup6_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let extension_type = match read_u16(data, sub_base + 2) {
    None => fail("GSUB extension type missing")
    Some(value) => value
  }
  let extension_offset = match read_u32(data, sub_base + 4) {
    None => fail("GSUB extension offset missing")
    Some(value) => value
  }
  let ext_base = sub_base + extension_offset
  let ext_format = match read_u16(data, ext_base) {
    None => fail("GSUB extension subtable format missing")
    Some(value) => value
  }
  let cov_offset = match read_u16(data, ext_base + 2) {
    None => fail("GSUB extension coverage offset missing")
    Some(value) => value
  }
  let glyph_count = match read_u16(data, ext_base + 4) {
    None => fail("GSUB extension glyph count missing")
    Some(value) => value
  }
  let substitute = match read_u16(data, ext_base + 6) {
    None => fail("GSUB extension substitute missing")
    Some(value) => value
  }
  let cov_base = ext_base + cov_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  inspect((lookup_type, sub_count, sub_format), content="(7, 1, 1)")
  inspect(extension_type, content="1")
  inspect((ext_format, glyph_count, substitute), content="(2, 1, 2)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
}

///|
test "subset rebuilds gsub reverse chaining" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gsub_blob.as_view()
  let lookup_offset = match read_u16(data, 8) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup7_offset = match read_u16(data, lookup_offset + 16) {
    None => fail("GSUB lookup offset missing")
    Some(value) => value
  }
  let lookup7_base = lookup_offset + lookup7_offset
  let lookup_type = match read_u16(data, lookup7_base) {
    None => fail("GSUB lookup type missing")
    Some(value) => value
  }
  let sub_count = match read_u16(data, lookup7_base + 4) {
    None => fail("GSUB subtable count missing")
    Some(value) => value
  }
  let sub_offset = match read_u16(data, lookup7_base + 6) {
    None => fail("GSUB subtable offset missing")
    Some(value) => value
  }
  let sub_base = lookup7_base + sub_offset
  let sub_format = match read_u16(data, sub_base) {
    None => fail("GSUB subtable format missing")
    Some(value) => value
  }
  let coverage_offset = match read_u16(data, sub_base + 2) {
    None => fail("GSUB coverage offset missing")
    Some(value) => value
  }
  let backtrack_count = match read_u16(data, sub_base + 4) {
    None => fail("GSUB reverse backtrack count missing")
    Some(value) => value
  }
  let backtrack_offset = match read_u16(data, sub_base + 6) {
    None => fail("GSUB reverse backtrack offset missing")
    Some(value) => value
  }
  let lookahead_count = match read_u16(data, sub_base + 8) {
    None => fail("GSUB reverse lookahead count missing")
    Some(value) => value
  }
  let lookahead_offset = match read_u16(data, sub_base + 10) {
    None => fail("GSUB reverse lookahead offset missing")
    Some(value) => value
  }
  let glyph_count = match read_u16(data, sub_base + 12) {
    None => fail("GSUB reverse glyph count missing")
    Some(value) => value
  }
  let substitute = match read_u16(data, sub_base + 14) {
    None => fail("GSUB reverse substitute missing")
    Some(value) => value
  }
  let cov_base = sub_base + coverage_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GSUB coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GSUB coverage count missing")
    Some(value) => value
  }
  let cov_glyph = match read_u16(data, cov_base + 4) {
    None => fail("GSUB coverage glyph missing")
    Some(value) => value
  }
  let backtrack_base = sub_base + backtrack_offset
  let backtrack_format = match read_u16(data, backtrack_base) {
    None => fail("GSUB reverse backtrack format missing")
    Some(value) => value
  }
  let backtrack_glyph = match read_u16(data, backtrack_base + 4) {
    None => fail("GSUB reverse backtrack glyph missing")
    Some(value) => value
  }
  let lookahead_base = sub_base + lookahead_offset
  let lookahead_format = match read_u16(data, lookahead_base) {
    None => fail("GSUB reverse lookahead format missing")
    Some(value) => value
  }
  let lookahead_glyph = match read_u16(data, lookahead_base + 4) {
    None => fail("GSUB reverse lookahead glyph missing")
    Some(value) => value
  }
  inspect((lookup_type, sub_count, sub_format), content="(8, 1, 1)")
  inspect((backtrack_count, lookahead_count, glyph_count, substitute), content="(1, 1, 1, 1)")
  inspect((cov_format, cov_count, cov_glyph), content="(1, 1, 1)")
  inspect((backtrack_format, backtrack_glyph), content="(1, 1)")
  inspect((lookahead_format, lookahead_glyph), content="(1, 1)")
}

///|
test "subset rebuilds colr v0" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let colr_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('C', 'O', 'L', 'R'),
  ) {
    Err(err) => fail("colr lookup failed: \{err}")
    Ok(None) => fail("COLR table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = colr_blob.as_view()
  let version = match read_u16(data, 0) {
    None => fail("COLR version missing")
    Some(value) => value
  }
  let num_base = match read_u16(data, 2) {
    None => fail("COLR numBase missing")
    Some(value) => value
  }
  let base_offset = match read_u32(data, 4) {
    None => fail("COLR base offset missing")
    Some(value) => value
  }
  let layer_offset = match read_u32(data, 8) {
    None => fail("COLR layer offset missing")
    Some(value) => value
  }
  let num_layers = match read_u16(data, 12) {
    None => fail("COLR numLayers missing")
    Some(value) => value
  }
  inspect((version, num_base, num_layers), content="(0, 1, 2)")
  inspect((base_offset, layer_offset), content="(14, 20)")
  let base_gid = match read_u16(data, base_offset) {
    None => fail("COLR base glyph missing")
    Some(value) => value
  }
  let first_layer = match read_u16(data, base_offset + 2) {
    None => fail("COLR base first layer missing")
    Some(value) => value
  }
  let layer_count = match read_u16(data, base_offset + 4) {
    None => fail("COLR base layer count missing")
    Some(value) => value
  }
  inspect((base_gid, first_layer, layer_count), content="(1, 0, 2)")
  let layer0_gid = match read_u16(data, layer_offset) {
    None => fail("COLR layer0 gid missing")
    Some(value) => value
  }
  let layer0_color = match read_u16(data, layer_offset + 2) {
    None => fail("COLR layer0 color missing")
    Some(value) => value
  }
  let layer1_gid = match read_u16(data, layer_offset + 4) {
    None => fail("COLR layer1 gid missing")
    Some(value) => value
  }
  let layer1_color = match read_u16(data, layer_offset + 6) {
    None => fail("COLR layer1 color missing")
    Some(value) => value
  }
  inspect((layer0_gid, layer0_color), content="(1, 0)")
  inspect((layer1_gid, layer1_color), content="(2, 1)")
}

///|
test "subset rebuilds gdef" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gdef_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'D', 'E', 'F'),
  ) {
    Err(err) => fail("gdef lookup failed: \{err}")
    Ok(None) => fail("GDEF table missing from subset")
    Ok(Some(blob)) => blob
  }
  let data = gdef_blob.as_view()
  let version = match read_u32(data, 0) {
    None => fail("GDEF version missing")
    Some(value) => value
  }
  let glyph_class_offset = match read_u16(data, 4) {
    None => fail("GDEF class offset missing")
    Some(value) => value
  }
  let attach_list_offset = match read_u16(data, 6) {
    None => fail("GDEF attach list offset missing")
    Some(value) => value
  }
  let lig_caret_offset = match read_u16(data, 8) {
    None => fail("GDEF lig caret offset missing")
    Some(value) => value
  }
  let mark_attach_offset = match read_u16(data, 10) {
    None => fail("GDEF mark attach offset missing")
    Some(value) => value
  }
  let mark_sets_offset = match read_u16(data, 12) {
    None => fail("GDEF mark sets offset missing")
    Some(value) => value
  }
  inspect(
    (
      version,
      glyph_class_offset,
      attach_list_offset,
      lig_caret_offset,
      mark_attach_offset,
      mark_sets_offset,
    ),
    content="(65538, 14, 26, 44, 92, 104)",
  )
  let class_format = match read_u16(data, glyph_class_offset) {
    None => fail("GDEF class format missing")
    Some(value) => value
  }
  let class_count = match read_u16(data, glyph_class_offset + 4) {
    None => fail("GDEF class count missing")
    Some(value) => value
  }
  let class1 = match read_u16(data, glyph_class_offset + 6) {
    None => fail("GDEF class value missing")
    Some(value) => value
  }
  let class2 = match read_u16(data, glyph_class_offset + 8) {
    None => fail("GDEF class value missing")
    Some(value) => value
  }
  let class3 = match read_u16(data, glyph_class_offset + 10) {
    None => fail("GDEF class value missing")
    Some(value) => value
  }
  inspect((class_format, class_count, class1, class2, class3), content="(1, 3, 0, 2, 0)")
  let mark_format = match read_u16(data, mark_attach_offset) {
    None => fail("GDEF mark format missing")
    Some(value) => value
  }
  let mark_class_count = match read_u16(data, mark_attach_offset + 4) {
    None => fail("GDEF mark count missing")
    Some(value) => value
  }
  let mark1 = match read_u16(data, mark_attach_offset + 6) {
    None => fail("GDEF mark class missing")
    Some(value) => value
  }
  let mark2 = match read_u16(data, mark_attach_offset + 8) {
    None => fail("GDEF mark class missing")
    Some(value) => value
  }
  let mark3 = match read_u16(data, mark_attach_offset + 10) {
    None => fail("GDEF mark class missing")
    Some(value) => value
  }
  inspect((mark_format, mark_class_count, mark1, mark2, mark3), content="(1, 3, 0, 1, 2)")
  let sets_format = match read_u16(data, mark_sets_offset) {
    None => fail("GDEF sets format missing")
    Some(value) => value
  }
  let sets_count = match read_u16(data, mark_sets_offset + 2) {
    None => fail("GDEF sets count missing")
    Some(value) => value
  }
  let cov_offset = match read_u16(data, mark_sets_offset + 4) {
    None => fail("GDEF sets offset missing")
    Some(value) => value
  }
  let cov_base = mark_sets_offset + cov_offset
  let cov_format = match read_u16(data, cov_base) {
    None => fail("GDEF coverage format missing")
    Some(value) => value
  }
  let cov_count = match read_u16(data, cov_base + 2) {
    None => fail("GDEF coverage count missing")
    Some(value) => value
  }
  let cov1 = match read_u16(data, cov_base + 4) {
    None => fail("GDEF coverage missing")
    Some(value) => value
  }
  let cov2 = match read_u16(data, cov_base + 6) {
    None => fail("GDEF coverage missing")
    Some(value) => value
  }
  inspect((sets_format, sets_count, cov_format, cov_count, cov1, cov2), content="(1, 1, 1, 2, 1, 2)")

  let attach_cov_offset = match read_u16(data, attach_list_offset) {
    None => fail("GDEF attach coverage offset missing")
    Some(value) => value
  }
  let attach_count = match read_u16(data, attach_list_offset + 2) {
    None => fail("GDEF attach count missing")
    Some(value) => value
  }
  let attach_cov_base = attach_list_offset + attach_cov_offset
  let attach_cov_format = match read_u16(data, attach_cov_base) {
    None => fail("GDEF attach coverage format missing")
    Some(value) => value
  }
  let attach_cov_count = match read_u16(data, attach_cov_base + 2) {
    None => fail("GDEF attach coverage count missing")
    Some(value) => value
  }
  let attach_cov_glyph = match read_u16(data, attach_cov_base + 4) {
    None => fail("GDEF attach coverage glyph missing")
    Some(value) => value
  }
  let attach_point_offset = match read_u16(data, attach_list_offset + 4) {
    None => fail("GDEF attach point offset missing")
    Some(value) => value
  }
  let attach_point_base = attach_list_offset + attach_point_offset
  let attach_point_count = match read_u16(data, attach_point_base) {
    None => fail("GDEF attach point count missing")
    Some(value) => value
  }
  let attach_point1 = match read_u16(data, attach_point_base + 2) {
    None => fail("GDEF attach point missing")
    Some(value) => value
  }
  let attach_point2 = match read_u16(data, attach_point_base + 4) {
    None => fail("GDEF attach point missing")
    Some(value) => value
  }
  inspect(
    (
      attach_cov_format,
      attach_count,
      attach_cov_count,
      attach_cov_glyph,
      attach_point_count,
      attach_point1,
      attach_point2,
    ),
    content="(1, 1, 1, 2, 2, 3, 4)",
  )

  let lig_cov_offset = match read_u16(data, lig_caret_offset) {
    None => fail("GDEF lig caret coverage offset missing")
    Some(value) => value
  }
  let lig_cov_base = lig_caret_offset + lig_cov_offset
  let lig_cov_format = match read_u16(data, lig_cov_base) {
    None => fail("GDEF lig caret coverage format missing")
    Some(value) => value
  }
  let lig_cov_count = match read_u16(data, lig_cov_base + 2) {
    None => fail("GDEF lig caret coverage count missing")
    Some(value) => value
  }
  let lig_cov1 = match read_u16(data, lig_cov_base + 4) {
    None => fail("GDEF lig caret coverage glyph missing")
    Some(value) => value
  }
  let lig_cov2 = match read_u16(data, lig_cov_base + 6) {
    None => fail("GDEF lig caret coverage glyph missing")
    Some(value) => value
  }
  inspect((lig_cov_format, lig_cov_count, lig_cov1, lig_cov2), content="(1, 2, 1, 2)")
  let lig_offset1 = match read_u16(data, lig_caret_offset + 4) {
    None => fail("GDEF lig caret offset missing")
    Some(value) => value
  }
  let lig_offset2 = match read_u16(data, lig_caret_offset + 6) {
    None => fail("GDEF lig caret offset missing")
    Some(value) => value
  }
  let lig1_base = lig_caret_offset + lig_offset1
  let lig2_base = lig_caret_offset + lig_offset2
  let lig1_count = match read_u16(data, lig1_base) {
    None => fail("GDEF lig caret count missing")
    Some(value) => value
  }
  let lig1_caret_offset = match read_u16(data, lig1_base + 2) {
    None => fail("GDEF lig caret offset missing")
    Some(value) => value
  }
  let lig1_caret_base = lig1_base + lig1_caret_offset
  let lig1_format = match read_u16(data, lig1_caret_base) {
    None => fail("GDEF lig caret format missing")
    Some(value) => value
  }
  let lig1_coord = match read_i16(data, lig1_caret_base + 2) {
    None => fail("GDEF lig caret coord missing")
    Some(value) => value
  }
  inspect((lig1_count, lig1_format, lig1_coord), content="(1, 1, 100)")
  let lig2_count = match read_u16(data, lig2_base) {
    None => fail("GDEF lig caret count missing")
    Some(value) => value
  }
  let lig2_caret1_offset = match read_u16(data, lig2_base + 2) {
    None => fail("GDEF lig caret offset missing")
    Some(value) => value
  }
  let lig2_caret2_offset = match read_u16(data, lig2_base + 4) {
    None => fail("GDEF lig caret offset missing")
    Some(value) => value
  }
  let lig2_caret1_base = lig2_base + lig2_caret1_offset
  let lig2_caret2_base = lig2_base + lig2_caret2_offset
  let lig2_format1 = match read_u16(data, lig2_caret1_base) {
    None => fail("GDEF lig caret format missing")
    Some(value) => value
  }
  let lig2_point = match read_u16(data, lig2_caret1_base + 2) {
    None => fail("GDEF lig caret point missing")
    Some(value) => value
  }
  let lig2_format2 = match read_u16(data, lig2_caret2_base) {
    None => fail("GDEF lig caret format missing")
    Some(value) => value
  }
  let lig2_coord = match read_i16(data, lig2_caret2_base + 2) {
    None => fail("GDEF lig caret coord missing")
    Some(value) => value
  }
  let lig2_device_offset = match read_u16(data, lig2_caret2_base + 4) {
    None => fail("GDEF lig caret device offset missing")
    Some(value) => value
  }
  let lig2_device_base = lig2_caret2_base + lig2_device_offset
  let lig2_device_format = match read_u16(data, lig2_device_base + 4) {
    None => fail("GDEF lig caret device format missing")
    Some(value) => value
  }
  inspect(
    (
      lig2_count,
      lig2_format1,
      lig2_point,
      lig2_format2,
      lig2_coord,
      lig2_device_offset,
      lig2_device_format,
    ),
    content="(2, 2, 5, 3, 200, 6, 1)",
  )
}

///|
test "subset drops layout tables when remapped" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => ()
    Ok(Some(_)) => fail("GSUB should be dropped for remapped subsets")
  }
}

///|
test "subset preserves layout tables for identity subset" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U, 0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gsub_blob = match subset_font.get_face().reference_table_optional(
    @common.Tag::from_chars('G', 'S', 'U', 'B'),
  ) {
    Err(err) => fail("GSUB lookup failed: \{err}")
    Ok(None) => fail("GSUB table missing from identity subset")
    Ok(Some(blob)) => blob
  }
  let gsub_view = gsub_blob.as_view()
  let version = match read_u32(gsub_view, 0) {
    None => fail("GSUB header missing")
    Some(value) => value
  }
  inspect(version, content="65536")
  inspect(gsub_view.length(), content="336")
}

///|
test "subset rebuilds vmtx" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x41U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let face = subset_font.get_face()
  let maxp_blob = match face.reference_table_optional(@common.Tag::from_chars('m', 'a', 'x', 'p')) {
    Err(err) => fail("maxp table missing: \{err}")
    Ok(None) => fail("maxp table missing")
    Ok(Some(blob)) => blob
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => fail("maxp parse error: \{err}")
    Ok(value) => value
  }
  let vhea_blob = match face.reference_table_optional(@common.Tag::from_chars('v', 'h', 'e', 'a')) {
    Err(err) => fail("vhea table missing: \{err}")
    Ok(None) => fail("vhea table missing")
    Ok(Some(blob)) => blob
  }
  let vhea = match @sfnt.VheaTable::parse(vhea_blob.as_view()) {
    Err(err) => fail("vhea parse error: \{err}")
    Ok(value) => value
  }
  inspect(vhea.number_of_vmetrics, content=maxp.num_glyphs.to_string())
  let vmtx_blob = match face.reference_table_optional(@common.Tag::from_chars('v', 'm', 't', 'x')) {
    Err(err) => fail("vmtx table missing: \{err}")
    Ok(None) => fail("vmtx table missing")
    Ok(Some(blob)) => blob
  }
  let vmtx = match @sfnt.VmtxTable::parse(
    vmtx_blob.as_view(),
    maxp.num_glyphs,
    vhea.number_of_vmetrics,
  ) {
    Err(err) => fail("vmtx parse error: \{err}")
    Ok(value) => value
  }
  inspect(vmtx.advances.length(), content="2")
  inspect(vmtx.tsbs.length(), content="2")
  inspect(vmtx.advances[0], content="900")
  inspect(vmtx.advances[1], content="910")
  inspect(vmtx.tsbs[0], content="5")
  inspect(vmtx.tsbs[1], content="6")
}

///|
test "subset remaps composite components" {
  let font = @font.Font::from_bytes(build_font_bytes_subset_fixture())
  let bytes = match subset(font, SubsetInput::from_codepoints([0x42U])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gid = match subset_font.glyph_for_codepoint(0x42U) {
    Err(err) => fail("glyph lookup failed: \{err}")
    Ok(value) => value
  }
  assert_true(gid is Some(1U))
  let face = subset_font.get_face()
  let head = match face.reference_table_optional(@common.Tag::from_chars('h', 'e', 'a', 'd')) {
    Err(err) => fail("head table missing: \{err}")
    Ok(None) => fail("head table missing")
    Ok(Some(blob)) =>
      match @sfnt.HeadTable::parse(blob.as_view()) {
        Err(err) => fail("head parse failed: \{err}")
        Ok(value) => value
      }
  }
  let loca = match face.reference_table_optional(@common.Tag::from_chars('l', 'o', 'c', 'a')) {
    Err(err) => fail("loca table missing: \{err}")
    Ok(None) => fail("loca table missing")
    Ok(Some(blob)) =>
      match @sfnt.LocaTable::parse(blob.as_view(), 3, head.index_to_loc_format) {
        Err(err) => fail("loca parse failed: \{err}")
        Ok(value) => value
      }
  }
  let glyf = match face.reference_table_optional(@common.Tag::from_chars('g', 'l', 'y', 'f')) {
    Err(err) => fail("glyf table missing: \{err}")
    Ok(None) => fail("glyf table missing")
    Ok(Some(blob)) =>
      match @sfnt.GlyfTable::parse(blob) {
        Err(err) => fail("glyf parse failed: \{err}")
        Ok(value) => value
      }
  }
  let start = loca.offsets[1]
  let end = loca.offsets[2]
  let comps = match glyf.glyph_composite_components(start, end - start) {
    Err(err) => fail("composite parse failed: \{err}")
    Ok(value) => value
  }
  match comps {
    None => fail("expected composite glyph")
    Some(components) => inspect(components[0].glyph, content="2")
  }
}

///|
fn build_font_bytes_cff1_seac_c0() -> Bytes {
  Bytes::from_array([
    0x4f, 0x54, 0x54, 0x4f, 0x00, 0x09, 0x00, 0x80, 0x00, 0x03, 0x00, 0x10, 0x43, 0x46, 0x46, 0x20,
    0x38, 0x71, 0x67, 0x2e, 0x00, 0x00, 0x03, 0xec, 0x00, 0x00, 0x02, 0x2f, 0x4f, 0x53, 0x2f, 0x32,
    0x5b, 0x86, 0x76, 0x65, 0x00, 0x00, 0x01, 0x64, 0x00, 0x00, 0x00, 0x60, 0x63, 0x6d, 0x61, 0x70,
    0x00, 0x0d, 0x01, 0x13, 0x00, 0x00, 0x00, 0xf8, 0x00, 0x00, 0x00, 0x34, 0x68, 0x65, 0x61, 0x64,
    0x11, 0x21, 0x0c, 0xab, 0x00, 0x00, 0x01, 0x2c, 0x00, 0x00, 0x00, 0x36, 0x68, 0x68, 0x65, 0x61,
    0x06, 0x0b, 0x01, 0x84, 0x00, 0x00, 0x00, 0xd4, 0x00, 0x00, 0x00, 0x24, 0x68, 0x6d, 0x74, 0x78,
    0x08, 0xeb, 0x00, 0xdf, 0x00, 0x00, 0x00, 0xa4, 0x00, 0x00, 0x00, 0x10, 0x6d, 0x61, 0x78, 0x70,
    0x00, 0x04, 0x50, 0x00, 0x00, 0x00, 0x00, 0x9c, 0x00, 0x00, 0x00, 0x06, 0x6e, 0x61, 0x6d, 0x65,
    0x4b, 0x26, 0x64, 0x44, 0x00, 0x00, 0x01, 0xc4, 0x00, 0x00, 0x02, 0x26, 0x70, 0x6f, 0x73, 0x74,
    0xff, 0xd1, 0x00, 0x32, 0x00, 0x00, 0x00, 0xb4, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x50, 0x00,
    0x00, 0x04, 0x00, 0x00, 0x02, 0x8d, 0x00, 0x59, 0x02, 0x20, 0x00, 0x03, 0x02, 0x20, 0x00, 0x03,
    0x02, 0x1e, 0x00, 0x80, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xce, 0x00, 0x32,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x03, 0xd8, 0xfe, 0xef, 0x00, 0x00, 0x02, 0x8d,
    0x00, 0x03, 0x00, 0x03, 0x02, 0x2e, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x03,
    0x00, 0x00, 0x00, 0x14, 0x00, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x14, 0x00, 0x04, 0x00, 0x20,
    0x00, 0x00, 0x00, 0x04, 0x00, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0xc0, 0xff, 0xff, 0x00, 0x00,
    0x00, 0xc0, 0xff, 0xff, 0xff, 0x42, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x02, 0x05, 0x1e, 0xe8, 0xac, 0x99, 0xc6, 0x5f, 0x0f, 0x3c, 0xf5, 0x00, 0x03, 0x03, 0xe8,
    0x00, 0x00, 0x00, 0x00, 0xd7, 0xc5, 0x8b, 0x5f, 0x00, 0x00, 0x00, 0x00, 0xd8, 0x12, 0x37, 0xfd,
    0x00, 0x03, 0xff, 0xf4, 0x02, 0x2e, 0x03, 0x5d, 0x00, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x02, 0x0a, 0x01, 0x90, 0x00, 0x05, 0x00, 0x00, 0x02, 0x8a,
    0x02, 0x58, 0x00, 0x00, 0x00, 0x4b, 0x02, 0x8a, 0x02, 0x58, 0x00, 0x00, 0x01, 0x5e, 0x00, 0x32,
    0x01, 0x23, 0x00, 0x00, 0x02, 0x0b, 0x05, 0x03, 0x03, 0x04, 0x03, 0x02, 0x02, 0x04, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x44,
    0x42, 0x4f, 0x00, 0x40, 0x00, 0xc0, 0x00, 0xc0, 0x02, 0xee, 0xff, 0x06, 0x00, 0x00, 0x03, 0xd8,
    0x01, 0x11, 0x20, 0x00, 0x01, 0x9f, 0x00, 0x00, 0x00, 0x00, 0x01, 0xe6, 0x02, 0x94, 0x00, 0x00,
    0x00, 0x20, 0x00, 0x03, 0x00, 0x00, 0x00, 0x07, 0x00, 0x5a, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x00, 0x00, 0x00, 0xc6, 0x01, 0x06, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x01, 0x00, 0x1e,
    0x00, 0xe8, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x02, 0x00, 0x0e, 0x00, 0xda, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x00, 0x03, 0x00, 0x4c, 0x00, 0x8e, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x00, 0x04, 0x00, 0x1e, 0x00, 0xe8, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x05, 0x00, 0x64,
    0x00, 0x2a, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x06, 0x00, 0x2a, 0x00, 0x00, 0x00, 0x53,
    0x00, 0x6f, 0x00, 0x75, 0x00, 0x72, 0x00, 0x63, 0x00, 0x65, 0x00, 0x53, 0x00, 0x61, 0x00, 0x6e,
    0x00, 0x73, 0x00, 0x50, 0x00, 0x72, 0x00, 0x6f, 0x00, 0x2d, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67,
    0x00, 0x75, 0x00, 0x6c, 0x00, 0x61, 0x00, 0x72, 0x00, 0x56, 0x00, 0x65, 0x00, 0x72, 0x00, 0x73,
    0x00, 0x69, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x20, 0x00, 0x32, 0x00, 0x2e, 0x00, 0x30, 0x00, 0x32,
    0x00, 0x30, 0x00, 0x3b, 0x00, 0x68, 0x00, 0x6f, 0x00, 0x74, 0x00, 0x63, 0x00, 0x6f, 0x00, 0x6e,
    0x00, 0x76, 0x00, 0x20, 0x00, 0x31, 0x00, 0x2e, 0x00, 0x30, 0x00, 0x2e, 0x00, 0x31, 0x00, 0x30,
    0x00, 0x39, 0x00, 0x3b, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6b, 0x00, 0x65, 0x00, 0x6f, 0x00, 0x74,
    0x00, 0x66, 0x00, 0x65, 0x00, 0x78, 0x00, 0x65, 0x00, 0x20, 0x00, 0x32, 0x00, 0x2e, 0x00, 0x35,
    0x00, 0x2e, 0x00, 0x36, 0x00, 0x35, 0x00, 0x35, 0x00, 0x39, 0x00, 0x33, 0x00, 0x32, 0x00, 0x2e,
    0x00, 0x30, 0x00, 0x32, 0x00, 0x30, 0x00, 0x3b, 0x00, 0x41, 0x00, 0x44, 0x00, 0x42, 0x00, 0x4f,
    0x00, 0x3b, 0x00, 0x53, 0x00, 0x6f, 0x00, 0x75, 0x00, 0x72, 0x00, 0x63, 0x00, 0x65, 0x00, 0x53,
    0x00, 0x61, 0x00, 0x6e, 0x00, 0x73, 0x00, 0x50, 0x00, 0x72, 0x00, 0x6f, 0x00, 0x2d, 0x00, 0x52,
    0x00, 0x65, 0x00, 0x67, 0x00, 0x75, 0x00, 0x6c, 0x00, 0x61, 0x00, 0x72, 0x00, 0x3b, 0x00, 0x41,
    0x00, 0x44, 0x00, 0x4f, 0x00, 0x42, 0x00, 0x45, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67, 0x00, 0x75,
    0x00, 0x6c, 0x00, 0x61, 0x00, 0x72, 0x00, 0x53, 0x00, 0x6f, 0x00, 0x75, 0x00, 0x72, 0x00, 0x63,
    0x00, 0x65, 0x00, 0x20, 0x00, 0x53, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x73, 0x00, 0x20, 0x00, 0x50,
    0x00, 0x72, 0x00, 0x6f, 0x00, 0xa9, 0x00, 0x20, 0x00, 0x32, 0x00, 0x30, 0x00, 0x31, 0x00, 0x30,
    0x00, 0x20, 0x00, 0x2d, 0x00, 0x20, 0x00, 0x32, 0x00, 0x30, 0x00, 0x31, 0x00, 0x34, 0x00, 0x20,
    0x00, 0x41, 0x00, 0x64, 0x00, 0x6f, 0x00, 0x62, 0x00, 0x65, 0x00, 0x20, 0x00, 0x53, 0x00, 0x79,
    0x00, 0x73, 0x00, 0x74, 0x00, 0x65, 0x00, 0x6d, 0x00, 0x73, 0x00, 0x20, 0x00, 0x49, 0x00, 0x6e,
    0x00, 0x63, 0x00, 0x6f, 0x00, 0x72, 0x00, 0x70, 0x00, 0x6f, 0x00, 0x72, 0x00, 0x61, 0x00, 0x74,
    0x00, 0x65, 0x00, 0x64, 0x00, 0x20, 0x00, 0x28, 0x00, 0x68, 0x00, 0x74, 0x00, 0x74, 0x00, 0x70,
    0x00, 0x3a, 0x00, 0x2f, 0x00, 0x2f, 0x00, 0x77, 0x00, 0x77, 0x00, 0x77, 0x00, 0x2e, 0x00, 0x61,
    0x00, 0x64, 0x00, 0x6f, 0x00, 0x62, 0x00, 0x65, 0x00, 0x2e, 0x00, 0x63, 0x00, 0x6f, 0x00, 0x6d,
    0x00, 0x2f, 0x00, 0x29, 0x00, 0x2c, 0x00, 0x20, 0x00, 0x77, 0x00, 0x69, 0x00, 0x74, 0x00, 0x68,
    0x00, 0x20, 0x00, 0x52, 0x00, 0x65, 0x00, 0x73, 0x00, 0x65, 0x00, 0x72, 0x00, 0x76, 0x00, 0x65,
    0x00, 0x64, 0x00, 0x20, 0x00, 0x46, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x74, 0x00, 0x20, 0x00, 0x4e,
    0x00, 0x61, 0x00, 0x6d, 0x00, 0x65, 0x00, 0x20, 0x20, 0x18, 0x00, 0x53, 0x00, 0x6f, 0x00, 0x75,
    0x00, 0x72, 0x00, 0x63, 0x00, 0x65, 0x20, 0x19, 0x00, 0x2e, 0x00, 0x00, 0x01, 0x00, 0x04, 0x04,
    0x00, 0x01, 0x01, 0x01, 0x16, 0x53, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x53, 0x61, 0x6e, 0x73, 0x50,
    0x72, 0x6f, 0x2d, 0x52, 0x65, 0x67, 0x75, 0x6c, 0x61, 0x72, 0x00, 0x01, 0x01, 0x01, 0x31, 0x1c,
    0x01, 0x87, 0x00, 0x1c, 0x01, 0x88, 0x01, 0x1c, 0x01, 0x89, 0x0c, 0x00, 0x1c, 0x01, 0x8a, 0x03,
    0x40, 0x0c, 0x03, 0x8e, 0x7f, 0xf8, 0xc2, 0xf9, 0xf1, 0x05, 0x1d, 0x00, 0x00, 0x01, 0x9c, 0x0f,
    0x1c, 0x00, 0x44, 0x1d, 0x00, 0x00, 0x01, 0xa3, 0x12, 0x1d, 0x00, 0x00, 0x02, 0x0d, 0x11, 0x00,
    0x04, 0x01, 0x01, 0x05, 0x65, 0xd5, 0xe4, 0x32, 0x2e, 0x32, 0x30, 0x53, 0x6f, 0x75, 0x72, 0x63,
    0x65, 0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x74, 0x72, 0x61, 0x64, 0x65, 0x6d, 0x61, 0x72, 0x6b,
    0x20, 0x6f, 0x66, 0x20, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x20, 0x53, 0x79, 0x73, 0x74, 0x65, 0x6d,
    0x73, 0x20, 0x49, 0x6e, 0x63, 0x6f, 0x72, 0x70, 0x6f, 0x72, 0x61, 0x74, 0x65, 0x64, 0x20, 0x69,
    0x6e, 0x20, 0x74, 0x68, 0x65, 0x20, 0x55, 0x6e, 0x69, 0x74, 0x65, 0x64, 0x20, 0x53, 0x74, 0x61,
    0x74, 0x65, 0x73, 0x20, 0x61, 0x6e, 0x64, 0x2f, 0x6f, 0x72, 0x20, 0x6f, 0x74, 0x68, 0x65, 0x72,
    0x20, 0x63, 0x6f, 0x75, 0x6e, 0x74, 0x72, 0x69, 0x65, 0x73, 0x2e, 0x43, 0x6f, 0x70, 0x79, 0x72,
    0x69, 0x67, 0x68, 0x74, 0x20, 0x32, 0x30, 0x31, 0x30, 0x2c, 0x20, 0x32, 0x30, 0x31, 0x32, 0x2c,
    0x20, 0x32, 0x30, 0x31, 0x34, 0x20, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x20, 0x53, 0x79, 0x73, 0x74,
    0x65, 0x6d, 0x73, 0x20, 0x49, 0x6e, 0x63, 0x6f, 0x72, 0x70, 0x6f, 0x72, 0x61, 0x74, 0x65, 0x64,
    0x20, 0x28, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x61, 0x64, 0x6f,
    0x62, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x29, 0x2c, 0x20, 0x77, 0x69, 0x74, 0x68, 0x20, 0x52,
    0x65, 0x73, 0x65, 0x72, 0x76, 0x65, 0x64, 0x20, 0x46, 0x6f, 0x6e, 0x74, 0x20, 0x4e, 0x61, 0x6d,
    0x65, 0x20, 0x27, 0x53, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x27, 0x2e, 0x53, 0x6f, 0x75, 0x72, 0x63,
    0x65, 0x20, 0x53, 0x61, 0x6e, 0x73, 0x20, 0x50, 0x72, 0x6f, 0x00, 0x07, 0x01, 0x01, 0x2d, 0x31,
    0x36, 0x3e, 0x49, 0x4d, 0x54, 0xa3, 0xd4, 0xa0, 0xd3, 0x9f, 0xd7, 0x08, 0x8f, 0x06, 0xa0, 0x3f,
    0xa0, 0x43, 0xa3, 0x42, 0xaa, 0x27, 0x18, 0xfb, 0x59, 0x06, 0xfb, 0x3d, 0xfb, 0x9f, 0x15, 0xe0,
    0x06, 0xca, 0xf7, 0x5c, 0x05, 0xf7, 0x83, 0x06, 0xc9, 0xfb, 0x5c, 0x05, 0xe4, 0x06, 0x23, 0x1d,
    0x0b, 0x03, 0x20, 0x0a, 0x0b, 0x25, 0x1d, 0x26, 0x1d, 0x0b, 0xfb, 0x72, 0xf9, 0x24, 0x05, 0x2d,
    0x06, 0x0b, 0x15, 0xb5, 0xb4, 0xfb, 0x21, 0xf7, 0x3b, 0x51, 0x54, 0x05, 0x0e, 0x7d, 0x23, 0x0a,
    0x0b, 0x01, 0x8e, 0xf8, 0xae, 0x21, 0x1d, 0x0b, 0x00, 0x00, 0x22, 0x00, 0xae, 0x00, 0x7c, 0x7f,
    0x97, 0xf8, 0x7a, 0x97, 0x9f, 0x97, 0xb7, 0x97, 0xbf, 0x97, 0x91, 0x97, 0xb7, 0x97, 0x06, 0xfb,
    0x6d, 0x97, 0x07, 0x7f, 0x97, 0xf8, 0x7a, 0x97, 0x9f, 0x97, 0xb7, 0x97, 0xbf, 0x97, 0x91, 0x97,
    0xb7, 0x97, 0x08, 0xfb, 0x6d, 0x97, 0x09, 0x1e, 0xa0, 0x62, 0x5f, 0x0c, 0x09, 0x8b, 0x0c, 0x0b,
    0xce, 0x0a, 0xdf, 0x0b, 0xce, 0x96, 0x0c, 0x0c, 0xdf, 0x96, 0x0c, 0x0d, 0xf8, 0xc2, 0x15, 0x1c,
    0x00, 0x44, 0x13, 0x00, 0x05, 0x01, 0x01, 0x06, 0x0c, 0x14, 0x18, 0x1e, 0xf7, 0x5f, 0x21, 0x0a,
    0x0b, 0xf8, 0x03, 0x15, 0x20, 0x1d, 0x0b, 0x76, 0xf7, 0x5c, 0xce, 0xf7, 0xd5, 0xcf, 0x0b, 0xa0,
    0x22, 0x0a, 0x0b, 0xf8, 0xd1, 0xf7, 0x64, 0x01, 0x0b, 0x00, 0x04, 0x01, 0x01, 0x03, 0x06, 0x0d,
    0x1b, 0xea, 0x0e, 0x22, 0x1d, 0x0e, 0x7d, 0x9a, 0xdb, 0xcc, 0xf7, 0x55, 0x0e, 0x7b, 0x24, 0x0a,
    0xf7, 0x14, 0xf7, 0x5b, 0x03, 0xf7, 0xb1, 0xf8, 0xd1, 0x24, 0x1d, 0x00,
  ])
}

///|
fn build_font_bytes_test_cff2_vf() -> Bytes {
  Bytes::from_array([
    0x4f, 0x54, 0x54, 0x4f, 0x00, 0x12, 0x01, 0x00, 0x00, 0x04, 0x00, 0x20, 0x42, 0x41, 0x53, 0x45,
    0x65, 0x1e, 0x5d, 0xbd, 0x00, 0x00, 0x08, 0xc4, 0x00, 0x00, 0x00, 0x46, 0x43, 0x46, 0x46, 0x32,
    0xe3, 0x06, 0x06, 0xbd, 0x00, 0x00, 0x09, 0x0c, 0x00, 0x00, 0x03, 0x2d, 0x44, 0x53, 0x49, 0x47,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x0e, 0x2c, 0x00, 0x00, 0x00, 0x08, 0x47, 0x50, 0x4f, 0x53,
    0xb7, 0xfd, 0xc7, 0x46, 0x00, 0x00, 0x0c, 0x3c, 0x00, 0x00, 0x00, 0x36, 0x47, 0x53, 0x55, 0x42,
    0xec, 0x27, 0x4a, 0x14, 0x00, 0x00, 0x0c, 0x74, 0x00, 0x00, 0x00, 0x86, 0x48, 0x56, 0x41, 0x52,
    0x00, 0x15, 0x00, 0x33, 0x00, 0x00, 0x0c, 0xfc, 0x00, 0x00, 0x00, 0x36, 0x4d, 0x56, 0x41, 0x52,
    0xe6, 0xfd, 0xd2, 0x35, 0x00, 0x00, 0x0d, 0x34, 0x00, 0x00, 0x00, 0x46, 0x4f, 0x53, 0x2f, 0x32,
    0x59, 0x4a, 0x56, 0x4b, 0x00, 0x00, 0x01, 0x90, 0x00, 0x00, 0x00, 0x60, 0x53, 0x54, 0x41, 0x54,
    0x78, 0x70, 0x68, 0x8d, 0x00, 0x00, 0x0d, 0x7c, 0x00, 0x00, 0x00, 0x1c, 0x61, 0x76, 0x61, 0x72,
    0x23, 0x0c, 0x2c, 0xce, 0x00, 0x00, 0x0d, 0x98, 0x00, 0x00, 0x00, 0x26, 0x63, 0x6d, 0x61, 0x70,
    0x00, 0x90, 0x01, 0xd4, 0x00, 0x00, 0x01, 0xfc, 0x00, 0x00, 0x00, 0xb8, 0x66, 0x76, 0x61, 0x72,
    0x8d, 0xcc, 0x75, 0x9d, 0x00, 0x00, 0x0d, 0xc0, 0x00, 0x00, 0x00, 0x6a, 0x68, 0x65, 0x61, 0x64,
    0x12, 0xb9, 0x53, 0xaa, 0x00, 0x00, 0x01, 0x2c, 0x00, 0x00, 0x00, 0x36, 0x68, 0x68, 0x65, 0x61,
    0x06, 0x32, 0x01, 0x68, 0x00, 0x00, 0x01, 0x64, 0x00, 0x00, 0x00, 0x24, 0x68, 0x6d, 0x74, 0x78,
    0x02, 0xcc, 0x00, 0xbc, 0x00, 0x00, 0x01, 0xf0, 0x00, 0x00, 0x00, 0x0c, 0x6d, 0x61, 0x78, 0x70,
    0x00, 0x05, 0x50, 0x00, 0x00, 0x00, 0x01, 0x88, 0x00, 0x00, 0x00, 0x06, 0x6e, 0x61, 0x6d, 0x65,
    0xa3, 0x43, 0x1c, 0x45, 0x00, 0x00, 0x02, 0xb4, 0x00, 0x00, 0x05, 0xee, 0x70, 0x6f, 0x73, 0x74,
    0xff, 0xb8, 0x00, 0x33, 0x00, 0x00, 0x08, 0xa4, 0x00, 0x00, 0x00, 0x20, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x01, 0x02, 0x8f, 0xf6, 0x3c, 0xae, 0x33, 0x5f, 0x0f, 0x3c, 0xf5, 0x00, 0x03, 0x03, 0xe8,
    0x00, 0x00, 0x00, 0x00, 0xd7, 0xed, 0x09, 0x7b, 0x00, 0x00, 0x00, 0x00, 0xd9, 0x5d, 0x04, 0x42,
    0x00, 0x1f, 0xff, 0x8f, 0x02, 0x39, 0x02, 0xef, 0x00, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x03, 0xd8, 0xfe, 0xef, 0x00, 0x00, 0x02, 0x58,
    0x00, 0x1f, 0x00, 0x1f, 0x02, 0x39, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x50, 0x00, 0x00, 0x05, 0x00, 0x00,
    0x00, 0x03, 0x02, 0x58, 0x01, 0x90, 0x00, 0x05, 0x00, 0x00, 0x02, 0x8a, 0x02, 0x58, 0x00, 0x00,
    0x00, 0x4b, 0x02, 0x8a, 0x02, 0x58, 0x00, 0x00, 0x01, 0x5e, 0x00, 0x32, 0x01, 0x23, 0x00, 0x00,
    0x02, 0x0b, 0x05, 0x09, 0x03, 0x04, 0x03, 0x02, 0x02, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41, 0x44, 0x42, 0x4f, 0x00, 0x40,
    0x00, 0x24, 0x00, 0x54, 0x02, 0xee, 0xff, 0x06, 0x00, 0x00, 0x03, 0xd8, 0x01, 0x11, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0xe6, 0x02, 0x94, 0x00, 0x00, 0x00, 0x20, 0x00, 0x01,
    0x02, 0x58, 0x00, 0x3e, 0x00, 0x1f, 0x00, 0x29, 0x00, 0x55, 0x00, 0x55, 0x00, 0x00, 0x00, 0x03,
    0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4c,
    0x00, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x04, 0x00, 0x30, 0x00, 0x00, 0x00, 0x08,
    0x00, 0x08, 0x00, 0x02, 0x00, 0x00, 0x00, 0x24, 0x00, 0x41, 0x00, 0x54, 0xff, 0xff, 0x00, 0x00,
    0x00, 0x24, 0x00, 0x41, 0x00, 0x54, 0xff, 0xff, 0xff, 0xe0, 0xff, 0xc0, 0xff, 0xae, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x6c, 0x00, 0x00, 0x00, 0x24,
    0x00, 0x31, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x2c, 0x02, 0x16, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x14, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x07,
    0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x23, 0x00, 0x1b, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x14, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x05, 0x00, 0x32, 0x00, 0x3e, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x18,
    0x00, 0x70, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x05, 0x00, 0x88, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x06, 0x00, 0x8d, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x01, 0x00, 0x0a, 0x00, 0x93, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x00, 0x18,
    0x00, 0x9d, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x05, 0x00, 0xb5, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x04, 0x00, 0x13, 0x00, 0xba, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x05, 0x00, 0x07, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x06, 0x00, 0x15,
    0x00, 0xcd, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x07, 0x00, 0x06, 0x00, 0xe2, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x08, 0x00, 0x14, 0x00, 0xe8, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x09, 0x00, 0x08, 0x00, 0xfc, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x0a, 0x00, 0x16,
    0x01, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x0b, 0x00, 0x04, 0x01, 0x1a, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x0c, 0x00, 0x12, 0x01, 0x1e, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x0d, 0x00, 0x05, 0x01, 0x30, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x0e, 0x00, 0x13,
    0x01, 0x35, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x01, 0x00, 0x28, 0x01, 0x48, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x00, 0x02, 0x00, 0x0e, 0x01, 0x70, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x00, 0x03, 0x00, 0x46, 0x01, 0x7e, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x04, 0x00, 0x28,
    0x01, 0x48, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x00, 0x05, 0x00, 0x64, 0x01, 0xc4, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x00, 0x06, 0x00, 0x30, 0x02, 0x28, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x00, 0x11, 0x00, 0x0a, 0x02, 0x58, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x00, 0x00, 0x0c,
    0x02, 0x62, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x01, 0x00, 0x14, 0x02, 0x6e, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x01, 0x02, 0x00, 0x30, 0x02, 0x82, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x01, 0x03, 0x00, 0x0a, 0x02, 0xb2, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x04, 0x00, 0x26,
    0x02, 0xbc, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x05, 0x00, 0x0e, 0x01, 0x70, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x01, 0x06, 0x00, 0x2a, 0x02, 0xe2, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x01, 0x07, 0x00, 0x0c, 0x03, 0x0c, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x08, 0x00, 0x28,
    0x03, 0x18, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x09, 0x00, 0x10, 0x03, 0x40, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x01, 0x0a, 0x00, 0x2c, 0x03, 0x50, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09,
    0x01, 0x0b, 0x00, 0x08, 0x03, 0x7c, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x0c, 0x00, 0x24,
    0x03, 0x84, 0x00, 0x03, 0x00, 0x01, 0x04, 0x09, 0x01, 0x0d, 0x00, 0x0a, 0x03, 0xa8, 0x00, 0x03,
    0x00, 0x01, 0x04, 0x09, 0x01, 0x0e, 0x00, 0x26, 0x03, 0xb2, 0x53, 0x6f, 0x75, 0x72, 0x63, 0x65,
    0x20, 0x43, 0x6f, 0x64, 0x65, 0x20, 0x56, 0x61, 0x72, 0x69, 0x61, 0x62, 0x6c, 0x65, 0x52, 0x65,
    0x67, 0x75, 0x6c, 0x61, 0x72, 0x31, 0x2e, 0x30, 0x31, 0x30, 0x3b, 0x41, 0x44, 0x42, 0x4f, 0x3b,
    0x53, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x43, 0x6f, 0x64, 0x65, 0x56, 0x61, 0x72, 0x69, 0x61, 0x62,
    0x6c, 0x65, 0x2d, 0x52, 0x6f, 0x6d, 0x61, 0x6e, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x20,
    0x31, 0x2e, 0x30, 0x31, 0x30, 0x3b, 0x68, 0x6f, 0x74, 0x63, 0x6f, 0x6e, 0x76, 0x20, 0x31, 0x2e,
    0x30, 0x2e, 0x31, 0x30, 0x39, 0x3b, 0x6d, 0x61, 0x6b, 0x65, 0x6f, 0x74, 0x66, 0x65, 0x78, 0x65,
    0x20, 0x32, 0x2e, 0x35, 0x2e, 0x36, 0x35, 0x35, 0x39, 0x36, 0x53, 0x6f, 0x75, 0x72, 0x63, 0x65,
    0x43, 0x6f, 0x64, 0x65, 0x56, 0x61, 0x72, 0x69, 0x61, 0x62, 0x6c, 0x65, 0x2d, 0x52, 0x6f, 0x6d,
    0x61, 0x6e, 0x52, 0x6f, 0x6d, 0x61, 0x6e, 0x57, 0x65, 0x69, 0x67, 0x68, 0x74, 0x45, 0x78, 0x74,
    0x72, 0x61, 0x4c, 0x69, 0x67, 0x68, 0x74, 0x54, 0x65, 0x73, 0x74, 0x43, 0x46, 0x46, 0x32, 0x52,
    0x6f, 0x6d, 0x61, 0x6e, 0x2d, 0x45, 0x78, 0x74, 0x72, 0x61, 0x4c, 0x69, 0x67, 0x68, 0x74, 0x4c,
    0x69, 0x67, 0x68, 0x74, 0x54, 0x65, 0x73, 0x74, 0x43, 0x46, 0x46, 0x32, 0x52, 0x6f, 0x6d, 0x61,
    0x6e, 0x2d, 0x4c, 0x69, 0x67, 0x68, 0x74, 0x54, 0x65, 0x73, 0x74, 0x43, 0x46, 0x46, 0x32, 0x52,
    0x6f, 0x6d, 0x61, 0x6e, 0x2d, 0x52, 0x65, 0x67, 0x75, 0x6c, 0x61, 0x72, 0x4d, 0x65, 0x64, 0x69,
    0x75, 0x6d, 0x54, 0x65, 0x73, 0x74, 0x43, 0x46, 0x46, 0x32, 0x52, 0x6f, 0x6d, 0x61, 0x6e, 0x2d,
    0x4d, 0x65, 0x64, 0x69, 0x75, 0x6d, 0x53, 0x65, 0x6d, 0x69, 0x62, 0x6f, 0x6c, 0x64, 0x54, 0x65,
    0x73, 0x74, 0x43, 0x46, 0x46, 0x32, 0x52, 0x6f, 0x6d, 0x61, 0x6e, 0x2d, 0x53, 0x65, 0x6d, 0x69,
    0x62, 0x6f, 0x6c, 0x64, 0x42, 0x6f, 0x6c, 0x64, 0x54, 0x65, 0x73, 0x74, 0x43, 0x46, 0x46, 0x32,
    0x52, 0x6f, 0x6d, 0x61, 0x6e, 0x2d, 0x42, 0x6f, 0x6c, 0x64, 0x42, 0x6c, 0x61, 0x63, 0x6b, 0x54,
    0x65, 0x73, 0x74, 0x43, 0x46, 0x46, 0x32, 0x52, 0x6f, 0x6d, 0x61, 0x6e, 0x2d, 0x42, 0x6c, 0x61,
    0x63, 0x6b, 0x00, 0x53, 0x00, 0x6f, 0x00, 0x75, 0x00, 0x72, 0x00, 0x63, 0x00, 0x65, 0x00, 0x20,
    0x00, 0x43, 0x00, 0x6f, 0x00, 0x64, 0x00, 0x65, 0x00, 0x20, 0x00, 0x56, 0x00, 0x61, 0x00, 0x72,
    0x00, 0x69, 0x00, 0x61, 0x00, 0x62, 0x00, 0x6c, 0x00, 0x65, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67,
    0x00, 0x75, 0x00, 0x6c, 0x00, 0x61, 0x00, 0x72, 0x00, 0x31, 0x00, 0x2e, 0x00, 0x30, 0x00, 0x31,
    0x00, 0x30, 0x00, 0x3b, 0x00, 0x41, 0x00, 0x44, 0x00, 0x42, 0x00, 0x4f, 0x00, 0x3b, 0x00, 0x53,
    0x00, 0x6f, 0x00, 0x75, 0x00, 0x72, 0x00, 0x63, 0x00, 0x65, 0x00, 0x43, 0x00, 0x6f, 0x00, 0x64,
    0x00, 0x65, 0x00, 0x56, 0x00, 0x61, 0x00, 0x72, 0x00, 0x69, 0x00, 0x61, 0x00, 0x62, 0x00, 0x6c,
    0x00, 0x65, 0x00, 0x2d, 0x00, 0x52, 0x00, 0x6f, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x56,
    0x00, 0x65, 0x00, 0x72, 0x00, 0x73, 0x00, 0x69, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x20, 0x00, 0x31,
    0x00, 0x2e, 0x00, 0x30, 0x00, 0x31, 0x00, 0x30, 0x00, 0x3b, 0x00, 0x68, 0x00, 0x6f, 0x00, 0x74,
    0x00, 0x63, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x76, 0x00, 0x20, 0x00, 0x31, 0x00, 0x2e, 0x00, 0x30,
    0x00, 0x2e, 0x00, 0x31, 0x00, 0x30, 0x00, 0x39, 0x00, 0x3b, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6b,
    0x00, 0x65, 0x00, 0x6f, 0x00, 0x74, 0x00, 0x66, 0x00, 0x65, 0x00, 0x78, 0x00, 0x65, 0x00, 0x20,
    0x00, 0x32, 0x00, 0x2e, 0x00, 0x35, 0x00, 0x2e, 0x00, 0x36, 0x00, 0x35, 0x00, 0x35, 0x00, 0x39,
    0x00, 0x36, 0x00, 0x53, 0x00, 0x6f, 0x00, 0x75, 0x00, 0x72, 0x00, 0x63, 0x00, 0x65, 0x00, 0x43,
    0x00, 0x6f, 0x00, 0x64, 0x00, 0x65, 0x00, 0x56, 0x00, 0x61, 0x00, 0x72, 0x00, 0x69, 0x00, 0x61,
    0x00, 0x62, 0x00, 0x6c, 0x00, 0x65, 0x00, 0x2d, 0x00, 0x52, 0x00, 0x6f, 0x00, 0x6d, 0x00, 0x61,
    0x00, 0x6e, 0x00, 0x52, 0x00, 0x6f, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x57, 0x00, 0x65,
    0x00, 0x69, 0x00, 0x67, 0x00, 0x68, 0x00, 0x74, 0x00, 0x45, 0x00, 0x78, 0x00, 0x74, 0x00, 0x72,
    0x00, 0x61, 0x00, 0x4c, 0x00, 0x69, 0x00, 0x67, 0x00, 0x68, 0x00, 0x74, 0x00, 0x54, 0x00, 0x65,
    0x00, 0x73, 0x00, 0x74, 0x00, 0x43, 0x00, 0x46, 0x00, 0x46, 0x00, 0x32, 0x00, 0x52, 0x00, 0x6f,
    0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x2d, 0x00, 0x45, 0x00, 0x78, 0x00, 0x74, 0x00, 0x72,
    0x00, 0x61, 0x00, 0x4c, 0x00, 0x69, 0x00, 0x67, 0x00, 0x68, 0x00, 0x74, 0x00, 0x4c, 0x00, 0x69,
    0x00, 0x67, 0x00, 0x68, 0x00, 0x74, 0x00, 0x54, 0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00, 0x43,
    0x00, 0x46, 0x00, 0x46, 0x00, 0x32, 0x00, 0x52, 0x00, 0x6f, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e,
    0x00, 0x2d, 0x00, 0x4c, 0x00, 0x69, 0x00, 0x67, 0x00, 0x68, 0x00, 0x74, 0x00, 0x54, 0x00, 0x65,
    0x00, 0x73, 0x00, 0x74, 0x00, 0x43, 0x00, 0x46, 0x00, 0x46, 0x00, 0x32, 0x00, 0x52, 0x00, 0x6f,
    0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x2d, 0x00, 0x52, 0x00, 0x65, 0x00, 0x67, 0x00, 0x75,
    0x00, 0x6c, 0x00, 0x61, 0x00, 0x72, 0x00, 0x4d, 0x00, 0x65, 0x00, 0x64, 0x00, 0x69, 0x00, 0x75,
    0x00, 0x6d, 0x00, 0x54, 0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00, 0x43, 0x00, 0x46, 0x00, 0x46,
    0x00, 0x32, 0x00, 0x52, 0x00, 0x6f, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x2d, 0x00, 0x4d,
    0x00, 0x65, 0x00, 0x64, 0x00, 0x69, 0x00, 0x75, 0x00, 0x6d, 0x00, 0x53, 0x00, 0x65, 0x00, 0x6d,
    0x00, 0x69, 0x00, 0x62, 0x00, 0x6f, 0x00, 0x6c, 0x00, 0x64, 0x00, 0x54, 0x00, 0x65, 0x00, 0x73,
    0x00, 0x74, 0x00, 0x43, 0x00, 0x46, 0x00, 0x46, 0x00, 0x32, 0x00, 0x52, 0x00, 0x6f, 0x00, 0x6d,
    0x00, 0x61, 0x00, 0x6e, 0x00, 0x2d, 0x00, 0x53, 0x00, 0x65, 0x00, 0x6d, 0x00, 0x69, 0x00, 0x62,
    0x00, 0x6f, 0x00, 0x6c, 0x00, 0x64, 0x00, 0x42, 0x00, 0x6f, 0x00, 0x6c, 0x00, 0x64, 0x00, 0x54,
    0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00, 0x43, 0x00, 0x46, 0x00, 0x46, 0x00, 0x32, 0x00, 0x52,
    0x00, 0x6f, 0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x2d, 0x00, 0x42, 0x00, 0x6f, 0x00, 0x6c,
    0x00, 0x64, 0x00, 0x42, 0x00, 0x6c, 0x00, 0x61, 0x00, 0x63, 0x00, 0x6b, 0x00, 0x54, 0x00, 0x65,
    0x00, 0x73, 0x00, 0x74, 0x00, 0x43, 0x00, 0x46, 0x00, 0x46, 0x00, 0x32, 0x00, 0x52, 0x00, 0x6f,
    0x00, 0x6d, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x2d, 0x00, 0x42, 0x00, 0x6c, 0x00, 0x61, 0x00, 0x63,
    0x00, 0x6b, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xb5, 0x00, 0x32,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x04, 0x00, 0x0e,
    0x00, 0x02, 0x69, 0x64, 0x65, 0x6f, 0x72, 0x6f, 0x6d, 0x6e, 0x00, 0x04, 0x44, 0x46, 0x4c, 0x54,
    0x00, 0x1a, 0x63, 0x79, 0x72, 0x6c, 0x00, 0x1a, 0x67, 0x72, 0x65, 0x6b, 0x00, 0x1a, 0x6c, 0x61,
    0x74, 0x6e, 0x00, 0x1a, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x08,
    0x00, 0x0c, 0x00, 0x01, 0xff, 0x56, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x05, 0x00,
    0x08, 0xf8, 0xb9, 0x0c, 0x24, 0xc4, 0x11, 0x9c, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x26, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x01, 0x00, 0x02, 0xc0,
    0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x05, 0x02, 0x00, 0x01, 0x00, 0xa7, 0x01, 0x1b,
    0x01, 0x3e, 0x01, 0x7b, 0x01, 0xdc, 0xc9, 0xa1, 0x65, 0x8c, 0x10, 0x16, 0xf8, 0x70, 0x5f, 0xd7,
    0x8c, 0x10, 0xf9, 0x28, 0xfc, 0x70, 0xb7, 0x3f, 0x21, 0x0a, 0xf7, 0x01, 0xfc, 0xed, 0x4e, 0xf2,
    0x70, 0xb8, 0x22, 0x0a, 0xd4, 0xf7, 0x17, 0xc1, 0xf1, 0xa8, 0x5c, 0xb8, 0x40, 0x95, 0x79, 0x8f,
    0x85, 0x8f, 0x10, 0x05, 0x8f, 0x06, 0xbf, 0x25, 0xd4, 0xfb, 0x17, 0x95, 0x7b, 0x87, 0x91, 0xa6,
    0x5c, 0x5e, 0xd6, 0x8f, 0x10, 0x05, 0xfb, 0xc0, 0xbf, 0x61, 0xd3, 0x81, 0x9b, 0x22, 0x0a, 0xf8,
    0x61, 0xd6, 0xfb, 0x11, 0x8c, 0x10, 0x07, 0xf7, 0x13, 0xfb, 0x7c, 0xa6, 0x5e, 0x65, 0xcb, 0x8d,
    0x10, 0x05, 0xb7, 0xbb, 0x75, 0xaf, 0x75, 0xaf, 0x22, 0x0a, 0x59, 0xe8, 0x49, 0xf7, 0x0b, 0x85,
    0x95, 0x8a, 0x8e, 0x6f, 0xbb, 0xbc, 0x38, 0x8f, 0x10, 0x05, 0xf7, 0x7e, 0xcf, 0xfb, 0x06, 0x21,
    0x0a, 0x4a, 0xfb, 0x0b, 0x5a, 0x2e, 0x6e, 0xba, 0x5a, 0xde, 0x86, 0x94, 0x8c, 0x88, 0x8f, 0x10,
    0x05, 0xb7, 0x5b, 0x75, 0xaf, 0xa1, 0x67, 0x22, 0x0a, 0xf7, 0x12, 0xf7, 0x7c, 0xa5, 0x5f, 0xb1,
    0x4b, 0x8d, 0x10, 0x05, 0xfc, 0x61, 0x40, 0xf7, 0x11, 0x8c, 0x10, 0x07, 0xaa, 0x9e, 0x6c, 0x8c,
    0x10, 0x16, 0xe1, 0x55, 0xe5, 0x21, 0x0a, 0xf7, 0x07, 0xf8, 0x02, 0xa2, 0xd4, 0xa0, 0xd3, 0xa0,
    0xd7, 0xa4, 0x61, 0xa9, 0x59, 0x90, 0x82, 0x92, 0x80, 0x8e, 0x87, 0x87, 0x91, 0x8e, 0x84, 0x91,
    0x81, 0x93, 0x10, 0x19, 0x8f, 0x06, 0x9f, 0x3f, 0xa1, 0x43, 0xa2, 0x42, 0xf7, 0x05, 0xfc, 0x02,
    0x8f, 0x85, 0x85, 0x95, 0x8d, 0x88, 0x8f, 0x85, 0x90, 0x82, 0x84, 0x96, 0xa4, 0x63, 0x6d, 0xbd,
    0x93, 0x10, 0x18, 0xe5, 0x53, 0xe7, 0x21, 0x0a, 0xfb, 0x71, 0xf9, 0x24, 0x7c, 0xa4, 0x8f, 0x85,
    0x8d, 0x10, 0x05, 0x2b, 0xcf, 0xfb, 0x04, 0x21, 0x0a, 0x23, 0xfc, 0x5d, 0x6d, 0xbc, 0xac, 0x54,
    0x22, 0x0a, 0xf7, 0xc1, 0xcf, 0xfb, 0xc1, 0x83, 0x9a, 0x63, 0xcc, 0x93, 0x7c, 0x8e, 0x10, 0x06,
    0xf7, 0x96, 0xa5, 0x5f, 0x8c, 0x10, 0x16, 0xdf, 0xf8, 0xdd, 0xf7, 0x6d, 0xd2, 0xfc, 0x9a, 0x44,
    0xf7, 0x6d, 0x57, 0xe3, 0xba, 0x3c, 0x9c, 0x6d, 0x60, 0xd4, 0x9d, 0x6f, 0xb6, 0x42, 0x9c, 0x6d,
    0x92, 0x10, 0x06, 0x20, 0x0a, 0xa0, 0x68, 0xaf, 0x51, 0x8d, 0x10, 0x05, 0x60, 0xbf, 0xdf, 0x67,
    0xde, 0x90, 0x80, 0x84, 0x98, 0x80, 0x9c, 0x87, 0x93, 0x93, 0x7e, 0x90, 0x10, 0x1b, 0x58, 0xfb,
    0x27, 0x78, 0xab, 0x8c, 0x88, 0x22, 0x0a, 0xf7, 0x33, 0xf9, 0xed, 0x53, 0x92, 0xfb, 0x33, 0xfd,
    0xee, 0x8a, 0x8c, 0x8e, 0x88, 0xa5, 0x5f, 0x88, 0x90, 0x8c, 0x8a, 0x89, 0x8f, 0x91, 0x10, 0x05,
    0x20, 0x0a, 0xd4, 0x71, 0xd4, 0x71, 0xd4, 0x70, 0xa0, 0x68, 0xaf, 0x51, 0x6f, 0x83, 0x7f, 0x6f,
    0x8b, 0xa7, 0x7d, 0x89, 0x9d, 0x88, 0xa6, 0xa6, 0x93, 0x10, 0x19, 0x73, 0xf8, 0xca, 0x91, 0x76,
    0x8b, 0x69, 0x22, 0x0a, 0xc3, 0x71, 0xc3, 0x21, 0x0a, 0xbd, 0x8b, 0x94, 0x8c, 0x10, 0x8b, 0xbd,
    0xbd, 0x8b, 0x94, 0x8b, 0x95, 0x8d, 0x10, 0x1a, 0x53, 0xa5, 0x53, 0x21, 0x0a, 0x59, 0x8b, 0x82,
    0x8c, 0x10, 0x8b, 0x59, 0x59, 0x8b, 0x82, 0x8b, 0x81, 0x8d, 0x10, 0x1a, 0xfc, 0xc6, 0x8b, 0xf1,
    0x8c, 0x10, 0x04, 0xfb, 0x28, 0xc3, 0xf7, 0x28, 0x8b, 0x47, 0x71, 0xc3, 0x8b, 0xcf, 0x8e, 0x10,
    0x07, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x05, 0xd4, 0xf8, 0xc4, 0x12, 0x7f, 0x97, 0xf8, 0x7a,
    0x97, 0xd7, 0x97, 0xbf, 0x97, 0x91, 0x97, 0xb7, 0x97, 0x8b, 0x8b, 0x8b, 0x8b, 0x83, 0x99, 0x8b,
    0x8b, 0x8f, 0x83, 0x8b, 0x8b, 0x91, 0x81, 0x8b, 0x8b, 0x8d, 0x89, 0x8b, 0x8b, 0x91, 0x81, 0x8b,
    0x8b, 0x97, 0x17, 0x06, 0xfb, 0x6d, 0x97, 0x7a, 0xa8, 0x8b, 0x8b, 0x8d, 0x17, 0x07, 0x1e, 0xa0,
    0x62, 0x5f, 0x0c, 0x09, 0x8b, 0x0c, 0x0b, 0xce, 0x64, 0xce, 0x8c, 0x17, 0x0a, 0xe0, 0x58, 0xe2,
    0x8c, 0x17, 0x0b, 0xd4, 0x13, 0x00, 0x00, 0x00, 0x03, 0x01, 0x01, 0xa6, 0xa9, 0xac, 0xf7, 0xc4,
    0x92, 0x7f, 0x8c, 0x10, 0xad, 0x15, 0xf7, 0x11, 0xe1, 0xcc, 0xeb, 0x75, 0xb1, 0x8d, 0x88, 0x82,
    0x9a, 0x89, 0x8f, 0x8f, 0x10, 0x1f, 0xf7, 0x4b, 0xfb, 0xd8, 0x76, 0xf7, 0x02, 0x8c, 0x8a, 0x7d,
    0xa1, 0x80, 0x9c, 0xab, 0x55, 0x8f, 0x10, 0x1a, 0xbd, 0xb5, 0xab, 0xce, 0xcf, 0xaf, 0x76, 0x67,
    0xba, 0x9d, 0x6e, 0x9a, 0x73, 0x97, 0x76, 0x9d, 0x6c, 0x93, 0x7e, 0x89, 0x8e, 0x88, 0x90, 0x89,
    0x8f, 0x88, 0x90, 0x94, 0x10, 0x1e, 0xb7, 0xbc, 0x73, 0xb3, 0x6e, 0xbc, 0x8d, 0x10, 0x05, 0xb7,
    0x5d, 0x55, 0xac, 0x32, 0x85, 0x93, 0x90, 0x84, 0x94, 0x7c, 0x8a, 0x8e, 0x8f, 0x83, 0x90, 0x10,
    0x1b, 0xfb, 0x07, 0x3a, 0x50, 0x2d, 0x9b, 0x71, 0x8e, 0x84, 0x90, 0x82, 0x91, 0x81, 0x8f, 0x10,
    0x1f, 0xfb, 0x42, 0xf7, 0xd8, 0xa1, 0xfb, 0x10, 0x93, 0x7d, 0x99, 0x75, 0x91, 0x81, 0x6b, 0xc3,
    0x8f, 0x10, 0x1a, 0x58, 0x61, 0x68, 0x3d, 0x3f, 0x4d, 0xaa, 0xb0, 0x57, 0x78, 0xaa, 0x7d, 0xa2,
    0x7c, 0xa4, 0x72, 0xb4, 0x82, 0x9a, 0x87, 0x92, 0x92, 0x80, 0x88, 0x8e, 0x97, 0x77, 0x94, 0x10,
    0x1e, 0x64, 0x51, 0x8c, 0x10, 0x06, 0x8d, 0x10, 0x15, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x0a, 0x00, 0x1e, 0x00, 0x34, 0x00, 0x01, 0x44, 0x46, 0x4c, 0x54, 0x00, 0x08, 0x00, 0x04,
    0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x73, 0x69, 0x7a, 0x65,
    0x00, 0x08, 0x00, 0x04, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x0e, 0x00, 0x24, 0x00, 0x3c, 0x00, 0x00,
    0x00, 0x56, 0x00, 0x01, 0x44, 0x46, 0x4c, 0x54, 0x00, 0x08, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00,
    0xff, 0xff, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x72, 0x76, 0x72, 0x6e, 0x00, 0x0e,
    0x74, 0x65, 0x73, 0x74, 0x00, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x06, 0x00, 0x06, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x08, 0x00, 0x01,
    0x00, 0x06, 0xff, 0xff, 0x00, 0x01, 0x00, 0x01, 0x00, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x01, 0x00, 0x00, 0x00, 0x06,
    0x00, 0x01, 0x00, 0x00, 0xc0, 0x00, 0x17, 0x7e, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x01, 0x00, 0x02,
    0xc0, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x40, 0x00, 0x00, 0x05, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x02, 0x00, 0x1c,
    0x73, 0x74, 0x72, 0x6f, 0x00, 0x00, 0x00, 0x01, 0x78, 0x68, 0x67, 0x74, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x01, 0x00, 0x02,
    0xc0, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x40, 0x00, 0x00, 0x02, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0xf8, 0x0e, 0xfb, 0x09, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02,
    0x00, 0x08, 0x00, 0x01, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
    0x77, 0x67, 0x68, 0x74, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x07, 0xc0, 0x00, 0xc0, 0x00, 0xe0, 0x00, 0xd1, 0x64, 0x00, 0x00, 0x00, 0x00, 0x0c, 0xcd,
    0x0b, 0xf3, 0x19, 0x9a, 0x17, 0x7e, 0x26, 0x66, 0x2e, 0x2d, 0x40, 0x00, 0x40, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x10, 0x00, 0x02, 0x00, 0x01, 0x00, 0x14, 0x00, 0x07, 0x00, 0x0a,
    0x77, 0x67, 0x68, 0x74, 0x00, 0xc8, 0x00, 0x00, 0x01, 0x90, 0x00, 0x00, 0x03, 0x84, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0xc8, 0x00, 0x00, 0x01, 0x02, 0x01, 0x03,
    0x00, 0x00, 0x01, 0x2c, 0x00, 0x00, 0x01, 0x04, 0x01, 0x05, 0x00, 0x00, 0x01, 0x90, 0x00, 0x00,
    0x01, 0x06, 0x01, 0x07, 0x00, 0x00, 0x01, 0xf4, 0x00, 0x00, 0x01, 0x08, 0x01, 0x09, 0x00, 0x00,
    0x02, 0x58, 0x00, 0x00, 0x01, 0x0a, 0x01, 0x0b, 0x00, 0x00, 0x02, 0xbc, 0x00, 0x00, 0x01, 0x0c,
    0x01, 0x0d, 0x00, 0x00, 0x03, 0x84, 0x00, 0x00, 0x01, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00,
  ])
}

///|
test "subset cff1 cmap" {
  let font = @font.Font::from_bytes(build_font_bytes_cff1_seac_c0())
  let keep = 0xC0U
  let bytes = match subset(font, SubsetInput::from_codepoints([keep])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let gid = match subset_font.glyph_for_codepoint(keep) {
    Err(err) => fail("glyph lookup error: \{err}")
    Ok(None) => fail("missing glyph for U+00C0")
    Ok(Some(value)) => value
  }
  let face = subset_font.get_face()
  let cmap_blob = match face.reference_table_optional(@common.Tag::from_chars('c', 'm', 'a', 'p')) {
    Err(err) => fail("cmap table missing: \{err}")
    Ok(None) => fail("cmap table missing")
    Ok(Some(blob)) => blob
  }
  let cmap_data = cmap_blob.as_view()
  let subtable_offset = match find_cmap_subtable(cmap_data, 3, 10) {
    None => fail("cmap format 12 subtable missing")
    Some(value) => value
  }
  let format = match read_u16(cmap_data, subtable_offset) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  let group_count = match read_u32(cmap_data, subtable_offset + 12) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  let start = match read_u32(cmap_data, subtable_offset + 16) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  let end = match read_u32(cmap_data, subtable_offset + 20) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  assert_eq(format, 12)
  assert_eq(group_count, 1)
  assert_eq(start, keep.reinterpret_as_int())
  assert_eq(end, keep.reinterpret_as_int())
  let bounds = match subset_font.glyph_bounds(gid) {
    Err(err) => fail("bounds error: \{err}")
    Ok(None) => fail("missing bounds")
    Ok(Some(value)) => value
  }
  inspect((bounds.x_min, bounds.y_min, bounds.x_max, bounds.y_max), content="(3, 0, 541, 861)")
}

///|
test "subset cff1 outlines" {
  let font = @font.Font::from_bytes(build_font_bytes_cff1_seac_c0())
  let keep = 0xC0U
  let original_gid = match font.glyph_for_codepoint(keep) {
    Err(err) => fail("glyph lookup error: \{err}")
    Ok(None) => fail("missing glyph for U+00C0")
    Ok(Some(value)) => value.reinterpret_as_int()
  }
  let original_face = font.get_face()
  let original_cff_blob = match original_face.reference_table_optional(
    @common.Tag::from_chars('C', 'F', 'F', ' ')
  ) {
    Err(err) => fail("cff missing: \{err}")
    Ok(None) => fail("cff missing")
    Ok(Some(blob)) => blob
  }
  let original_cff = match @ot_cff.Cff1Table::parse(original_cff_blob.as_view()) {
    Err(err) => fail("cff parse error: \{err}")
    Ok(value) => value
  }
  let original_components = match original_cff.seac_components(original_gid) {
    Err(err) => fail("seac components error: \{err}")
    Ok(value) => value
  }
  let bytes = match subset(font, SubsetInput::from_codepoints([keep])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  let face = subset_font.get_face()
  let maxp_blob = match face.reference_table_optional(@common.Tag::from_chars('m', 'a', 'x', 'p')) {
    Err(err) => fail("maxp missing: \{err}")
    Ok(None) => fail("maxp missing")
    Ok(Some(blob)) => blob
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => fail("maxp parse error: \{err}")
    Ok(value) => value
  }
  inspect(maxp.num_glyphs, content="4")

  let cff_blob = match face.reference_table_optional(@common.Tag::from_chars('C', 'F', 'F', ' ')) {
    Err(err) => fail("cff missing: \{err}")
    Ok(None) => fail("cff missing")
    Ok(Some(blob)) => blob
  }
  let cff = match @ot_cff.Cff1Table::parse(cff_blob.as_view()) {
    Err(err) => fail("cff parse error: \{err}")
    Ok(value) => value
  }
  let gid = match subset_font.glyph_for_codepoint(keep) {
    Err(err) => fail("glyph lookup error: \{err}")
    Ok(None) => fail("missing glyph for U+00C0")
    Ok(Some(value)) => value
  }
  let components = match cff.seac_components(gid.reinterpret_as_int()) {
    Err(err) => fail("seac components error: \{err}")
    Ok(value) => value
  }
  let expected_components =
    match original_components {
      None => None
      Some((base, accent)) => {
        let selected : Array[Int] = [0, original_gid, base, accent]
        let unique : Array[Int] = []
        for gid in selected {
          if !unique.contains(gid) {
            unique.push(gid)
          }
        }
        let n = unique.length()
        for i in 1..<n {
          let key = unique[i]
          let mut j = i - 1
          while j >= 0 && unique[j] > key {
            unique[j + 1] = unique[j]
            j = j - 1
          }
          unique[j + 1] = key
        }
        let mut base_new = -1
        let mut accent_new = -1
        for i in 0..<unique.length() {
          if unique[i] == base {
            base_new = i
          }
          if unique[i] == accent {
            accent_new = i
          }
        }
        if base_new < 0 || accent_new < 0 {
          None
        } else {
          Some((base_new, accent_new))
        }
      }
    }
  assert_eq(components, expected_components)
}

///|
test "subset cff2 outlines" {
  let font = @font.Font::from_bytes(build_font_bytes_test_cff2_vf())
  let keep = 0x41U
  let bytes = match subset(font, SubsetInput::from_codepoints([keep])) {
    Err(err) => fail("subset failed: \{err}")
    Ok(value) => value
  }
  let subset_font = @font.Font::from_bytes(bytes)
  match subset_font.glyph_for_codepoint(keep) {
    Err(err) => fail("glyph lookup error: \{err}")
    Ok(None) => fail("missing glyph for U+0041")
    Ok(Some(_)) => ()
  }
  let face = subset_font.get_face()
  let maxp_blob = match face.reference_table_optional(@common.Tag::from_chars('m', 'a', 'x', 'p')) {
    Err(err) => fail("maxp table missing: \{err}")
    Ok(None) => fail("maxp table missing")
    Ok(Some(blob)) => blob
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => fail("maxp parse error: \{err}")
    Ok(value) => value
  }
  let cff2_blob = match face.reference_table_optional(@common.Tag::from_chars('C', 'F', 'F', '2')) {
    Err(err) => fail("cff2 table missing: \{err}")
    Ok(None) => fail("cff2 table missing")
    Ok(Some(blob)) => blob
  }
  let cff2 = match @ot_cff.Cff2Table::parse(cff2_blob.as_view()) {
    Err(err) => fail("cff2 parse error: \{err}")
    Ok(value) => value
  }
  inspect(cff2.glyph_count(), content=maxp.num_glyphs.to_string())
  let cmap_blob = match face.reference_table_optional(@common.Tag::from_chars('c', 'm', 'a', 'p')) {
    Err(err) => fail("cmap table missing: \{err}")
    Ok(None) => fail("cmap table missing")
    Ok(Some(blob)) => blob
  }
  let cmap_data = cmap_blob.as_view()
  let subtable_offset = match find_cmap_subtable(cmap_data, 3, 10) {
    None => fail("cmap format 12 subtable missing")
    Some(value) => value
  }
  let format = match read_u16(cmap_data, subtable_offset) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  let group_count = match read_u32(cmap_data, subtable_offset + 12) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  let start = match read_u32(cmap_data, subtable_offset + 16) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  let end = match read_u32(cmap_data, subtable_offset + 20) {
    None => fail("unexpected eof")
    Some(value) => value
  }
  assert_eq(format, 12)
  assert_eq(group_count, 1)
  assert_eq(start, keep.reinterpret_as_int())
  assert_eq(end, keep.reinterpret_as_int())
}
