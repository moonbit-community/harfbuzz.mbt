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
let tag_base : @common.Tag = @common.Tag::from_chars('B', 'A', 'S', 'E')

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
  tags : Array[@common.Tag],
  table_bytes : Array[Array[Byte]],
  offsets : Array[Int],
  checksums : Array[UInt],
) -> Bytes {
  let bytes : Array[Byte] = []
  push_u32(bytes, 0x00010000)
  push_u16(bytes, tags.length())
  let (search_range, entry_selector, range_shift) = sfnt_search_params(tags.length())
  push_u16(bytes, search_range)
  push_u16(bytes, entry_selector)
  push_u16(bytes, range_shift)
  for i in 0..<tags.length() {
    let tag = tags[i]
    let (b1, b2, b3, b4) = tag.bytes()
    bytes.push(b1)
    bytes.push(b2)
    bytes.push(b3)
    bytes.push(b4)
    push_u32_uint(bytes, checksums[i])
    push_u32(bytes, offsets[i])
    push_u32(bytes, table_bytes[i].length())
  }
  for i in 0..<table_bytes.length() {
    pad_to(bytes, offsets[i])
    for b in table_bytes[i] {
      bytes.push(b)
    }
  }
  pad_to(bytes, align4(bytes.length()))
  Bytes::from_array(bytes)
}

///|
fn build_sfnt(tables : Array[(@common.Tag, Bytes)]) -> Bytes {
  let sorted : Array[(@common.Tag, Bytes)] = []
  for entry in tables {
    sorted.push(entry)
  }
  sorted.sort_by((a, b) => {
    let (tag_a, _) = a
    let (tag_b, _) = b
    compare_tags(tag_a, tag_b)
  })
  let tags : Array[@common.Tag] = []
  let table_bytes : Array[Array[Byte]] = []
  for entry in sorted {
    let (tag, table) = entry
    tags.push(tag)
    table_bytes.push(table.to_array())
  }
  let mut offset = 12 + tags.length() * 16
  let offsets : Array[Int] = []
  for i in 0..<table_bytes.length() {
    offset = align4(offset)
    offsets.push(offset)
    offset = offset + table_bytes[i].length()
  }
  let mut head_index = -1
  for i in 0..<tags.length() {
    if tags[i] == tag_head {
      head_index = i
      break
    }
  }
  if head_index >= 0 && table_bytes[head_index].length() >= 12 {
    write_u32_uint(table_bytes[head_index], 8, 0U)
  }
  let checksums : Array[UInt] = []
  for table in table_bytes {
    checksums.push(checksum_bytes(table))
  }
  let mut bytes = build_sfnt_bytes(tags, table_bytes, offsets, checksums)
  if head_index >= 0 && table_bytes[head_index].length() >= 12 {
    let total = checksum_bytes(bytes.to_array())
    let adjust = 0xB1B0AFBAU - total
    write_u32_uint(table_bytes[head_index], 8, adjust)
    checksums[head_index] = checksum_bytes(table_bytes[head_index])
    bytes = build_sfnt_bytes(tags, table_bytes, offsets, checksums)
  }
  bytes
}

fn build_cmap_table_multi(subtables : Array[(Int, Int, Bytes)]) -> Bytes {
  let bytes : Array[Byte] = []
  push_u16(bytes, 0)
  push_u16(bytes, subtables.length())
  let mut offset = 4 + subtables.length() * 8
  let offsets : Array[Int] = []
  for entry in subtables {
    let (_, _, table) = entry
    offsets.push(offset)
    offset = offset + table.length()
  }
  for i in 0..<subtables.length() {
    let (platform, encoding, _) = subtables[i]
    push_u16(bytes, platform)
    push_u16(bytes, encoding)
    push_u32(bytes, offsets[i])
  }
  for entry in subtables {
    let (_, _, table) = entry
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
fn build_cmap_from_pairs(pairs : Array[(UInt, Int)]) -> Bytes? {
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
  let mut bmp_only = true
  for pair in dedup {
    if pair.0 > 0xFFFFU {
      bmp_only = false
      break
    }
  }
  let subtables : Array[(Int, Int, Bytes)] = []
  if bmp_only {
    match build_cmap_format4(groups) {
      None => ()
      Some(table) => subtables.push((3, 1, table))
    }
  }
  subtables.push((3, 10, build_cmap_format12(groups)))
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
      }
      tables.push((tag_os2, Bytes::from_array(bytes)))
      Ok(())
    }
  }
}

