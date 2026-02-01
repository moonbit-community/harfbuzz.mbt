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
fn build_vhea(number_of_vmetrics : Int) -> Bytes {
  let bytes : Array[Byte] = Array::make(36, b'\x00')
  bytes[34] = ((number_of_vmetrics >> 8) & 0xff).to_byte()
  bytes[35] = (number_of_vmetrics & 0xff).to_byte()
  Bytes::from_array(bytes)
}

///|
fn build_hmtx() -> Bytes {
  let bytes : Array[Byte] = []
  // glyph 0 advance 200, lsb 0
  push_u16(bytes, 200)
  push_u16(bytes, 0)
  // glyph 1 advance 300, lsb 0
  push_u16(bytes, 300)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_hmtx_three() -> Bytes {
  let bytes : Array[Byte] = []
  // glyph 0 advance 200, lsb 0
  push_u16(bytes, 200)
  push_u16(bytes, 0)
  // glyph 1 advance 300, lsb 0
  push_u16(bytes, 300)
  push_u16(bytes, 0)
  // glyph 2 advance 400, lsb 0
  push_u16(bytes, 400)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_vmtx() -> Bytes {
  let bytes : Array[Byte] = []
  // glyph 0 advance 700, tsb 0
  push_u16(bytes, 700)
  push_u16(bytes, 0)
  // glyph 1 advance 800, tsb 0
  push_u16(bytes, 800)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_vmtx_three() -> Bytes {
  let bytes : Array[Byte] = []
  // glyph 0 advance 700, tsb 0
  push_u16(bytes, 700)
  push_u16(bytes, 0)
  // glyph 1 advance 800, tsb 0
  push_u16(bytes, 800)
  push_u16(bytes, 0)
  // glyph 2 advance 900, tsb 0
  push_u16(bytes, 900)
  push_u16(bytes, 0)
  Bytes::from_array(bytes)
}

///|
fn build_loca_short(offsets : Array[Int]) -> Bytes {
  let bytes : Array[Byte] = []
  for offset in offsets {
    push_u16(bytes, offset / 2)
  }
  Bytes::from_array(bytes)
}

///|
fn build_glyf_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_i16(bytes, 1)
  push_i16(bytes, 5)
  push_i16(bytes, -2)
  push_i16(bytes, 50)
  push_i16(bytes, 100)
  Bytes::from_array(bytes)
}

///|
fn build_glyf_simple_square() -> Bytes {
  let bytes : Array[Byte] = []
  push_i16(bytes, 1) // contours
  push_i16(bytes, 0) // x min
  push_i16(bytes, 0) // y min
  push_i16(bytes, 50) // x max
  push_i16(bytes, 50) // y max
  push_u16(bytes, 3) // endPtsOfContours[0]
  push_u16(bytes, 0) // instruction length
  bytes.push(0x31) // on-curve, x same, y same
  bytes.push(0x33) // on-curve, x short + same, y same
  bytes.push(0x35) // on-curve, x same, y short + same
  bytes.push(0x23) // on-curve, x short (neg), y same
  bytes.push(50) // x delta +50
  bytes.push(50) // x delta -50
  bytes.push(50) // y delta +50
  if (bytes.length() & 1) != 0 {
    bytes.push(0)
  }
  Bytes::from_array(bytes)
}

///|
fn build_glyf_composite_one_component() -> Bytes {
  let bytes : Array[Byte] = []
  push_i16(bytes, -1) // composite
  push_i16(bytes, 100) // x min
  push_i16(bytes, 0) // y min
  push_i16(bytes, 150) // x max
  push_i16(bytes, 50) // y max
  let flags = 0x0003 // args are words + xy values
  push_u16(bytes, flags)
  push_u16(bytes, 1) // component glyph id
  push_i16(bytes, 100) // dx
  push_i16(bytes, 0) // dy
  Bytes::from_array(bytes)
}

///|
fn build_glyf_table_composite() -> Bytes {
  let glyph1 = build_glyf_simple_square()
  let glyph2 = build_glyf_composite_one_component()
  let bytes : Array[Byte] = []
  for b in glyph1 {
    bytes.push(b)
  }
  for b in glyph2 {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gvar_tuple_iup_phantom() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 2) // tuple var count
  push_u16(bytes, 16) // data offset
  push_u16(bytes, 10) // tuple 0 data size
  push_u16(bytes, 0xA000) // embedded peak + private points
  push_i16(bytes, 0x4000) // peak 1.0
  push_u16(bytes, 8) // tuple 1 data size
  push_u16(bytes, 0xA000) // embedded peak + private points
  push_i16(bytes, 0x4000) // peak 1.0
  // tuple 0 data: points [1, 3]
  bytes.push(2) // point count
  bytes.push(1) // run count 2
  bytes.push(1)
  bytes.push(2)
  bytes.push(1) // x deltas
  bytes.push(0x32) // 50
  bytes.push(0xec) // -20
  bytes.push(1) // y deltas
  bytes.push(0x0A) // 10
  bytes.push(0x00)
  // tuple 1 data: phantom points [4, 5]
  bytes.push(2) // point count
  bytes.push(1) // run count 2
  bytes.push(4)
  bytes.push(1)
  bytes.push(1) // x deltas
  bytes.push(10)
  bytes.push(30)
  bytes.push(0x81) // y deltas: two zeros
  Bytes::from_array(bytes)
}

///|
fn build_gvar_table_iup_phantom(tuple_data : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000) // version 1.0
  push_u16(bytes, 1) // axis count
  push_u16(bytes, 0) // shared tuple count
  push_u32(bytes, 0) // shared tuples offset
  push_u16(bytes, 2) // glyph count
  push_u16(bytes, 0) // flags short offsets
  push_u32(bytes, 26) // data offset (20 + 6)
  push_u16(bytes, 0) // glyph 0 start
  push_u16(bytes, 0) // glyph 1 start
  push_u16(bytes, tuple_data.length() / 2) // glyph 1 end
  for b in tuple_data {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_gvar_tuple_composite() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1) // tuple var count
  push_u16(bytes, 10) // data offset
  push_u16(bytes, 8) // tuple data size
  push_u16(bytes, 0xA000) // embedded peak + private points
  push_i16(bytes, 0x4000) // peak 1.0
  bytes.push(2) // point count
  bytes.push(1) // run count 2
  bytes.push(0) // point 0
  bytes.push(2) // point 2
  bytes.push(1) // x deltas: bytes
  bytes.push(20)
  bytes.push(30)
  bytes.push(0x81) // y deltas: two zeros
  Bytes::from_array(bytes)
}

///|
fn build_gvar_table_composite(tuple_data : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000) // version 1.0
  push_u16(bytes, 1) // axis count
  push_u16(bytes, 0) // shared tuple count
  push_u32(bytes, 0) // shared tuples offset
  push_u16(bytes, 3) // glyph count
  push_u16(bytes, 0) // flags short offsets
  push_u32(bytes, 28) // data offset (20 + 8 offsets)
  push_u16(bytes, 0) // glyph 0 start
  push_u16(bytes, 0) // glyph 1 start
  push_u16(bytes, 0) // glyph 2 start
  push_u16(bytes, tuple_data.length() / 2) // glyph 2 end
  for b in tuple_data {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_gvar_composite() -> Bytes {
  let glyf = build_glyf_table_composite()
  let offsets : Array[Int] = [0, 0, glyf.length() - build_glyf_composite_one_component().length(), glyf.length()]
  let loca = build_loca_short(offsets)
  let gvar = build_gvar_table_composite(build_gvar_tuple_composite())
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(3)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(3)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx_three()),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(3)),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx_three()),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('g', 'v', 'a', 'r'), gvar),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_gvar_iup() -> Bytes {
  let glyf = build_glyf_simple_square()
  let loca = build_loca_short([0, 0, glyf.length()])
  let gvar = build_gvar_table_iup_phantom(build_gvar_tuple_iup_phantom())
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(2)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx()),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(2)),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx()),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('g', 'v', 'a', 'r'), gvar),
  ]
  build_sfnt(tables)
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

