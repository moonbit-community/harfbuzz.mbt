let feat_flag_exclusive = 0x8000
let feat_flag_not_default = 0x4000
let feat_flag_index_mask = 0x00ff

///|
/// Feature setting name record.
pub struct FeatSettingName {
  setting : Int
  name_id : Int
} derive(Eq, Show, ToJson)

///|
/// Feature name record.
pub struct FeatFeatureName {
  feature : Int
  name_id : Int
  flags : Int
  settings : Array[FeatSettingName]
} derive(Eq, Show, ToJson)

///|
/// Parsed feat table.
pub struct FeatTable {
  version : Int
  features : Array[FeatFeatureName]
} derive(Show, ToJson)

///|
pub fn FeatTable::has_data(self : FeatTable) -> Bool {
  self.version != 0
}

///|
pub fn FeatTable::feature_types(self : FeatTable) -> Array[Int] {
  let types : Array[Int] = []
  for feature in self.features {
    types.push(feature.feature)
  }
  types
}

///|
pub fn FeatTable::feature(
  self : FeatTable,
  feature_type : Int,
) -> FeatFeatureName? {
  for feature in self.features {
    if feature.feature == feature_type {
      return Some(feature)
    }
  }
  None
}

///|
pub fn FeatFeatureName::is_exclusive(self : FeatFeatureName) -> Bool {
  (self.flags & feat_flag_exclusive) != 0
}

///|
pub fn FeatFeatureName::default_setting_index(
  self : FeatFeatureName,
) -> Int? {
  if !self.is_exclusive() {
    return None
  }
  let index = if (self.flags & feat_flag_not_default) != 0 {
    self.flags & feat_flag_index_mask
  } else {
    0
  }
  if index < 0 || index >= self.settings.length() {
    None
  } else {
    Some(index)
  }
}

///|
pub fn FeatFeatureName::default_setting(
  self : FeatFeatureName,
) -> FeatSettingName? {
  match self.default_setting_index() {
    None => None
    Some(index) => Some(self.settings[index])
  }
}

///|
/// Parse a feat table.
pub fn FeatTable::parse(data : BytesView) -> Result[FeatTable, AatError] {
  let version = read_i32(data, 0)
  let feature_count = read_u16_int(data, 4)
  let reserved1 = read_u16_int(data, 6)
  let reserved2 = read_u32_non_negative(data, 8)
  match (version, feature_count, reserved1, reserved2) {
    (Err(err), _, _, _) => Err(err)
    (_, Err(err), _, _) => Err(err)
    (_, _, Err(err), _) => Err(err)
    (_, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(feature_count), Ok(_), Ok(_)) => {
      if feature_count < 0 {
        return Err(InvalidFormat)
      }
      let records_base = 12
      let record_size = 12
      if records_base + feature_count * record_size > data.length() {
        return Err(UnexpectedEof)
      }
      let features : Array[FeatFeatureName] = []
      for i in 0..<feature_count {
        let record_offset = records_base + i * record_size
        let feature = read_u16_int(data, record_offset)
        let n_settings = read_u16_int(data, record_offset + 2)
        let settings_offset = read_u32_non_negative(data, record_offset + 4)
        let flags = read_u16_int(data, record_offset + 8)
        let name_id = read_i16(data, record_offset + 10)
        match (feature, n_settings, settings_offset, flags, name_id) {
          (Err(err), _, _, _, _) => return Err(err)
          (_, Err(err), _, _, _) => return Err(err)
          (_, _, Err(err), _, _) => return Err(err)
          (_, _, _, Err(err), _) => return Err(err)
          (_, _, _, _, Err(err)) => return Err(err)
          (Ok(feature), Ok(n_settings), Ok(settings_offset), Ok(flags), Ok(name_id)) => {
            if n_settings < 0 || settings_offset < 0 {
              return Err(InvalidFormat)
            }
            if settings_offset + n_settings * 4 > data.length() {
              return Err(UnexpectedEof)
            }
            let settings : Array[FeatSettingName] = []
            for j in 0..<n_settings {
              let setting_offset = settings_offset + j * 4
              let setting = read_u16_int(data, setting_offset)
              let setting_name = read_u16_int(data, setting_offset + 2)
              match (setting, setting_name) {
                (Err(err), _) => return Err(err)
                (_, Err(err)) => return Err(err)
                (Ok(setting), Ok(setting_name)) => {
                  settings.push(
                    FeatSettingName::{ setting, name_id: setting_name },
                  )
                }
              }
            }
            features.push(
              FeatFeatureName::{ feature, name_id, flags, settings },
            )
          }
        }
      }
      Ok(FeatTable::{ version, features })
    }
  }
}
