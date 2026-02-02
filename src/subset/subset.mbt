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
  Some(build_cmap_table(build_cmap_format12(groups)))
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

fn add_passthrough_tables(
  face : @face.Face,
  tables : Array[(@common.Tag, Bytes)],
) -> Result[Unit, SubsetError] {
  let tags : Array[@common.Tag] = [
    tag_name,
    tag_post,
    tag_os2,
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
      if (length & 1) != 0 {
        glyf_bytes.push(b'\x00')
        offset = offset + 1
      }
      offset = offset + length
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
  match cmap_bytes {
    None => ()
    Some(cmap) => tables.push((tag_cmap, cmap))
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
  match cmap_bytes {
    None => ()
    Some(cmap) => tables.push((tag_cmap, cmap))
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
  match cmap_bytes {
    None => ()
    Some(cmap) => tables.push((tag_cmap, cmap))
  }
  match add_passthrough_tables(face, tables) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  Ok(build_sfnt(tables))
}