fn push_u32var(bytes : Array[Byte], value : UInt) -> Unit {
  if value < 0x80U {
    bytes.push(value.reinterpret_as_int().to_byte())
    return
  }
  if value < 0x4000U {
    let b0 = 0x80U | ((value >> 8) & 0x3FU)
    bytes.push(b0.reinterpret_as_int().to_byte())
    bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
    return
  }
  if value < 0x200000U {
    let b0 = 0xC0U | ((value >> 16) & 0x1FU)
    bytes.push(b0.reinterpret_as_int().to_byte())
    bytes.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
    return
  }
  if value < 0x10000000U {
    let b0 = 0xE0U | ((value >> 24) & 0x0FU)
    bytes.push(b0.reinterpret_as_int().to_byte())
    bytes.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
    bytes.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
    return
  }
  bytes.push((0xF0).to_byte())
  bytes.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
  bytes.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  bytes.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  bytes.push((value & 0xFFU).reinterpret_as_int().to_byte())
}

fn build_varc_table_bounds() -> Bytes {
  let record : Array[Byte] = []
  let flags = 16U // HAVE_TRANSLATE_X
  push_u32var(record, flags)
  push_u16(record, 1) // component glyph id
  push_i16(record, 20) // translate x

  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u32(bytes, 24) // coverage offset
  push_u32(bytes, 0) // var store offset
  push_u32(bytes, 0) // condition list offset
  push_u32(bytes, 0) // axis indices offset
  push_u32(bytes, 30) // glyph records offset

  // Coverage format 1 for glyph 2
  push_u16(bytes, 1)
  push_u16(bytes, 1)
  push_u16(bytes, 2)

  // Glyph records CFF2 INDEX
  push_u32(bytes, 1)
  bytes.push(1) // offSize
  bytes.push(1)
  bytes.push((1 + record.length()).to_byte())
  for b in record {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

fn build_font_bytes_varc_bounds() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_short([0, 0, glyf.length(), glyf.length()])
  let varc = build_varc_table_bounds()
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(3)),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (@common.Tag::from_chars('V', 'A', 'R', 'C'), varc),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_short([0, 0, glyf.length()])
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(2)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx()),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(2)),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx()),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x41U, 1U)),
    ),
  ]
  build_sfnt(tables)
}

