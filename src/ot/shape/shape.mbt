///|
/// Shape a buffer with OT GSUB/GPOS lookups.
pub fn shape(font : @font.Font, buffer : @buffer.Buffer) -> Result[Unit, @buffer.ShapeError] {
  buffer.guess_segment_properties()
  buffer.normalize()
  let script = buffer.get_script()
  if script == @common.script_arabic || script == @common.script_mongolian {
    return buffer.shape_arabic(font)
  }
  if script == @common.script_thai || script == @common.script_lao {
    return buffer.shape_thai(font)
  }
  if script == @common.script_khmer {
    return buffer.shape_khmer(font)
  }
  if script == @common.script_myanmar {
    return buffer.shape_myanmar(font)
  }
  if is_indic_script(script) {
    return buffer.shape_indic(font)
  }
  if is_use_script(script) {
    return buffer.shape_use(font)
  }
  if script == @common.script_hangul {
    return buffer.shape_hangul(font)
  }
  buffer.shape_ot(font)
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
/// Fallback shaping using cmap + advances only.
pub fn shape_basic(font : @font.Font, buffer : @buffer.Buffer) -> Result[Unit, @buffer.ShapeError] {
  buffer.shape_basic(font)
}
