///|
pub struct GdefHeader {
  version : UInt
  glyph_class_def_offset : Int?
  attach_list_offset : Int?
  lig_caret_list_offset : Int?
  mark_attach_class_def_offset : Int?
  mark_glyph_sets_def_offset : Int?
} derive(Show, ToJson)

///|
pub struct GdefTable {
  data : BytesView
  header : GdefHeader
} derive(Show, ToJson)

///|
pub fn GdefTable::parse(blob : @blob.Blob) -> Result[GdefTable, OtLayoutError] {
  let data = blob.as_view()
  let version = read_u32(data, 0)
  match version {
    Err(err) => Err(err)
    Ok(version) => {
      if version < 0x00010000U {
        return Err(InvalidFormat)
      }
      let header_len = if version >= 0x00010002U { 14 } else { 12 }
      match check_range(data, 0, header_len) {
        Err(err) => return Err(err)
        Ok(_) => ()
      }
      let glyph_class_def_offset = read_u16_int(data, 4)
      let attach_list_offset = read_u16_int(data, 6)
      let lig_caret_list_offset = read_u16_int(data, 8)
      let mark_attach_class_def_offset = read_u16_int(data, 10)
      match (
        glyph_class_def_offset,
        attach_list_offset,
        lig_caret_list_offset,
        mark_attach_class_def_offset,
      ) {
        (Err(err), _, _, _) => Err(err)
        (_, Err(err), _, _) => Err(err)
        (_, _, Err(err), _) => Err(err)
        (_, _, _, Err(err)) => Err(err)
        (
          Ok(glyph_class_def_offset),
          Ok(attach_list_offset),
          Ok(lig_caret_list_offset),
          Ok(mark_attach_class_def_offset),
        ) => {
          let mark_glyph_sets_def_offset =
            if version >= 0x00010002U {
              match read_u16_int(data, 12) {
                Err(err) => return Err(err)
                Ok(value) => if value == 0 { None } else { Some(value) }
              }
            } else {
              None
            }
          let header = GdefHeader::{
            version,
            glyph_class_def_offset: if glyph_class_def_offset == 0 {
              None
            } else {
              Some(glyph_class_def_offset)
            },
            attach_list_offset: if attach_list_offset == 0 {
              None
            } else {
              Some(attach_list_offset)
            },
            lig_caret_list_offset: if lig_caret_list_offset == 0 {
              None
            } else {
              Some(lig_caret_list_offset)
            },
            mark_attach_class_def_offset: if mark_attach_class_def_offset == 0 {
              None
            } else {
              Some(mark_attach_class_def_offset)
            },
            mark_glyph_sets_def_offset,
          }
          Ok(GdefTable::{ data, header })
        }
      }
    }
  }
}

///|
pub fn GdefTable::header(self : GdefTable) -> GdefHeader {
  self.header
}

///|
pub fn GdefTable::glyph_class(
  self : GdefTable,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  match self.header.glyph_class_def_offset {
    None => Ok(0)
    Some(offset) => class_def_value(self.data, offset, glyph)
  }
}

///|
pub fn GdefTable::mark_attach_class(
  self : GdefTable,
  glyph : UInt,
) -> Result[Int, OtLayoutError] {
  match self.header.mark_attach_class_def_offset {
    None => Ok(0)
    Some(offset) => class_def_value(self.data, offset, glyph)
  }
}

///|
pub fn GdefTable::mark_glyph_set_contains(
  self : GdefTable,
  set_index : Int,
  glyph : UInt,
) -> Result[Bool, OtLayoutError] {
  match self.header.mark_glyph_sets_def_offset {
    None => Ok(false)
    Some(offset) => {
      if offset < 0 || offset + 4 > self.data.length() {
        return Err(UnexpectedEof)
      }
      let format = read_u16_int(self.data, offset)
      let set_count = read_u16_int(self.data, offset + 2)
      match (format, set_count) {
        (Err(err), _) => Err(err)
        (_, Err(err)) => Err(err)
        (Ok(format), Ok(set_count)) => {
          if format != 1 || set_count <= 0 {
            return Err(InvalidFormat)
          }
          if set_index < 0 || set_index >= set_count {
            return Err(InvalidFormat)
          }
          let list_base = offset + 4
          if list_base < 0 || list_base + set_count * 2 > self.data.length() {
            return Err(UnexpectedEof)
          }
          let cov_offset = read_u16_int(self.data, list_base + set_index * 2)
          match cov_offset {
            Err(err) => Err(err)
            Ok(cov_offset) => {
              if cov_offset == 0 {
                return Err(InvalidFormat)
              }
              let cov_base = offset + cov_offset
              let covered = coverage_index(self.data, cov_base, glyph)
              match covered {
                Err(err) => Err(err)
                Ok(None) => Ok(false)
                Ok(Some(_)) => Ok(true)
              }
            }
          }
        }
      }
    }
  }
}