///|
fn build_fvar_table() -> Bytes {
  Bytes::from_array([
    0x00, 0x01, 0x00, 0x00, // version 1.0
    0x00, 0x10, // axis offset
    0x00, 0x02, // reserved
    0x00, 0x01, // axis count
    0x00, 0x14, // axis size
    0x00, 0x00, // instance count
    0x00, 0x08, // instance size
    0x77, 0x67, 0x68, 0x74, // 'wght'
    0xFF, 0xFF, 0x00, 0x00, // min -1.0
    0x00, 0x00, 0x00, 0x00, // default 0.0
    0x00, 0x01, 0x00, 0x00, // max 1.0
    0x00, 0x00, // flags
    0x01, 0x00, // name id
  ])
}

///|
fn build_avar_table() -> Bytes {
  Bytes::from_array([
    0x00, 0x01, 0x00, 0x00, // version 1.0
    0x00, 0x00, // reserved
    0x00, 0x01, // axis count
    0x00, 0x04, // segment count
    0xC0, 0x00, 0xC0, 0x00, // -1.0 -> -1.0
    0x00, 0x00, 0x00, 0x00, // 0.0 -> 0.0
    0x20, 0x00, 0x30, 0x00, // 0.5 -> 0.75
    0x40, 0x00, 0x40, 0x00, // 1.0 -> 1.0
  ])
}

///|
fn build_cvt_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_i16(bytes, 100)
  push_i16(bytes, 200)
  push_i16(bytes, 300)
  Bytes::from_array(bytes)
}

