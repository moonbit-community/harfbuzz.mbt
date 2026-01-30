///|
let dotted_circle_codepoint : UInt = 0x25CCU

///|
fn is_syllabic_joiner(u : UInt) -> Bool {
  u == 0x200CU || u == 0x200DU
}

///|
fn is_syllabic_base(u : UInt) -> Bool {
  if u == dotted_circle_codepoint {
    return true
  }
  let cat = @unicode.general_category(u)
  cat == @unicode.gc_lowercase_letter ||
    cat == @unicode.gc_uppercase_letter ||
    cat == @unicode.gc_titlecase_letter ||
    cat == @unicode.gc_modifier_letter ||
    cat == @unicode.gc_other_letter ||
    cat == @unicode.gc_decimal_number ||
    cat == @unicode.gc_letter_number ||
    cat == @unicode.gc_other_number
}

///|
fn is_indic_script(script : @common.Script) -> Bool {
  script == @common.script_devanagari ||
    script == @common.script_bengali ||
    script == @common.script_gurmukhi ||
    script == @common.script_gujarati ||
    script == @common.script_oriya ||
    script == @common.script_tamil ||
    script == @common.script_telugu ||
    script == @common.script_kannada ||
    script == @common.script_malayalam
}

///|
fn is_use_script(script : @common.Script) -> Bool {
  script == @common.script_sinhala ||
    script == @common.script_tibetan ||
    script == @common.script_buhid ||
    script == @common.script_hanunoo ||
    script == @common.script_tagalog ||
    script == @common.script_tagbanwa ||
    script == @common.script_limbu ||
    script == @common.script_tai_le ||
    script == @common.script_buginese ||
    script == @common.script_kharoshthi ||
    script == @common.script_syloti_nagri ||
    script == @common.script_tifinagh ||
    script == @common.script_balinese ||
    script == @common.script_nko ||
    script == @common.script_phags_pa ||
    script == @common.script_cham ||
    script == @common.script_kayah_li ||
    script == @common.script_lepcha ||
    script == @common.script_rejang ||
    script == @common.script_saurashtra ||
    script == @common.script_sundanese ||
    script == @common.script_egyptian_hieroglyphs ||
    script == @common.script_javanese ||
    script == @common.script_kaithi ||
    script == @common.script_meetei_mayek ||
    script == @common.script_tai_tham ||
    script == @common.script_tai_viet ||
    script == @common.script_batak ||
    script == @common.script_brahmi ||
    script == @common.script_mandaic ||
    script == @common.script_chakma ||
    script == @common.script_miao ||
    script == @common.script_sharada ||
    script == @common.script_takri ||
    script == @common.script_duployan ||
    script == @common.script_grantha ||
    script == @common.script_khojki ||
    script == @common.script_khudawadi ||
    script == @common.script_mahajani ||
    script == @common.script_manichaean ||
    script == @common.script_modi ||
    script == @common.script_pahawh_hmong ||
    script == @common.script_psalter_pahlavi ||
    script == @common.script_siddham ||
    script == @common.script_tirhuta ||
    script == @common.script_ahom ||
    script == @common.script_multani ||
    script == @common.script_adlam ||
    script == @common.script_bhaiksuki ||
    script == @common.script_marchen ||
    script == @common.script_newa ||
    script == @common.script_masaram_gondi ||
    script == @common.script_soyombo ||
    script == @common.script_zanabazar_square ||
    script == @common.script_dogra ||
    script == @common.script_gunjala_gondi ||
    script == @common.script_hanifi_rohingya ||
    script == @common.script_makasar ||
    script == @common.script_medefaidrin ||
    script == @common.script_old_sogdian ||
    script == @common.script_sogdian ||
    script == @common.script_elymaic ||
    script == @common.script_nandinagari ||
    script == @common.script_nyiakeng_puachue_hmong ||
    script == @common.script_wancho ||
    script == @common.script_chorasmian ||
    script == @common.script_dives_akuru ||
    script == @common.script_khitan_small_script ||
    script == @common.script_yezidi ||
    script == @common.script_cypro_minoan ||
    script == @common.script_old_uyghur ||
    script == @common.script_tangsa ||
    script == @common.script_toto ||
    script == @common.script_vithkuqi ||
    script == @common.script_kawi ||
    script == @common.script_nag_mundari ||
    script == @common.script_garay ||
    script == @common.script_gurung_khema ||
    script == @common.script_kirat_rai ||
    script == @common.script_ol_onal ||
    script == @common.script_sunuwar ||
    script == @common.script_todhri ||
    script == @common.script_tulu_tigalari ||
    script == @common.script_beria_erfe ||
    script == @common.script_sidetic ||
    script == @common.script_tai_yo ||
    script == @common.script_tolong_siki
}

