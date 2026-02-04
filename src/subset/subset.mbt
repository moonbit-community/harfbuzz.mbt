///|
suberror SubsetError {
  Face(@face.FaceTableError)
  Sfnt(@sfnt.SfntError)
  Font(@font.FontError)
  Cff(@ot_cff.CffError)
  Unsupported(String)
  InvalidInput(String)
} derive(Eq, Show, ToJson)

///|
pub struct SubsetInput {
  codepoints : Array[UInt]
} derive(Show, ToJson)

///|
pub fn SubsetInput::from_codepoints(
  codepoints : Array[UInt],
) -> SubsetInput {
  SubsetInput::{ codepoints }
}

///|
pub struct SubsetPlan {
  glyphs : Array[UInt]
  old_to_new : Array[Int]
  codepoint_map : Array[(UInt, Int)]
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
let tag_loca : @common.Tag = @common.Tag::from_chars('l', 'o', 'c', 'a')

///|
let tag_glyf : @common.Tag = @common.Tag::from_chars('g', 'l', 'y', 'f')

///|
let tag_cmap : @common.Tag = @common.Tag::from_chars('c', 'm', 'a', 'p')

///|
let tag_cff : @common.Tag = @common.Tag::from_chars('C', 'F', 'F', ' ')

///|
let tag_cff2 : @common.Tag = @common.Tag::from_chars('C', 'F', 'F', '2')

///|
let tag_name : @common.Tag = @common.Tag::from_chars('n', 'a', 'm', 'e')

///|
let tag_post : @common.Tag = @common.Tag::from_chars('p', 'o', 's', 't')

///|
let tag_os2 : @common.Tag = @common.Tag::from_chars('O', 'S', '/', '2')

///|
let tag_cvt : @common.Tag = @common.Tag::from_chars('c', 'v', 't', ' ')

///|
let tag_fpgm : @common.Tag = @common.Tag::from_chars('f', 'p', 'g', 'm')

///|
let tag_prep : @common.Tag = @common.Tag::from_chars('p', 'r', 'e', 'p')

///|
let tag_gasp : @common.Tag = @common.Tag::from_chars('g', 'a', 's', 'p')

///|
let tag_vdmx : @common.Tag = @common.Tag::from_chars('V', 'D', 'M', 'X')

///|
let tag_hdmx : @common.Tag = @common.Tag::from_chars('h', 'd', 'm', 'x')

///|
let tag_fvar : @common.Tag = @common.Tag::from_chars('f', 'v', 'a', 'r')

///|
let tag_avar : @common.Tag = @common.Tag::from_chars('a', 'v', 'a', 'r')

///|
let tag_stat : @common.Tag = @common.Tag::from_chars('S', 'T', 'A', 'T')

///|
let tag_mvar : @common.Tag = @common.Tag::from_chars('M', 'V', 'A', 'R')

///|
let tag_cvar : @common.Tag = @common.Tag::from_chars('c', 'v', 'a', 'r')

///|
let tag_cpal : @common.Tag = @common.Tag::from_chars('C', 'P', 'A', 'L')

///|
let tag_meta : @common.Tag = @common.Tag::from_chars('m', 'e', 't', 'a')

///|
let tag_gsub : @common.Tag = @common.Tag::from_chars('G', 'S', 'U', 'B')

///|
let tag_gpos : @common.Tag = @common.Tag::from_chars('G', 'P', 'O', 'S')

///|
let tag_gdef : @common.Tag = @common.Tag::from_chars('G', 'D', 'E', 'F')

///|

///|
let tag_jstf : @common.Tag = @common.Tag::from_chars('J', 'S', 'T', 'F')

///|
let tag_morx : @common.Tag = @common.Tag::from_chars('m', 'o', 'r', 'x')

///|
let tag_mort : @common.Tag = @common.Tag::from_chars('m', 'o', 'r', 't')

///|
let tag_kerx : @common.Tag = @common.Tag::from_chars('k', 'e', 'r', 'x')

///|
let tag_kern : @common.Tag = @common.Tag::from_chars('k', 'e', 'r', 'n')

///|
let tag_ankr : @common.Tag = @common.Tag::from_chars('a', 'n', 'k', 'r')

///|
let tag_trak : @common.Tag = @common.Tag::from_chars('t', 'r', 'a', 'k')

///|
let tag_bsln : @common.Tag = @common.Tag::from_chars('b', 's', 'l', 'n')

///|
let tag_feat : @common.Tag = @common.Tag::from_chars('f', 'e', 'a', 't')

///|
let tag_opbd : @common.Tag = @common.Tag::from_chars('o', 'p', 'b', 'd')

///|
let tag_just : @common.Tag = @common.Tag::from_chars('j', 'u', 's', 't')

///|
let tag_ltag : @common.Tag = @common.Tag::from_chars('l', 't', 'a', 'g')

///|
let tag_colr : @common.Tag = @common.Tag::from_chars('C', 'O', 'L', 'R')

///|
let tag_cblc : @common.Tag = @common.Tag::from_chars('C', 'B', 'L', 'C')

///|
let tag_cbdt : @common.Tag = @common.Tag::from_chars('C', 'B', 'D', 'T')

///|
let tag_svg : @common.Tag = @common.Tag::from_chars('S', 'V', 'G', ' ')

///|
let tag_sbix : @common.Tag = @common.Tag::from_chars('s', 'b', 'i', 'x')

///|
let tag_gvar : @common.Tag = @common.Tag::from_chars('g', 'v', 'a', 'r')

///|
let tag_hvar : @common.Tag = @common.Tag::from_chars('H', 'V', 'A', 'R')

///|
let tag_vvar : @common.Tag = @common.Tag::from_chars('V', 'V', 'A', 'R')

///|
let tag_vorg : @common.Tag = @common.Tag::from_chars('V', 'O', 'R', 'G')

///|
let tag_varc : @common.Tag = @common.Tag::from_chars('V', 'A', 'R', 'C')

///|
fn read_u16(bytes : Array[Byte], offset : Int) -> Result[Int, SubsetError] {
  if offset < 0 || offset + 2 > bytes.length() {
    return Err(InvalidInput("unexpected eof"))
  }
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  Ok((b0 << 8) | b1)
}

///|
fn read_i16(bytes : Array[Byte], offset : Int) -> Result[Int, SubsetError] {
  match read_u16(bytes, offset) {
    Err(err) => Err(err)
    Ok(value) => if value >= 0x8000 { Ok(value - 0x10000) } else { Ok(value) }
  }
}

///|
fn read_u24(bytes : Array[Byte], offset : Int) -> Result[Int, SubsetError] {
  if offset < 0 || offset + 3 > bytes.length() {
    return Err(InvalidInput("unexpected eof"))
  }
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  let b2 = bytes[offset + 2].to_int()
  Ok((b0 << 16) | (b1 << 8) | b2)
}

fn read_u8(bytes : Array[Byte], offset : Int) -> Result[Int, SubsetError] {
  if offset < 0 || offset >= bytes.length() {
    return Err(InvalidInput("unexpected eof"))
  }
  Ok(bytes[offset].to_int())
}

///|
fn read_u32(bytes : Array[Byte], offset : Int) -> Result[Int, SubsetError] {
  if offset < 0 || offset + 4 > bytes.length() {
    return Err(InvalidInput("unexpected eof"))
  }
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  let b2 = bytes[offset + 2].to_int()
  let b3 = bytes[offset + 3].to_int()
  Ok((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
}

///|
fn write_u16(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  bytes[offset] = ((value >> 8) & 0xff).to_byte()
  bytes[offset + 1] = (value & 0xff).to_byte()
}

///|
fn write_u24(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  bytes[offset] = ((value >> 16) & 0xff).to_byte()
  bytes[offset + 1] = ((value >> 8) & 0xff).to_byte()
  bytes[offset + 2] = (value & 0xff).to_byte()
}

fn write_u32(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  bytes[offset] = ((value >> 24) & 0xff).to_byte()
  bytes[offset + 1] = ((value >> 16) & 0xff).to_byte()
  bytes[offset + 2] = ((value >> 8) & 0xff).to_byte()
  bytes[offset + 3] = (value & 0xff).to_byte()
}

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

fn align4(value : Int) -> Int {
  let rem = value % 4
  if rem == 0 { value } else { value + (4 - rem) }
}

fn pad_to(bytes : Array[Byte], target : Int) -> Unit {
  let mut count = target - bytes.length()
  while count > 0 {
    bytes.push(b'\x00')
    count = count - 1
  }
}

fn write_u32_uint(bytes : Array[Byte], offset : Int, value : UInt) -> Unit {
  bytes[offset] = ((value >> 24) & 0xffU).reinterpret_as_int().to_byte()
  bytes[offset + 1] = ((value >> 16) & 0xffU).reinterpret_as_int().to_byte()
  bytes[offset + 2] = ((value >> 8) & 0xffU).reinterpret_as_int().to_byte()
  bytes[offset + 3] = (value & 0xffU).reinterpret_as_int().to_byte()
}

fn push_u32_uint(bytes : Array[Byte], value : UInt) -> Unit {
  bytes.push(((value >> 24) & 0xffU).reinterpret_as_int().to_byte())
  bytes.push(((value >> 16) & 0xffU).reinterpret_as_int().to_byte())
  bytes.push(((value >> 8) & 0xffU).reinterpret_as_int().to_byte())
  bytes.push((value & 0xffU).reinterpret_as_int().to_byte())
}

fn checksum_bytes(bytes : Array[Byte]) -> UInt {
  let length = bytes.length()
  let padded = align4(length)
  let mut sum : UInt = 0U
  let mut i = 0
  while i < padded {
    let b0 = if i < length { bytes[i].to_uint() } else { 0U }
    let b1 = if i + 1 < length { bytes[i + 1].to_uint() } else { 0U }
    let b2 = if i + 2 < length { bytes[i + 2].to_uint() } else { 0U }
    let b3 = if i + 3 < length { bytes[i + 3].to_uint() } else { 0U }
    let word = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    sum = sum + word
    i = i + 4
  }
  sum
}

fn sfnt_search_params(num_tables : Int) -> (Int, Int, Int) {
  let mut max_power = 1
  let mut entry_selector = 0
  while max_power * 2 <= num_tables {
    max_power = max_power * 2
    entry_selector = entry_selector + 1
  }
  let search_range = if num_tables > 0 { max_power * 16 } else { 0 }
  let range_shift = num_tables * 16 - search_range
  (search_range, entry_selector, range_shift)
}

fn kern_search_params(pair_count : Int) -> (Int, Int, Int) {
  let mut max_power = 1
  let mut entry_selector = 0
  while max_power * 2 <= pair_count {
    max_power = max_power * 2
    entry_selector = entry_selector + 1
  }
  let search_range = if pair_count > 0 { max_power * 6 } else { 0 }
  let range_shift = pair_count * 6 - search_range
  (search_range, entry_selector, range_shift)
}

fn kern_class_for_glyph(
  table : @sfnt.KernClassTable,
  glyph : Int,
) -> Int {
  let start = table.first_glyph
  let index = glyph - start
  if index < 0 || index >= table.classes.length() {
    return 0
  }
  let value = table.classes[index]
  if value < 0 { 0 } else { value }
}

fn build_kern_format0_subtable(
  pairs : Array[(Int, Int, Int)],
  horizontal : Bool,
  minimum : Bool,
  cross_stream : Bool,
  override_flag : Bool,
) -> Result[Bytes?, SubsetError] {
  if pairs.is_empty() {
    return Ok(None)
  }
  pairs.sort_by((a, b) => {
    let (left_a, right_a, _) = a
    let (left_b, right_b, _) = b
    if left_a != left_b {
      left_a - left_b
    } else {
      right_a - right_b
    }
  })
  let pair_count = pairs.length()
  if pair_count > 0xFFFF {
    return Err(Unsupported("kern pair count exceeds 65535"))
  }
  let (search_range, entry_selector, range_shift) = kern_search_params(pair_count)
  let mut flags = 0
  if horizontal {
    flags = flags | 0x01
  }
  if minimum {
    flags = flags | 0x02
  }
  if cross_stream {
    flags = flags | 0x04
  }
  if override_flag {
    flags = flags | 0x08
  }
  let length = 14 + pair_count * 6
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, length)
  push_u16(bytes, flags)
  push_u16(bytes, pair_count)
  push_u16(bytes, search_range)
  push_u16(bytes, entry_selector)
  push_u16(bytes, range_shift)
  for pair in pairs {
    let (left, right, value) = pair
    push_u16(bytes, left)
    push_u16(bytes, right)
    push_i16(bytes, value)
  }
  Ok(Some(Bytes::from_array(bytes)))
}

fn kern_pairs_from_format2(
  format2 : @sfnt.KernSubtableFormat2,
  plan : SubsetPlan,
) -> Result[Array[(Int, Int, Int)], SubsetError] {
  let left_class_count = format2.left.class_count
  let right_class_count = format2.right_class_count
  if left_class_count <= 0 || right_class_count <= 0 {
    return Ok([])
  }
  let total_values = left_class_count * right_class_count
  if total_values < 0 || total_values > format2.values.length() {
    return Err(InvalidInput("kern format2 value count out of range"))
  }
  let left_classes : Array[Array[Int]] = []
  for _ in 0..<left_class_count {
    left_classes.push([])
  }
  let right_classes : Array[Array[Int]] = []
  for _ in 0..<right_class_count {
    right_classes.push([])
  }
  for old_gid_u in plan.glyphs {
    let old_gid = old_gid_u.reinterpret_as_int()
    if old_gid < 0 || old_gid >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[old_gid]
    if new_gid < 0 {
      continue
    }
    let left_class = kern_class_for_glyph(format2.left, old_gid)
    if left_class >= 0 && left_class < left_class_count {
      left_classes[left_class].push(new_gid)
    }
    let right_class = kern_class_for_glyph(format2.right, old_gid)
    if right_class >= 0 && right_class < right_class_count {
      right_classes[right_class].push(new_gid)
    }
  }
  let pairs : Array[(Int, Int, Int)] = []
  for left_class in 0..<left_class_count {
    let left_glyphs = left_classes[left_class]
    if left_glyphs.is_empty() {
      continue
    }
    let base = left_class * right_class_count
    for right_class in 0..<right_class_count {
      let right_glyphs = right_classes[right_class]
      if right_glyphs.is_empty() {
        continue
      }
      let idx = base + right_class
      if idx < 0 || idx >= format2.values.length() {
        return Err(InvalidInput("kern format2 value index out of range"))
      }
      let value = format2.values[idx]
      if value == 0 {
        continue
      }
      for left_gid in left_glyphs {
        for right_gid in right_glyphs {
          pairs.push((left_gid, right_gid, value))
        }
      }
    }
  }
  Ok(pairs)
}

fn kern_class_from_list(
  classes : Array[Int],
  class_count : Int,
  glyph : Int,
) -> Int {
  if glyph < 0 || glyph >= classes.length() {
    return 0
  }
  let value = classes[glyph]
  if value < 0 || value >= class_count { 0 } else { value }
}

fn kern_pairs_from_format3(
  format3 : @sfnt.KernSubtableFormat3,
  plan : SubsetPlan,
) -> Result[Array[(Int, Int, Int)], SubsetError] {
  let glyph_count = format3.glyph_count
  if glyph_count <= 0 {
    return Ok([])
  }
  if glyph_count > format3.left_class.length() || glyph_count > format3.right_class.length() {
    return Err(InvalidInput("kern format3 glyph count mismatch"))
  }
  let left_class_count = format3.left_class_count
  let right_class_count = format3.right_class_count
  if left_class_count <= 0 || right_class_count <= 0 {
    return Ok([])
  }
  let index_len = left_class_count * right_class_count
  if index_len < 0 || index_len > format3.kern_index.length() {
    return Err(InvalidInput("kern format3 index length mismatch"))
  }
  if format3.values.is_empty() {
    return Ok([])
  }
  let left_classes : Array[Array[Int]] = []
  for _ in 0..<left_class_count {
    left_classes.push([])
  }
  let right_classes : Array[Array[Int]] = []
  for _ in 0..<right_class_count {
    right_classes.push([])
  }
  for old_gid_u in plan.glyphs {
    let old_gid = old_gid_u.reinterpret_as_int()
    if old_gid < 0 || old_gid >= glyph_count {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[old_gid]
    if new_gid < 0 {
      continue
    }
    let left_class = kern_class_from_list(format3.left_class, left_class_count, old_gid)
    let right_class = kern_class_from_list(format3.right_class, right_class_count, old_gid)
    left_classes[left_class].push(new_gid)
    right_classes[right_class].push(new_gid)
  }
  let pairs : Array[(Int, Int, Int)] = []
  for left_class in 0..<left_class_count {
    let left_glyphs = left_classes[left_class]
    if left_glyphs.is_empty() {
      continue
    }
    let base = left_class * right_class_count
    for right_class in 0..<right_class_count {
      let right_glyphs = right_classes[right_class]
      if right_glyphs.is_empty() {
        continue
      }
      let idx = base + right_class
      if idx < 0 || idx >= format3.kern_index.length() {
        return Err(InvalidInput("kern format3 index out of range"))
      }
      let value_index = format3.kern_index[idx]
      if value_index < 0 || value_index >= format3.values.length() {
        return Err(InvalidInput("kern format3 value index out of range"))
      }
      let value = format3.values[value_index]
      if value == 0 {
        continue
      }
      for left_gid in left_glyphs {
        for right_gid in right_glyphs {
          pairs.push((left_gid, right_gid, value))
        }
      }
    }
  }
  Ok(pairs)
}

fn compare_tags(a : @common.Tag, b : @common.Tag) -> Int {
  let (a1, a2, a3, a4) = a.bytes()
  let (b1, b2, b3, b4) = b.bytes()
  let ai1 = a1.to_int()
  let bi1 = b1.to_int()
  if ai1 != bi1 {
    return ai1 - bi1
  }
  let ai2 = a2.to_int()
  let bi2 = b2.to_int()
  if ai2 != bi2 {
    return ai2 - bi2
  }
  let ai3 = a3.to_int()
  let bi3 = b3.to_int()
  if ai3 != bi3 {
    return ai3 - bi3
  }
  let ai4 = a4.to_int()
  let bi4 = b4.to_int()
  ai4 - bi4
}

fn cmap_search_params(seg_count : Int) -> (Int, Int, Int) {
  let mut max_power = 1
  let mut entry_selector = 0
  while max_power * 2 <= seg_count {
    max_power = max_power * 2
    entry_selector = entry_selector + 1
  }
  let search_range = max_power * 2
  let range_shift = seg_count * 2 - search_range
  (search_range, entry_selector, range_shift)
}

fn build_sfnt_bytes(
  dir_tags : Array[@common.Tag],
  dir_checksums : Array[UInt],
  dir_offsets : Array[Int],
  dir_lengths : Array[Int],
  data_bytes : Array[Array[Byte]],
  data_offsets : Array[Int],
) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, dir_tags.length())
  let (search_range, entry_selector, range_shift) = sfnt_search_params(dir_tags.length())
  push_u16(bytes, search_range)
  push_u16(bytes, entry_selector)
  push_u16(bytes, range_shift)
  for i in 0..<dir_tags.length() {
    let tag = dir_tags[i]
    let (b1, b2, b3, b4) = tag.bytes()
    bytes.push(b1)
    bytes.push(b2)
    bytes.push(b3)
    bytes.push(b4)
    push_u32_uint(bytes, dir_checksums[i])
    push_u32(bytes, dir_offsets[i])
    push_u32(bytes, dir_lengths[i])
  }
  for i in 0..<data_bytes.length() {
    pad_to(bytes, data_offsets[i])
    for b in data_bytes[i] {
      bytes.push(b)
    }
  }
  pad_to(bytes, align4(bytes.length()))
  Bytes::from_array(bytes)
}

///|
fn build_sfnt(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let data_sorted : Array[(@common.Tag, Bytes)] = []
  for entry in tables {
    data_sorted.push(entry)
  }
  data_sorted.sort_by((a, b) => {
    let (tag_a, bytes_a) = a
    let (tag_b, bytes_b) = b
    let len_a = bytes_a.length()
    let len_b = bytes_b.length()
    if len_a != len_b {
      len_a - len_b
    } else {
      compare_tags(tag_a, tag_b)
    }
  })
  let data_tags : Array[@common.Tag] = []
  let data_bytes : Array[Array[Byte]] = []
  for entry in data_sorted {
    let (tag, table) = entry
    data_tags.push(tag)
    data_bytes.push(table.to_array())
  }
  let mut offset = 12 + data_tags.length() * 16
  let data_offsets : Array[Int] = []
  for i in 0..<data_bytes.length() {
    offset = align4(offset)
    data_offsets.push(offset)
    offset = offset + data_bytes[i].length()
  }
  let mut head_index = -1
  for i in 0..<data_tags.length() {
    if data_tags[i] == tag_head {
      head_index = i
      break
    }
  }
  if head_index >= 0 && data_bytes[head_index].length() >= 12 {
    write_u32_uint(data_bytes[head_index], 8, 0U)
  }
  let data_checksums : Array[UInt] = []
  for table in data_bytes {
    data_checksums.push(checksum_bytes(table))
  }
  let dir_tags : Array[@common.Tag] = []
  for entry in tables {
    let (tag, _) = entry
    dir_tags.push(tag)
  }
  dir_tags.sort_by(compare_tags)
  let dir_checksums : Array[UInt] = []
  let dir_offsets : Array[Int] = []
  let dir_lengths : Array[Int] = []
  for tag in dir_tags {
    let mut idx = -1
    for i in 0..<data_tags.length() {
      if data_tags[i] == tag {
        idx = i
        break
      }
    }
    if idx >= 0 {
      dir_checksums.push(data_checksums[idx])
      dir_offsets.push(data_offsets[idx])
      dir_lengths.push(data_bytes[idx].length())
    }
  }
  let mut bytes = build_sfnt_bytes(
    dir_tags,
    dir_checksums,
    dir_offsets,
    dir_lengths,
    data_bytes,
    data_offsets,
  )
  if head_index >= 0 && data_bytes[head_index].length() >= 12 {
    let total = checksum_bytes(bytes.to_array())
    let adjust = 0xB1B0AFBAU - total
    write_u32_uint(data_bytes[head_index], 8, adjust)
    bytes = build_sfnt_bytes(
      dir_tags,
      dir_checksums,
      dir_offsets,
      dir_lengths,
      data_bytes,
      data_offsets,
    )
  }
  bytes
}

fn build_cmap_table_multi(subtables : Array[(Int, Int, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, subtables.length())
  let mut offset = 4 + subtables.length() * 8
  let table_indices : Array[Int] = []
  let unique_tables : Array[Bytes] = []
  let unique_offsets : Array[Int] = []
  for entry in subtables {
    let (_, _, table) = entry
    let mut found = -1
    for i in 0..<unique_tables.length() {
      if unique_tables[i] == table {
        found = i
        break
      }
    }
    if found >= 0 {
      table_indices.push(found)
    } else {
      unique_tables.push(table)
      unique_offsets.push(offset)
      table_indices.push(unique_tables.length() - 1)
      offset = offset + table.length()
    }
  }
  for i in 0..<subtables.length() {
    let (platform, encoding, _) = subtables[i]
    let table_index = table_indices[i]
    push_u16(bytes, platform)
    push_u16(bytes, encoding)
    push_u32(bytes, unique_offsets[table_index])
  }
  for table in unique_tables {
    for b in table {
      bytes.push(b)
    }
  }
  Bytes::from_array(bytes)
}

fn build_cmap_format4(groups : Array[(UInt, UInt, UInt)]) -> Bytes? {
  let seg_count = groups.length() + 1
  if seg_count <= 0 || seg_count > 0xFFFF {
    return None
  }
  let bytes : Array[Byte] = []
  push_u16(bytes, 4)
  push_u16(bytes, 0)
  push_u16(bytes, 0)
  push_u16(bytes, seg_count * 2)
  let (search_range, entry_selector, range_shift) = cmap_search_params(seg_count)
  push_u16(bytes, search_range)
  push_u16(bytes, entry_selector)
  push_u16(bytes, range_shift)
  for group in groups {
    let end = group.1
    if end > 0xFFFFU {
      return None
    }
    push_u16(bytes, end.reinterpret_as_int())
  }
  push_u16(bytes, 0xFFFF)
  push_u16(bytes, 0)
  for group in groups {
    let start = group.0
    if start > 0xFFFFU {
      return None
    }
    push_u16(bytes, start.reinterpret_as_int())
  }
  push_u16(bytes, 0xFFFF)
  for group in groups {
    let delta = group.2.reinterpret_as_int() - group.0.reinterpret_as_int()
    push_i16(bytes, delta)
  }
  push_i16(bytes, 1)
  for _ in 0..<seg_count {
    push_u16(bytes, 0)
  }
  let length = bytes.length()
  if length > 0xFFFF {
    return None
  }
  write_u16(bytes, 2, length)
  Some(Bytes::from_array(bytes))
}

///|
fn build_cmap_format12(groups : Array[(UInt, UInt, UInt)]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 12)
  push_u16(bytes, 0)
  let length = 16 + groups.length() * 12
  push_u32(bytes, length)
  push_u32(bytes, 0)
  push_u32(bytes, groups.length())
  for group in groups {
    let (start, end, start_gid) = group
    push_u32(bytes, start.reinterpret_as_int())
    push_u32(bytes, end.reinterpret_as_int())
    push_u32(bytes, start_gid.reinterpret_as_int())
  }
  Bytes::from_array(bytes)
}

///|
fn sort_codepoint_map(
  pairs : Array[(UInt, Int)],
) -> Array[(UInt, Int)] {
  let sorted = pairs.copy()
  let n = sorted.length()
  for i in 1..<n {
    let key = sorted[i]
    let mut j = i - 1
    while j >= 0 && sorted[j].0 > key.0 {
      sorted[j + 1] = sorted[j]
      j = j - 1
    }
    sorted[j + 1] = key
  }
  sorted
}

///|
fn build_format12_groups(
  pairs : Array[(UInt, Int)],
) -> Array[(UInt, UInt, UInt)] {
  if pairs.is_empty() {
    return []
  }
  let groups : Array[(UInt, UInt, UInt)] = []
  let mut start_cp = pairs[0].0
  let mut prev_cp = pairs[0].0
  let mut start_gid = pairs[0].1.reinterpret_as_uint()
  let mut prev_gid = start_gid
  for i in 1..<pairs.length() {
    let cp = pairs[i].0
    let gid = pairs[i].1.reinterpret_as_uint()
    if cp == prev_cp + 1U && gid == prev_gid + 1U {
      prev_cp = cp
      prev_gid = gid
    } else {
      groups.push((start_cp, prev_cp, start_gid))
      start_cp = cp
      prev_cp = cp
      start_gid = gid
      prev_gid = gid
    }
  }
  groups.push((start_cp, prev_cp, start_gid))
  groups
}

///|
fn cmap_find_format4_offset(data : BytesView) -> Result[Int?, SubsetError] {
  let bytes = data.to_bytes().to_array()
  let num_tables = read_u16(bytes, 2)
  match num_tables {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidInput("invalid cmap table"))
      }
      let mut offset = 4
      let mut found : Int? = None
      for _ in 0..<count {
        let platform_id = read_u16(bytes, offset)
        let encoding_id = read_u16(bytes, offset + 2)
        let sub_offset = read_u32(bytes, offset + 4)
        match (platform_id, encoding_id, sub_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(platform_id), Ok(encoding_id), Ok(sub_offset)) => {
            if sub_offset < 0 || sub_offset + 2 > bytes.length() {
              offset = offset + 8
              continue
            }
            let format = read_u16(bytes, sub_offset)
            match format {
              Err(err) => return Err(err)
              Ok(format) => {
                if format == 4 {
                  if platform_id == 0 && encoding_id == 3 {
                    return Ok(Some(sub_offset))
                  }
                  if platform_id == 3 && encoding_id == 1 && found is None {
                    found = Some(sub_offset)
                  }
                }
              }
            }
          }
        }
        offset = offset + 8
      }
      Ok(found)
    }
  }
}