///|
fn build_cvar_table() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000) // version
  push_u16(bytes, 1) // tuple var count
  push_u16(bytes, 10) // data offset
  push_u16(bytes, 4) // tuple data size
  push_u16(bytes, 0x8000) // embedded peak
  push_i16(bytes, 0x4000) // peak 1.0
  bytes.push(2) // run length 3 (0x02)
  bytes.push(10)
  bytes.push(0)
  bytes.push(0xfb)
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_variations() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('a', 'v', 'a', 'r'), build_avar_table()),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_cvar() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('c', 'v', 't', ' '), build_cvt_table()),
    (@common.Tag::from_chars('c', 'v', 'a', 'r'), build_cvar_table()),
  ]
  build_sfnt(tables)
}

///|
fn build_hvar_var_store() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1) // format
  push_u32(bytes, 12) // region list offset
  push_u16(bytes, 1) // data count
  push_u32(bytes, 22) // data offset
  push_u16(bytes, 1) // axis count
  push_u16(bytes, 1) // region count
  push_i16(bytes, 0) // start
  push_i16(bytes, 0x4000) // peak 1.0
  push_i16(bytes, 0x4000) // end 1.0
  push_u16(bytes, 2) // item count
  push_u16(bytes, 1) // word size count
  push_u16(bytes, 1) // region index count
  push_u16(bytes, 0) // region index
  push_i16(bytes, 10) // delta item 0
  push_i16(bytes, 20) // delta item 1
  Bytes::from_array(bytes)
}

///|
fn build_vvar_var_store() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 1) // format
  push_u32(bytes, 12) // region list offset
  push_u16(bytes, 1) // data count
  push_u32(bytes, 22) // data offset
  push_u16(bytes, 1) // axis count
  push_u16(bytes, 1) // region count
  push_i16(bytes, 0) // start
  push_i16(bytes, 0x4000) // peak 1.0
  push_i16(bytes, 0x4000) // end 1.0
  push_u16(bytes, 2) // item count
  push_u16(bytes, 1) // word size count
  push_u16(bytes, 1) // region index count
  push_u16(bytes, 0) // region index
  push_i16(bytes, 5) // delta item 0
  push_i16(bytes, 30) // delta item 1
  Bytes::from_array(bytes)
}

///|
fn build_delta_map_two() -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0) // format
  bytes.push(0x1F) // width=2, inner bits=16
  push_u16(bytes, 2) // map count
  bytes.push(0)
  bytes.push(0) // var idx 0
  bytes.push(0)
  bytes.push(1) // var idx 1
  Bytes::from_array(bytes)
}

///|
fn build_hvar_table() -> Bytes {
  let var_store = build_hvar_var_store()
  let adv_map = build_delta_map_two()
  let header_len = 20
  let var_offset = header_len
  let adv_offset = var_offset + var_store.length()
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000) // version
  push_u32(bytes, var_offset)
  push_u32(bytes, adv_offset)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  for b in var_store {
    bytes.push(b)
  }
  for b in adv_map {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_vvar_table() -> Bytes {
  let var_store = build_vvar_var_store()
  let adv_map = build_delta_map_two()
  let header_len = 20
  let var_offset = header_len
  let adv_offset = var_offset + var_store.length()
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000) // version
  push_u32(bytes, var_offset)
  push_u32(bytes, adv_offset)
  push_u32(bytes, 0)
  push_u32(bytes, 0)
  for b in var_store {
    bytes.push(b)
  }
  for b in adv_map {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_hvar() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_short([0, 0, glyf.length()])
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('h', 'h', 'e', 'a'), build_hhea(2)),
    (@common.Tag::from_chars('h', 'm', 't', 'x'), build_hmtx()),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x41U, 1U)),
    ),
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('a', 'v', 'a', 'r'), build_avar_table()),
    (@common.Tag::from_chars('H', 'V', 'A', 'R'), build_hvar_table()),
  ]
  build_sfnt(tables)
}