///|
fn uses_indic_table(script : @common.Script) -> Bool {
  is_indic_script(script) ||
    script == @common.script_khmer ||
    script == @common.script_myanmar ||
    is_use_script(script)
}

///|
fn indic_is_mark_category(cat : UInt) -> Bool {
  cat == 3U || // N / DB
    cat == 4U || // H
    cat == 5U || // ZWNJ
    cat == 6U || // ZWJ
    cat == 7U || // M
    cat == 8U || // SM
    cat == 9U || // A / VD
    cat == 13U || // MPst
    cat == 16U || // CM
    cat == 20U || // VAbv
    cat == 21U || // VBlw
    cat == 22U || // VPre
    cat == 23U || // VPst
    cat == 25U || // Robatic
    cat == 26U || // Xgroup
    cat == 27U || // Ygroup
    cat == 32U || // As
    cat == 35U || // MH
    cat == 36U || // MR
    cat == 37U || // MW
    cat == 38U || // MY
    cat == 39U || // PT
    cat == 40U || // VS
    cat == 41U || // ML
    cat == 57U // SMPst
}

///|
fn insert_dotted_circle_for_broken_syllables(buffer : Buffer) -> Bool {
  if buffer.infos.is_empty() {
    return false
  }
  let use_indic = uses_indic_table(buffer.script)
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let mut seen_base = false
  let mut inserted = false
  for i in 0..<buffer.infos.length() {
    let info = buffer.infos[i]
    let pos = buffer.positions[i]
    let codepoint = info.codepoint
    if is_syllabic_joiner(codepoint) {
      next_infos.push(info)
      next_positions.push(pos)
      continue
    }
    let mut is_mark = @unicode.is_mark(codepoint)
    if use_indic {
      let cat = indic_category(indic_get_categories(codepoint))
      if indic_is_mark_category(cat) {
        is_mark = true
      }
    }
    if is_mark {
      if !seen_base {
        inserted = true
        next_infos.push(GlyphInfo::{ codepoint: dotted_circle_codepoint, cluster: info.cluster })
        next_positions.push(GlyphPosition::{ x_advance: 0, y_advance: 0, x_offset: 0, y_offset: 0 })
        seen_base = true
      }
      next_infos.push(info)
      next_positions.push(pos)
      continue
    }
    if is_syllabic_base(codepoint) {
      seen_base = true
    } else {
      seen_base = false
    }
    next_infos.push(info)
    next_positions.push(pos)
  }
  if inserted {
    buffer.infos = next_infos
    buffer.positions = next_positions
  }
  inserted
}

///|
fn insert_dotted_circle_for_syllables(
  font : @font.Font,
  buffer : Buffer,
  syllables : Array[Int],
  broken_type : Int,
) -> Result[Bool, ShapeError] {
  if buffer.infos.length() != syllables.length() || buffer.infos.is_empty() {
    return Ok(false)
  }
  let has_dotted_circle = match font.glyph_for_codepoint(dotted_circle_codepoint) {
    Err(err) => return Err(Font(err))
    Ok(None) => false
    Ok(Some(_)) => true
  }
  if !has_dotted_circle {
    return Ok(false)
  }
  let next_infos : Array[GlyphInfo] = []
  let next_positions : Array[GlyphPosition] = []
  let mut inserted = false
  let mut last_syllable = -1
  for i in 0..<buffer.infos.length() {
    let syllable = syllables[i]
    if syllable != last_syllable && (syllable & 0x0f) == broken_type {
      inserted = true
      let info = buffer.infos[i]
      next_infos.push(GlyphInfo::{ codepoint: dotted_circle_codepoint, cluster: info.cluster })
      next_positions.push(GlyphPosition::{ x_advance: 0, y_advance: 0, x_offset: 0, y_offset: 0 })
    }
    next_infos.push(buffer.infos[i])
    next_positions.push(buffer.positions[i])
    last_syllable = syllable
  }
  if inserted {
    buffer.infos = next_infos
    buffer.positions = next_positions
  }
  Ok(inserted)
}

///|
fn insert_dotted_circle_if_supported(
  font : @font.Font,
  buffer : Buffer,
) -> Result[Bool, ShapeError] {
  let has_dotted_circle = match font.glyph_for_codepoint(dotted_circle_codepoint) {
    Err(err) => return Err(Font(err))
    Ok(None) => false
    Ok(Some(_)) => true
  }
  if !has_dotted_circle {
    return Ok(false)
  }
  Ok(insert_dotted_circle_for_broken_syllables(buffer))
}