fn build_post_subset(
  blob : @blob.Blob,
  post : @sfnt.PostTable,
  plan : SubsetPlan,
) -> Bytes? {
  let indices = match post.glyph_name_indices {
    None => return None
    Some(value) => value
  }
  let names = match post.custom_names {
    None => return None
    Some(value) => value
  }
  if plan.glyphs.is_empty() {
    return None
  }
  let header = blob.as_view().to_bytes().to_array()
  if header.length() < 32 {
    return None
  }
  let new_custom : Array[Bytes] = []
  let old_to_new : Array[Int] = Array::make(names.length(), -1)
  let new_indices : Array[Int] = []
  for old_gid in plan.glyphs {
    let gid = old_gid.reinterpret_as_int()
    if gid < 0 || gid >= indices.length() {
      return None
    }
    let index = indices[gid]
    if index < 0 {
      return None
    }
    if index < 258 {
      new_indices.push(index)
    } else {
      let custom_index = index - 258
      if custom_index < 0 || custom_index >= names.length() {
        return None
      }
      let mut mapped = old_to_new[custom_index]
      if mapped < 0 {
        mapped = new_custom.length()
        old_to_new[custom_index] = mapped
        new_custom.push(names[custom_index])
      }
      new_indices.push(258 + mapped)
    }
  }
  let out : Array[Byte] = []
  for i in 0..<32 {
    out.push(header[i])
  }
  push_u16(out, plan.glyphs.length())
  for index in new_indices {
    push_u16(out, index)
  }
  for name in new_custom {
    let length = name.length()
    if length > 255 {
      return None
    }
    out.push(length.to_byte())
    for b in name {
      out.push(b)
    }
  }
  Some(Bytes::from_array(out))
}