///|
fn build_font_bytes_vvar() -> Bytes {
  let glyf = build_glyf_table()
  let loca = build_loca_short([0, 0, glyf.length()])
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('h', 'e', 'a', 'd'), build_head(1000, 0)),
    (@common.Tag::from_chars('m', 'a', 'x', 'p'), build_maxp(2)),
    (@common.Tag::from_chars('v', 'h', 'e', 'a'), build_vhea(2)),
    (@common.Tag::from_chars('v', 'm', 't', 'x'), build_vmtx()),
    (@common.Tag::from_chars('l', 'o', 'c', 'a'), loca),
    (@common.Tag::from_chars('g', 'l', 'y', 'f'), glyf),
    (
      @common.Tag::from_chars('c', 'm', 'a', 'p'),
      build_cmap_table(build_cmap_format12(0x41U, 0x41U, 1U)),
    ),
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('a', 'v', 'a', 'r'), build_avar_table()),
    (@common.Tag::from_chars('V', 'V', 'A', 'R'), build_vvar_table()),
  ]
  build_sfnt(tables)
}

///|
fn build_mvar_table() -> Bytes {
  let var_store = build_hvar_var_store()
  let header_len = 12
  let record_len = 8
  let var_offset = header_len + record_len
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000) // version
  push_u16(bytes, 0) // reserved
  push_u16(bytes, record_len) // record size
  push_u16(bytes, 1) // record count
  push_u16(bytes, var_offset)
  bytes.push(b'T')
  bytes.push(b'E')
  bytes.push(b'S')
  bytes.push(b'T')
  push_u32(bytes, 0) // varIdx
  for b in var_store {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_font_bytes_mvar() -> Bytes {
  let tables : Array[(@common.Tag, Bytes)] = [
    (@common.Tag::from_chars('f', 'v', 'a', 'r'), build_fvar_table()),
    (@common.Tag::from_chars('a', 'v', 'a', 'r'), build_avar_table()),
    (@common.Tag::from_chars('M', 'V', 'A', 'R'), build_mvar_table()),
  ]
  build_sfnt(tables)
}

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

///|
test "font variation coords" {
  let font = Font::from_bytes(build_font_bytes_variations())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 0.5),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  inspect(font.variation_coords(), content="[12288]")
}

///|
test "font cvar cvt values" {
  let font = Font::from_bytes(build_font_bytes_cvar())
  let base = match font.cvt_values() {
    Err(err) => fail("cvt error: \{err}")
    Ok(value) => value
  }
  inspect(base, content="Some([100, 200, 300])")
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 1.0),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  let applied = match font.cvt_values() {
    Err(err) => fail("cvt error: \{err}")
    Ok(value) => value
  }
  inspect(applied, content="Some([110, 200, 295])")
}

///|
test "font cmap mapping and advances" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let gid = match font.glyph_for_codepoint(0x41U) {
    Err(err) => fail("lookup error: \{err}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  inspect(gid, content="1")
  let advance = match font.glyph_h_advance(gid) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="300")
}

///|
test "font vmtx advances" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let advance = match font.glyph_v_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="-800")
}

///|
test "font scale applies to advances" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  font.set_scale(2000, 2000)
  let advance = match font.glyph_h_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="600")
}

///|
test "font scale defaults to upem" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let _ = font.glyph_h_advance(1U)
  inspect(font.get_scale(), content="(1000, 1000)")
}

///|
test "font hvar advance delta" {
  let font = Font::from_bytes(build_font_bytes_hvar())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 1.0),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  let advance = match font.glyph_h_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="320")
}

///|
test "font contour points" {
  let font = Font::from_bytes(build_font_bytes_gvar_iup())
  let point0 = match font.glyph_contour_point_for_origin(1U, 0) {
    Err(err) => fail("contour point error: \{err}")
    Ok(value) => value
  }
  inspect(point0, content="Some((0, 0))")
  let point2 = match font.glyph_contour_point_for_origin(1U, 2) {
    Err(err) => fail("contour point error: \{err}")
    Ok(value) => value
  }
  inspect(point2, content="Some((50, 50))")
  let missing = match font.glyph_contour_point_for_origin(1U, 10) {
    Err(err) => fail("contour point error: \{err}")
    Ok(value) => value
  }
  inspect(missing, content="None")
}