fn cmap_has_format12(data : BytesView) -> Result[Bool, SubsetError] {
  let bytes = data.to_bytes().to_array()
  let num_tables = read_u16(bytes, 2)
  match num_tables {
    Err(err) => Err(err)
    Ok(count) => {
      if count < 0 {
        return Err(InvalidInput("invalid cmap table"))
      }
      let mut offset = 4
      for _ in 0..<count {
        let platform_id = read_u16(bytes, offset)
        let encoding_id = read_u16(bytes, offset + 2)
        let sub_offset = read_u32(bytes, offset + 4)
        match (platform_id, encoding_id, sub_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(platform_id), Ok(encoding_id), Ok(sub_offset)) => {
            if sub_offset < 0 || sub_offset + 2 > bytes.length() {
              offset = offset + 8
              continue
            }
            let format = read_u16(bytes, sub_offset)
            match format {
              Err(err) => return Err(err)
              Ok(format) => {
                if format == 12 &&
                   ((platform_id == 0 && encoding_id == 4) ||
                   (platform_id == 3 && encoding_id == 10)) {
                  return Ok(true)
                }
              }
            }
          }
        }
        offset = offset + 8
      }
      Ok(false)
    }
  }
}

fn cmap_format4_covers(
  data : BytesView,
  offset : Int,
  codepoints : Array[UInt],
) -> Result[Bool, SubsetError] {
  let bytes = data.to_bytes().to_array()
  for cp in codepoints {
    if cp > 0xFFFFU {
      return Ok(false)
    }
    let seg_count_x2 = read_u16(bytes, offset + 6)
    match seg_count_x2 {
      Err(err) => return Err(err)
      Ok(seg_count_x2) => {
        let seg_count = seg_count_x2 / 2
        let end_code_offset = offset + 14
        let start_code_offset = end_code_offset + seg_count * 2 + 2
        let id_delta_offset = start_code_offset + seg_count * 2
        let id_range_offset_offset = id_delta_offset + seg_count * 2
        let mut found = false
        for i in 0..<seg_count {
          let end_code = read_u16(bytes, end_code_offset + i * 2)
          let start_code = read_u16(bytes, start_code_offset + i * 2)
          match (end_code, start_code) {
            (Err(err), _) => return Err(err)
            (_, Err(err)) => return Err(err)
            (Ok(end_code), Ok(start_code)) => {
              let cp_int = cp.reinterpret_as_int()
              if cp_int >= start_code && cp_int <= end_code {
                let id_delta = read_i16(bytes, id_delta_offset + i * 2)
                let id_range_offset = read_u16(
                  bytes,
                  id_range_offset_offset + i * 2,
                )
                match (id_delta, id_range_offset) {
                  (Err(err), _) => return Err(err)
                  (_, Err(err)) => return Err(err)
                  (Ok(id_delta), Ok(id_range_offset)) => {
                    if id_range_offset == 0 {
                      let gid = (cp_int + id_delta) & 0xffff
                      if gid != 0 {
                        found = true
                      }
                    } else {
                      let glyph_index_offset = id_range_offset_offset +
                        i * 2 +
                        id_range_offset +
                        (cp_int - start_code) * 2
                      let glyph_id = read_u16(bytes, glyph_index_offset)
                      match glyph_id {
                        Err(err) => return Err(err)
                        Ok(glyph_id) => {
                          if glyph_id != 0 {
                            let gid = (glyph_id + id_delta) & 0xffff
                            if gid != 0 {
                              found = true
                            }
                          }
                        }
                      }
                    }
                  }
                }
                break
              }
            }
          }
        }
        if !found {
          return Ok(false)
        }
      }
    }
  }
  Ok(true)
}

fn build_cmap_from_pairs(
  face : @face.Face,
  pairs : Array[(UInt, Int)],
) -> Bytes? {
  if pairs.is_empty() {
    return None
  }
  let sorted = sort_codepoint_map(pairs)
  let dedup : Array[(UInt, Int)] = []
  for pair in sorted {
    if dedup.is_empty() || dedup[dedup.length() - 1].0 != pair.0 {
      dedup.push(pair)
    }
  }
  let groups = build_format12_groups(dedup)
  let codepoints = dedup.map(pair => pair.0)
  let mut bmp_only = true
  for pair in dedup {
    if pair.0 > 0xFFFFU {
      bmp_only = false
      break
    }
  }
  let mut use_format12 = !bmp_only
  if bmp_only {
    let cmap_blob = match face.reference_table_optional(tag_cmap) {
      Err(_) => None
      Ok(value) => value
    }
    match cmap_blob {
      None => ()
      Some(blob) => {
        let data = blob.as_view()
        let has_format12 = match cmap_has_format12(data) {
          Err(_) => false
          Ok(value) => value
        }
        if has_format12 {
          let format4_offset = match cmap_find_format4_offset(data) {
            Err(_) => None
            Ok(value) => value
          }
          match format4_offset {
            None => use_format12 = true
            Some(format4_offset) =>
              match cmap_format4_covers(data, format4_offset, codepoints) {
                Err(_) => ()
                Ok(covers) => use_format12 = !covers
              }
          }
        }
      }
    }
  }
  let subtables : Array[(Int, Int, Bytes)] = []
  if use_format12 {
    let table = build_cmap_format12(groups)
    subtables.push((0, 4, table))
    subtables.push((3, 10, table))
  } else {
    match build_cmap_format4(groups) {
      None => ()
      Some(table) => {
        subtables.push((0, 3, table))
        subtables.push((3, 1, table))
      }
    }
  }
  Some(build_cmap_table_multi(subtables))
}

///|
fn table_blob(
  face : @face.Face,
  tag : @common.Tag,
  name : String,
) -> Result[@blob.Blob, SubsetError] {
  match face.reference_table_optional(tag) {
    Err(err) => Err(Face(err))
    Ok(None) => Err(Unsupported("missing \{name} table"))
    Ok(Some(blob)) => Ok(blob)
  }
}

fn add_optional_table(
  face : @face.Face,
  tag : @common.Tag,
  tables : Array[(@common.Tag, Bytes)],
) -> Result[Unit, SubsetError] {
  match face.reference_table_optional(tag) {
    Err(err) => Err(Face(err))
    Ok(None) => Ok(())
    Ok(Some(blob)) => {
      tables.push((tag, blob.as_view().to_bytes()))
      Ok(())
    }
  }
}

fn build_name_subset(
  blob : @blob.Blob,
) -> Result[Bytes?, SubsetError] {
  let bytes = blob.as_view().to_bytes().to_array()
  if bytes.length() < 6 {
    return Ok(None)
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let count = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let string_offset = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format < 0 || format > 1 || count < 0 {
    return Err(InvalidInput("invalid name table"))
  }
  let record_base = 6
  let record_len = 12
  if record_base + count * record_len > bytes.length() {
    return Err(InvalidInput("invalid name records"))
  }
  let records : Array[(Int, Int, Int, Int, Bytes, Int)] = []
  for i in 0..<count {
    let rec_offset = record_base + i * record_len
    let platform_id = match read_u16(bytes, rec_offset) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let encoding_id = match read_u16(bytes, rec_offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let language_id = match read_u16(bytes, rec_offset + 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let name_id = match read_u16(bytes, rec_offset + 6) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let length = match read_u16(bytes, rec_offset + 8) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let offset = match read_u16(bytes, rec_offset + 10) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if platform_id == 3 &&
       encoding_id == 1 &&
       language_id == 0x0409 &&
       name_id >= 0 &&
       name_id <= 6 {
      if length < 0 || offset < 0 {
        return Err(InvalidInput("invalid name record"))
      }
      let str_start = string_offset + offset
      let str_end = str_start + length
      if str_end > bytes.length() {
        return Err(InvalidInput("invalid name string"))
      }
      let value = bytes[str_start:str_end].to_array()
      records.push((
        platform_id,
        encoding_id,
        language_id,
        name_id,
        Bytes::from_array(value),
        offset,
      ))
    }
  }
  if records.is_empty() {
    return Ok(None)
  }
  records.sort_by((a, b) => {
    if a.0 != b.0 {
      return a.0 - b.0
    }
    if a.1 != b.1 {
      return a.1 - b.1
    }
    if a.2 != b.2 {
      return a.2 - b.2
    }
    a.3 - b.3
  })
  let string_entries : Array[(Bytes, Int)] = []
  for record in records {
    let value = record.4
    let mut found = -1
    for i in 0..<string_entries.length() {
      if string_entries[i].0 == value {
        found = i
        break
      }
    }
    if found >= 0 {
      let existing_offset = string_entries[found].1
      if record.5 > existing_offset {
        string_entries[found] = (value, record.5)
      }
    } else {
      string_entries.push((value, record.5))
    }
  }
  string_entries.sort_by((a, b) => b.1 - a.1)
  let string_bytes : Array[Byte] = []
  let entry_offsets : Array[Int] = []
  for entry in string_entries {
    entry_offsets.push(string_bytes.length())
    for b in entry.0 {
      string_bytes.push(b)
    }
  }
  let out : Array[Byte] = []
  push_u16(out, 0)
  push_u16(out, records.length())
  let new_string_offset = 6 + records.length() * 12
  push_u16(out, new_string_offset)
  for record in records {
    let value = record.4
    let mut new_offset = 0
    for i in 0..<string_entries.length() {
      if string_entries[i].0 == value {
        new_offset = entry_offsets[i]
        break
      }
    }
    push_u16(out, record.0)
    push_u16(out, record.1)
    push_u16(out, record.2)
    push_u16(out, record.3)
    push_u16(out, value.length())
    push_u16(out, new_offset)
  }
  for b in string_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn add_optional_name(
  face : @face.Face,
  tables : Array[(@common.Tag, Bytes)],
  _identity : Bool,
) -> Result[Unit, SubsetError] {
  let blob = match face.reference_table_optional(tag_name) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(())
    Some(blob) => {
      match build_name_subset(blob) {
        Err(err) => Err(err)
        Ok(None) => Ok(())
        Ok(Some(bytes)) => {
          tables.push((tag_name, bytes))
          Ok(())
        }
      }
    }
  }
}

fn build_hdmx_subset(
  blob : @blob.Blob,
  maxp : @sfnt.MaxpTable,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let bytes = blob.as_view().to_bytes().to_array()
  if bytes.length() < 8 {
    return Ok(None)
  }
  let version = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let num_records = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let record_size = match read_u32(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if num_records < 0 || record_size <= 0 {
    return Err(InvalidInput("invalid hdmx header"))
  }
  if 8 + num_records * record_size > bytes.length() {
    return Err(InvalidInput("invalid hdmx record size"))
  }
  let glyph_count = plan.glyphs.length()
  if glyph_count <= 0 {
    return Ok(None)
  }
  let mut new_record_size = 2 + glyph_count
  let rem = new_record_size & 3
  if rem != 0 {
    new_record_size = new_record_size + (4 - rem)
  }
  let out : Array[Byte] = []
  push_u16(out, version)
  push_u16(out, num_records)
  push_u32(out, new_record_size)
  for i in 0..<num_records {
    let base = 8 + i * record_size
    if base + 2 > bytes.length() {
      return Err(InvalidInput("invalid hdmx record"))
    }
    let ppem = bytes[base]
    let widths_base = base + 2
    if widths_base + maxp.num_glyphs > base + record_size {
      return Err(InvalidInput("invalid hdmx widths"))
    }
    let widths : Array[Int] = []
    let mut max_width = 0
    for old_gid in plan.glyphs {
      let gid = old_gid.reinterpret_as_int()
      if gid < 0 || gid >= maxp.num_glyphs {
        return Err(InvalidInput("glyph id out of range"))
      }
      let width = bytes[widths_base + gid].to_int()
      widths.push(width)
      if width > max_width {
        max_width = width
      }
    }
    out.push(ppem)
    out.push(max_width.to_byte())
    for width in widths {
      out.push(width.to_byte())
    }
    let pad = new_record_size - (2 + widths.length())
    for _ in 0..<pad {
      out.push(b'\x00')
    }
  }
  Ok(Some(Bytes::from_array(out)))
}

fn add_optional_hdmx(
  face : @face.Face,
  maxp : @sfnt.MaxpTable,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  let blob = match face.reference_table_optional(tag_hdmx) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(())
    Some(blob) => {
      if identity {
        tables.push((tag_hdmx, blob.as_view().to_bytes()))
        return Ok(())
      }
      match build_hdmx_subset(blob, maxp, plan) {
        Err(err) => Err(err)
        Ok(None) => Ok(())
        Ok(Some(bytes)) => {
          tables.push((tag_hdmx, bytes))
          Ok(())
        }
      }
    }
  }
}

fn add_optional_os2(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
) -> Result[Unit, SubsetError] {
  let blob = match face.reference_table_optional(tag_os2) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(())
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() >= 68 && !plan.codepoint_map.is_empty() {
        let mut min_cp = plan.codepoint_map[0].0
        let mut max_cp = plan.codepoint_map[0].0
        for pair in plan.codepoint_map {
          let cp = pair.0
          if cp < min_cp {
            min_cp = cp
          }
          if cp > max_cp {
            max_cp = cp
          }
        }
        let min_val = if min_cp > 0xFFFFU { 0xFFFF } else { min_cp.reinterpret_as_int() }
        let max_val = if max_cp > 0xFFFFU { 0xFFFF } else { max_cp.reinterpret_as_int() }
        write_u16(bytes, 64, min_val)
        write_u16(bytes, 66, max_val)
        let orig1 = match read_u32(bytes, 42) {
          Ok(value) => value.reinterpret_as_uint()
          Err(_) => 0U
        }
        let orig2 = match read_u32(bytes, 46) {
          Ok(value) => value.reinterpret_as_uint()
          Err(_) => 0U
        }
        let orig3 = match read_u32(bytes, 50) {
          Ok(value) => value.reinterpret_as_uint()
          Err(_) => 0U
        }
        let orig4 = match read_u32(bytes, 54) {
          Ok(value) => value.reinterpret_as_uint()
          Err(_) => 0U
        }
        let (new1, new2, new3, new4) =
          os2_unicode_ranges_from_codepoints(plan.codepoint_map[:])
        write_u32_uint(bytes, 42, orig1 & new1)
        write_u32_uint(bytes, 46, orig2 & new2)
        write_u32_uint(bytes, 50, orig3 & new3)
        write_u32_uint(bytes, 54, orig4 & new4)
      }
      tables.push((tag_os2, Bytes::from_array(bytes)))
      Ok(())
    }
  }
}

fn build_post_format3(blob : @blob.Blob) -> Bytes? {
  let header = blob.as_view().to_bytes().to_array()
  if header.length() < 32 {
    return None
  }
  write_u32(header, 0, 0x00030000)
  let out : Array[Byte] = []
  for i in 0..<32 {
    out.push(header[i])
  }
  Some(Bytes::from_array(out))
}

fn add_optional_post(
  face : @face.Face,
  _plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  let blob = match face.reference_table_optional(tag_post) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(())
    Some(blob) => {
      if identity {
        tables.push((tag_post, blob.as_view().to_bytes()))
        return Ok(())
      }
      match @sfnt.PostTable::parse(blob.as_view()) {
        Err(_) => Ok(())
        Ok(post) => {
          if post.version == 0x00030000 {
            tables.push((tag_post, blob.as_view().to_bytes()))
            return Ok(())
          }
          if post.version == 0x00020000 {
            match build_post_format3(blob) {
              None => ()
              Some(bytes) => tables.push((tag_post, bytes))
            }
          }
          Ok(())
        }
      }
    }
  }
}

fn add_optional_kern(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return Ok(())
  }
  let bytes = match build_kern_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_kern, bytes))
      Ok(())
    }
  }
}

fn add_optional_colr(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return Ok(())
  }
  let bytes = match build_colr_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_colr, bytes))
      Ok(())
    }
  }
}

fn add_optional_svg(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return add_optional_table(face, tag_svg, tables)
  }
  let bytes = match build_svg_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_svg, bytes))
      Ok(())
    }
  }
}

fn add_optional_sbix(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return add_optional_table(face, tag_sbix, tables)
  }
  let bytes = match build_sbix_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_sbix, bytes))
      Ok(())
    }
  }
}

fn add_optional_cblc_cbdt(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    match add_optional_table(face, tag_cblc, tables) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
    return add_optional_table(face, tag_cbdt, tables)
  }
  let pair = match build_cblc_cbdt_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match pair {
    None => Ok(())
    Some((cblc_bytes, cbdt_bytes)) => {
      tables.push((tag_cblc, cblc_bytes))
      tables.push((tag_cbdt, cbdt_bytes))
      Ok(())
    }
  }
}

fn add_optional_gdef(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  _identity : Bool,
) -> Result[Unit, SubsetError] {
  let bytes = match build_gdef_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_gdef, bytes))
      Ok(())
    }
  }
}

fn add_optional_gvar(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return Ok(())
  }
  let bytes = match build_gvar_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_gvar, bytes))
      Ok(())
    }
  }
}

fn add_optional_hvar(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return Ok(())
  }
  let bytes = match build_hvar_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_hvar, bytes))
      Ok(())
    }
  }
}

fn add_optional_vvar(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return Ok(())
  }
  let bytes = match build_vvar_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_vvar, bytes))
      Ok(())
    }
  }
}

fn add_optional_varc(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return Ok(())
  }
  let bytes = match build_varc_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_varc, bytes))
      Ok(())
    }
  }
}

fn add_optional_gsub(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  _identity : Bool,
) -> Result[Unit, SubsetError] {
  let bytes = match build_gsub_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_gsub, bytes))
      Ok(())
    }
  }
}

fn add_optional_gpos(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  _identity : Bool,
) -> Result[Unit, SubsetError] {
  let bytes = match build_gpos_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match bytes {
    None => Ok(())
    Some(bytes) => {
      tables.push((tag_gpos, bytes))
      Ok(())
    }
  }
}

fn is_identity_subset(plan : SubsetPlan, total_glyphs : Int) -> Bool {
  if total_glyphs <= 0 || plan.glyphs.length() != total_glyphs {
    return false
  }
  for i in 0..<plan.glyphs.length() {
    if plan.glyphs[i].reinterpret_as_int() != i {
      return false
    }
  }
  true
}