fn add_optional_post(
  face : @face.Face,
  plan : SubsetPlan,
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
            match build_post_subset(blob, post, plan) {
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

fn add_optional_gdef(
  face : @face.Face,
  plan : SubsetPlan,
  tables : Array[(@common.Tag, Bytes)],
  identity : Bool,
) -> Result[Unit, SubsetError] {
  if identity {
    return add_optional_table(face, tag_gdef, tables)
  }
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
    tag_gsub,
    tag_gpos,
    tag_base,
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
    tag_cblc,
    tag_cbdt,
    tag_svg,
    tag_sbix,
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
    tag_name,
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
  let mut max_class = 0
  for i in 0..<glyph_count {
    let old_gid = plan.glyphs[i].reinterpret_as_int()
    let class_value = match class_def_value_subset(bytes, offset, old_gid) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    class_values.push(class_value)
    if class_value > max_class {
      max_class = class_value
    }
  }
  if max_class == 0 {
    return Ok(None)
  }
  let out : Array[Byte] = []
  push_u16(out, 1)
  push_u16(out, 0)
  push_u16(out, glyph_count)
  for value in class_values {
    push_u16(out, value)
  }
  Ok(Some(Bytes::from_array(out)))
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
    coverages.push(build_coverage_subset(mapped))
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
      if (offset & 3) != 0 {
        let pad = 4 - (offset & 3)
        for _ in 0..<pad {
          glyf_bytes.push(b'\x00')
        }
        offset = offset + pad
      }
    }
  }
  new_offsets.push(offset)

  let new_loca : Array[Byte] = []
  for loc in new_offsets {
    push_u32(new_loca, loc)
  }

  let new_hmtx : Array[Byte] = []
  for old_gid in plan.glyphs {
    let gid = old_gid.reinterpret_as_int()
    if gid < 0 || gid >= hmtx.advances.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let advance = hmtx.advances[gid]
    let lsb = hmtx.lsbs[gid]
    push_u16(new_hmtx, advance)
    push_i16(new_hmtx, lsb)
  }

  let head_bytes = head_blob.as_view().to_bytes().to_array()
  if head_bytes.length() >= 52 {
    write_u16(head_bytes, 50, 1)
  }
  let maxp_bytes = maxp_blob.as_view().to_bytes().to_array()
  if maxp_bytes.length() >= 6 {
    write_u16(maxp_bytes, 4, plan.glyphs.length())
  }
  let hhea_bytes = hhea_blob.as_view().to_bytes().to_array()
  if hhea_bytes.length() >= 36 {
    write_u16(hhea_bytes, 34, plan.glyphs.length())
  }

  let cmap_bytes = build_cmap_from_pairs(plan.codepoint_map)
  let identity = is_identity_subset(plan, maxp.num_glyphs)

  let tables : Array[(@common.Tag, Bytes)] = [
    (tag_head, Bytes::from_array(head_bytes)),
    (tag_maxp, Bytes::from_array(maxp_bytes)),
    (tag_hhea, Bytes::from_array(hhea_bytes)),
    (tag_hmtx, Bytes::from_array(new_hmtx)),
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
  match add_optional_post(face, plan, tables, identity) {
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
  match add_optional_gdef(face, plan, tables, identity) {
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

  let new_hmtx : Array[Byte] = []
  for old_gid in plan.glyphs {
    let gid = old_gid.reinterpret_as_int()
    if gid < 0 || gid >= hmtx.advances.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let advance = hmtx.advances[gid]
    let lsb = hmtx.lsbs[gid]
    push_u16(new_hmtx, advance)
    push_i16(new_hmtx, lsb)
  }

  let head_bytes = head_blob.as_view().to_bytes().to_array()
  let maxp_bytes = maxp_blob.as_view().to_bytes().to_array()
  if maxp_bytes.length() >= 6 {
    write_u16(maxp_bytes, 4, plan.glyphs.length())
  }
  let hhea_bytes = hhea_blob.as_view().to_bytes().to_array()
  if hhea_bytes.length() >= 36 {
    write_u16(hhea_bytes, 34, plan.glyphs.length())
  }

  let glyph_ids : Array[Int] = []
  for gid in plan.glyphs {
    glyph_ids.push(gid.reinterpret_as_int())
  }
  let cff_bytes = match cff.subset(glyph_ids) {
    Err(err) => return Err(Cff(err))
    Ok(value) => value
  }

  let cmap_bytes = build_cmap_from_pairs(plan.codepoint_map)
  let identity = is_identity_subset(plan, maxp.num_glyphs)

  let tables : Array[(@common.Tag, Bytes)] = [
    (tag_head, Bytes::from_array(head_bytes)),
    (tag_maxp, Bytes::from_array(maxp_bytes)),
    (tag_hhea, Bytes::from_array(hhea_bytes)),
    (tag_hmtx, Bytes::from_array(new_hmtx)),
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
  match add_optional_post(face, plan, tables, identity) {
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
  match add_optional_gdef(face, plan, tables, identity) {
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

  let new_hmtx : Array[Byte] = []
  for old_gid in plan.glyphs {
    let gid = old_gid.reinterpret_as_int()
    if gid < 0 || gid >= hmtx.advances.length() {
      return Err(InvalidInput("glyph id out of range"))
    }
    let advance = hmtx.advances[gid]
    let lsb = hmtx.lsbs[gid]
    push_u16(new_hmtx, advance)
    push_i16(new_hmtx, lsb)
  }

  let head_bytes = head_blob.as_view().to_bytes().to_array()
  let maxp_bytes = maxp_blob.as_view().to_bytes().to_array()
  if maxp_bytes.length() >= 6 {
    write_u16(maxp_bytes, 4, plan.glyphs.length())
  }
  let hhea_bytes = hhea_blob.as_view().to_bytes().to_array()
  if hhea_bytes.length() >= 36 {
    write_u16(hhea_bytes, 34, plan.glyphs.length())
  }

  let glyph_ids : Array[Int] = []
  for gid in plan.glyphs {
    glyph_ids.push(gid.reinterpret_as_int())
  }
  let cff_bytes = match cff.subset(glyph_ids) {
    Err(err) => return Err(Cff(err))
    Ok(value) => value
  }

  let cmap_bytes = build_cmap_from_pairs(plan.codepoint_map)
  let identity = is_identity_subset(plan, maxp.num_glyphs)

  let tables : Array[(@common.Tag, Bytes)] = [
    (tag_head, Bytes::from_array(head_bytes)),
    (tag_maxp, Bytes::from_array(maxp_bytes)),
    (tag_hhea, Bytes::from_array(hhea_bytes)),
    (tag_hmtx, Bytes::from_array(new_hmtx)),
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
  match add_optional_post(face, plan, tables, identity) {
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
  match add_optional_gdef(face, plan, tables, identity) {
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