///|
test "font gvar outline deltas and phantom points" {
  let font = Font::from_bytes(build_font_bytes_gvar_iup())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 1.0),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  let bounds = match font.glyph_bounds(1U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(None) => fail("missing bounds")
    Ok(Some(value)) => value
  }
  inspect(bounds.x_min, content="-20")
  inspect(bounds.y_min, content="10")
  inspect(bounds.x_max, content="100")
  inspect(bounds.y_max, content="50")
  let advance = match font.glyph_h_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="320")
}

///|
test "font gvar composite deltas" {
  let font = Font::from_bytes(build_font_bytes_gvar_composite())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 1.0),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  let gvar = match font.gvar() {
    Err(err) => fail("gvar error: \{err}")
    Ok(value) => value
  }
  match gvar {
    None => fail("missing gvar")
    Some(gvar) => {
      let data = gvar.glyph_variation_data(2)
      inspect(data.map(bytes => bytes.length()), content="Some(18)")
      let deltas = match gvar.glyph_deltas(2, [16384], 5) {
        Err(err) => fail("gvar deltas error: \{err}")
        Ok(value) => value
      }
      let deltas_x = deltas.0.map(delta => delta.round().to_int())
      inspect(deltas_x, content="[20, 0, 30, 0, 0]")
    }
  }
  let bounds = match font.glyph_bounds(2U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(None) => fail("missing bounds")
    Ok(Some(value)) => value
  }
  inspect(bounds.x_min, content="120")
  inspect(bounds.y_min, content="0")
  inspect(bounds.x_max, content="170")
  inspect(bounds.y_max, content="50")
  let advance = match font.glyph_h_advance(2U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="430")
}

///|
test "font vvar advance delta" {
  let font = Font::from_bytes(build_font_bytes_vvar())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 1.0),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  let advance = match font.glyph_v_advance(1U) {
    Err(err) => fail("advance error: \{err}")
    Ok(value) => value
  }
  inspect(advance, content="-830")
}

///|
test "font mvar delta" {
  let font = Font::from_bytes(build_font_bytes_mvar())
  let variations : Array[@ot_var.AxisCoord] = [
    @ot_var.AxisCoord::new(@common.Tag::from_chars('w', 'g', 'h', 't'), 1.0),
  ]
  match font.set_variations(variations) {
    Err(err) => fail("set variations failed: \{err}")
    Ok(_) => ()
  }
  let delta = match font.mvar_delta(@common.Tag::from_chars('T', 'E', 'S', 'T')) {
    Err(err) => fail("mvar error: \{err}")
    Ok(value) => value
  }
  inspect(delta.round().to_int(), content="10")
}

///|
test "font glyph bounds" {
  let bytes = build_font_bytes()
  let font = Font::from_bytes(bytes)
  let bounds0 = match font.glyph_bounds(0U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(value) => value
  }
  inspect(bounds0, content="None")
  let bounds1 = match font.glyph_bounds(1U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(None) => fail("missing bounds")
    Ok(Some(value)) => value
  }
  inspect(bounds1.contours, content="1")
  inspect(bounds1.x_min, content="5")
  inspect(bounds1.y_min, content="-2")
  inspect(bounds1.x_max, content="50")
  inspect(bounds1.y_max, content="100")
}

///|
test "font glyph bounds varc composite" {
  let bytes = build_font_bytes_varc_bounds()
  let font = Font::from_bytes(bytes)
  let bounds = match font.glyph_bounds(2U) {
    Err(err) => fail("bounds error: \{err}")
    Ok(None) => fail("missing bounds")
    Ok(Some(value)) => value
  }
  inspect((bounds.x_min, bounds.y_min, bounds.x_max, bounds.y_max), content="(25, -2, 70, 100)")
}