fn add_identity_passthrough_tables(
  face : @face.Face,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if !identity {
    return Ok(())
  }
  let tags : Array[@common.Tag] = [
    tag_jstf,
    tag_morx,
    tag_mort,
    tag_kerx,
    tag_kern,
    tag_ankr,
    tag_trak,
    tag_bsln,
    tag_feat,
    tag_opbd,
    tag_just,
    tag_ltag,
    tag_colr,
    tag_gvar,
    tag_hvar,
    tag_vvar,
    tag_varc,
  ]
  for tag in tags {
    match add_optional_table(face, tag, tables) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  Ok(())
}

fn add_passthrough_tables(
  face : @face.Face,
  tables : Array[(@common.Tag, Bytes)],
) -> Result[Unit, SubsetError] {
  let tags : Array[@common.Tag] = [
    tag_cvt,
    tag_fpgm,
    tag_prep,
    tag_gasp,
    tag_vdmx,
    tag_fvar,
    tag_avar,
    tag_stat,
    tag_mvar,
    tag_cvar,
    tag_cpal,
    tag_meta,
  ]
  for tag in tags {
    match add_optional_table(face, tag, tables) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  Ok(())
}

///|
fn remap_gid(remap : Array[Int], glyph : Int) -> Result[Int, SubsetError] {
  if glyph < 0 || glyph >= remap.length() {
    return Err(InvalidInput("glyph id out of range"))
  }
  let mapped = remap[glyph]
  if mapped < 0 {
    Err(InvalidInput("glyph missing from subset"))
  } else {
    Ok(mapped)
  }
}

///|
fn remap_composite_glyph(
  glyph_bytes : Array[Byte],
  remap : Array[Int],
) -> Result[Unit, SubsetError] {
  if glyph_bytes.length() < 10 {
    return Ok(())
  }
  let contours = read_i16(glyph_bytes, 0)
  let contours = match contours {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if contours >= 0 {
    return Ok(())
  }
  let mut pos = 10
  let end = glyph_bytes.length()
  let mut last_flags = 0
  while true {
    if pos + 4 > end {
      return Err(InvalidInput("unexpected eof in composite glyph"))
    }
    let record_start = pos
    let flags = read_u16(glyph_bytes, record_start)
    let glyph_index = read_u16(glyph_bytes, record_start + 2)
    let flags = match flags {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let glyph_index = match glyph_index {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mut gid = glyph_index
    pos = record_start + 4
    if (flags & 0x2000) != 0 {
      let gid24 = read_u24(glyph_bytes, pos)
      match gid24 {
        Err(err) => return Err(err)
        Ok(value) => gid = value
      }
      pos = pos + 3
    }
    let mapped = match remap_gid(remap, gid) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if (flags & 0x2000) != 0 {
      write_u16(glyph_bytes, record_start + 2, mapped)
      write_u24(glyph_bytes, record_start + 4, mapped)
    } else {
      write_u16(glyph_bytes, record_start + 2, mapped)
    }
    let args_are_words = (flags & 0x0001) != 0
    if args_are_words {
      pos = pos + 4
    } else {
      pos = pos + 2
    }
    if (flags & 0x0008) != 0 {
      pos = pos + 2
    } else if (flags & 0x0040) != 0 {
      pos = pos + 4
    } else if (flags & 0x0080) != 0 {
      pos = pos + 8
    }
    last_flags = flags
    if (flags & 0x0020) == 0 {
      break
    }
  }
  if (last_flags & 0x0100) != 0 {
    let instr_len = read_u16(glyph_bytes, pos)
    let instr_len = match instr_len {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    pos = pos + 2 + instr_len
    if pos > end {
      return Err(InvalidInput("unexpected eof in composite glyph"))
    }
  }
  Ok(())
}

///|
pub fn build_plan(
  font : @font.Font,
  input : SubsetInput,
) -> Result[SubsetPlan, SubsetError] {
  let face = font.get_face()
  let maxp_blob = match table_blob(face, tag_maxp, "maxp") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  if maxp.num_glyphs <= 0 {
    return Err(InvalidInput("font has no glyphs"))
  }
  let selected : Array[Bool] = Array::make(maxp.num_glyphs, false)
  let queue : Array[Int] = []
  let add_gid = (gid : Int) => {
    if gid < 0 || gid >= selected.length() {
      return
    }
    if !selected[gid] {
      selected[gid] = true
      queue.push(gid)
    }
  }
  add_gid(0)
  for codepoint in input.codepoints {
    let gid = match font.glyph_for_codepoint(codepoint) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    match gid {
      None => ()
      Some(gid) => add_gid(gid.reinterpret_as_int())
    }
  }
  let head_blob = match table_blob(face, tag_head, "head") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let head = match @sfnt.HeadTable::parse(head_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let loca_blob = match table_blob(face, tag_loca, "loca") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let glyf_blob = match table_blob(face, tag_glyf, "glyf") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let loca = match @sfnt.LocaTable::parse(
    loca_blob.as_view(),
    maxp.num_glyphs,
    head.index_to_loc_format,
  ) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let glyf = match @sfnt.GlyfTable::parse(glyf_blob) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let mut idx = 0
  while idx < queue.length() {
    let gid = queue[idx]
    idx = idx + 1
    if gid + 1 >= loca.offsets.length() {
      continue
    }
    let start = loca.offsets[gid]
    let end = loca.offsets[gid + 1]
    let length = end - start
    let components = match glyf.glyph_composite_components(start, length) {
      Err(err) => return Err(Sfnt(err))
      Ok(value) => value
    }
    match components {
      None => ()
      Some(components) => {
        for comp in components {
          add_gid(comp.glyph)
        }
      }
    }
  }
  let glyphs : Array[UInt] = []
  for gid in 0..<selected.length() {
    if selected[gid] {
      glyphs.push(gid.reinterpret_as_uint())
    }
  }
  if glyphs.is_empty() {
    return Err(InvalidInput("empty subset"))
  }
  let old_to_new : Array[Int] = Array::make(maxp.num_glyphs, -1)
  for i in 0..<glyphs.length() {
    let old_gid = glyphs[i].reinterpret_as_int()
    if old_gid >= 0 && old_gid < old_to_new.length() {
      old_to_new[old_gid] = i
    }
  }
  let codepoint_map : Array[(UInt, Int)] = []
  for codepoint in input.codepoints {
    let gid = match font.glyph_for_codepoint(codepoint) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    match gid {
      None => ()
      Some(gid) => {
        let old_gid = gid.reinterpret_as_int()
        if old_gid >= 0 && old_gid < old_to_new.length() {
          let new_gid = old_to_new[old_gid]
          if new_gid >= 0 {
            codepoint_map.push((codepoint, new_gid))
          }
        }
      }
    }
  }
  Ok(SubsetPlan::{ glyphs, old_to_new, codepoint_map })
}

fn build_vmetrics_subset(
  face : @face.Face,
  maxp : @sfnt.MaxpTable,
  plan : SubsetPlan,
) -> Result[(Bytes, Bytes)?, SubsetError] {
  let vhea_blob = match face.reference_table_optional(tag_vhea) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  let vmtx_blob = match face.reference_table_optional(tag_vmtx) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match (vhea_blob, vmtx_blob) {
    (Some(vhea_blob), Some(vmtx_blob)) => {
      let vhea = match @sfnt.VheaTable::parse(vhea_blob.as_view()) {
        Err(err) => return Err(Sfnt(err))
        Ok(value) => value
      }
      let vmtx = match @sfnt.VmtxTable::parse(
        vmtx_blob.as_view(),
        maxp.num_glyphs,
        vhea.number_of_vmetrics,
      ) {
        Err(err) => return Err(Sfnt(err))
        Ok(value) => value
      }
      let new_vmtx : Array[Byte] = []
      for old_gid in plan.glyphs {
        let gid = old_gid.reinterpret_as_int()
        if gid < 0 || gid >= vmtx.advances.length() {
          return Err(InvalidInput("glyph id out of range"))
        }
        let advance = vmtx.advances[gid]
        let tsb = vmtx.tsbs[gid]
        push_u16(new_vmtx, advance)
        push_i16(new_vmtx, tsb)
      }
      let vhea_bytes = vhea_blob.as_view().to_bytes().to_array()
      if vhea_bytes.length() >= 36 {
        write_u16(vhea_bytes, 34, plan.glyphs.length())
      }
      Ok(Some((Bytes::from_array(vhea_bytes), Bytes::from_array(new_vmtx))))
    }
    _ => Ok(None)
  }
}

fn build_hmtx_subset(
  hmtx : @sfnt.HmtxTable,
  plan : SubsetPlan,
) -> Result[(Bytes, Int), SubsetError] {
  let advances : Array[Int] = []
  let lsbs : Array[Int] = []
  for old_gid in plan.glyphs {
    let gid = old_gid.reinterpret_as_int()
    if gid < 0 || gid >= hmtx.advances.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    advances.push(hmtx.advances[gid])
    lsbs.push(hmtx.lsbs[gid])
  }
  if advances.is_empty() {
    return Err(InvalidInput("empty subset"))
  }
  let last_advance = advances[advances.length() - 1]
  let mut last_diff = -1
  for i in 0..<advances.length() {
    if advances[i] != last_advance {
      last_diff = i
    }
  }
  let num_hmetrics = if last_diff < 0 { 1 } else { last_diff + 2 }
  let out : Array[Byte] = []
  for i in 0..<num_hmetrics {
    push_u16(out, advances[i])
    push_i16(out, lsbs[i])
  }
  for i in num_hmetrics..<advances.length() {
    push_i16(out, lsbs[i])
  }
  Ok((Bytes::from_array(out), num_hmetrics))
}

fn build_vorg_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_vorg) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let vorg = match @sfnt.VorgTable::parse(blob.as_view()) {
        Err(err) => return Err(Sfnt(err))
        Ok(value) => value
      }
      let entries : Array[(Int, Int)] = []
      for metric in vorg.metrics {
        let gid = metric.glyph
        if gid < 0 || gid >= plan.old_to_new.length() {
          return Err(InvalidInput("glyph id out of range"))
        }
        let new_gid = plan.old_to_new[gid]
        if new_gid >= 0 {
          entries.push((new_gid, metric.origin_y))
        }
      }
      entries.sort_by((a, b) => {
        let (ga, _) = a
        let (gb, _) = b
        ga - gb
      })
      let out : Array[Byte] = []
      push_u16(out, vorg.major_version)
      push_u16(out, vorg.minor_version)
      push_i16(out, vorg.default_origin_y)
      push_u16(out, entries.length())
      for entry in entries {
        let (gid, origin) = entry
        push_u16(out, gid)
        push_i16(out, origin)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_kern_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_kern) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let kern = match @sfnt.KernTable::parse(blob.as_view()) {
        Err(err) => return Err(Sfnt(err))
        Ok(value) => value
      }
      let subtables : Array[Bytes] = []
      for subtable in kern.subtables {
        let horizontal = subtable.horizontal
        let minimum = subtable.minimum
        let cross_stream = subtable.cross_stream
        let override_flag = subtable.override_flag
        if subtable.format == 0 {
          let pairs : Array[(Int, Int, Int)] = []
          for pair in subtable.pairs {
            let left = pair.left.reinterpret_as_int()
            let right = pair.right.reinterpret_as_int()
            if left < 0 || left >= plan.old_to_new.length() {
              return Err(InvalidInput("glyph id out of range"))
            }
            if right < 0 || right >= plan.old_to_new.length() {
              return Err(InvalidInput("glyph id out of range"))
            }
            let new_left = plan.old_to_new[left]
            let new_right = plan.old_to_new[right]
            if new_left >= 0 && new_right >= 0 {
              pairs.push((new_left, new_right, pair.value))
            }
          }
          let bytes = match build_kern_format0_subtable(
            pairs,
            horizontal,
            minimum,
            cross_stream,
            override_flag,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          match bytes {
            None => ()
            Some(bytes) => subtables.push(bytes)
          }
          continue
        }
        if subtable.format == 2 {
          let format2 = match subtable.format2 {
            None => continue
            Some(value) => value
          }
          let pairs = match kern_pairs_from_format2(format2, plan) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let bytes = match build_kern_format0_subtable(
            pairs,
            horizontal,
            minimum,
            cross_stream,
            override_flag,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          match bytes {
            None => ()
            Some(bytes) => subtables.push(bytes)
          }
          continue
        }
        if subtable.format == 3 {
          let format3 = match subtable.format3 {
            None => continue
            Some(value) => value
          }
          let pairs = match kern_pairs_from_format3(format3, plan) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let bytes = match build_kern_format0_subtable(
            pairs,
            horizontal,
            minimum,
            cross_stream,
            override_flag,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          match bytes {
            None => ()
            Some(bytes) => subtables.push(bytes)
          }
          continue
        }
      }
      if subtables.is_empty() {
        return Ok(None)
      }
      let out : Array[Byte] = []
      push_u16(out, 0)
      push_u16(out, subtables.length())
      for subtable in subtables {
        for b in subtable {
          out.push(b)
        }
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

let max_colr_paint_depth : Int = 64

fn parse_colr_layer_offsets(
  bytes : Array[Byte],
  layer_list_offset : Int,
) -> Result[Array[Int], SubsetError] {
  if layer_list_offset < 0 || layer_list_offset + 4 > bytes.length() {
    return Err(InvalidInput("invalid COLR layer list offset"))
  }
  let count = match read_u32(bytes, layer_list_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if count < 0 {
    return Err(InvalidInput("invalid COLR layer list count"))
  }
  let entries_offset = layer_list_offset + 4
  if entries_offset + count * 4 > bytes.length() {
    return Err(InvalidInput("invalid COLR layer list bounds"))
  }
  let offsets : Array[Int] = []
  for i in 0..<count {
    let rel = match read_u32(bytes, entries_offset + i * 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if rel < 0 {
      return Err(InvalidInput("invalid COLR layer paint offset"))
    }
    let abs = layer_list_offset + rel
    if abs < 0 || abs >= bytes.length() {
      return Err(InvalidInput("invalid COLR layer paint bounds"))
    }
    offsets.push(abs)
  }
  Ok(offsets)
}

fn remap_colr_v1_paint(
  bytes : Array[Byte],
  offset : Int,
  plan : SubsetPlan,
  layer_offsets : Array[Int],
  visited : Array[Bool],
  depth : Int,
) -> Result[Bool, SubsetError] {
  if depth <= 0 {
    return Err(InvalidInput("COLR paint depth exceeded"))
  }
  if offset < 0 || offset >= bytes.length() {
    return Err(InvalidInput("invalid COLR paint offset"))
  }
  if visited[offset] {
    return Ok(true)
  }
  visited[offset] = true
  let format = match read_u8(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match format {
    1 => {
      let num_layers = match read_u8(bytes, offset + 1) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let first_layer = match read_u32(bytes, offset + 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if num_layers < 0 || first_layer < 0 {
        return Err(InvalidInput("invalid COLR layer indices"))
      }
      let end = first_layer + num_layers
      if end > layer_offsets.length() {
        return Err(InvalidInput("invalid COLR layer range"))
      }
      for i in 0..<num_layers {
        let idx = first_layer + i
        let child_offset = layer_offsets[idx]
        let ok = match remap_colr_v1_paint(
          bytes,
          child_offset,
          plan,
          layer_offsets,
          visited,
          depth - 1,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if !ok {
          return Ok(false)
        }
      }
      Ok(true)
    }
    2 | 3 => Ok(true)
    4 | 5 | 6 | 7 | 8 | 9 => Ok(true)
    10 => {
      let paint_offset = match read_u24(bytes, offset + 1) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let glyph_id = match read_u16(bytes, offset + 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if glyph_id < 0 || glyph_id >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_gid = plan.old_to_new[glyph_id]
      if new_gid < 0 {
        return Ok(false)
      }
      write_u16(bytes, offset + 4, new_gid)
      let child_offset = offset + paint_offset
      let ok = match remap_colr_v1_paint(
        bytes,
        child_offset,
        plan,
        layer_offsets,
        visited,
        depth - 1,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(ok)
    }
    11 => {
      let glyph_id = match read_u16(bytes, offset + 1) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if glyph_id < 0 || glyph_id >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_gid = plan.old_to_new[glyph_id]
      if new_gid < 0 {
        return Ok(false)
      }
      write_u16(bytes, offset + 1, new_gid)
      Ok(true)
    }
    12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30
    | 31 => {
      let paint_offset = match read_u24(bytes, offset + 1) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let child_offset = offset + paint_offset
      remap_colr_v1_paint(bytes, child_offset, plan, layer_offsets, visited, depth - 1)
    }
    32 => {
      let src_offset = match read_u24(bytes, offset + 1) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let backdrop_offset = match read_u24(bytes, offset + 5) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let src_abs = offset + src_offset
      let backdrop_abs = offset + backdrop_offset
      let src_ok = match remap_colr_v1_paint(
        bytes,
        src_abs,
        plan,
        layer_offsets,
        visited,
        depth - 1,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if !src_ok {
        return Ok(false)
      }
      let back_ok = match remap_colr_v1_paint(
        bytes,
        backdrop_abs,
        plan,
        layer_offsets,
        visited,
        depth - 1,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      Ok(back_ok)
    }
    _ => Err(InvalidInput("unsupported COLR paint format"))
  }
}

fn build_colr_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_colr) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 14 {
        return Err(InvalidInput("invalid COLR table"))
      }
      let version = match read_u16(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if version >= 1 {
        if bytes.length() < 34 {
          return Err(InvalidInput("invalid COLR table"))
        }
        let base_glyph_list_offset = match read_u32(bytes, 14) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let layer_list_offset = match read_u32(bytes, 18) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let clip_list_offset = match read_u32(bytes, 22) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if base_glyph_list_offset <= 0 || layer_list_offset <= 0 {
          return Ok(None)
        }
        let layer_offsets = match parse_colr_layer_offsets(bytes, layer_list_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if base_glyph_list_offset < 0 || base_glyph_list_offset + 4 > bytes.length() {
          return Err(InvalidInput("invalid COLR base glyph list offset"))
        }
        let count = match read_u32(bytes, base_glyph_list_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if count <= 0 {
          return Ok(None)
        }
        let record_base = base_glyph_list_offset + 4
        let record_len = 6
        let records_end = record_base + count * record_len
        if records_end > bytes.length() {
          return Err(InvalidInput("invalid COLR base glyph list bounds"))
        }
        let mut min_paint_offset = bytes.length()
        let visited : Array[Bool] = Array::make(bytes.length(), false)
        let kept_records : Array[(Int, Int)] = []
        for i in 0..<count {
          let rec_offset = record_base + i * record_len
          let gid = match read_u16(bytes, rec_offset) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let paint_offset = match read_u32(bytes, rec_offset + 2) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if paint_offset < 0 {
            return Err(InvalidInput("invalid COLR paint offset"))
          }
          if paint_offset < min_paint_offset {
            min_paint_offset = paint_offset
          }
          if gid < 0 || gid >= plan.old_to_new.length() {
            return Err(InvalidInput("glyph id out of range"))
          }
          let new_gid = plan.old_to_new[gid]
          if new_gid < 0 {
            continue
          }
          let abs_paint = base_glyph_list_offset + paint_offset
          if abs_paint < 0 || abs_paint >= bytes.length() {
            return Err(InvalidInput("invalid COLR paint bounds"))
          }
          let ok = match remap_colr_v1_paint(
            bytes,
            abs_paint,
            plan,
            layer_offsets,
            visited,
            max_colr_paint_depth,
          ) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if ok {
            kept_records.push((new_gid, paint_offset))
          }
        }
        if kept_records.is_empty() {
          return Ok(None)
        }
        if min_paint_offset < 4 {
          return Err(InvalidInput("invalid COLR paint offset"))
        }
        let max_records = (min_paint_offset - 4) / record_len
        if kept_records.length() > max_records {
          return Err(InvalidInput("COLR base glyph list overflow"))
        }
        write_u16(bytes, 2, 0)
        write_u32(bytes, 4, 0)
        write_u32(bytes, 8, 0)
        write_u16(bytes, 12, 0)
        if clip_list_offset != 0 {
          write_u32(bytes, 22, 0)
        }
        write_u32(bytes, base_glyph_list_offset, kept_records.length())
        let clear_end = base_glyph_list_offset + min_paint_offset
        let mut pos = base_glyph_list_offset + 4
        while pos < clear_end {
          bytes[pos] = (0).to_byte()
          pos = pos + 1
        }
        for i in 0..<kept_records.length() {
          let rec_offset = base_glyph_list_offset + 4 + i * record_len
          let (gid, paint_offset) = kept_records[i]
          write_u16(bytes, rec_offset, gid)
          write_u32(bytes, rec_offset + 2, paint_offset)
        }
        return Ok(Some(Bytes::from_array(bytes)))
      }
      if version != 0 {
        return Ok(None)
      }
      let num_base = match read_u16(bytes, 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let base_offset = match read_u32(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let layer_offset = match read_u32(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let num_layers = match read_u16(bytes, 12) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if num_base < 0 || num_layers < 0 {
        return Err(InvalidInput("invalid COLR counts"))
      }
      if base_offset < 0 || layer_offset < 0 {
        return Err(InvalidInput("invalid COLR offsets"))
      }
      let base_end = base_offset + num_base * 6
      let layer_end = layer_offset + num_layers * 4
      if base_end > bytes.length() || layer_end > bytes.length() {
        return Err(InvalidInput("invalid COLR table"))
      }
      let base_records : Array[(Int, Int, Int)] = []
      for i in 0..<num_base {
        let rec_offset = base_offset + i * 6
        let gid = match read_u16(bytes, rec_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let first_layer = match read_u16(bytes, rec_offset + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let layer_count = match read_u16(bytes, rec_offset + 4) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        base_records.push((gid, first_layer, layer_count))
      }
      base_records.sort_by((a, b) => {
        let (ga, _, _) = a
        let (gb, _, _) = b
        ga - gb
      })
      let layers : Array[(Int, Int)] = []
      for i in 0..<num_layers {
        let rec_offset = layer_offset + i * 4
        let gid = match read_u16(bytes, rec_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let color_index = match read_u16(bytes, rec_offset + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        layers.push((gid, color_index))
      }
      let new_layers : Array[(Int, Int)] = []
      let new_base : Array[(Int, Int, Int)] = []
      for base in base_records {
        let (gid, first_layer, layer_count) = base
        if gid < 0 || gid >= plan.old_to_new.length() {
          return Err(InvalidInput("glyph id out of range"))
        }
        let new_gid = plan.old_to_new[gid]
        if new_gid < 0 {
          continue
        }
        if first_layer < 0 || layer_count < 0 || first_layer + layer_count > layers.length() {
          return Err(InvalidInput("invalid COLR layer range"))
        }
        let new_first = new_layers.length()
        let mut new_count = 0
        for i in 0..<layer_count {
          let (layer_gid, color_index) = layers[first_layer + i]
          if layer_gid < 0 || layer_gid >= plan.old_to_new.length() {
            return Err(InvalidInput("glyph id out of range"))
          }
          let new_layer_gid = plan.old_to_new[layer_gid]
          if new_layer_gid >= 0 {
            new_layers.push((new_layer_gid, color_index))
            new_count = new_count + 1
          }
        }
        if new_count > 0 {
          new_base.push((new_gid, new_first, new_count))
        }
      }
      if new_base.is_empty() {
        return Ok(None)
      }
      let out : Array[Byte] = []
      push_u16(out, 0)
      push_u16(out, new_base.length())
      let base_records_offset = 14
      let layer_records_offset = base_records_offset + new_base.length() * 6
      push_u32(out, base_records_offset)
      push_u32(out, layer_records_offset)
      push_u16(out, new_layers.length())
      for base in new_base {
        let (gid, first_layer, layer_count) = base
        push_u16(out, gid)
        push_u16(out, first_layer)
        push_u16(out, layer_count)
      }
      for layer in new_layers {
        let (gid, color_index) = layer
        push_u16(out, gid)
        push_u16(out, color_index)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_svg_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_svg) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 10 {
        return Err(InvalidInput("invalid SVG table"))
      }
      let version = match read_u16(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if version != 0 {
        return Ok(None)
      }
      let index_offset = match read_u32(bytes, 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if index_offset <= 0 || index_offset >= bytes.length() {
        return Err(InvalidInput("invalid SVG index offset"))
      }
      let index_base = index_offset
      if index_base + 2 > bytes.length() {
        return Err(InvalidInput("invalid SVG index bounds"))
      }
      let entry_count = match read_u16(bytes, index_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if entry_count < 0 {
        return Err(InvalidInput("invalid SVG entry count"))
      }
      let entry_base = index_base + 2
      if entry_base + entry_count * 12 > bytes.length() {
        return Err(InvalidInput("invalid SVG entry bounds"))
      }
      let doc_keys : Array[(Int, Int)] = []
      let docs : Array[Bytes] = []
      let runs : Array[(Int, Int, Int)] = []
      for i in 0..<entry_count {
        let rec_base = entry_base + i * 12
        let start = match read_u16(bytes, rec_base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let end = match read_u16(bytes, rec_base + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let doc_offset = match read_u32(bytes, rec_base + 4) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let doc_length = match read_u32(bytes, rec_base + 8) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if end < start {
          return Err(InvalidInput("invalid SVG entry range"))
        }
        if doc_offset <= 0 || doc_length <= 0 {
          return Err(InvalidInput("invalid SVG document range"))
        }
        let doc_base = index_base + doc_offset
        if doc_base < 0 || doc_base + doc_length > bytes.length() {
          return Err(InvalidInput("invalid SVG document bounds"))
        }
        let mut doc_id = -1
        for j in 0..<doc_keys.length() {
          let (offset_key, length_key) = doc_keys[j]
          if offset_key == doc_offset && length_key == doc_length {
            doc_id = j
            break
          }
        }
        if doc_id < 0 {
          let doc_bytes = bytes[doc_base:doc_base + doc_length].to_array()
          doc_keys.push((doc_offset, doc_length))
          docs.push(Bytes::from_array(doc_bytes))
          doc_id = doc_keys.length() - 1
        }
        let mut run_start = -1
        let mut run_last = -1
        for old_gid in plan.glyphs {
          let gid = old_gid.reinterpret_as_int()
          if gid < start || gid > end {
            continue
          }
          if gid < 0 || gid >= plan.old_to_new.length() {
            return Err(InvalidInput("glyph id out of range"))
          }
          let new_gid = plan.old_to_new[gid]
          if new_gid < 0 {
            continue
          }
          if new_gid > 0xFFFF {
            return Err(InvalidInput("SVG glyph id out of range"))
          }
          if run_start < 0 {
            run_start = new_gid
            run_last = new_gid
          } else if new_gid == run_last + 1 {
            run_last = new_gid
          } else {
            runs.push((run_start, run_last, doc_id))
            run_start = new_gid
            run_last = new_gid
          }
        }
        if run_start >= 0 {
          runs.push((run_start, run_last, doc_id))
        }
      }
      if runs.is_empty() {
        return Ok(None)
      }
      runs.sort_by((a, b) => a.0 - b.0)
      let index_size = 2 + runs.length() * 12
      let doc_offsets : Array[Int] = []
      let mut cursor = index_size
      for doc in docs {
        doc_offsets.push(cursor)
        cursor = cursor + doc.length()
      }
      let index_bytes : Array[Byte] = []
      push_u16(index_bytes, runs.length())
      for run in runs {
        let (start, end, doc_id) = run
        push_u16(index_bytes, start)
        push_u16(index_bytes, end)
        push_u32(index_bytes, doc_offsets[doc_id])
        push_u32(index_bytes, docs[doc_id].length())
      }
      for doc in docs {
        for b in doc {
          index_bytes.push(b)
        }
      }
      let out : Array[Byte] = []
      push_u16(out, version)
      push_u32(out, 10)
      push_u32(out, 0)
      for b in index_bytes {
        out.push(b)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_sbix_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_sbix) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 8 {
        return Err(InvalidInput("invalid sbix table"))
      }
      let version = match read_u16(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let flags = match read_u16(bytes, 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let strike_count = match read_u32(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if strike_count <= 0 {
        return Ok(None)
      }
      let strike_offsets_base = 8
      if strike_offsets_base + strike_count * 4 > bytes.length() {
        return Err(InvalidInput("invalid sbix strike offsets"))
      }
      let strike_offsets : Array[Int] = []
      for i in 0..<strike_count {
        let offset = match read_u32(bytes, strike_offsets_base + i * 4) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if offset < 0 || offset >= bytes.length() {
          return Err(InvalidInput("invalid sbix strike offset"))
        }
        strike_offsets.push(offset)
      }
      let old_glyph_count = plan.old_to_new.length()
      let new_glyph_count = plan.glyphs.length()
      let strikes : Array[Bytes] = []
      for i in 0..<strike_count {
        let strike_offset = strike_offsets[i]
        let strike_end =
          if i + 1 < strike_count {
            let next = strike_offsets[i + 1]
            if next < strike_offset {
              return Err(InvalidInput("invalid sbix strike bounds"))
            }
            next
          } else {
            bytes.length()
          }
        if strike_offset + 4 > strike_end {
          return Err(InvalidInput("invalid sbix strike header"))
        }
        let available_len = strike_end - strike_offset
        let ppem = match read_u16(bytes, strike_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let resolution = match read_u16(bytes, strike_offset + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let offsets_base = strike_offset + 4
        let offsets_len = (old_glyph_count + 1) * 4
        if offsets_base + offsets_len > strike_end {
          return Err(InvalidInput("invalid sbix glyph offsets"))
        }
        let old_offsets : Array[Int] = []
        for j in 0..<(old_glyph_count + 1) {
          let offset = match read_u32(bytes, offsets_base + j * 4) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          old_offsets.push(offset)
        }
        let header_size = 4 + (new_glyph_count + 1) * 4
        let mut head = header_size
        let new_offsets : Array[Int] = []
        let glyph_data : Array[Byte] = []
        let mut has_glyphs = false
        for new_gid in 0..<new_glyph_count {
          let old_gid = plan.glyphs[new_gid].reinterpret_as_int()
          if old_gid < 0 || old_gid + 1 >= old_offsets.length() {
            return Err(InvalidInput("glyph id out of range"))
          }
          let start = old_offsets[old_gid]
          let end = old_offsets[old_gid + 1]
          if start <= 0 || end <= 0 || end <= start || end - start <= 8 || end > available_len {
            new_offsets.push(head)
            continue
          }
          new_offsets.push(head)
          let data_start = strike_offset + start
          let data_end = strike_offset + end
          if data_start < 0 || data_end > bytes.length() {
            return Err(InvalidInput("invalid sbix glyph data bounds"))
          }
          for idx in data_start..<data_end {
            glyph_data.push(bytes[idx])
          }
          head = head + (end - start)
          has_glyphs = true
        }
        if !has_glyphs {
          continue
        }
        let out : Array[Byte] = []
        push_u16(out, ppem)
        push_u16(out, resolution)
        for offset in new_offsets {
          push_u32(out, offset)
        }
        push_u32(out, head)
        for b in glyph_data {
          out.push(b)
        }
        strikes.push(Bytes::from_array(out))
      }
      if strikes.is_empty() {
        return Ok(None)
      }
      let out : Array[Byte] = []
      push_u16(out, version)
      push_u16(out, flags)
      push_u32(out, strikes.length())
      let mut cursor = 8 + strikes.length() * 4
      for strike in strikes {
        push_u32(out, cursor)
        cursor = cursor + strike.length()
      }
      for strike in strikes {
        for b in strike {
          out.push(b)
        }
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

priv struct CblcStrike {
  metrics : Array[Byte]
  ppem_x : Int
  ppem_y : Int
  bit_depth : Int
  flags : Int
  color_ref : Int
  list : Array[Byte]
  subtable : Array[Byte]
}

priv struct DeltaMapInfo {
  format : Int
  entry_format : Int
  width : Int
  map_count : Int
  map_data : Array[Byte]
}

fn parse_delta_map(
  bytes : Array[Byte],
  offset : Int,
) -> Result[DeltaMapInfo, SubsetError] {
  let format = match read_u8(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let entry_format = match read_u8(bytes, offset + 1) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let width = ((entry_format >> 4) & 0x3) + 1
  let map_count = if format == 0 {
    match read_u16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if format == 1 {
    match read_u32(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else {
    return Err(InvalidInput("unsupported delta map format"))
  }
  if map_count <= 0 {
    return Err(InvalidInput("invalid delta map count"))
  }
  let data_offset = if format == 0 { offset + 4 } else { offset + 6 }
  let length = map_count * width
  if data_offset < 0 || data_offset + length > bytes.length() {
    return Err(InvalidInput("invalid delta map bounds"))
  }
  let map_data = bytes[data_offset:data_offset + length].to_array()
  Ok(DeltaMapInfo::{ format, entry_format, width, map_count, map_data })
}

fn build_delta_map_subset(
  info : DeltaMapInfo,
  glyphs : Array[UInt],
) -> Result[Array[Byte], SubsetError] {
  let new_count = glyphs.length()
  if new_count <= 0 {
    return Err(InvalidInput("invalid delta map size"))
  }
  let format =
    if info.format == 0 && new_count <= 0xFFFF { 0 } else if info.format == 1 { 1 } else { 1 }
  let out : Array[Byte] = []
  out.push(format.to_byte())
  out.push(info.entry_format.to_byte())
  if format == 0 {
    push_u16(out, new_count)
  } else {
    push_u32(out, new_count)
  }
  let max_index = info.map_count - 1
  for gid in glyphs {
    let mut idx = gid.reinterpret_as_int()
    if idx < 0 {
      idx = 0
    }
    if idx > max_index {
      idx = max_index
    }
    let base = idx * info.width
    for i in 0..<info.width {
      out.push(info.map_data[base + i])
    }
  }
  Ok(out)
}

fn build_cblc_cbdt_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[(Bytes, Bytes)?, SubsetError] {
  let cblc_blob = match face.reference_table_optional(tag_cblc) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  let cbdt_blob = match face.reference_table_optional(tag_cbdt) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match (cblc_blob, cbdt_blob) {
    (Some(cblc_blob), Some(cbdt_blob)) => {
      let cblc_bytes = cblc_blob.as_view().to_bytes().to_array()
      let cbdt_bytes = cbdt_blob.as_view().to_bytes().to_array()
      if cblc_bytes.length() < 8 || cbdt_bytes.length() < 4 {
        return Err(InvalidInput("invalid CBLC/CBDT table"))
      }
      let major = match read_u16(cblc_bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let minor = match read_u16(cblc_bytes, 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let num_sizes = match read_u32(cblc_bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if num_sizes <= 0 {
        return Ok(None)
      }
      let size_record_len = 48
      let size_base = 8
      if size_base + num_sizes * size_record_len > cblc_bytes.length() {
        return Err(InvalidInput("invalid CBLC size records"))
      }
      let new_glyph_count = plan.glyphs.length()
      if new_glyph_count <= 0 {
        return Ok(None)
      }
      let cbdt_header = cbdt_bytes[0:4].to_array()
      let cbdt_out : Array[Byte] = []
      for b in cbdt_header {
        cbdt_out.push(b)
      }
      let mut cbdt_cursor = cbdt_out.length()
      let strikes : Array[CblcStrike] = []
      let old_glyph_count = plan.old_to_new.length()
      for i in 0..<num_sizes {
        let record_offset = size_base + i * size_record_len
        let list_offset = match read_u32(cblc_bytes, record_offset) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let list_size = match read_u32(cblc_bytes, record_offset + 4) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let subtable_count = match read_u32(cblc_bytes, record_offset + 8) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let color_ref = match read_u32(cblc_bytes, record_offset + 12) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if subtable_count <= 0 || list_offset < 0 {
          continue
        }
        if list_offset + list_size > cblc_bytes.length() {
          return Err(InvalidInput("invalid CBLC index subtable list"))
        }
        let metrics : Array[Byte] = []
        let metrics_base = record_offset + 16
        for j in 0..<24 {
          metrics.push(cblc_bytes[metrics_base + j])
        }
        let ppem_x = cblc_bytes[record_offset + 44].to_int()
        let ppem_y = cblc_bytes[record_offset + 45].to_int()
        let bit_depth = cblc_bytes[record_offset + 46].to_int()
        let flags = cblc_bytes[record_offset + 47].to_int()
        let record_len = subtable_count * 8
        if list_offset + record_len > cblc_bytes.length() {
          return Err(InvalidInput("invalid CBLC index subtable records"))
        }
        let glyph_offsets : Array[Int] = Array::make(old_glyph_count, -1)
        let glyph_lengths : Array[Int] = Array::make(old_glyph_count, 0)
        let mut image_format = -1
        for j in 0..<subtable_count {
          let rec_offset = list_offset + j * 8
          let first = match read_u16(cblc_bytes, rec_offset) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let last = match read_u16(cblc_bytes, rec_offset + 2) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let subtable_offset = match read_u32(cblc_bytes, rec_offset + 4) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if last < first || subtable_offset < 0 {
            continue
          }
          let subtable_base = list_offset + subtable_offset
          if subtable_base + 8 > cblc_bytes.length() {
            return Err(InvalidInput("invalid CBLC subtable"))
          }
          let index_format = match read_u16(cblc_bytes, subtable_base) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if index_format != 1 {
            continue
          }
          let sub_image_format = match read_u16(cblc_bytes, subtable_base + 2) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          if image_format < 0 {
            image_format = sub_image_format
          } else if image_format != sub_image_format {
            return Err(InvalidInput("mixed CBLC image formats"))
          }
          let image_data_offset = match read_u32(cblc_bytes, subtable_base + 4) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          let num_offsets = last - first + 2
          if num_offsets < 2 {
            continue
          }
          let offsets_base = subtable_base + 8
          if offsets_base + num_offsets * 4 > cblc_bytes.length() {
            return Err(InvalidInput("invalid CBLC offset array"))
          }
          let offsets : Array[Int] = []
          for k in 0..<num_offsets {
            let off = match read_u32(cblc_bytes, offsets_base + k * 4) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            offsets.push(off)
          }
          for k in 0..<(num_offsets - 1) {
            let gid = first + k
            if gid < 0 || gid >= old_glyph_count {
              continue
            }
            let start = offsets[k]
            let end = offsets[k + 1]
            if end <= start {
              continue
            }
            let abs_offset = image_data_offset + start
            let length = end - start
            if abs_offset < 0 || abs_offset + length > cbdt_bytes.length() {
              return Err(InvalidInput("invalid CBDT data offset"))
            }
            glyph_offsets[gid] = abs_offset
            glyph_lengths[gid] = length
          }
        }
        if image_format < 0 {
          continue
        }
        let new_offsets : Array[Int] = []
        let strike_data : Array[Byte] = []
        let mut data_cursor = 0
        let mut has_data = false
        for new_gid in 0..<new_glyph_count {
          let old_gid = plan.glyphs[new_gid].reinterpret_as_int()
          if old_gid < 0 || old_gid >= glyph_offsets.length() {
            return Err(InvalidInput("glyph id out of range"))
          }
          let start = glyph_offsets[old_gid]
          let length = glyph_lengths[old_gid]
          if start < 0 || length <= 0 {
            new_offsets.push(data_cursor)
            continue
          }
          new_offsets.push(data_cursor)
          let end = start + length
          if start < 0 || end > cbdt_bytes.length() {
            return Err(InvalidInput("invalid CBDT glyph bounds"))
          }
          for idx in start..<end {
            strike_data.push(cbdt_bytes[idx])
          }
          data_cursor = data_cursor + length
          has_data = true
        }
        if !has_data {
          continue
        }
        let image_data_offset = cbdt_cursor
        for b in strike_data {
          cbdt_out.push(b)
        }
        cbdt_cursor = cbdt_cursor + strike_data.length()
        let subtable : Array[Byte] = []
        push_u16(subtable, 1)
        push_u16(subtable, image_format)
        push_u32(subtable, image_data_offset)
        for offset in new_offsets {
          push_u32(subtable, offset)
        }
        push_u32(subtable, data_cursor)
        let list : Array[Byte] = []
        push_u16(list, 0)
        push_u16(list, new_glyph_count - 1)
        push_u32(list, 8)
        strikes.push(CblcStrike::{
          metrics,
          ppem_x,
          ppem_y,
          bit_depth,
          flags,
          color_ref,
          list,
          subtable,
        })
      }
      if strikes.is_empty() {
        return Ok(None)
      }
      let out : Array[Byte] = []
      push_u16(out, major)
      push_u16(out, minor)
      push_u32(out, strikes.length())
      let mut cursor = 8 + strikes.length() * size_record_len
      for strike in strikes {
        let list_size = strike.list.length() + strike.subtable.length()
        push_u32(out, cursor)
        push_u32(out, list_size)
        push_u32(out, 1)
        push_u32(out, strike.color_ref)
        for b in strike.metrics {
          out.push(b)
        }
        push_u16(out, 0)
        push_u16(out, new_glyph_count - 1)
        out.push(strike.ppem_x.to_byte())
        out.push(strike.ppem_y.to_byte())
        out.push(strike.bit_depth.to_byte())
        out.push(strike.flags.to_byte())
        cursor = cursor + list_size
      }
      for strike in strikes {
        for b in strike.list {
          out.push(b)
        }
        for b in strike.subtable {
          out.push(b)
        }
      }
      Ok(Some((Bytes::from_array(out), Bytes::from_array(cbdt_out))))
    }
    _ => Ok(None)
  }
}

fn parse_gvar_offsets(
  bytes : Array[Byte],
  offset : Int,
  glyph_count : Int,
  long_offsets : Bool,
) -> Result[Array[Int], SubsetError] {
  let count = glyph_count + 1
  if count <= 0 {
    return Err(InvalidInput("invalid gvar glyph count"))
  }
  let offsets : Array[Int] = []
  if long_offsets {
    let total = count * 4
    if offset < 0 || offset + total > bytes.length() {
      return Err(InvalidInput("invalid gvar offsets"))
    }
    let mut pos = offset
    for _ in 0..<count {
      let value = match read_u32(bytes, pos) {
        Err(err) => return Err(err)
        Ok(v) => v
      }
      offsets.push(value)
      pos = pos + 4
    }
  } else {
    let total = count * 2
    if offset < 0 || offset + total > bytes.length() {
      return Err(InvalidInput("invalid gvar offsets"))
    }
    let mut pos = offset
    for _ in 0..<count {
      let value = match read_u16(bytes, pos) {
        Err(err) => return Err(err)
        Ok(v) => v
      }
      offsets.push(value * 2)
      pos = pos + 2
    }
  }
  Ok(offsets)
}

fn build_gvar_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_gvar) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 20 {
        return Err(InvalidInput("invalid gvar table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let axis_count = match read_u16(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let shared_tuple_count = match read_u16(bytes, 6) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let shared_tuples_offset = match read_u32(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let glyph_count = match read_u16(bytes, 12) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let flags = match read_u16(bytes, 14) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let data_offset = match read_u32(bytes, 16) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let major = (version >> 16) & 0xFFFF
      if major != 1 {
        return Ok(None)
      }
      let long_offsets = (flags & 1) != 0
      let offsets = match parse_gvar_offsets(bytes, 20, glyph_count, long_offsets) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if glyph_count <= 0 {
        return Ok(None)
      }
      let shared_len = shared_tuple_count * axis_count * 2
      let shared_bytes : Array[Byte] = []
      if shared_tuple_count > 0 {
        if shared_tuples_offset <= 0 || shared_tuples_offset + shared_len > bytes.length() {
          return Err(InvalidInput("invalid gvar shared tuples"))
        }
        for b in bytes[shared_tuples_offset:shared_tuples_offset + shared_len] {
          shared_bytes.push(b)
        }
      }
      let new_offsets : Array[Int] = []
      let mut cursor = 0
      let data_bytes : Array[Byte] = []
      for old_gid in plan.glyphs {
        let gid = old_gid.reinterpret_as_int()
        if gid < 0 || gid + 1 >= offsets.length() {
          return Err(InvalidInput("glyph id out of range"))
        }
        let start = offsets[gid]
        let end = offsets[gid + 1]
        if end < start {
          return Err(InvalidInput("invalid gvar glyph range"))
        }
        new_offsets.push(cursor)
        let length = end - start
        if length > 0 {
          if data_offset < 0 || data_offset + end > bytes.length() {
            return Err(InvalidInput("invalid gvar data offset"))
          }
          let base = data_offset + start
          let limit = base + length
          for idx in base..<limit {
            data_bytes.push(bytes[idx])
          }
          cursor = cursor + length
        }
      }
      new_offsets.push(cursor)
      if cursor == 0 {
        return Ok(None)
      }
      let new_glyph_count = plan.glyphs.length()
      let offsets_len = (new_glyph_count + 1) * 4
      let data_start = 20 + offsets_len
      let shared_offset = if shared_tuple_count > 0 { data_start } else { 0 }
      let data_start = if shared_tuple_count > 0 { data_start + shared_bytes.length() } else { data_start }
      let out : Array[Byte] = []
      push_u32(out, version)
      push_u16(out, axis_count)
      push_u16(out, shared_tuple_count)
      push_u32(out, shared_offset)
      push_u16(out, new_glyph_count)
      push_u16(out, flags | 1)
      push_u32(out, data_start)
      for offset in new_offsets {
        push_u32(out, offset)
      }
      for b in shared_bytes {
        out.push(b)
      }
      for b in data_bytes {
        out.push(b)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_metrics_variation_subset(
  bytes : Array[Byte],
  map_offsets : Array[Int],
  plan : SubsetPlan,
) -> Result[Array[(Int, Array[Byte])], SubsetError] {
  let built : Array[(Int, Array[Byte])] = []
  for offset in map_offsets {
    if offset == 0 {
      built.push((0, []))
      continue
    }
    let info = match parse_delta_map(bytes, offset) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let map_bytes = match build_delta_map_subset(info, plan.glyphs) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    built.push((offset, map_bytes))
  }
  Ok(built)
}

fn build_hvar_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_hvar) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 20 {
        return Err(InvalidInput("invalid HVAR table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let major = (version >> 16) & 0xFFFF
      if major != 1 {
        return Ok(None)
      }
      let var_store_offset = match read_u32(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let adv_offset = match read_u32(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lsb_offset = match read_u32(bytes, 12) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let rsb_offset = match read_u32(bytes, 16) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if var_store_offset <= 0 || var_store_offset > bytes.length() {
        return Err(InvalidInput("invalid HVAR var store"))
      }
      let maps = match build_metrics_variation_subset(bytes, [adv_offset, lsb_offset, rsb_offset], plan) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let out : Array[Byte] = []
      push_u32(out, version)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      let mut cursor = 20
      let mut idx = 0
      while idx < maps.length() {
        let (_, map_bytes) = maps[idx]
        if map_bytes.length() > 0 {
          write_u32(out, 8 + idx * 4, cursor)
          for b in map_bytes {
            out.push(b)
          }
          cursor = cursor + map_bytes.length()
        }
        idx = idx + 1
      }
      write_u32(out, 4, cursor)
      for b in bytes[var_store_offset:] {
        out.push(b)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_vvar_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_vvar) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 24 {
        return Err(InvalidInput("invalid VVAR table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let major = (version >> 16) & 0xFFFF
      if major != 1 {
        return Ok(None)
      }
      let var_store_offset = match read_u32(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let adv_offset = match read_u32(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let tsb_offset = match read_u32(bytes, 12) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let bsb_offset = match read_u32(bytes, 16) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let vorg_offset = match read_u32(bytes, 20) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if var_store_offset <= 0 || var_store_offset > bytes.length() {
        return Err(InvalidInput("invalid VVAR var store"))
      }
      let maps = match build_metrics_variation_subset(
        bytes,
        [adv_offset, tsb_offset, bsb_offset, vorg_offset],
        plan,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let out : Array[Byte] = []
      push_u32(out, version)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      let mut cursor = 24
      let mut idx = 0
      while idx < maps.length() {
        let (_, map_bytes) = maps[idx]
        if map_bytes.length() > 0 {
          write_u32(out, 8 + idx * 4, cursor)
          for b in map_bytes {
            out.push(b)
          }
          cursor = cursor + map_bytes.length()
        }
        idx = idx + 1
      }
      write_u32(out, 4, cursor)
      for b in bytes[var_store_offset:] {
        out.push(b)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

let varc_flag_have_axes : UInt = 1U << 1
let varc_flag_axis_values_have_variation : UInt = 1U << 2
let varc_flag_transform_has_variation : UInt = 1U << 3
let varc_flag_have_translate_x : UInt = 1U << 4
let varc_flag_have_translate_y : UInt = 1U << 5
let varc_flag_have_rotation : UInt = 1U << 6
let varc_flag_have_condition : UInt = 1U << 7
let varc_flag_have_scale_x : UInt = 1U << 8
let varc_flag_have_scale_y : UInt = 1U << 9
let varc_flag_have_tcenter_x : UInt = 1U << 10
let varc_flag_have_tcenter_y : UInt = 1U << 11
let varc_flag_gid_is_24bit : UInt = 1U << 12
let varc_flag_have_skew_x : UInt = 1U << 13
let varc_flag_have_skew_y : UInt = 1U << 14
let varc_flag_reserved_mask : UInt = 0xFFFF8000U

fn read_u32var(bytes : Array[Byte], offset : Int) -> Result[(UInt, Int), SubsetError] {
  if offset < 0 || offset >= bytes.length() {
    return Err(InvalidInput("invalid VARC u32var offset"))
  }
  let b0 = bytes[offset].to_uint()
  if b0 < 0x80U {
    return Ok((b0, 1))
  }
  if b0 < 0xC0U {
    if offset + 2 > bytes.length() {
      return Err(InvalidInput("invalid VARC u32var bounds"))
    }
    let b1 = bytes[offset + 1].to_uint()
    let value = ((b0 & 0x3FU) << 8) | b1
    return Ok((value, 2))
  }
  if b0 < 0xE0U {
    if offset + 3 > bytes.length() {
      return Err(InvalidInput("invalid VARC u32var bounds"))
    }
    let b1 = bytes[offset + 1].to_uint()
    let b2 = bytes[offset + 2].to_uint()
    let value = ((b0 & 0x1FU) << 16) | (b1 << 8) | b2
    return Ok((value, 3))
  }
  if b0 < 0xF0U {
    if offset + 4 > bytes.length() {
      return Err(InvalidInput("invalid VARC u32var bounds"))
    }
    let b1 = bytes[offset + 1].to_uint()
    let b2 = bytes[offset + 2].to_uint()
    let b3 = bytes[offset + 3].to_uint()
    let value = ((b0 & 0x0FU) << 24) | (b1 << 16) | (b2 << 8) | b3
    return Ok((value, 4))
  }
  if offset + 5 > bytes.length() {
    return Err(InvalidInput("invalid VARC u32var bounds"))
  }
  let b1 = bytes[offset + 1].to_uint()
  let b2 = bytes[offset + 2].to_uint()
  let b3 = bytes[offset + 3].to_uint()
  let b4 = bytes[offset + 4].to_uint()
  let value = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
  Ok((value, 5))
}

fn read_glyph_id_24(bytes : Array[Byte], offset : Int) -> Result[Int, SubsetError] {
  if offset < 0 || offset + 3 > bytes.length() {
    return Err(InvalidInput("invalid VARC glyph bounds"))
  }
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  let b2 = bytes[offset + 2].to_int()
  Ok((b0 << 16) | (b1 << 8) | b2)
}

fn count_tuple_values(data : Array[Byte]) -> Result[Int, SubsetError] {
  let mut pos = 0
  let mut count = 0
  while pos < data.length() {
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x3F) + 1
    let mode = control & 0xC0
    let bytes_per =
      if mode == 0x80 {
        0
      } else if mode == 0x40 {
        2
      } else if mode == 0xC0 {
        4
      } else {
        1
      }
    let needed = run_count * bytes_per
    if pos + needed > data.length() {
      return Err(InvalidInput("invalid VARC tuple values"))
    }
    pos = pos + needed
    count = count + run_count
  }
  Ok(count)
}

fn skip_tuple_values(
  data : Array[Byte],
  offset : Int,
  count : Int,
) -> Result[Int, SubsetError] {
  if count < 0 {
    return Err(InvalidInput("invalid VARC tuple count"))
  }
  let mut pos = offset
  let mut seen = 0
  while seen < count {
    if pos >= data.length() {
      return Err(InvalidInput("invalid VARC tuple data"))
    }
    let control = data[pos].to_int()
    pos = pos + 1
    let run_count = (control & 0x3F) + 1
    let mode = control & 0xC0
    let bytes_per =
      if mode == 0x80 {
        0
      } else if mode == 0x40 {
        2
      } else if mode == 0xC0 {
        4
      } else {
        1
      }
    let needed = run_count * bytes_per
    if pos + needed > data.length() {
      return Err(InvalidInput("invalid VARC tuple data"))
    }
    pos = pos + needed
    seen = seen + run_count
  }
  Ok(pos - offset)
}

fn axis_indices_count(
  index : @ot_cff.CffIndex,
  axis_index : Int,
) -> Result[Int, SubsetError] {
  let bytes = match index.item_bytes(axis_index) {
    Err(err) => return Err(Cff(err))
    Ok(value) => value
  }
  count_tuple_values(bytes.to_array())
}

fn offset_size_for(value : Int) -> Result[Int, SubsetError] {
  if value <= 0 {
    return Err(InvalidInput("invalid VARC index size"))
  }
  if value <= 0xFF {
    return Ok(1)
  }
  if value <= 0xFFFF {
    return Ok(2)
  }
  if value <= 0xFFFFFF {
    return Ok(3)
  }
  if value <= 0x7FFFFFFF {
    return Ok(4)
  }
  Err(InvalidInput("invalid VARC index size"))
}

fn push_offset(bytes : Array[Byte], value : Int, size : Int) -> Result[Unit, SubsetError] {
  if value < 0 || size <= 0 || size > 4 {
    return Err(InvalidInput("invalid VARC index offset"))
  }
  for i in 0..<size {
    let shift = (size - 1 - i) * 8
    bytes.push(((value >> shift) & 0xff).to_byte())
  }
  Ok(())
}

fn write_cff2_index(items : Array[Bytes]) -> Result[Bytes, SubsetError] {
  let out : Array[Byte] = []
  let count = items.length()
  push_u32(out, count)
  if count == 0 {
    return Ok(Bytes::from_array(out))
  }
  let offsets : Array[Int] = []
  let mut current = 1
  offsets.push(current)
  for item in items {
    current = current + item.length()
    offsets.push(current)
  }
  let off_size = match offset_size_for(current) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  out.push(off_size.to_byte())
  for off in offsets {
    match push_offset(out, off, off_size) {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  for item in items {
    for b in item {
      out.push(b)
    }
  }
  Ok(Bytes::from_array(out))
}

fn rewrite_varc_record(
  record : Bytes,
  plan : SubsetPlan,
  axis_indices : @ot_cff.CffIndex?,
) -> Result[Bytes?, SubsetError] {
  let data = record.to_array()
  let out : Array[Byte] = []
  let mut pos = 0
  while pos < data.length() {
    let (flags, size) = match read_u32var(data, pos) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mut cursor = pos + size
    let glyph_pos = cursor
    let is_24 = (flags & varc_flag_gid_is_24bit) != 0U
    let glyph =
      if is_24 {
        match read_glyph_id_24(data, cursor) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      } else {
        match read_u16(data, cursor) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      }
    cursor = cursor + (if is_24 { 3 } else { 2 })
    if (flags & varc_flag_have_condition) != 0U {
      let (_, skip) = match read_u32var(data, cursor) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      cursor = cursor + skip
    }
    if (flags & varc_flag_have_axes) != 0U {
      let (axis_index, skip) = match read_u32var(data, cursor) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      cursor = cursor + skip
      let axis_index = axis_index.reinterpret_as_int()
      if axis_index < 0 {
        return Err(InvalidInput("invalid VARC axis index"))
      }
      let axis_count = match axis_indices {
        None => return Err(InvalidInput("missing VARC axis indices"))
        Some(index) => match axis_indices_count(index, axis_index) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      }
      let consumed = match skip_tuple_values(data, cursor, axis_count) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      cursor = cursor + consumed
    }
    if (flags & varc_flag_axis_values_have_variation) != 0U {
      let (_, skip) = match read_u32var(data, cursor) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      cursor = cursor + skip
    }
    if (flags & varc_flag_transform_has_variation) != 0U {
      let (_, skip) = match read_u32var(data, cursor) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      cursor = cursor + skip
    }
    if (flags & varc_flag_have_translate_x) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_translate_y) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_rotation) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_scale_x) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_scale_y) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_skew_x) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_skew_y) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_tcenter_x) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    if (flags & varc_flag_have_tcenter_y) != 0U {
      if cursor + 2 > data.length() {
        return Err(InvalidInput("invalid VARC transform"))
      }
      cursor = cursor + 2
    }
    let mut reserved = flags & varc_flag_reserved_mask
    while reserved != 0U {
      let (_, skip) = match read_u32var(data, cursor) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      cursor = cursor + skip
      reserved = reserved & (reserved - 1U)
    }
    if cursor <= pos {
      return Err(InvalidInput("invalid VARC component bounds"))
    }
    let new_gid =
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        -1
      } else {
        plan.old_to_new[glyph]
      }
    if new_gid >= 0 {
      if !is_24 && new_gid > 0xFFFF {
        return Err(InvalidInput("VARC glyph id overflow"))
      }
      let component : Array[Byte] = []
      for idx in pos..<cursor {
        component.push(data[idx])
      }
      let rel = glyph_pos - pos
      if is_24 {
        write_u24(component, rel, new_gid)
      } else {
        write_u16(component, rel, new_gid)
      }
      for b in component {
        out.push(b)
      }
    }
    pos = cursor
  }
  if out.is_empty() {
    return Ok(None)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_varc_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_varc) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let data = blob.as_view().to_bytes()
      let bytes = data.to_array()
      if bytes.length() < 24 {
        return Err(InvalidInput("invalid VARC table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let major = (version >> 16) & 0xFFFF
      if major != 1 {
        return Ok(None)
      }
      let coverage_offset = match read_u32(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let var_store_offset = match read_u32(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let condition_list_offset = match read_u32(bytes, 12) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let axis_indices_offset = match read_u32(bytes, 16) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let glyph_records_offset = match read_u32(bytes, 20) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if coverage_offset <= 0 || glyph_records_offset <= 0 {
        return Ok(None)
      }
      if coverage_offset >= bytes.length() || glyph_records_offset >= bytes.length() {
        return Err(InvalidInput("invalid VARC offsets"))
      }
      let coverage = match parse_coverage_subset(bytes, coverage_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if coverage.is_empty() {
        return Ok(None)
      }
      let records_index = match @ot_cff.parse_cff2_index(data[:], glyph_records_offset) {
        Err(err) => return Err(Cff(err))
        Ok(value) => value
      }
      if coverage.length() > records_index.count {
        return Err(InvalidInput("invalid VARC record count"))
      }
      let axis_indices =
        if axis_indices_offset == 0 {
          None
        } else {
          if axis_indices_offset >= bytes.length() {
            return Err(InvalidInput("invalid VARC axis indices"))
          }
          match @ot_cff.parse_cff2_index(data[:], axis_indices_offset) {
            Err(err) => return Err(Cff(err))
            Ok(value) => Some(value)
          }
        }
      let new_glyphs : Array[Int] = []
      let new_records : Array[Bytes] = []
      for i in 0..<coverage.length() {
        let old_gid = coverage[i]
        if old_gid < 0 || old_gid >= plan.old_to_new.length() {
          continue
        }
        let new_gid = plan.old_to_new[old_gid]
        if new_gid < 0 {
          continue
        }
        let record = match records_index.item_bytes(i) {
          Err(err) => return Err(Cff(err))
          Ok(value) => value
        }
        let rewritten = match rewrite_varc_record(record, plan, axis_indices) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        match rewritten {
          None => ()
          Some(record) => {
            new_glyphs.push(new_gid)
            new_records.push(record)
          }
        }
      }
      if new_glyphs.is_empty() {
        return Ok(None)
      }
      let coverage_bytes = build_coverage_subset(new_glyphs)
      let glyph_records_bytes = match write_cff2_index(new_records) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let offsets : Array[Int] = []
      offsets.push(coverage_offset)
      offsets.push(glyph_records_offset)
      if var_store_offset > 0 {
        offsets.push(var_store_offset)
      }
      if condition_list_offset > 0 {
        offsets.push(condition_list_offset)
      }
      if axis_indices_offset > 0 {
        offsets.push(axis_indices_offset)
      }
      offsets.push(bytes.length())
      offsets.sort()
      let segment_bytes = (offset : Int) => {
        let mut next = bytes.length()
        for off in offsets {
          if off > offset && off < next {
            next = off
          }
        }
        if offset < 0 || next <= offset || next > bytes.length() {
          return Err(InvalidInput("invalid VARC segment bounds"))
        }
        Ok(bytes[offset:next].to_array())
      }
      let condition_bytes =
        if condition_list_offset > 0 {
          match segment_bytes(condition_list_offset) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
        } else {
          []
        }
      let axis_bytes =
        if axis_indices_offset > 0 {
          match segment_bytes(axis_indices_offset) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
        } else {
          []
        }
      let var_store_bytes =
        if var_store_offset > 0 {
          match segment_bytes(var_store_offset) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
        } else {
          []
        }
      let out : Array[Byte] = []
      push_u32(out, version)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      push_u32(out, 0)
      let mut cursor = 24
      write_u32(out, 4, cursor)
      for b in coverage_bytes {
        out.push(b)
      }
      cursor = cursor + coverage_bytes.length()
      if !condition_bytes.is_empty() {
        write_u32(out, 12, cursor)
        for b in condition_bytes {
          out.push(b)
        }
        cursor = cursor + condition_bytes.length()
      }
      if !axis_bytes.is_empty() {
        write_u32(out, 16, cursor)
        for b in axis_bytes {
          out.push(b)
        }
        cursor = cursor + axis_bytes.length()
      }
      write_u32(out, 20, cursor)
      for b in glyph_records_bytes {
        out.push(b)
      }
      cursor = cursor + glyph_records_bytes.length()
      if !var_store_bytes.is_empty() {
        write_u32(out, 8, cursor)
        for b in var_store_bytes {
          out.push(b)
        }
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn class_def_value_subset(
  bytes : Array[Byte],
  offset : Int,
  glyph : Int,
) -> Result[Int, SubsetError] {
  let format = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format == 1 {
    let start = match read_u16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let count = match read_u16(bytes, offset + 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if glyph < start || glyph >= start + count {
      return Ok(0)
    }
    let idx = glyph - start
    let value = match read_u16(bytes, offset + 6 + idx * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    Ok(value)
  } else if format == 2 {
    let count = match read_u16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mut record_offset = offset + 4
    for _ in 0..<count {
      let start = match read_u16(bytes, record_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let end = match read_u16(bytes, record_offset + 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let class_value = match read_u16(bytes, record_offset + 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if glyph >= start && glyph <= end {
        return Ok(class_value)
      }
      record_offset = record_offset + 6
    }
    Ok(0)
  } else {
    Err(InvalidInput("unsupported class def format"))
  }
}

fn build_class_def_subset(
  bytes : Array[Byte],
  offset : Int,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let glyph_count = plan.glyphs.length()
  if glyph_count <= 0 {
    return Ok(None)
  }
  let class_values : Array[Int] = []
  for i in 0..<glyph_count {
    let old_gid = plan.glyphs[i].reinterpret_as_int()
    let class_value = match class_def_value_subset(bytes, offset, old_gid) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    class_values.push(class_value)
  }
  Ok(build_class_def_from_values(class_values, false))
}

fn build_class_def_from_values(
  class_values : Array[Int],
  allow_empty : Bool,
) -> Bytes? {
  if class_values.is_empty() {
    return None
  }
  let mut first_non_zero = -1
  let mut last_non_zero = -1
  for i in 0..<class_values.length() {
    if class_values[i] != 0 {
      if first_non_zero < 0 {
        first_non_zero = i
      }
      last_non_zero = i
    }
  }
  if first_non_zero < 0 {
    if !allow_empty {
      return None
    }
    let out : Array[Byte] = []
    push_u16(out, 2)
    push_u16(out, 0)
    return Some(Bytes::from_array(out))
  }
  let start = first_non_zero
  let end = last_non_zero
  let count = end - start + 1
  let format1 : Array[Byte] = []
  push_u16(format1, 1)
  push_u16(format1, start)
  push_u16(format1, count)
  for i in start..<(end + 1) {
    push_u16(format1, class_values[i])
  }
  let ranges : Array[(Int, Int, Int)] = []
  let mut idx = 0
  while idx < class_values.length() {
    let value = class_values[idx]
    if value == 0 {
      idx = idx + 1
      continue
    }
    let mut range_end = idx
    while range_end + 1 < class_values.length() &&
          class_values[range_end + 1] == value {
      range_end = range_end + 1
    }
    ranges.push((idx, range_end, value))
    idx = range_end + 1
  }
  let format2 : Array[Byte] = []
  push_u16(format2, 2)
  push_u16(format2, ranges.length())
  for range in ranges {
    let (range_start, range_end, value) = range
    push_u16(format2, range_start)
    push_u16(format2, range_end)
    push_u16(format2, value)
  }
  if format2.length() < format1.length() {
    Some(Bytes::from_array(format2))
  } else {
    Some(Bytes::from_array(format1))
  }
}

fn parse_coverage_subset(
  bytes : Array[Byte],
  offset : Int,
) -> Result[Array[Int], SubsetError] {
  let format = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format == 1 {
    let count = match read_u16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let glyphs : Array[Int] = []
    for i in 0..<count {
      let glyph = match read_u16(bytes, offset + 4 + i * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      glyphs.push(glyph)
    }
    Ok(glyphs)
  } else if format == 2 {
    let count = match read_u16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let glyphs : Array[Int] = []
    let mut record_offset = offset + 4
    for _ in 0..<count {
      let start = match read_u16(bytes, record_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let end = match read_u16(bytes, record_offset + 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      for glyph in start..=end {
        glyphs.push(glyph)
      }
      record_offset = record_offset + 6
    }
    Ok(glyphs)
  } else {
    Err(InvalidInput("unsupported coverage format"))
  }
}

fn build_coverage_subset(glyphs : Array[Int]) -> Bytes {
  let sorted : Array[Int] = []
  for glyph in glyphs {
    sorted.push(glyph)
  }
  sorted.sort()
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, sorted.length())
  for glyph in sorted {
    push_u16(out, glyph)
  }
  Bytes::from_array(out)
}

fn gpos_value_record_size(value_format : Int) -> Int {
  let mut size = 0
  if (value_format & 0x0001) != 0 {
    size = size + 2
  }
  if (value_format & 0x0002) != 0 {
    size = size + 2
  }
  if (value_format & 0x0004) != 0 {
    size = size + 2
  }
  if (value_format & 0x0008) != 0 {
    size = size + 2
  }
  if (value_format & 0x0010) != 0 {
    size = size + 2
  }
  if (value_format & 0x0020) != 0 {
    size = size + 2
  }
  if (value_format & 0x0040) != 0 {
    size = size + 2
  }
  if (value_format & 0x0080) != 0 {
    size = size + 2
  }
  size
}

fn build_anchor_bytes_optional(
  bytes : Array[Byte],
  offset : Int,
) -> Result[Bytes?, SubsetError] {
  if offset == 0 {
    return Ok(None)
  }
  if offset < 0 || offset + 6 > bytes.length() {
    return Err(InvalidInput("invalid GPOS anchor offset"))
  }
  let format = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format == 1 {
    let anchor_bytes = bytes[offset:offset + 6].to_array()
    return Ok(Some(Bytes::from_array(anchor_bytes)))
  }
  if format == 2 {
    if offset + 8 > bytes.length() {
      return Err(InvalidInput("invalid GPOS anchor format2 bounds"))
    }
    let anchor_bytes = bytes[offset:offset + 8].to_array()
    return Ok(Some(Bytes::from_array(anchor_bytes)))
  }
  Ok(None)
}

fn build_mark_glyph_sets_subset(
  bytes : Array[Byte],
  offset : Int,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let format = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let set_count = match read_u16(bytes, offset + 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if set_count < 0 {
    return Err(InvalidInput("invalid mark glyph set count"))
  }
  let offsets_base = offset + 4
  let coverages : Array[Bytes] = []
  let mut any_nonempty = false
  for i in 0..<set_count {
    let cov_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if cov_offset == 0 {
      coverages.push(build_coverage_subset([]))
      continue
    }
    let cov_base = offset + cov_offset
    let glyphs = match parse_coverage_subset(bytes, cov_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mapped : Array[Int] = []
    for glyph in glyphs {
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_gid = plan.old_to_new[glyph]
      if new_gid >= 0 {
        mapped.push(new_gid)
      }
    }
    if !mapped.is_empty() {
      any_nonempty = true
    }
    coverages.push(build_coverage_subset(mapped))
  }
  if !any_nonempty {
    return Ok(None)
  }
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, set_count)
  let mut cursor = 4 + set_count * 2
  let offsets : Array[Int] = []
  for coverage in coverages {
    offsets.push(cursor)
    cursor = cursor + coverage.length()
  }
  for offset_value in offsets {
    push_u16(out, offset_value)
  }
  for coverage in coverages {
    for b in coverage {
      out.push(b)
    }
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_coverage_from_pairs(
  pairs : Array[(Int, Int)],
) -> (Bytes, Array[Int]) {
  pairs.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let substitutes : Array[Int] = []
  for pair in pairs {
    let (gid, sub) = pair
    glyphs.push(gid)
    substitutes.push(sub)
  }
  (build_coverage_subset(glyphs), substitutes)
}

fn build_gsub_single_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 6 {
    return Err(InvalidInput("invalid GSUB subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 {
    return Err(InvalidInput("invalid GSUB coverage offset"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let pairs : Array[(Int, Int)] = []
  if format == 1 {
    let delta = match read_i16(bytes, 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    for glyph in coverage {
      let out_glyph = glyph + delta
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      if out_glyph < 0 || out_glyph >= plan.old_to_new.length() {
        continue
      }
      let new_in = plan.old_to_new[glyph]
      let new_out = plan.old_to_new[out_glyph]
      if new_in >= 0 && new_out >= 0 {
        pairs.push((new_in, new_out))
      }
    }
  } else if format == 2 {
    let glyph_count = match read_u16(bytes, 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if glyph_count < 0 || glyph_count != coverage.length() {
      return Err(InvalidInput("GSUB single glyph count mismatch"))
    }
    let subs_base = 6
    if subs_base + glyph_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB substitute array"))
    }
    for i in 0..<glyph_count {
      let glyph = coverage[i]
      let sub = match read_u16(bytes, subs_base + i * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      if sub < 0 || sub >= plan.old_to_new.length() {
        continue
      }
      let new_in = plan.old_to_new[glyph]
      let new_out = plan.old_to_new[sub]
      if new_in >= 0 && new_out >= 0 {
        pairs.push((new_in, new_out))
      }
    }
  } else {
    return Ok(None)
  }
  if pairs.is_empty() {
    return Ok(None)
  }
  let (coverage_bytes, substitutes) = build_coverage_from_pairs(pairs)
  let out : Array[Byte] = []
  push_u16(out, 2)
  let coverage_offset = 6 + substitutes.length() * 2
  push_u16(out, coverage_offset)
  push_u16(out, substitutes.length())
  for sub in substitutes {
    push_u16(out, sub)
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gsub_multiple_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GSUB multiple subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let seq_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || seq_count < 0 {
    return Err(InvalidInput("invalid GSUB multiple header"))
  }
  let offsets_base = 6
  if offsets_base + seq_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB multiple offsets"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != seq_count {
    return Err(InvalidInput("GSUB multiple coverage count mismatch"))
  }
  let pairs : Array[(Int, Array[Int])] = []
  for i in 0..<seq_count {
    let glyph = coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_in = plan.old_to_new[glyph]
    if new_in < 0 {
      continue
    }
    let seq_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if seq_offset <= 0 {
      continue
    }
    let seq_base = seq_offset
    if seq_base < 0 || seq_base + 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB sequence offset"))
    }
    let glyph_count = match read_u16(bytes, seq_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if glyph_count <= 0 {
      continue
    }
    if seq_base + 2 + glyph_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB sequence length"))
    }
    let sequence : Array[Int] = []
    let mut ok = true
    for j in 0..<glyph_count {
      let sub = match read_u16(bytes, seq_base + 2 + j * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if sub < 0 || sub >= plan.old_to_new.length() {
        ok = false
        break
      }
      let new_sub = plan.old_to_new[sub]
      if new_sub < 0 {
        ok = false
        break
      }
      sequence.push(new_sub)
    }
    if ok && !sequence.is_empty() {
      pairs.push((new_in, sequence))
    }
  }
  if pairs.is_empty() {
    return Ok(None)
  }
  pairs.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let sequences : Array[Bytes] = []
  for pair in pairs {
    let (gid, seq) = pair
    glyphs.push(gid)
    let seq_bytes : Array[Byte] = []
    push_u16(seq_bytes, seq.length())
    for value in seq {
      push_u16(seq_bytes, value)
    }
    sequences.push(Bytes::from_array(seq_bytes))
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 6 + sequences.length() * 2
  let mut cursor = header_len
  let offsets : Array[Int] = []
  for seq in sequences {
    offsets.push(cursor)
    cursor = cursor + seq.length()
  }
  let coverage_offset = cursor
  push_u16(out, coverage_offset)
  push_u16(out, sequences.length())
  for offset in offsets {
    push_u16(out, offset)
  }
  for seq in sequences {
    for b in seq {
      out.push(b)
    }
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gsub_alternate_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GSUB alternate subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let alt_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || alt_count < 0 {
    return Err(InvalidInput("invalid GSUB alternate header"))
  }
  let offsets_base = 6
  if offsets_base + alt_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB alternate offsets"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != alt_count {
    return Err(InvalidInput("GSUB alternate coverage count mismatch"))
  }
  let pairs : Array[(Int, Array[Int])] = []
  for i in 0..<alt_count {
    let glyph = coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_in = plan.old_to_new[glyph]
    if new_in < 0 {
      continue
    }
    let alt_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if alt_offset <= 0 {
      continue
    }
    let alt_base = alt_offset
    if alt_base < 0 || alt_base + 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB alternate set offset"))
    }
    let glyph_count = match read_u16(bytes, alt_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if glyph_count <= 0 {
      continue
    }
    if alt_base + 2 + glyph_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB alternate set length"))
    }
    let alternates : Array[Int] = []
    for j in 0..<glyph_count {
      let alt = match read_u16(bytes, alt_base + 2 + j * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if alt < 0 || alt >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_alt = plan.old_to_new[alt]
      if new_alt >= 0 {
        alternates.push(new_alt)
      }
    }
    if !alternates.is_empty() {
      pairs.push((new_in, alternates))
    }
  }
  if pairs.is_empty() {
    return Ok(None)
  }
  pairs.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let alt_sets : Array[Bytes] = []
  for pair in pairs {
    let (gid, alternates) = pair
    glyphs.push(gid)
    let alt_bytes : Array[Byte] = []
    push_u16(alt_bytes, alternates.length())
    for value in alternates {
      push_u16(alt_bytes, value)
    }
    alt_sets.push(Bytes::from_array(alt_bytes))
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 6 + alt_sets.length() * 2
  let mut cursor = header_len
  let offsets : Array[Int] = []
  for alt_set in alt_sets {
    offsets.push(cursor)
    cursor = cursor + alt_set.length()
  }
  let coverage_offset = cursor
  push_u16(out, coverage_offset)
  push_u16(out, alt_sets.length())
  for offset in offsets {
    push_u16(out, offset)
  }
  for alt_set in alt_sets {
    for b in alt_set {
      out.push(b)
    }
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gsub_ligature_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GSUB ligature subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let set_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || set_count < 0 {
    return Err(InvalidInput("invalid GSUB ligature header"))
  }
  let offsets_base = 6
  if offsets_base + set_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB ligature offsets"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != set_count {
    return Err(InvalidInput("GSUB ligature coverage count mismatch"))
  }
  let pairs : Array[(Int, Array[(Int, Array[Int])])] = []
  for i in 0..<set_count {
    let glyph = coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_in = plan.old_to_new[glyph]
    if new_in < 0 {
      continue
    }
    let set_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if set_offset <= 0 {
      continue
    }
    let set_base = set_offset
    if set_base < 0 || set_base + 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB ligature set offset"))
    }
    let lig_count = match read_u16(bytes, set_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if lig_count <= 0 {
      continue
    }
    if set_base + 2 + lig_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB ligature set length"))
    }
    let ligatures : Array[(Int, Array[Int])] = []
    for j in 0..<lig_count {
      let lig_offset = match read_u16(bytes, set_base + 2 + j * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if lig_offset <= 0 {
        continue
      }
      let lig_base = set_base + lig_offset
      if lig_base < 0 || lig_base + 4 > bytes.length() {
        return Err(InvalidInput("invalid GSUB ligature offset"))
      }
      let lig_glyph = match read_u16(bytes, lig_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let comp_count = match read_u16(bytes, lig_base + 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if comp_count <= 1 {
        continue
      }
      let comp_len = comp_count - 1
      if lig_base + 4 + comp_len * 2 > bytes.length() {
        return Err(InvalidInput("invalid GSUB ligature components"))
      }
      if lig_glyph < 0 || lig_glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_lig = plan.old_to_new[lig_glyph]
      if new_lig < 0 {
        continue
      }
      let components : Array[Int] = []
      let mut ok = true
      for k in 0..<comp_len {
        let comp = match read_u16(bytes, lig_base + 4 + k * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if comp < 0 || comp >= plan.old_to_new.length() {
          ok = false
          break
        }
        let new_comp = plan.old_to_new[comp]
        if new_comp < 0 {
          ok = false
          break
        }
        components.push(new_comp)
      }
      if ok {
        ligatures.push((new_lig, components))
      }
    }
    if !ligatures.is_empty() {
      pairs.push((new_in, ligatures))
    }
  }
  if pairs.is_empty() {
    return Ok(None)
  }
  pairs.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let lig_sets : Array[Bytes] = []
  for pair in pairs {
    let (gid, ligatures) = pair
    glyphs.push(gid)
    let set_bytes : Array[Byte] = []
    push_u16(set_bytes, ligatures.length())
    let mut cursor = 2 + ligatures.length() * 2
    let offsets : Array[Int] = []
    let lig_bytes_list : Array[Bytes] = []
    for ligature in ligatures {
      let (lig_gid, components) = ligature
      let lig_bytes : Array[Byte] = []
      push_u16(lig_bytes, lig_gid)
      push_u16(lig_bytes, components.length() + 1)
      for comp in components {
        push_u16(lig_bytes, comp)
      }
      let lig_blob = Bytes::from_array(lig_bytes)
      offsets.push(cursor)
      cursor = cursor + lig_blob.length()
      lig_bytes_list.push(lig_blob)
    }
    for offset in offsets {
      push_u16(set_bytes, offset)
    }
    for lig_blob in lig_bytes_list {
      for b in lig_blob {
        set_bytes.push(b)
      }
    }
    lig_sets.push(Bytes::from_array(set_bytes))
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 6 + lig_sets.length() * 2
  let mut cursor = header_len
  let offsets : Array[Int] = []
  for set_bytes in lig_sets {
    offsets.push(cursor)
    cursor = cursor + set_bytes.length()
  }
  let coverage_offset = cursor
  push_u16(out, coverage_offset)
  push_u16(out, lig_sets.length())
  for offset in offsets {
    push_u16(out, offset)
  }
  for set_bytes in lig_sets {
    for b in set_bytes {
      out.push(b)
    }
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gsub_contextual_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GSUB contextual subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let set_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || set_count < 0 {
    return Err(InvalidInput("invalid GSUB contextual header"))
  }
  let offsets_base = 6
  if offsets_base + set_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB contextual offsets"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != set_count {
    return Err(InvalidInput("GSUB contextual coverage count mismatch"))
  }
  let pairs : Array[(Int, Bytes)] = []
  for i in 0..<set_count {
    let glyph = coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_in = plan.old_to_new[glyph]
    if new_in < 0 {
      continue
    }
    let set_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if set_offset <= 0 {
      continue
    }
    let set_base = set_offset
    if set_base < 0 || set_base + 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB contextual set offset"))
    }
    let rule_count = match read_u16(bytes, set_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if rule_count <= 0 {
      continue
    }
    if set_base + 2 + rule_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB contextual set length"))
    }
    let rule_bytes_list : Array[Bytes] = []
    for j in 0..<rule_count {
      let rule_offset = match read_u16(bytes, set_base + 2 + j * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if rule_offset <= 0 {
        continue
      }
      let rule_base = set_base + rule_offset
      if rule_base < 0 || rule_base + 4 > bytes.length() {
        return Err(InvalidInput("invalid GSUB contextual rule offset"))
      }
      let glyph_count = match read_u16(bytes, rule_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let subst_count = match read_u16(bytes, rule_base + 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if glyph_count <= 0 {
        continue
      }
      let input_len = glyph_count - 1
      let input_base = rule_base + 4
      let records_base = input_base + input_len * 2
      if records_base + subst_count * 4 > bytes.length() {
        return Err(InvalidInput("invalid GSUB contextual rule length"))
      }
      if input_base + input_len * 2 > bytes.length() {
        return Err(InvalidInput("invalid GSUB contextual input length"))
      }
      let inputs : Array[Int] = []
      let mut ok = true
      for k in 0..<input_len {
        let input_gid = match read_u16(bytes, input_base + k * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if input_gid < 0 || input_gid >= plan.old_to_new.length() {
          ok = false
          break
        }
        let new_input = plan.old_to_new[input_gid]
        if new_input < 0 {
          ok = false
          break
        }
        inputs.push(new_input)
      }
      if !ok {
        continue
      }
      let rule_bytes : Array[Byte] = []
      push_u16(rule_bytes, glyph_count)
      push_u16(rule_bytes, subst_count)
      for input in inputs {
        push_u16(rule_bytes, input)
      }
      for k in 0..<subst_count {
        let record_base = records_base + k * 4
        let seq_index = match read_u16(bytes, record_base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let lookup_index = match read_u16(bytes, record_base + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        push_u16(rule_bytes, seq_index)
        push_u16(rule_bytes, lookup_index)
      }
      rule_bytes_list.push(Bytes::from_array(rule_bytes))
    }
    if !rule_bytes_list.is_empty() {
      let set_bytes : Array[Byte] = []
      push_u16(set_bytes, rule_bytes_list.length())
      let mut cursor = 2 + rule_bytes_list.length() * 2
      let offsets : Array[Int] = []
      for rule_bytes in rule_bytes_list {
        offsets.push(cursor)
        cursor = cursor + rule_bytes.length()
      }
      for offset in offsets {
        push_u16(set_bytes, offset)
      }
      for rule_bytes in rule_bytes_list {
        for b in rule_bytes {
          set_bytes.push(b)
        }
      }
      pairs.push((new_in, Bytes::from_array(set_bytes)))
    }
  }
  if pairs.is_empty() {
    return Ok(None)
  }
  pairs.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let sets : Array[Bytes] = []
  for pair in pairs {
    let (gid, set_bytes) = pair
    glyphs.push(gid)
    sets.push(set_bytes)
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 6 + sets.length() * 2
  let mut cursor = header_len
  let offsets : Array[Int] = []
  for set_bytes in sets {
    offsets.push(cursor)
    cursor = cursor + set_bytes.length()
  }
  let coverage_offset = cursor
  push_u16(out, coverage_offset)
  push_u16(out, sets.length())
  for offset in offsets {
    push_u16(out, offset)
  }
  for set_bytes in sets {
    for b in set_bytes {
      out.push(b)
    }
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gsub_chaining_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GSUB chaining subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let set_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || set_count < 0 {
    return Err(InvalidInput("invalid GSUB chaining header"))
  }
  let offsets_base = 6
  if offsets_base + set_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB chaining offsets"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != set_count {
    return Err(InvalidInput("GSUB chaining coverage count mismatch"))
  }
  let pairs : Array[(Int, Bytes)] = []
  for i in 0..<set_count {
    let glyph = coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_in = plan.old_to_new[glyph]
    if new_in < 0 {
      continue
    }
    let set_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if set_offset <= 0 {
      continue
    }
    let set_base = set_offset
    if set_base < 0 || set_base + 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB chaining set offset"))
    }
    let rule_count = match read_u16(bytes, set_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if rule_count <= 0 {
      continue
    }
    if set_base + 2 + rule_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GSUB chaining set length"))
    }
    let rule_bytes_list : Array[Bytes] = []
    for j in 0..<rule_count {
      let rule_offset = match read_u16(bytes, set_base + 2 + j * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if rule_offset <= 0 {
        continue
      }
      let rule_base = set_base + rule_offset
      if rule_base < 0 || rule_base + 2 > bytes.length() {
        return Err(InvalidInput("invalid GSUB chaining rule offset"))
      }
      let backtrack_count = match read_u16(bytes, rule_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let backtrack_base = rule_base + 2
      let input_count_offset = backtrack_base + backtrack_count * 2
      if input_count_offset + 2 > bytes.length() {
        return Err(InvalidInput("invalid GSUB chaining backtrack length"))
      }
      let input_count = match read_u16(bytes, input_count_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if input_count <= 0 {
        continue
      }
      let input_base = input_count_offset + 2
      let input_len = input_count - 1
      let lookahead_count_offset = input_base + input_len * 2
      if lookahead_count_offset + 2 > bytes.length() {
        return Err(InvalidInput("invalid GSUB chaining input length"))
      }
      let lookahead_count = match read_u16(bytes, lookahead_count_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lookahead_base = lookahead_count_offset + 2
      let subst_count_offset = lookahead_base + lookahead_count * 2
      if subst_count_offset + 2 > bytes.length() {
        return Err(InvalidInput("invalid GSUB chaining lookahead length"))
      }
      let subst_count = match read_u16(bytes, subst_count_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let records_base = subst_count_offset + 2
      if records_base + subst_count * 4 > bytes.length() {
        return Err(InvalidInput("invalid GSUB chaining rule length"))
      }
      let mut ok = true
      let backtracks : Array[Int] = []
      for k in 0..<backtrack_count {
        let gid = match read_u16(bytes, backtrack_base + k * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if gid < 0 || gid >= plan.old_to_new.length() {
          ok = false
          break
        }
        let new_gid = plan.old_to_new[gid]
        if new_gid < 0 {
          ok = false
          break
        }
        backtracks.push(new_gid)
      }
      if !ok {
        continue
      }
      let inputs : Array[Int] = []
      for k in 0..<input_len {
        let gid = match read_u16(bytes, input_base + k * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if gid < 0 || gid >= plan.old_to_new.length() {
          ok = false
          break
        }
        let new_gid = plan.old_to_new[gid]
        if new_gid < 0 {
          ok = false
          break
        }
        inputs.push(new_gid)
      }
      if !ok {
        continue
      }
      let lookaheads : Array[Int] = []
      for k in 0..<lookahead_count {
        let gid = match read_u16(bytes, lookahead_base + k * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if gid < 0 || gid >= plan.old_to_new.length() {
          ok = false
          break
        }
        let new_gid = plan.old_to_new[gid]
        if new_gid < 0 {
          ok = false
          break
        }
        lookaheads.push(new_gid)
      }
      if !ok {
        continue
      }
      let rule_bytes : Array[Byte] = []
      push_u16(rule_bytes, backtracks.length())
      for gid in backtracks {
        push_u16(rule_bytes, gid)
      }
      push_u16(rule_bytes, input_count)
      for gid in inputs {
        push_u16(rule_bytes, gid)
      }
      push_u16(rule_bytes, lookaheads.length())
      for gid in lookaheads {
        push_u16(rule_bytes, gid)
      }
      push_u16(rule_bytes, subst_count)
      for k in 0..<subst_count {
        let record_base = records_base + k * 4
        let seq_index = match read_u16(bytes, record_base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let lookup_index = match read_u16(bytes, record_base + 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        push_u16(rule_bytes, seq_index)
        push_u16(rule_bytes, lookup_index)
      }
      rule_bytes_list.push(Bytes::from_array(rule_bytes))
    }
    if !rule_bytes_list.is_empty() {
      let set_bytes : Array[Byte] = []
      push_u16(set_bytes, rule_bytes_list.length())
      let mut cursor = 2 + rule_bytes_list.length() * 2
      let offsets : Array[Int] = []
      for rule_bytes in rule_bytes_list {
        offsets.push(cursor)
        cursor = cursor + rule_bytes.length()
      }
      for offset in offsets {
        push_u16(set_bytes, offset)
      }
      for rule_bytes in rule_bytes_list {
        for b in rule_bytes {
          set_bytes.push(b)
        }
      }
      pairs.push((new_in, Bytes::from_array(set_bytes)))
    }
  }
  if pairs.is_empty() {
    return Ok(None)
  }
  pairs.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let sets : Array[Bytes] = []
  for pair in pairs {
    let (gid, set_bytes) = pair
    glyphs.push(gid)
    sets.push(set_bytes)
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 6 + sets.length() * 2
  let mut cursor = header_len
  let offsets : Array[Int] = []
  for set_bytes in sets {
    offsets.push(cursor)
    cursor = cursor + set_bytes.length()
  }
  let coverage_offset = cursor
  push_u16(out, coverage_offset)
  push_u16(out, sets.length())
  for offset in offsets {
    push_u16(out, offset)
  }
  for set_bytes in sets {
    for b in set_bytes {
      out.push(b)
    }
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gsub_extension_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[(Int, Bytes)?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GSUB extension subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let extension_type = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_offset = match read_u32(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if extension_offset <= 0 {
    return Err(InvalidInput("invalid GSUB extension offset"))
  }
  if extension_offset >= bytes.length() {
    return Err(InvalidInput("invalid GSUB extension bounds"))
  }
  let ext_base = extension_offset
  let ext_bytes = bytes[ext_base:bytes.length()].to_array()
  let mut new_sub : Bytes? = None
  if extension_type == 1 {
    new_sub = match build_gsub_single_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 2 {
    new_sub = match build_gsub_multiple_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 3 {
    new_sub = match build_gsub_alternate_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 4 {
    new_sub = match build_gsub_ligature_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 5 {
    new_sub = match build_gsub_contextual_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 6 {
    new_sub = match build_gsub_chaining_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else {
    return Ok(None)
  }
  match new_sub {
    None => Ok(None)
    Some(value) => Ok(Some((extension_type, value)))
  }
}

fn build_gsub_reverse_chaining_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 12 {
    return Err(InvalidInput("invalid GSUB reverse chaining subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let backtrack_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || backtrack_count < 0 {
    return Err(InvalidInput("invalid GSUB reverse chaining header"))
  }
  let backtrack_base = 6
  let lookahead_count_offset = backtrack_base + backtrack_count * 2
  if lookahead_count_offset + 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB reverse chaining backtrack offsets"))
  }
  let lookahead_count = match read_u16(bytes, lookahead_count_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let lookahead_base = lookahead_count_offset + 2
  let glyph_count_offset = lookahead_base + lookahead_count * 2
  if glyph_count_offset + 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB reverse chaining lookahead offsets"))
  }
  let glyph_count = match read_u16(bytes, glyph_count_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let substitute_base = glyph_count_offset + 2
  if substitute_base + glyph_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GSUB reverse chaining substitutes"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != glyph_count {
    return Err(InvalidInput("GSUB reverse chaining coverage count mismatch"))
  }
  let mut ok = true
  let new_coverage : Array[Int] = []
  let new_subs : Array[Int] = []
  for i in 0..<glyph_count {
    let glyph = coverage[i]
    let sub = match read_u16(bytes, substitute_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if glyph < 0 || glyph >= plan.old_to_new.length() ||
        sub < 0 || sub >= plan.old_to_new.length() {
      ok = false
      break
    }
    let new_glyph = plan.old_to_new[glyph]
    let new_sub = plan.old_to_new[sub]
    if new_glyph < 0 || new_sub < 0 {
      ok = false
      break
    }
    new_coverage.push(new_glyph)
    new_subs.push(new_sub)
  }
  if !ok || new_coverage.is_empty() {
    return Ok(None)
  }
  let new_backtrack : Array[Bytes] = []
  for i in 0..<backtrack_count {
    let offset = match read_u16(bytes, backtrack_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if offset <= 0 || offset >= bytes.length() {
      return Err(InvalidInput("invalid GSUB reverse chaining backtrack offset"))
    }
    let coverage = match parse_coverage_subset(bytes, offset) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mapped : Array[Int] = []
    for glyph in coverage {
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        ok = false
        break
      }
      let new_gid = plan.old_to_new[glyph]
      if new_gid < 0 {
        ok = false
        break
      }
      mapped.push(new_gid)
    }
    if !ok || mapped.is_empty() {
      return Ok(None)
    }
    new_backtrack.push(build_coverage_subset(mapped))
  }
  let new_lookahead : Array[Bytes] = []
  for i in 0..<lookahead_count {
    let offset = match read_u16(bytes, lookahead_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if offset <= 0 || offset >= bytes.length() {
      return Err(InvalidInput("invalid GSUB reverse chaining lookahead offset"))
    }
    let coverage = match parse_coverage_subset(bytes, offset) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mapped : Array[Int] = []
    for glyph in coverage {
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        ok = false
        break
      }
      let new_gid = plan.old_to_new[glyph]
      if new_gid < 0 {
        ok = false
        break
      }
      mapped.push(new_gid)
    }
    if !ok || mapped.is_empty() {
      return Ok(None)
    }
    new_lookahead.push(build_coverage_subset(mapped))
  }
  let coverage_bytes = build_coverage_subset(new_coverage)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 8 + new_backtrack.length() * 2 + new_lookahead.length() * 2 + new_subs.length() * 2
  let mut cursor = header_len
  push_u16(out, cursor)
  push_u16(out, new_backtrack.length())
  for coverage in new_backtrack {
    push_u16(out, cursor)
    cursor = cursor + coverage.length()
  }
  push_u16(out, new_lookahead.length())
  for coverage in new_lookahead {
    push_u16(out, cursor)
    cursor = cursor + coverage.length()
  }
  push_u16(out, new_subs.length())
  for sub in new_subs {
    push_u16(out, sub)
  }
  for b in coverage_bytes {
    out.push(b)
  }
  for coverage in new_backtrack {
    for b in coverage {
      out.push(b)
    }
  }
  for coverage in new_lookahead {
    for b in coverage {
      out.push(b)
    }
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gpos_single_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 6 {
    return Err(InvalidInput("invalid GPOS single subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let value_format = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if (value_format & 0x00f0) != 0 {
    return Ok(None)
  }
  if coverage_offset <= 0 {
    return Err(InvalidInput("invalid GPOS coverage offset"))
  }
  let record_size = gpos_value_record_size(value_format)
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format == 1 {
    let record_base = 6
    if record_base + record_size > bytes.length() {
      return Err(InvalidInput("invalid GPOS value record"))
    }
    let kept : Array[Int] = []
    for glyph in coverage {
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_gid = plan.old_to_new[glyph]
      if new_gid >= 0 {
        kept.push(new_gid)
      }
    }
    if kept.is_empty() {
      return Ok(None)
    }
    let coverage_bytes = build_coverage_subset(kept)
    let out : Array[Byte] = []
    push_u16(out, 1)
    let coverage_offset = 6 + record_size
    push_u16(out, coverage_offset)
    push_u16(out, value_format)
    if record_size > 0 {
      let record_bytes = bytes[record_base:record_base + record_size]
      for b in record_bytes {
        out.push(b)
      }
    }
    for b in coverage_bytes {
      out.push(b)
    }
    Ok(Some(Bytes::from_array(out)))
  } else if format == 2 {
    if bytes.length() < 8 {
      return Err(InvalidInput("invalid GPOS format2 header"))
    }
    let value_count = match read_u16(bytes, 6) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if value_count < 0 || value_count != coverage.length() {
      return Err(InvalidInput("GPOS value count mismatch"))
    }
    let record_base = 8
    if record_base + value_count * record_size > bytes.length() {
      return Err(InvalidInput("invalid GPOS value records"))
    }
    let pairs : Array[(Int, Bytes)] = []
    for i in 0..<value_count {
      let glyph = coverage[i]
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_gid = plan.old_to_new[glyph]
      if new_gid < 0 {
        continue
      }
      let start = record_base + i * record_size
      let record_bytes = bytes[start:start + record_size].to_array()
      pairs.push((new_gid, Bytes::from_array(record_bytes)))
    }
    if pairs.is_empty() {
      return Ok(None)
    }
    pairs.sort_by((a, b) => a.0 - b.0)
    let glyphs : Array[Int] = []
    let records : Array[Bytes] = []
    for pair in pairs {
      let (gid, record_bytes) = pair
      glyphs.push(gid)
      records.push(record_bytes)
    }
    let coverage_bytes = build_coverage_subset(glyphs)
    let out : Array[Byte] = []
    push_u16(out, 2)
    let coverage_offset = 8 + records.length() * record_size
    push_u16(out, coverage_offset)
    push_u16(out, value_format)
    push_u16(out, records.length())
    for record_bytes in records {
      for b in record_bytes {
        out.push(b)
      }
    }
    for b in coverage_bytes {
      out.push(b)
    }
    Ok(Some(Bytes::from_array(out)))
  } else {
    Ok(None)
  }
}

fn build_gpos_pair_format1(
  value_format1 : Int,
  value_format2 : Int,
  records : Array[(Int, Array[(Int, Bytes)])],
) -> Bytes {
  let sorted : Array[(Int, Array[(Int, Bytes)])] = []
  for record in records {
    sorted.push(record)
  }
  sorted.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let pair_sets : Array[Bytes] = []
  for record in sorted {
    let (first_gid, pairs) = record
    glyphs.push(first_gid)
    let sorted_pairs : Array[(Int, Bytes)] = []
    for pair in pairs {
      sorted_pairs.push(pair)
    }
    sorted_pairs.sort_by((a, b) => a.0 - b.0)
    let set_bytes : Array[Byte] = []
    push_u16(set_bytes, sorted_pairs.length())
    for pair in sorted_pairs {
      let (second_gid, record_bytes) = pair
      push_u16(set_bytes, second_gid)
      for b in record_bytes {
        set_bytes.push(b)
      }
    }
    pair_sets.push(Bytes::from_array(set_bytes))
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let out : Array[Byte] = []
  push_u16(out, 1)
  let header_len = 10 + pair_sets.length() * 2
  let mut cursor = header_len
  let offsets : Array[Int] = []
  for set_bytes in pair_sets {
    offsets.push(cursor)
    cursor = cursor + set_bytes.length()
  }
  let coverage_offset = cursor
  push_u16(out, coverage_offset)
  push_u16(out, value_format1)
  push_u16(out, value_format2)
  push_u16(out, pair_sets.length())
  for offset in offsets {
    push_u16(out, offset)
  }
  for set_bytes in pair_sets {
    for b in set_bytes {
      out.push(b)
    }
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Bytes::from_array(out)
}

fn build_gpos_pair_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 10 {
    return Err(InvalidInput("invalid GPOS pair subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let value_format1 = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let value_format2 = match read_u16(bytes, 6) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if ((value_format1 | value_format2) & 0x00f0) != 0 {
    return Ok(None)
  }
  let value_size1 = gpos_value_record_size(value_format1)
  let value_size2 = gpos_value_record_size(value_format2)
  let record_size = value_size1 + value_size2
  if record_size == 0 {
    return Ok(None)
  }
  if coverage_offset <= 0 {
    return Err(InvalidInput("invalid GPOS coverage offset"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format == 1 {
    if bytes.length() < 10 {
      return Err(InvalidInput("invalid GPOS pair format1 header"))
    }
    let pair_set_count = match read_u16(bytes, 8) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if pair_set_count < 0 || pair_set_count != coverage.length() {
      return Err(InvalidInput("GPOS pair set count mismatch"))
    }
    let offsets_base = 10
    if offsets_base + pair_set_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid GPOS pair set offsets"))
    }
    let records : Array[(Int, Array[(Int, Bytes)])] = []
    let pair_record_size = 2 + record_size
    for i in 0..<pair_set_count {
      let glyph = coverage[i]
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_first = plan.old_to_new[glyph]
      let pair_set_offset = match read_u16(bytes, offsets_base + i * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if pair_set_offset <= 0 {
        continue
      }
      let pair_set_base = pair_set_offset
      if pair_set_base < 0 || pair_set_base + 2 > bytes.length() {
        return Err(InvalidInput("invalid GPOS pair set offset"))
      }
      let pair_value_count = match read_u16(bytes, pair_set_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if pair_value_count < 0 {
        return Err(InvalidInput("invalid GPOS pair value count"))
      }
      let record_base = pair_set_base + 2
      if record_base + pair_value_count * pair_record_size > bytes.length() {
        return Err(InvalidInput("invalid GPOS pair value records"))
      }
      let pairs : Array[(Int, Bytes)] = []
      for j in 0..<pair_value_count {
        let entry_base = record_base + j * pair_record_size
        let second_gid = match read_u16(bytes, entry_base) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if second_gid < 0 || second_gid >= plan.old_to_new.length() {
          return Err(InvalidInput("glyph id out of range"))
        }
        let new_second = plan.old_to_new[second_gid]
        if new_second < 0 {
          continue
        }
        let value_start = entry_base + 2
        let value_end = value_start + record_size
        let record_bytes = bytes[value_start:value_end].to_array()
        pairs.push((new_second, Bytes::from_array(record_bytes)))
      }
      if new_first >= 0 && !pairs.is_empty() {
        records.push((new_first, pairs))
      }
    }
    if records.is_empty() {
      return Ok(None)
    }
    return Ok(Some(build_gpos_pair_format1(value_format1, value_format2, records)))
  } else if format == 2 {
    if bytes.length() < 16 {
      return Err(InvalidInput("invalid GPOS pair format2 header"))
    }
    let class_def1_offset = match read_u16(bytes, 8) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let class_def2_offset = match read_u16(bytes, 10) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let class1_count = match read_u16(bytes, 12) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let class2_count = match read_u16(bytes, 14) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if class_def1_offset <= 0 || class_def2_offset <= 0 {
      return Ok(None)
    }
    if class1_count <= 0 || class2_count <= 0 {
      return Ok(None)
    }
    let class1_base = class_def1_offset
    let class2_base = class_def2_offset
    let matrix_base = 16
    let class_record_size = record_size
    let class1_record_size = class2_count * class_record_size
    if matrix_base + class1_count * class1_record_size > bytes.length() {
      return Err(InvalidInput("invalid GPOS class pair records"))
    }
    let coverage_pairs : Array[(Int, Int)] = []
    for glyph in coverage {
      if glyph < 0 || glyph >= plan.old_to_new.length() {
        return Err(InvalidInput("glyph id out of range"))
      }
      let new_gid = plan.old_to_new[glyph]
      if new_gid >= 0 {
        coverage_pairs.push((new_gid, glyph))
      }
    }
    if coverage_pairs.is_empty() {
      return Ok(None)
    }
    coverage_pairs.sort_by((a, b) => a.0 - b.0)
    let coverage_new : Array[Int] = []
    let old_class1_indices : Array[Int] = []
    let class_values1 : Array[Int] = Array::make(plan.glyphs.length(), 0)
    for i in 0..<coverage_pairs.length() {
      let (new_gid, old_gid) = coverage_pairs[i]
      coverage_new.push(new_gid)
      class_values1[new_gid] = i
      let class1 = match class_def_value_subset(bytes, class1_base, old_gid) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let class1_index = if class1 >= class1_count { 0 } else { class1 }
      old_class1_indices.push(class1_index)
    }
    let coverage_bytes = build_coverage_subset(coverage_new)
    let class_def1_bytes = match build_class_def_from_values(class_values1, true) {
      None => return Ok(None)
      Some(value) => value
    }
    let class_values2 : Array[Int] = []
    for old_gid in plan.glyphs {
      let gid = old_gid.reinterpret_as_int()
      let class2 = match class_def_value_subset(bytes, class2_base, gid) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let class2_index = if class2 >= class2_count { 0 } else { class2 }
      class_values2.push(class2_index)
    }
    let used_classes : Array[Int] = []
    for value in class_values2 {
      if value > 0 {
        let mut exists = false
        for seen in used_classes {
          if seen == value {
            exists = true
            break
          }
        }
        if !exists {
          used_classes.push(value)
        }
      }
    }
    used_classes.sort()
    let class_values2_new : Array[Int] = []
    let old_class2_for_new : Array[Int] = [0]
    for value in used_classes {
      old_class2_for_new.push(value)
    }
    for value in class_values2 {
      if value == 0 {
        class_values2_new.push(0)
      } else {
        let mut mapped = 0
        for i in 0..<used_classes.length() {
          if used_classes[i] == value {
            mapped = i + 1
            break
          }
        }
        class_values2_new.push(mapped)
      }
    }
    let new_class2_count = old_class2_for_new.length()
    let class_def2_bytes = match build_class_def_from_values(class_values2_new, true) {
      None => return Ok(None)
      Some(value) => value
    }
    let matrix_bytes : Array[Byte] = []
    for i in 0..<coverage_pairs.length() {
      let class1_index = old_class1_indices[i]
      for j in 0..<new_class2_count {
        let old_class2 = old_class2_for_new[j]
        let record_index = class1_index * class2_count + old_class2
        let record_offset = matrix_base + record_index * class_record_size
        if record_offset < 0 || record_offset + class_record_size > bytes.length() {
          return Err(InvalidInput("invalid GPOS class pair record"))
        }
        let record_bytes = bytes[record_offset:record_offset + class_record_size]
        for b in record_bytes {
          matrix_bytes.push(b)
        }
      }
    }
    let out : Array[Byte] = []
    push_u16(out, 2)
    let coverage_offset = 16 + matrix_bytes.length()
    let class_def2_offset = coverage_offset + coverage_bytes.length()
    let class_def1_offset = class_def2_offset + class_def2_bytes.length()
    push_u16(out, coverage_offset)
    push_u16(out, value_format1)
    push_u16(out, value_format2)
    push_u16(out, class_def1_offset)
    push_u16(out, class_def2_offset)
    push_u16(out, coverage_pairs.length())
    push_u16(out, new_class2_count)
    for b in matrix_bytes {
      out.push(b)
    }
    for b in coverage_bytes {
      out.push(b)
    }
    for b in class_def2_bytes {
      out.push(b)
    }
    for b in class_def1_bytes {
      out.push(b)
    }
    return Ok(Some(Bytes::from_array(out)))
  } else {
    Ok(None)
  }
}

fn build_mark_array_bytes(records : Array[(Int, Int, Bytes)]) -> Bytes {
  let out : Array[Byte] = []
  push_u16(out, records.length())
  let mut cursor = 2 + records.length() * 4
  let anchors : Array[Bytes] = []
  for record in records {
    let (_, mark_class, anchor_bytes) = record
    push_u16(out, mark_class)
    push_u16(out, cursor)
    cursor = cursor + anchor_bytes.length()
    anchors.push(anchor_bytes)
  }
  for anchor_bytes in anchors {
    for b in anchor_bytes {
      out.push(b)
    }
  }
  Bytes::from_array(out)
}

fn build_base_array_bytes(
  records : Array[(Int, Array[Bytes?])],
  class_count : Int,
) -> Bytes {
  let out : Array[Byte] = []
  push_u16(out, records.length())
  let mut cursor = 2 + records.length() * class_count * 2
  let anchors : Array[Bytes] = []
  for record in records {
    let (_, anchor_list) = record
    for anchor in anchor_list {
      match anchor {
        None => push_u16(out, 0)
        Some(anchor_bytes) => {
          push_u16(out, cursor)
          cursor = cursor + anchor_bytes.length()
          anchors.push(anchor_bytes)
        }
      }
    }
  }
  for anchor_bytes in anchors {
    for b in anchor_bytes {
      out.push(b)
    }
  }
  Bytes::from_array(out)
}

fn build_ligature_attach_bytes(
  components : Array[Array[Bytes?]],
  class_count : Int,
) -> Bytes {
  let out : Array[Byte] = []
  push_u16(out, components.length())
  let mut cursor = 2 + components.length() * class_count * 2
  let anchors : Array[Bytes] = []
  for component in components {
    for anchor in component {
      match anchor {
        None => push_u16(out, 0)
        Some(anchor_bytes) => {
          push_u16(out, cursor)
          cursor = cursor + anchor_bytes.length()
          anchors.push(anchor_bytes)
        }
      }
    }
  }
  for anchor_bytes in anchors {
    for b in anchor_bytes {
      out.push(b)
    }
  }
  Bytes::from_array(out)
}

fn build_ligature_array_bytes(
  records : Array[(Int, Array[Array[Bytes?]])],
  class_count : Int,
) -> Bytes {
  let out : Array[Byte] = []
  push_u16(out, records.length())
  let mut cursor = 2 + records.length() * 2
  let attaches : Array[Bytes] = []
  for record in records {
    let (_, components) = record
    let attach_bytes = build_ligature_attach_bytes(components, class_count)
    push_u16(out, cursor)
    cursor = cursor + attach_bytes.length()
    attaches.push(attach_bytes)
  }
  for attach_bytes in attaches {
    for b in attach_bytes {
      out.push(b)
    }
  }
  Bytes::from_array(out)
}

fn build_gpos_cursive_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 6 {
    return Err(InvalidInput("invalid GPOS cursive subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let coverage_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let entry_exit_count = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage_offset <= 0 || entry_exit_count < 0 {
    return Err(InvalidInput("invalid GPOS cursive header"))
  }
  let record_base = 6
  if record_base + entry_exit_count * 4 > bytes.length() {
    return Err(InvalidInput("invalid GPOS cursive records"))
  }
  let coverage = match parse_coverage_subset(bytes, coverage_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if coverage.length() != entry_exit_count {
    return Err(InvalidInput("GPOS cursive coverage count mismatch"))
  }
  let records : Array[(Int, Bytes?, Bytes?)] = []
  for i in 0..<entry_exit_count {
    let glyph = coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let entry_offset = match read_u16(bytes, record_base + i * 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let exit_offset = match read_u16(bytes, record_base + i * 4 + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let entry_anchor = if entry_offset == 0 {
      None
    } else {
      match build_anchor_bytes_optional(bytes, entry_offset) {
        Err(err) => return Err(err)
        Ok(None) => return Ok(None)
        Ok(Some(value)) => Some(value)
      }
    }
    let exit_anchor = if exit_offset == 0 {
      None
    } else {
      match build_anchor_bytes_optional(bytes, exit_offset) {
        Err(err) => return Err(err)
        Ok(None) => return Ok(None)
        Ok(Some(value)) => Some(value)
      }
    }
    records.push((new_gid, entry_anchor, exit_anchor))
  }
  if records.is_empty() {
    return Ok(None)
  }
  records.sort_by((a, b) => a.0 - b.0)
  let glyphs : Array[Int] = []
  let out_records : Array[Byte] = []
  push_u16(out_records, records.length())
  let mut cursor = 2 + records.length() * 4
  let anchors : Array[Bytes] = []
  for record in records {
    let (gid, entry_anchor, exit_anchor) = record
    glyphs.push(gid)
    match entry_anchor {
      None => push_u16(out_records, 0)
      Some(anchor_bytes) => {
        push_u16(out_records, 4 + cursor)
        cursor = cursor + anchor_bytes.length()
        anchors.push(anchor_bytes)
      }
    }
    match exit_anchor {
      None => push_u16(out_records, 0)
      Some(anchor_bytes) => {
        push_u16(out_records, 4 + cursor)
        cursor = cursor + anchor_bytes.length()
        anchors.push(anchor_bytes)
      }
    }
  }
  for anchor_bytes in anchors {
    for b in anchor_bytes {
      out_records.push(b)
    }
  }
  let coverage_bytes = build_coverage_subset(glyphs)
  let coverage_offset = 4 + out_records.length()
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, coverage_offset)
  for b in out_records {
    out.push(b)
  }
  for b in coverage_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gpos_mark_base_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 12 {
    return Err(InvalidInput("invalid GPOS mark-to-base subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let mark_cov_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let base_cov_offset = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let class_count = match read_u16(bytes, 6) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark_array_offset = match read_u16(bytes, 8) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let base_array_offset = match read_u16(bytes, 10) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark_cov_offset <= 0 || base_cov_offset <= 0 ||
      mark_array_offset <= 0 || base_array_offset <= 0 ||
      class_count <= 0 {
    return Ok(None)
  }
  let mark_coverage = match parse_coverage_subset(bytes, mark_cov_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let base_coverage = match parse_coverage_subset(bytes, base_cov_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark_array_base = mark_array_offset
  let mark_count = match read_u16(bytes, mark_array_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark_count < 0 || mark_count != mark_coverage.length() {
    return Err(InvalidInput("GPOS mark array count mismatch"))
  }
  let mark_record_base = mark_array_base + 2
  if mark_record_base + mark_count * 4 > bytes.length() {
    return Err(InvalidInput("invalid GPOS mark array bounds"))
  }
  let base_array_base = base_array_offset
  let base_count = match read_u16(bytes, base_array_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if base_count < 0 || base_count != base_coverage.length() {
    return Err(InvalidInput("GPOS base array count mismatch"))
  }
  let base_record_base = base_array_base + 2
  let base_record_size = class_count * 2
  if base_record_base + base_count * base_record_size > bytes.length() {
    return Err(InvalidInput("invalid GPOS base array bounds"))
  }

  let mark_records : Array[(Int, Int, Bytes)] = []
  for i in 0..<mark_count {
    let glyph = mark_coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let mark_class = match read_u16(bytes, mark_record_base + i * 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mark_anchor_offset = match read_u16(bytes, mark_record_base + i * 4 + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if mark_class < 0 || mark_class >= class_count {
      return Err(InvalidInput("invalid GPOS mark class"))
    }
    if mark_anchor_offset == 0 {
      return Ok(None)
    }
    let mark_anchor = match build_anchor_bytes_optional(
      bytes,
      mark_array_base + mark_anchor_offset,
    ) {
      Err(err) => return Err(err)
      Ok(None) => return Ok(None)
      Ok(Some(value)) => value
    }
    mark_records.push((new_gid, mark_class, mark_anchor))
  }

  let base_records : Array[(Int, Array[Bytes?])] = []
  for i in 0..<base_count {
    let glyph = base_coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let anchors : Array[Bytes?] = []
    for class_index in 0..<class_count {
      let anchor_offset = match read_u16(
        bytes,
        base_record_base + i * base_record_size + class_index * 2,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if anchor_offset == 0 {
        anchors.push(None)
      } else {
        let anchor = match build_anchor_bytes_optional(
          bytes,
          base_array_base + anchor_offset,
        ) {
          Err(err) => return Err(err)
          Ok(None) => return Ok(None)
          Ok(Some(value)) => Some(value)
        }
        anchors.push(anchor)
      }
    }
    base_records.push((new_gid, anchors))
  }

  if mark_records.is_empty() || base_records.is_empty() {
    return Ok(None)
  }
  mark_records.sort_by((a, b) => a.0 - b.0)
  base_records.sort_by((a, b) => a.0 - b.0)
  let mark_glyphs : Array[Int] = []
  let base_glyphs : Array[Int] = []
  for record in mark_records {
    mark_glyphs.push(record.0)
  }
  for record in base_records {
    base_glyphs.push(record.0)
  }
  let mark_cov_bytes = build_coverage_subset(mark_glyphs)
  let base_cov_bytes = build_coverage_subset(base_glyphs)
  let mark_array_bytes = build_mark_array_bytes(mark_records)
  let base_array_bytes = build_base_array_bytes(base_records, class_count)

  let header_len = 12
  let mark_array_offset = header_len
  let base_array_offset = mark_array_offset + mark_array_bytes.length()
  let mark_cov_offset = base_array_offset + base_array_bytes.length()
  let base_cov_offset = mark_cov_offset + mark_cov_bytes.length()
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, mark_cov_offset)
  push_u16(out, base_cov_offset)
  push_u16(out, class_count)
  push_u16(out, mark_array_offset)
  push_u16(out, base_array_offset)
  for b in mark_array_bytes {
    out.push(b)
  }
  for b in base_array_bytes {
    out.push(b)
  }
  for b in mark_cov_bytes {
    out.push(b)
  }
  for b in base_cov_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gpos_mark_ligature_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 12 {
    return Err(InvalidInput("invalid GPOS mark-to-ligature subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let mark_cov_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let lig_cov_offset = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let class_count = match read_u16(bytes, 6) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark_array_offset = match read_u16(bytes, 8) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let lig_array_offset = match read_u16(bytes, 10) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark_cov_offset <= 0 || lig_cov_offset <= 0 ||
      mark_array_offset <= 0 || lig_array_offset <= 0 ||
      class_count <= 0 {
    return Ok(None)
  }
  let mark_coverage = match parse_coverage_subset(bytes, mark_cov_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let lig_coverage = match parse_coverage_subset(bytes, lig_cov_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark_array_base = mark_array_offset
  let mark_count = match read_u16(bytes, mark_array_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark_count < 0 || mark_count != mark_coverage.length() {
    return Err(InvalidInput("GPOS mark array count mismatch"))
  }
  let mark_record_base = mark_array_base + 2
  if mark_record_base + mark_count * 4 > bytes.length() {
    return Err(InvalidInput("invalid GPOS mark array bounds"))
  }
  let lig_array_base = lig_array_offset
  let lig_count = match read_u16(bytes, lig_array_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if lig_count < 0 || lig_count != lig_coverage.length() {
    return Err(InvalidInput("GPOS ligature array count mismatch"))
  }
  if lig_array_base + 2 + lig_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid GPOS ligature array bounds"))
  }

  let mark_records : Array[(Int, Int, Bytes)] = []
  for i in 0..<mark_count {
    let glyph = mark_coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let mark_class = match read_u16(bytes, mark_record_base + i * 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mark_anchor_offset = match read_u16(bytes, mark_record_base + i * 4 + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if mark_class < 0 || mark_class >= class_count {
      return Err(InvalidInput("invalid GPOS mark class"))
    }
    if mark_anchor_offset == 0 {
      return Ok(None)
    }
    let mark_anchor = match build_anchor_bytes_optional(
      bytes,
      mark_array_base + mark_anchor_offset,
    ) {
      Err(err) => return Err(err)
      Ok(None) => return Ok(None)
      Ok(Some(value)) => value
    }
    mark_records.push((new_gid, mark_class, mark_anchor))
  }

  let lig_records : Array[(Int, Array[Array[Bytes?]])] = []
  for i in 0..<lig_count {
    let glyph = lig_coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let attach_offset = match read_u16(bytes, lig_array_base + 2 + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if attach_offset == 0 {
      continue
    }
    let attach_base = lig_array_base + attach_offset
    if attach_base < 0 || attach_base + 2 > bytes.length() {
      return Err(InvalidInput("invalid GPOS ligature attach offset"))
    }
    let component_count = match read_u16(bytes, attach_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if component_count <= 0 {
      continue
    }
    let record_base = attach_base + 2
    let record_size = class_count * 2
    if record_base + component_count * record_size > bytes.length() {
      return Err(InvalidInput("invalid GPOS ligature attach bounds"))
    }
    let components : Array[Array[Bytes?]] = []
    for component_index in 0..<component_count {
      let anchors : Array[Bytes?] = []
      for class_index in 0..<class_count {
        let anchor_offset = match read_u16(
          bytes,
          record_base + component_index * record_size + class_index * 2,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if anchor_offset == 0 {
          anchors.push(None)
        } else {
          let anchor = match build_anchor_bytes_optional(
            bytes,
            attach_base + anchor_offset,
          ) {
            Err(err) => return Err(err)
            Ok(None) => return Ok(None)
            Ok(Some(value)) => Some(value)
          }
          anchors.push(anchor)
        }
      }
      components.push(anchors)
    }
    lig_records.push((new_gid, components))
  }

  if mark_records.is_empty() || lig_records.is_empty() {
    return Ok(None)
  }
  mark_records.sort_by((a, b) => a.0 - b.0)
  lig_records.sort_by((a, b) => a.0 - b.0)
  let mark_glyphs : Array[Int] = []
  let lig_glyphs : Array[Int] = []
  for record in mark_records {
    mark_glyphs.push(record.0)
  }
  for record in lig_records {
    lig_glyphs.push(record.0)
  }
  let mark_cov_bytes = build_coverage_subset(mark_glyphs)
  let lig_cov_bytes = build_coverage_subset(lig_glyphs)
  let mark_array_bytes = build_mark_array_bytes(mark_records)
  let lig_array_bytes = build_ligature_array_bytes(lig_records, class_count)

  let header_len = 12
  let mark_array_offset = header_len
  let lig_array_offset = mark_array_offset + mark_array_bytes.length()
  let mark_cov_offset = lig_array_offset + lig_array_bytes.length()
  let lig_cov_offset = mark_cov_offset + mark_cov_bytes.length()
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, mark_cov_offset)
  push_u16(out, lig_cov_offset)
  push_u16(out, class_count)
  push_u16(out, mark_array_offset)
  push_u16(out, lig_array_offset)
  for b in mark_array_bytes {
    out.push(b)
  }
  for b in lig_array_bytes {
    out.push(b)
  }
  for b in mark_cov_bytes {
    out.push(b)
  }
  for b in lig_cov_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gpos_mark_mark_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  if bytes.length() < 12 {
    return Err(InvalidInput("invalid GPOS mark-to-mark subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let mark1_cov_offset = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark2_cov_offset = match read_u16(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let class_count = match read_u16(bytes, 6) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark1_array_offset = match read_u16(bytes, 8) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark2_array_offset = match read_u16(bytes, 10) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark1_cov_offset <= 0 || mark2_cov_offset <= 0 ||
      mark1_array_offset <= 0 || mark2_array_offset <= 0 ||
      class_count <= 0 {
    return Ok(None)
  }
  let mark1_coverage = match parse_coverage_subset(bytes, mark1_cov_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark2_coverage = match parse_coverage_subset(bytes, mark2_cov_offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let mark1_array_base = mark1_array_offset
  let mark1_count = match read_u16(bytes, mark1_array_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark1_count < 0 || mark1_count != mark1_coverage.length() {
    return Err(InvalidInput("GPOS mark1 array count mismatch"))
  }
  let mark1_record_base = mark1_array_base + 2
  if mark1_record_base + mark1_count * 4 > bytes.length() {
    return Err(InvalidInput("invalid GPOS mark1 array bounds"))
  }
  let mark2_array_base = mark2_array_offset
  let mark2_count = match read_u16(bytes, mark2_array_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if mark2_count < 0 || mark2_count != mark2_coverage.length() {
    return Err(InvalidInput("GPOS mark2 array count mismatch"))
  }
  let mark2_record_base = mark2_array_base + 2
  let mark2_record_size = class_count * 2
  if mark2_record_base + mark2_count * mark2_record_size > bytes.length() {
    return Err(InvalidInput("invalid GPOS mark2 array bounds"))
  }

  let mark1_records : Array[(Int, Int, Bytes)] = []
  for i in 0..<mark1_count {
    let glyph = mark1_coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let mark_class = match read_u16(bytes, mark1_record_base + i * 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let mark_anchor_offset = match read_u16(bytes, mark1_record_base + i * 4 + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if mark_class < 0 || mark_class >= class_count {
      return Err(InvalidInput("invalid GPOS mark class"))
    }
    if mark_anchor_offset == 0 {
      return Ok(None)
    }
    let mark_anchor = match build_anchor_bytes_optional(
      bytes,
      mark1_array_base + mark_anchor_offset,
    ) {
      Err(err) => return Err(err)
      Ok(None) => return Ok(None)
      Ok(Some(value)) => value
    }
    mark1_records.push((new_gid, mark_class, mark_anchor))
  }

  let mark2_records : Array[(Int, Array[Bytes?])] = []
  for i in 0..<mark2_count {
    let glyph = mark2_coverage[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid < 0 {
      continue
    }
    let anchors : Array[Bytes?] = []
    for class_index in 0..<class_count {
      let anchor_offset = match read_u16(
        bytes,
        mark2_record_base + i * mark2_record_size + class_index * 2,
      ) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if anchor_offset == 0 {
        anchors.push(None)
      } else {
        let anchor = match build_anchor_bytes_optional(
          bytes,
          mark2_array_base + anchor_offset,
        ) {
          Err(err) => return Err(err)
          Ok(None) => return Ok(None)
          Ok(Some(value)) => Some(value)
        }
        anchors.push(anchor)
      }
    }
    mark2_records.push((new_gid, anchors))
  }

  if mark1_records.is_empty() || mark2_records.is_empty() {
    return Ok(None)
  }
  mark1_records.sort_by((a, b) => a.0 - b.0)
  mark2_records.sort_by((a, b) => a.0 - b.0)
  let mark1_glyphs : Array[Int] = []
  let mark2_glyphs : Array[Int] = []
  for record in mark1_records {
    mark1_glyphs.push(record.0)
  }
  for record in mark2_records {
    mark2_glyphs.push(record.0)
  }
  let mark1_cov_bytes = build_coverage_subset(mark1_glyphs)
  let mark2_cov_bytes = build_coverage_subset(mark2_glyphs)
  let mark1_array_bytes = build_mark_array_bytes(mark1_records)
  let mark2_array_bytes = build_base_array_bytes(mark2_records, class_count)

  let header_len = 12
  let mark1_array_offset = header_len
  let mark2_array_offset = mark1_array_offset + mark1_array_bytes.length()
  let mark1_cov_offset = mark2_array_offset + mark2_array_bytes.length()
  let mark2_cov_offset = mark1_cov_offset + mark1_cov_bytes.length()
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, mark1_cov_offset)
  push_u16(out, mark2_cov_offset)
  push_u16(out, class_count)
  push_u16(out, mark1_array_offset)
  push_u16(out, mark2_array_offset)
  for b in mark1_array_bytes {
    out.push(b)
  }
  for b in mark2_array_bytes {
    out.push(b)
  }
  for b in mark1_cov_bytes {
    out.push(b)
  }
  for b in mark2_cov_bytes {
    out.push(b)
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gpos_contextual_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  build_gsub_contextual_subtable(bytes, plan)
}

fn build_gpos_chaining_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  build_gsub_chaining_subtable(bytes, plan)
}

fn build_gpos_extension_subtable(
  bytes : Array[Byte],
  plan : SubsetPlan,
) -> Result[(Int, Bytes)?, SubsetError] {
  if bytes.length() < 8 {
    return Err(InvalidInput("invalid GPOS extension subtable"))
  }
  let format = match read_u16(bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format != 1 {
    return Ok(None)
  }
  let extension_type = match read_u16(bytes, 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let extension_offset = match read_u32(bytes, 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if extension_offset <= 0 {
    return Err(InvalidInput("invalid GPOS extension offset"))
  }
  if extension_offset >= bytes.length() {
    return Err(InvalidInput("invalid GPOS extension bounds"))
  }
  let ext_base = extension_offset
  let ext_bytes = bytes[ext_base:bytes.length()].to_array()
  let mut new_sub : Bytes? = None
  if extension_type == 1 {
    new_sub = match build_gpos_single_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 2 {
    new_sub = match build_gpos_pair_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 3 {
    new_sub = match build_gpos_cursive_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 4 {
    new_sub = match build_gpos_mark_base_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 5 {
    new_sub = match build_gpos_mark_ligature_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 6 {
    new_sub = match build_gpos_mark_mark_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 7 {
    new_sub = match build_gpos_contextual_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else if extension_type == 8 {
    new_sub = match build_gpos_chaining_subtable(ext_bytes, plan) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else {
    return Ok(None)
  }
  match new_sub {
    None => Ok(None)
    Some(value) => Ok(Some((extension_type, value)))
  }
}

fn parse_lookup_header(
  bytes : Array[Byte],
  offset : Int,
) -> Result[(Int, Int, Int?, Array[Int]), SubsetError] {
  let lookup_type = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let lookup_flag = match read_u16(bytes, offset + 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let subtable_count = match read_u16(bytes, offset + 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if subtable_count < 0 {
    return Err(InvalidInput("invalid lookup subtable count"))
  }
  let offsets_base = offset + 6
  if offsets_base + subtable_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid lookup offsets"))
  }
  let subtable_offsets : Array[Int] = []
  for i in 0..<subtable_count {
    let value = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if value <= 0 {
      return Err(InvalidInput("invalid lookup offset"))
    }
    subtable_offsets.push(value)
  }
  let mark_set = if (lookup_flag & 0x0010) != 0 {
    let extra_offset = offsets_base + subtable_count * 2
    if extra_offset + 2 > bytes.length() {
      return Err(InvalidInput("invalid lookup mark filtering set"))
    }
    let value = match read_u16(bytes, extra_offset) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    Some(value)
  } else {
    None
  }
  Ok((lookup_type, lookup_flag, mark_set, subtable_offsets))
}

fn build_lookup_bytes(
  lookup_type : Int,
  lookup_flag : Int,
  mark_set : Int?,
  subtables : Array[Bytes],
) -> Result[Bytes, SubsetError] {
  let out : Array[Byte] = []
  push_u16(out, lookup_type)
  push_u16(out, lookup_flag)
  push_u16(out, subtables.length())
  let mut cursor = 6 + subtables.length() * 2
  if mark_set is Some(_) {
    cursor = cursor + 2
  }
  for subtable in subtables {
    push_u16(out, cursor)
    cursor = cursor + subtable.length()
  }
  match mark_set {
    None => ()
    Some(value) => push_u16(out, value)
  }
  for subtable in subtables {
    for b in subtable {
      out.push(b)
    }
  }
  Ok(Bytes::from_array(out))
}

fn push_langsys_no_features(out : Array[Byte]) -> Unit {
  push_u16(out, 0)
  push_u16(out, 0xFFFF)
  push_u16(out, 0)
}

fn build_script_table_no_features(
  has_default : Bool,
  lang_tags : Array[Int],
) -> Bytes {
  let lang_count = lang_tags.length()
  let header_len = 4 + lang_count * 6
  let mut cursor = header_len
  let default_offset = if has_default { cursor } else { 0 }
  if has_default {
    cursor = cursor + 6
  }
  let offsets : Array[Int] = []
  for _ in 0..<lang_count {
    offsets.push(cursor)
    cursor = cursor + 6
  }
  let out : Array[Byte] = []
  push_u16(out, default_offset)
  push_u16(out, lang_count)
  for i in 0..<lang_count {
    push_u32(out, lang_tags[i])
    push_u16(out, offsets[i])
  }
  if has_default {
    push_langsys_no_features(out)
  }
  for _ in 0..<lang_count {
    push_langsys_no_features(out)
  }
  Bytes::from_array(out)
}

fn build_script_list_no_features(
  script_bytes : Array[Byte],
) -> Result[Bytes, SubsetError] {
  if script_bytes.length() < 2 {
    return Err(InvalidInput("invalid script list"))
  }
  let script_count = match read_u16(script_bytes, 0) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if script_count < 0 {
    return Err(InvalidInput("invalid script count"))
  }
  let records : Array[(Int, Bool, Array[Int])] = []
  for i in 0..<script_count {
    let record_base = 2 + i * 6
    if record_base + 6 > script_bytes.length() {
      return Err(InvalidInput("invalid script record"))
    }
    let tag = match read_u32(script_bytes, record_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let offset = match read_u16(script_bytes, record_base + 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if offset < 0 || offset >= script_bytes.length() {
      return Err(InvalidInput("invalid script record offset"))
    }
    let script_base = offset
    let default_offset = match read_u16(script_bytes, script_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let lang_count = match read_u16(script_bytes, script_base + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if lang_count < 0 {
      return Err(InvalidInput("invalid script langsys count"))
    }
    let lang_tags : Array[Int] = []
    for j in 0..<lang_count {
      let lang_base = script_base + 4 + j * 6
      if lang_base + 6 > script_bytes.length() {
        return Err(InvalidInput("invalid langsys record"))
      }
      let lang_tag = match read_u32(script_bytes, lang_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      lang_tags.push(lang_tag)
    }
    records.push((tag, default_offset != 0, lang_tags))
  }
  let record_tables : Array[Bytes] = []
  for record in records {
    record_tables.push(build_script_table_no_features(record.1, record.2))
  }
  let unique_tables : Array[(Int, Int, Bytes)] = []
  for table_bytes in record_tables {
    let mut exists = false
    for entry in unique_tables {
      if entry.2 == table_bytes {
        exists = true
        break
      }
    }
    if !exists {
      unique_tables.push((table_bytes.length(), unique_tables.length(), table_bytes))
    }
  }
  unique_tables.sort_by((a, b) => {
    let diff = a.0 - b.0
    if diff != 0 {
      diff
    } else {
      a.1 - b.1
    }
  })
  let mut cursor = 2 + script_count * 6
  let script_tables : Array[Bytes] = []
  let script_offsets : Array[Int] = []
  for entry in unique_tables {
    let table_bytes = entry.2
    script_tables.push(table_bytes)
    script_offsets.push(cursor)
    cursor = cursor + table_bytes.length()
  }
  let record_offsets : Array[Int] = []
  for table_bytes in record_tables {
    let mut offset = 0
    for i in 0..<script_tables.length() {
      if script_tables[i] == table_bytes {
        offset = script_offsets[i]
        break
      }
    }
    record_offsets.push(offset)
  }
  let out : Array[Byte] = []
  push_u16(out, script_count)
  for i in 0..<records.length() {
    push_u32(out, records[i].0)
    push_u16(out, record_offsets[i])
  }
  for table_bytes in script_tables {
    for b in table_bytes {
      out.push(b)
    }
  }
  Ok(Bytes::from_array(out))
}

fn build_gsub_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_gsub) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 10 {
        return Err(InvalidInput("invalid GSUB table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if version != 0x00010000 {
        return Ok(None)
      }
      let script_offset = match read_u16(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let feature_offset = match read_u16(bytes, 6) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lookup_offset = match read_u16(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if script_offset <= 0 || feature_offset <= 0 || lookup_offset <= 0 {
        return Ok(None)
      }
      if script_offset >= bytes.length() ||
          feature_offset >= bytes.length() ||
          lookup_offset >= bytes.length() {
        return Err(InvalidInput("invalid GSUB offsets"))
      }
      if !(script_offset < feature_offset && feature_offset < lookup_offset) {
        return Ok(None)
      }
      let script_bytes = bytes[script_offset:feature_offset].to_array()
      let feature_bytes = bytes[feature_offset:lookup_offset].to_array()
      let lookup_count = match read_u16(bytes, lookup_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if lookup_count < 0 {
        return Err(InvalidInput("invalid lookup count"))
      }
      let offsets_base = lookup_offset + 2
      if offsets_base + lookup_count * 2 > bytes.length() {
        return Err(InvalidInput("invalid lookup list offsets"))
      }
      let lookup_offsets : Array[Int] = []
      for i in 0..<lookup_count {
        let value = match read_u16(bytes, offsets_base + i * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if value <= 0 {
          return Err(InvalidInput("invalid lookup offset"))
        }
        lookup_offsets.push(value)
      }
      let lookup_bytes_list : Array[Bytes] = []
      let mut kept_subtables = 0
      for i in 0..<lookup_count {
        let base = lookup_offset + lookup_offsets[i]
        let end = if i + 1 < lookup_count {
          lookup_offset + lookup_offsets[i + 1]
        } else {
          bytes.length()
        }
        if base < 0 || base >= bytes.length() || end <= base || end > bytes.length() {
          return Err(InvalidInput("invalid lookup bounds"))
        }
        let (lookup_type, lookup_flag, mark_set, sub_offsets) = match parse_lookup_header(
          bytes,
          base,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let subtables : Array[Bytes] = []
        if lookup_type == 1 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_single_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 2 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_multiple_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 3 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_alternate_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 4 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_ligature_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 5 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_contextual_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 6 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_chaining_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 7 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let result = match build_gsub_extension_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match result {
              None => ()
              Some((extension_type, new_sub)) => {
                let ext_bytes : Array[Byte] = []
                push_u16(ext_bytes, 1)
                push_u16(ext_bytes, extension_type)
                let extension_offset = 8
                push_u32(ext_bytes, extension_offset)
                for b in new_sub {
                  ext_bytes.push(b)
                }
                kept_subtables = kept_subtables + 1
                subtables.push(Bytes::from_array(ext_bytes))
              }
            }
          }
        } else if lookup_type == 8 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GSUB subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gsub_reverse_chaining_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        }
        let lookup_bytes = match build_lookup_bytes(
          lookup_type,
          lookup_flag,
          mark_set,
          subtables,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        lookup_bytes_list.push(lookup_bytes)
      }
      if kept_subtables == 0 {
        let script_list = match build_script_list_no_features(script_bytes) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let out : Array[Byte] = []
        push_u32(out, version)
        let script_new_offset = 10
        let feature_new_offset = script_new_offset + script_list.length()
        let lookup_new_offset = feature_new_offset
        push_u16(out, script_new_offset)
        push_u16(out, feature_new_offset)
        push_u16(out, lookup_new_offset)
        for b in script_list {
          out.push(b)
        }
        push_u16(out, 0)
        return Ok(Some(Bytes::from_array(out)))
      }
      let lookup_list_bytes = match build_lookup_list_bytes(lookup_bytes_list) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let out : Array[Byte] = []
      push_u32(out, version)
      let script_new_offset = 10
      let feature_new_offset = script_new_offset + script_bytes.length()
      let lookup_new_offset = feature_new_offset + feature_bytes.length()
      push_u16(out, script_new_offset)
      push_u16(out, feature_new_offset)
      push_u16(out, lookup_new_offset)
      for b in script_bytes {
        out.push(b)
      }
      for b in feature_bytes {
        out.push(b)
      }
      for b in lookup_list_bytes {
        out.push(b)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_gpos_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_gpos) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 10 {
        return Err(InvalidInput("invalid GPOS table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if version != 0x00010000 {
        return Ok(None)
      }
      let script_offset = match read_u16(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let feature_offset = match read_u16(bytes, 6) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lookup_offset = match read_u16(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if script_offset <= 0 || feature_offset <= 0 || lookup_offset <= 0 {
        return Ok(None)
      }
      if script_offset >= bytes.length() ||
          feature_offset >= bytes.length() ||
          lookup_offset >= bytes.length() {
        return Err(InvalidInput("invalid GPOS offsets"))
      }
      if !(script_offset < feature_offset && feature_offset < lookup_offset) {
        return Ok(None)
      }
      let script_bytes = bytes[script_offset:feature_offset].to_array()
      let feature_bytes = bytes[feature_offset:lookup_offset].to_array()
      let lookup_count = match read_u16(bytes, lookup_offset) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if lookup_count < 0 {
        return Err(InvalidInput("invalid lookup count"))
      }
      let offsets_base = lookup_offset + 2
      if offsets_base + lookup_count * 2 > bytes.length() {
        return Err(InvalidInput("invalid lookup list offsets"))
      }
      let lookup_offsets : Array[Int] = []
      for i in 0..<lookup_count {
        let value = match read_u16(bytes, offsets_base + i * 2) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        if value <= 0 {
          return Err(InvalidInput("invalid lookup offset"))
        }
        lookup_offsets.push(value)
      }
      let lookup_bytes_list : Array[Bytes] = []
      let mut kept_subtables = 0
      for i in 0..<lookup_count {
        let base = lookup_offset + lookup_offsets[i]
        let end = if i + 1 < lookup_count {
          lookup_offset + lookup_offsets[i + 1]
        } else {
          bytes.length()
        }
        if base < 0 || base >= bytes.length() || end <= base || end > bytes.length() {
          return Err(InvalidInput("invalid lookup bounds"))
        }
        let (lookup_type, lookup_flag, mark_set, sub_offsets) = match parse_lookup_header(
          bytes,
          base,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        let subtables : Array[Bytes] = []
        if lookup_type == 1 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_single_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 2 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_pair_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 3 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_cursive_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 4 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_mark_base_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 5 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_mark_ligature_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 6 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_mark_mark_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 7 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_contextual_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 8 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let new_sub = match build_gpos_chaining_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match new_sub {
              None => ()
              Some(value) => {
                kept_subtables = kept_subtables + 1
                subtables.push(value)
              }
            }
          }
        } else if lookup_type == 9 {
          for j in 0..<sub_offsets.length() {
            let sub_base = base + sub_offsets[j]
            let sub_end = if j + 1 < sub_offsets.length() {
              base + sub_offsets[j + 1]
            } else {
              end
            }
            if sub_base < 0 || sub_base >= end || sub_end <= sub_base || sub_end > end {
              return Err(InvalidInput("invalid GPOS subtable bounds"))
            }
            let sub_bytes = bytes[sub_base:sub_end].to_array()
            let result = match build_gpos_extension_subtable(sub_bytes, plan) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            match result {
              None => ()
              Some((extension_type, new_sub)) => {
                let ext_bytes : Array[Byte] = []
                push_u16(ext_bytes, 1)
                push_u16(ext_bytes, extension_type)
                let extension_offset = 8
                push_u32(ext_bytes, extension_offset)
                for b in new_sub {
                  ext_bytes.push(b)
                }
                kept_subtables = kept_subtables + 1
                subtables.push(Bytes::from_array(ext_bytes))
              }
            }
          }
        }
        let lookup_bytes = match build_lookup_bytes(
          lookup_type,
          lookup_flag,
          mark_set,
          subtables,
        ) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
        lookup_bytes_list.push(lookup_bytes)
      }
      if kept_subtables == 0 {
        return Ok(None)
      }
      let lookup_list_bytes = match build_lookup_list_bytes(lookup_bytes_list) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let out : Array[Byte] = []
      push_u32(out, version)
      let script_new_offset = 10
      let feature_new_offset = script_new_offset + script_bytes.length()
      let lookup_new_offset = feature_new_offset + feature_bytes.length()
      push_u16(out, script_new_offset)
      push_u16(out, feature_new_offset)
      push_u16(out, lookup_new_offset)
      for b in script_bytes {
        out.push(b)
      }
      for b in feature_bytes {
        out.push(b)
      }
      for b in lookup_list_bytes {
        out.push(b)
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_lookup_list_bytes(
  lookups : Array[Bytes],
) -> Result[Bytes, SubsetError] {
  let out : Array[Byte] = []
  push_u16(out, lookups.length())
  let mut cursor = 2 + lookups.length() * 2
  for lookup in lookups {
    push_u16(out, cursor)
    cursor = cursor + lookup.length()
  }
  for lookup in lookups {
    for b in lookup {
      out.push(b)
    }
  }
  Ok(Bytes::from_array(out))
}

fn build_attach_list_subset(
  bytes : Array[Byte],
  offset : Int,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let cov_offset = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let glyph_count = match read_u16(bytes, offset + 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if cov_offset == 0 || glyph_count <= 0 {
    return Ok(None)
  }
  let offsets_base = offset + 4
  if offsets_base + glyph_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid attach list offsets"))
  }
  let cov_base = offset + cov_offset
  let glyphs = match parse_coverage_subset(bytes, cov_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if glyphs.length() != glyph_count {
    return Err(InvalidInput("attach list glyph count mismatch"))
  }
  let records : Array[(Int, Bytes)] = []
  for i in 0..<glyph_count {
    let glyph = glyphs[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let attach_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if attach_offset == 0 {
      continue
    }
    let attach_base = offset + attach_offset
    let point_count = match read_u16(bytes, attach_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if point_count < 0 {
      return Err(InvalidInput("invalid attach point count"))
    }
    let length = 2 + point_count * 2
    if attach_base < 0 || attach_base + length > bytes.length() {
      return Err(InvalidInput("invalid attach point table"))
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid >= 0 {
      let attach_bytes = Bytes::from_array(bytes[attach_base:attach_base + length].to_array())
      records.push((new_gid, attach_bytes))
    }
  }
  if records.is_empty() {
    return Ok(None)
  }
  records.sort_by((a, b) => {
    let (gid_a, _) = a
    let (gid_b, _) = b
    gid_a - gid_b
  })
  let mapped : Array[Int] = []
  for record in records {
    mapped.push(record.0)
  }
  let coverage = build_coverage_subset(mapped)
  let out : Array[Byte] = []
  let header_len = 4 + records.length() * 2
  push_u16(out, header_len)
  push_u16(out, records.length())
  let mut cursor = header_len + coverage.length()
  let offsets : Array[Int] = []
  for record in records {
    offsets.push(cursor)
    cursor = cursor + record.1.length()
  }
  for offset_value in offsets {
    push_u16(out, offset_value)
  }
  for b in coverage {
    out.push(b)
  }
  for record in records {
    for b in record.1 {
      out.push(b)
    }
  }
  Ok(Some(Bytes::from_array(out)))
}

fn device_table_length(
  bytes : Array[Byte],
  offset : Int,
) -> Result[Int, SubsetError] {
  let start_size = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let end_size = match read_u16(bytes, offset + 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let delta_format = match read_u16(bytes, offset + 4) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let count = end_size - start_size + 1
  if count <= 0 {
    return Err(InvalidInput("invalid device table range"))
  }
  let bits = if delta_format == 1 {
    2
  } else if delta_format == 2 {
    4
  } else if delta_format == 3 {
    8
  } else {
    return Err(InvalidInput("invalid device table format"))
  }
  let words = (count * bits + 15) / 16
  Ok(6 + words * 2)
}

fn build_caret_value_subset(
  bytes : Array[Byte],
  offset : Int,
) -> Result[Bytes, SubsetError] {
  let format = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if format == 1 {
    let coord = match read_i16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let out : Array[Byte] = []
    push_u16(out, 1)
    push_i16(out, coord)
    return Ok(Bytes::from_array(out))
  }
  if format == 2 {
    let point = match read_u16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let out : Array[Byte] = []
    push_u16(out, 2)
    push_u16(out, point)
    return Ok(Bytes::from_array(out))
  }
  if format == 3 {
    let coord = match read_i16(bytes, offset + 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let device_offset = match read_u16(bytes, offset + 4) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    let device_bytes : Array[Byte] = []
    if device_offset != 0 {
      let device_base = offset + device_offset
      let length = match device_table_length(bytes, device_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if device_base < 0 || device_base + length > bytes.length() {
        return Err(InvalidInput("invalid device table"))
      }
      for b in bytes[device_base:device_base + length] {
        device_bytes.push(b)
      }
    }
    let out : Array[Byte] = []
    push_u16(out, 3)
    push_i16(out, coord)
    let new_offset = if device_bytes.is_empty() { 0 } else { 6 }
    push_u16(out, new_offset)
    for b in device_bytes {
      out.push(b)
    }
    return Ok(Bytes::from_array(out))
  }
  Err(InvalidInput("unsupported caret value format"))
}

fn build_lig_caret_list_subset(
  bytes : Array[Byte],
  offset : Int,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let cov_offset = match read_u16(bytes, offset) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let glyph_count = match read_u16(bytes, offset + 2) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if cov_offset == 0 || glyph_count <= 0 {
    return Ok(None)
  }
  let offsets_base = offset + 4
  if offsets_base + glyph_count * 2 > bytes.length() {
    return Err(InvalidInput("invalid lig caret offsets"))
  }
  let cov_base = offset + cov_offset
  let glyphs = match parse_coverage_subset(bytes, cov_base) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  if glyphs.length() != glyph_count {
    return Err(InvalidInput("lig caret glyph count mismatch"))
  }
  let records : Array[(Int, Bytes)] = []
  for i in 0..<glyph_count {
    let glyph = glyphs[i]
    if glyph < 0 || glyph >= plan.old_to_new.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let lig_offset = match read_u16(bytes, offsets_base + i * 2) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if lig_offset == 0 {
      continue
    }
    let lig_base = offset + lig_offset
    let caret_count = match read_u16(bytes, lig_base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    if caret_count < 0 {
      return Err(InvalidInput("invalid caret count"))
    }
    let caret_offsets_base = lig_base + 2
    if caret_offsets_base + caret_count * 2 > bytes.length() {
      return Err(InvalidInput("invalid caret offsets"))
    }
    let caret_values : Array[Bytes] = []
    for j in 0..<caret_count {
      let caret_offset = match read_u16(bytes, caret_offsets_base + j * 2) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if caret_offset == 0 {
        continue
      }
      let caret_base = lig_base + caret_offset
      let caret_bytes = match build_caret_value_subset(bytes, caret_base) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      caret_values.push(caret_bytes)
    }
    if caret_values.is_empty() {
      continue
    }
    let lig_bytes : Array[Byte] = []
    push_u16(lig_bytes, caret_values.length())
    let mut cursor = 2 + caret_values.length() * 2
    let offsets : Array[Int] = []
    for caret in caret_values {
      offsets.push(cursor)
      cursor = cursor + caret.length()
    }
    for offset_value in offsets {
      push_u16(lig_bytes, offset_value)
    }
    for caret in caret_values {
      for b in caret {
        lig_bytes.push(b)
      }
    }
    let new_gid = plan.old_to_new[glyph]
    if new_gid >= 0 {
      records.push((new_gid, Bytes::from_array(lig_bytes)))
    }
  }
  if records.is_empty() {
    return Ok(None)
  }
  records.sort_by((a, b) => {
    let (gid_a, _) = a
    let (gid_b, _) = b
    gid_a - gid_b
  })
  let mapped : Array[Int] = []
  for record in records {
    mapped.push(record.0)
  }
  let coverage = build_coverage_subset(mapped)
  let out : Array[Byte] = []
  let header_len = 4 + records.length() * 2
  push_u16(out, header_len)
  push_u16(out, records.length())
  let mut cursor = header_len + coverage.length()
  let offsets : Array[Int] = []
  for record in records {
    offsets.push(cursor)
    cursor = cursor + record.1.length()
  }
  for offset_value in offsets {
    push_u16(out, offset_value)
  }
  for b in coverage {
    out.push(b)
  }
  for record in records {
    for b in record.1 {
      out.push(b)
    }
  }
  Ok(Some(Bytes::from_array(out)))
}

fn build_gdef_subset(
  face : @face.Face,
  plan : SubsetPlan,
) -> Result[Bytes?, SubsetError] {
  let blob = match face.reference_table_optional(tag_gdef) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match blob {
    None => Ok(None)
    Some(blob) => {
      let bytes = blob.as_view().to_bytes().to_array()
      if bytes.length() < 12 {
        return Err(InvalidInput("invalid GDEF table"))
      }
      let version = match read_u32(bytes, 0) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if version < 0x00010000 {
        return Err(InvalidInput("invalid GDEF version"))
      }
      let glyph_class_def_offset = match read_u16(bytes, 4) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let attach_list_offset = match read_u16(bytes, 6) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let lig_caret_list_offset = match read_u16(bytes, 8) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mark_attach_class_def_offset = match read_u16(bytes, 10) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let mut mark_glyph_sets_def_offset = 0
      if version >= 0x00010002 {
        mark_glyph_sets_def_offset = match read_u16(bytes, 12) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      }
      let glyph_class_def = if glyph_class_def_offset != 0 {
        match build_class_def_subset(bytes, glyph_class_def_offset, plan) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      } else {
        None
      }
      let mark_attach_class_def = if mark_attach_class_def_offset != 0 {
        match build_class_def_subset(bytes, mark_attach_class_def_offset, plan) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      } else {
        None
      }
      let attach_list = if attach_list_offset != 0 {
        match build_attach_list_subset(bytes, attach_list_offset, plan) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      } else {
        None
      }
      let lig_caret_list = if lig_caret_list_offset != 0 {
        match build_lig_caret_list_subset(bytes, lig_caret_list_offset, plan) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      } else {
        None
      }
      let mark_glyph_sets = if mark_glyph_sets_def_offset != 0 {
        match build_mark_glyph_sets_subset(bytes, mark_glyph_sets_def_offset, plan) {
          Err(err) => return Err(err)
          Ok(value) => value
        }
      } else {
        None
      }
      if glyph_class_def is None &&
          mark_attach_class_def is None &&
          attach_list is None &&
          lig_caret_list is None &&
          mark_glyph_sets is None {
        return Ok(None)
      }
      let include_mark_sets = mark_glyph_sets is Some(_)
      let header_len = if include_mark_sets { 14 } else { 12 }
      let mut offset = header_len
      let glyph_class_offset = match glyph_class_def {
        None => 0
        Some(bytes) => {
          let current = offset
          offset = offset + bytes.length()
          current
        }
      }
      let attach_list_offset = match attach_list {
        None => 0
        Some(bytes) => {
          let current = offset
          offset = offset + bytes.length()
          current
        }
      }
      let lig_caret_list_offset = match lig_caret_list {
        None => 0
        Some(bytes) => {
          let current = offset
          offset = offset + bytes.length()
          current
        }
      }
      let mark_attach_offset = match mark_attach_class_def {
        None => 0
        Some(bytes) => {
          let current = offset
          offset = offset + bytes.length()
          current
        }
      }
      let mark_sets_offset = match mark_glyph_sets {
        None => 0
        Some(bytes) => {
          let current = offset
          offset = offset + bytes.length()
          current
        }
      }
      let out : Array[Byte] = []
      let out_version = if include_mark_sets { 0x00010002 } else { 0x00010000 }
      push_u32(out, out_version)
      push_u16(out, glyph_class_offset)
      push_u16(out, attach_list_offset)
      push_u16(out, lig_caret_list_offset)
      push_u16(out, mark_attach_offset)
      if include_mark_sets {
        push_u16(out, mark_sets_offset)
      }
      match glyph_class_def {
        None => ()
        Some(bytes) => {
          for b in bytes {
            out.push(b)
          }
        }
      }
      match attach_list {
        None => ()
        Some(bytes) => {
          for b in bytes {
            out.push(b)
          }
        }
      }
      match lig_caret_list {
        None => ()
        Some(bytes) => {
          for b in bytes {
            out.push(b)
          }
        }
      }
      match mark_attach_class_def {
        None => ()
        Some(bytes) => {
          for b in bytes {
            out.push(b)
          }
        }
      }
      match mark_glyph_sets {
        None => ()
        Some(bytes) => {
          for b in bytes {
            out.push(b)
          }
        }
      }
      Ok(Some(Bytes::from_array(out)))
    }
  }
}

fn build_plan_cff1(
  font : @font.Font,
  input : SubsetInput,
  cff : @ot_cff.Cff1Table,
) -> Result[SubsetPlan, SubsetError] {
  let face = font.get_face()
  let maxp_blob = match table_blob(face, tag_maxp, "maxp") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  if maxp.num_glyphs <= 0 {
    return Err(InvalidInput("font has no glyphs"))
  }
  if cff.glyph_count() != maxp.num_glyphs {
    return Err(InvalidInput("cff glyph count mismatch"))
  }
  let selected : Array[Bool] = Array::make(maxp.num_glyphs, false)
  let queue : Array[Int] = []
  let add_gid = (gid : Int) => {
    if gid < 0 || gid >= selected.length() {
      return
    }
    if !selected[gid] {
      selected[gid] = true
      queue.push(gid)
    }
  }
  add_gid(0)
  for codepoint in input.codepoints {
    let gid = match font.glyph_for_codepoint(codepoint) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    match gid {
      None => ()
      Some(gid) => add_gid(gid.reinterpret_as_int())
    }
  }
  let mut idx = 0
  while idx < queue.length() {
    let gid = queue[idx]
    idx = idx + 1
    let components = match cff.seac_components(gid) {
      Err(err) => return Err(Cff(err))
      Ok(value) => value
    }
    match components {
      None => ()
      Some((base, accent)) => {
        add_gid(base)
        add_gid(accent)
      }
    }
  }
  let glyphs : Array[UInt] = []
  for gid in 0..<selected.length() {
    if selected[gid] {
      glyphs.push(gid.reinterpret_as_uint())
    }
  }
  if glyphs.is_empty() {
    return Err(InvalidInput("empty subset"))
  }
  let old_to_new : Array[Int] = Array::make(maxp.num_glyphs, -1)
  for i in 0..<glyphs.length() {
    let old_gid = glyphs[i].reinterpret_as_int()
    if old_gid >= 0 && old_gid < old_to_new.length() {
      old_to_new[old_gid] = i
    }
  }
  let codepoint_map : Array[(UInt, Int)] = []
  for codepoint in input.codepoints {
    let gid = match font.glyph_for_codepoint(codepoint) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    match gid {
      None => ()
      Some(gid) => {
        let old_gid = gid.reinterpret_as_int()
        if old_gid >= 0 && old_gid < old_to_new.length() {
          let new_gid = old_to_new[old_gid]
          if new_gid >= 0 {
            codepoint_map.push((codepoint, new_gid))
          }
        }
      }
    }
  }
  Ok(SubsetPlan::{ glyphs, old_to_new, codepoint_map })
}

fn build_plan_cff2(
  font : @font.Font,
  input : SubsetInput,
  cff : @ot_cff.Cff2Table,
) -> Result[SubsetPlan, SubsetError] {
  let face = font.get_face()
  let maxp_blob = match table_blob(face, tag_maxp, "maxp") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  if maxp.num_glyphs <= 0 {
    return Err(InvalidInput("font has no glyphs"))
  }
  if cff.glyph_count() != maxp.num_glyphs {
    return Err(InvalidInput("cff2 glyph count mismatch"))
  }
  let selected : Array[Bool] = Array::make(maxp.num_glyphs, false)
  let add_gid = (gid : Int) => {
    if gid < 0 || gid >= selected.length() {
      return
    }
    selected[gid] = true
  }
  add_gid(0)
  for codepoint in input.codepoints {
    let gid = match font.glyph_for_codepoint(codepoint) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    match gid {
      None => ()
      Some(gid) => add_gid(gid.reinterpret_as_int())
    }
  }
  let glyphs : Array[UInt] = []
  for gid in 0..<selected.length() {
    if selected[gid] {
      glyphs.push(gid.reinterpret_as_uint())
    }
  }
  if glyphs.is_empty() {
    return Err(InvalidInput("empty subset"))
  }
  let old_to_new : Array[Int] = Array::make(maxp.num_glyphs, -1)
  for i in 0..<glyphs.length() {
    let old_gid = glyphs[i].reinterpret_as_int()
    if old_gid >= 0 && old_gid < old_to_new.length() {
      old_to_new[old_gid] = i
    }
  }
  let codepoint_map : Array[(UInt, Int)] = []
  for codepoint in input.codepoints {
    let gid = match font.glyph_for_codepoint(codepoint) {
      Err(err) => return Err(Font(err))
      Ok(value) => value
    }
    match gid {
      None => ()
      Some(gid) => {
        let old_gid = gid.reinterpret_as_int()
        if old_gid >= 0 && old_gid < old_to_new.length() {
          let new_gid = old_to_new[old_gid]
          if new_gid >= 0 {
            codepoint_map.push((codepoint, new_gid))
          }
        }
      }
    }
  }
  Ok(SubsetPlan::{ glyphs, old_to_new, codepoint_map })
}

///|
pub fn subset(
  font : @font.Font,
  input : SubsetInput,
) -> Result[Bytes, SubsetError] {
  let face = font.get_face()
  let has_glyf = match face.reference_table_optional(tag_glyf) {
    Err(err) => return Err(Face(err))
    Ok(value) => value
  }
  match has_glyf {
    Some(_) => {
      let plan = match build_plan(font, input) {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      subset_with_plan(font, plan)
    }
    None => {
      let cff_blob = match face.reference_table_optional(tag_cff) {
        Err(err) => return Err(Face(err))
        Ok(value) => value
      }
      let cff2_blob = match face.reference_table_optional(tag_cff2) {
        Err(err) => return Err(Face(err))
        Ok(value) => value
      }
      match cff_blob {
        Some(blob) => {
          let cff = match @ot_cff.Cff1Table::parse(blob.as_view()) {
            Err(err) => return Err(Cff(err))
            Ok(value) => value
          }
          let plan = match build_plan_cff1(font, input, cff) {
            Err(err) => return Err(err)
            Ok(value) => value
          }
          subset_cff1_with_plan(font, plan, cff)
        }
        None =>
          match cff2_blob {
            Some(blob) => {
              let cff = match @ot_cff.Cff2Table::parse(blob.as_view()) {
                Err(err) => return Err(Cff(err))
                Ok(value) => value
              }
              let plan = match build_plan_cff2(font, input, cff) {
                Err(err) => return Err(err)
                Ok(value) => value
              }
              subset_cff2_with_plan(font, plan, cff)
            }
            None => Err(Unsupported("missing outline table"))
          }
      }
    }
  }
}

///|
pub fn subset_with_plan(
  font : @font.Font,
  plan : SubsetPlan,
) -> Result[Bytes, SubsetError] {
  let face = font.get_face()
  let head_blob = match table_blob(face, tag_head, "head") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let head = match @sfnt.HeadTable::parse(head_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let maxp_blob = match table_blob(face, tag_maxp, "maxp") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hhea_blob = match table_blob(face, tag_hhea, "hhea") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hmtx_blob = match table_blob(face, tag_hmtx, "hmtx") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let loca_blob = match table_blob(face, tag_loca, "loca") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let glyf_blob = match table_blob(face, tag_glyf, "glyf") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let hhea = match @sfnt.HheaTable::parse(hhea_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let hmtx = match @sfnt.HmtxTable::parse(
    hmtx_blob.as_view(),
    maxp.num_glyphs,
    hhea.number_of_hmetrics,
  ) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let vmetrics = match build_vmetrics_subset(face, maxp, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let vorg_bytes = match build_vorg_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let loca = match @sfnt.LocaTable::parse(
    loca_blob.as_view(),
    maxp.num_glyphs,
    head.index_to_loc_format,
  ) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let glyf_data = glyf_blob.as_view()

  let new_offsets : Array[Int] = []
  let glyf_bytes : Array[Byte] = []
  let mut offset = 0
  for old_gid in plan.glyphs {
    new_offsets.push(offset)
    let gid = old_gid.reinterpret_as_int()
    if gid == 0 {
      continue
    }
    if gid + 1 >= loca.offsets.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let start = loca.offsets[gid]
    let end = loca.offsets[gid + 1]
    let length = end - start
    if length > 0 {
      let glyph_bytes = glyf_data[start:end].to_bytes().to_array()
      match remap_composite_glyph(glyph_bytes, plan.old_to_new) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      for b in glyph_bytes {
        glyf_bytes.push(b)
      }
      offset = offset + length
      if (offset & 1) != 0 {
        glyf_bytes.push(b'\x00')
        offset = offset + 1
      }
    }
  }
  new_offsets.push(offset)

  let mut use_short_loca = true
  let mut max_offset = 0
  for loc in new_offsets {
    if (loc & 1) != 0 {
      use_short_loca = false
      break
    }
    if loc > max_offset {
      max_offset = loc
    }
  }
  if use_short_loca {
    if (max_offset / 2) > 0xFFFF {
      use_short_loca = false
    }
  }
  let new_loca : Array[Byte] = []
  if use_short_loca {
    for loc in new_offsets {
      push_u16(new_loca, loc / 2)
    }
  } else {
    for loc in new_offsets {
      push_u32(new_loca, loc)
    }
  }

  let (new_hmtx, num_hmetrics) = match build_hmtx_subset(hmtx, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let head_bytes = head_blob.as_view().to_bytes().to_array()
  if head_bytes.length() >= 52 {
    write_u16(head_bytes, 50, if use_short_loca { 0 } else { 1 })
  }
  let maxp_bytes = maxp_blob.as_view().to_bytes().to_array()
  if maxp_bytes.length() >= 6 {
    write_u16(maxp_bytes, 4, plan.glyphs.length())
  }
  let hhea_bytes = hhea_blob.as_view().to_bytes().to_array()
  if hhea_bytes.length() >= 36 {
    write_u16(hhea_bytes, 34, num_hmetrics)
  }

  let cmap_bytes = build_cmap_from_pairs(face, plan.codepoint_map)
  let identity = is_identity_subset(plan, maxp.num_glyphs)

  let tables : Array[(@common.Tag, Bytes)] = [
    (tag_head, Bytes::from_array(head_bytes)),
    (tag_maxp, Bytes::from_array(maxp_bytes)),
    (tag_hhea, Bytes::from_array(hhea_bytes)),
    (tag_hmtx, new_hmtx),
    (tag_loca, Bytes::from_array(new_loca)),
    (tag_glyf, Bytes::from_array(glyf_bytes)),
  ]
  match vmetrics {
    None => ()
    Some((vhea_bytes, vmtx_bytes)) => {
      tables.push((tag_vhea, vhea_bytes))
      tables.push((tag_vmtx, vmtx_bytes))
    }
  }
  match vorg_bytes {
    None => ()
    Some(vorg) => tables.push((tag_vorg, vorg))
  }
  match cmap_bytes {
    None => ()
    Some(cmap) => tables.push((tag_cmap, cmap))
  }
  match add_identity_passthrough_tables(face, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gsub(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gpos(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_post(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_name(face, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_hdmx(face, maxp, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_kern(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_colr(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_svg(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_sbix(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_cblc_cbdt(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gdef(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_hvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_vvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_varc(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_os2(face, plan, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_passthrough_tables(face, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  Ok(build_sfnt(tables))
}

fn subset_cff1_with_plan(
  font : @font.Font,
  plan : SubsetPlan,
  cff : @ot_cff.Cff1Table,
) -> Result[Bytes, SubsetError] {
  let face = font.get_face()
  let head_blob = match table_blob(face, tag_head, "head") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp_blob = match table_blob(face, tag_maxp, "maxp") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hhea_blob = match table_blob(face, tag_hhea, "hhea") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hmtx_blob = match table_blob(face, tag_hmtx, "hmtx") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let hhea = match @sfnt.HheaTable::parse(hhea_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let hmtx = match @sfnt.HmtxTable::parse(
    hmtx_blob.as_view(),
    maxp.num_glyphs,
    hhea.number_of_hmetrics,
  ) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let vmetrics = match build_vmetrics_subset(face, maxp, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let vorg_bytes = match build_vorg_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let (new_hmtx, num_hmetrics) = match build_hmtx_subset(hmtx, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let head_bytes = head_blob.as_view().to_bytes().to_array()
  let maxp_bytes = maxp_blob.as_view().to_bytes().to_array()
  if maxp_bytes.length() >= 6 {
    write_u16(maxp_bytes, 4, plan.glyphs.length())
  }
  let hhea_bytes = hhea_blob.as_view().to_bytes().to_array()
  if hhea_bytes.length() >= 36 {
    write_u16(hhea_bytes, 34, num_hmetrics)
  }

  let glyph_ids : Array[Int] = []
  for gid in plan.glyphs {
    glyph_ids.push(gid.reinterpret_as_int())
  }
  let cff_bytes = match cff.subset(glyph_ids) {
    Err(err) => return Err(Cff(err))
    Ok(value) => value
  }

  let cmap_bytes = build_cmap_from_pairs(face, plan.codepoint_map)
  let identity = is_identity_subset(plan, maxp.num_glyphs)

  let tables : Array[(@common.Tag, Bytes)] = [
    (tag_head, Bytes::from_array(head_bytes)),
    (tag_maxp, Bytes::from_array(maxp_bytes)),
    (tag_hhea, Bytes::from_array(hhea_bytes)),
    (tag_hmtx, new_hmtx),
    (tag_cff, cff_bytes),
  ]
  match vmetrics {
    None => ()
    Some((vhea_bytes, vmtx_bytes)) => {
      tables.push((tag_vhea, vhea_bytes))
      tables.push((tag_vmtx, vmtx_bytes))
    }
  }
  match vorg_bytes {
    None => ()
    Some(vorg) => tables.push((tag_vorg, vorg))
  }
  match cmap_bytes {
    None => ()
    Some(cmap) => tables.push((tag_cmap, cmap))
  }
  match add_identity_passthrough_tables(face, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gsub(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_post(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_name(face, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_kern(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_colr(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_svg(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_sbix(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_cblc_cbdt(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gdef(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_hvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_vvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_varc(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_os2(face, plan, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_passthrough_tables(face, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  Ok(build_sfnt(tables))
}

fn subset_cff2_with_plan(
  font : @font.Font,
  plan : SubsetPlan,
  cff : @ot_cff.Cff2Table,
) -> Result[Bytes, SubsetError] {
  let face = font.get_face()
  let head_blob = match table_blob(face, tag_head, "head") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp_blob = match table_blob(face, tag_maxp, "maxp") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hhea_blob = match table_blob(face, tag_hhea, "hhea") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let hmtx_blob = match table_blob(face, tag_hmtx, "hmtx") {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let maxp = match @sfnt.MaxpTable::parse(maxp_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let hhea = match @sfnt.HheaTable::parse(hhea_blob.as_view()) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let hmtx = match @sfnt.HmtxTable::parse(
    hmtx_blob.as_view(),
    maxp.num_glyphs,
    hhea.number_of_hmetrics,
  ) {
    Err(err) => return Err(Sfnt(err))
    Ok(value) => value
  }
  let vmetrics = match build_vmetrics_subset(face, maxp, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let vorg_bytes = match build_vorg_subset(face, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let (new_hmtx, num_hmetrics) = match build_hmtx_subset(hmtx, plan) {
    Err(err) => return Err(err)
    Ok(value) => value
  }

  let head_bytes = head_blob.as_view().to_bytes().to_array()
  let maxp_bytes = maxp_blob.as_view().to_bytes().to_array()
  if maxp_bytes.length() >= 6 {
    write_u16(maxp_bytes, 4, plan.glyphs.length())
  }
  let hhea_bytes = hhea_blob.as_view().to_bytes().to_array()
  if hhea_bytes.length() >= 36 {
    write_u16(hhea_bytes, 34, num_hmetrics)
  }

  let glyph_ids : Array[Int] = []
  for gid in plan.glyphs {
    glyph_ids.push(gid.reinterpret_as_int())
  }
  let cff_bytes = match cff.subset(glyph_ids) {
    Err(err) => return Err(Cff(err))
    Ok(value) => value
  }

  let cmap_bytes = build_cmap_from_pairs(face, plan.codepoint_map)
  let identity = is_identity_subset(plan, maxp.num_glyphs)

  let tables : Array[(@common.Tag, Bytes)] = [
    (tag_head, Bytes::from_array(head_bytes)),
    (tag_maxp, Bytes::from_array(maxp_bytes)),
    (tag_hhea, Bytes::from_array(hhea_bytes)),
    (tag_hmtx, new_hmtx),
    (tag_cff2, cff_bytes),
  ]
  match vmetrics {
    None => ()
    Some((vhea_bytes, vmtx_bytes)) => {
      tables.push((tag_vhea, vhea_bytes))
      tables.push((tag_vmtx, vmtx_bytes))
    }
  }
  match vorg_bytes {
    None => ()
    Some(vorg) => tables.push((tag_vorg, vorg))
  }
  match cmap_bytes {
    None => ()
    Some(cmap) => tables.push((tag_cmap, cmap))
  }
  match add_identity_passthrough_tables(face, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gsub(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_post(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_name(face, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_kern(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_colr(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_svg(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_sbix(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_cblc_cbdt(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gdef(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_gvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_hvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_vvar(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_varc(face, plan, tables, identity) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_optional_os2(face, plan, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  match add_passthrough_tables(face, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  Ok(build_sfnt(tables))
}
