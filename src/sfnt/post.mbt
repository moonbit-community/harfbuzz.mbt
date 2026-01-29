///|
/// Parsed post table (subset).
pub struct PostTable {
  version : Int
  italic_angle : Int
  underline_position : Int
  underline_thickness : Int
  is_fixed_pitch : Int
  min_mem_type42 : Int
  max_mem_type42 : Int
  min_mem_type1 : Int
  max_mem_type1 : Int
  glyph_name_indices : Array[Int]?
  custom_names : Array[Bytes]?
} derive(Show, ToJson)

///|
fn read_i32(data : BytesView, offset : Int) -> Result[Int, SfntError] {
  match read_u32(data, offset) {
    Err(err) => Err(err)
    Ok(value) => Ok(value.reinterpret_as_int())
  }
}

///|
fn parse_post_names(
  data : BytesView,
  offset : Int,
  num_glyphs : Int,
) -> Result[(Array[Int], Array[Bytes]), SfntError] {
  if num_glyphs < 0 {
    return Err(InvalidFormat)
  }
  let indices : Array[Int] = []
  let mut cursor = offset
  let end = data.length()
  for _ in 0..<num_glyphs {
    let index = read_u16_int(data, cursor)
    match index {
      Err(err) => return Err(err)
      Ok(value) => indices.push(value)
    }
    cursor = cursor + 2
  }
  let custom_names : Array[Bytes] = []
  while cursor < end {
    let length = data[cursor].to_uint().reinterpret_as_int()
    cursor = cursor + 1
    if length < 0 {
      return Err(InvalidFormat)
    }
    let next = cursor + length
    if next > end {
      return Err(UnexpectedEof)
    }
    let bytes : Array[Byte] = []
    for i in cursor..<next {
      bytes.push(data[i])
    }
    custom_names.push(Bytes::from_array(bytes))
    cursor = next
  }
  Ok((indices, custom_names))
}

///|
/// Parse post table bytes (format 1.0/2.0/3.0 subset; names only for 2.0).
pub fn PostTable::parse(data : BytesView) -> Result[PostTable, SfntError] {
  let version = read_u32_int(data, 0)
  let italic_angle = read_i32(data, 4)
  let underline_position = read_i16(data, 8)
  let underline_thickness = read_i16(data, 10)
  let is_fixed_pitch = read_u32_int(data, 12)
  let min_mem_type42 = read_u32_int(data, 16)
  let max_mem_type42 = read_u32_int(data, 20)
  let min_mem_type1 = read_u32_int(data, 24)
  let max_mem_type1 = read_u32_int(data, 28)
  match (
    version,
    italic_angle,
    underline_position,
    underline_thickness,
    is_fixed_pitch,
    min_mem_type42,
    max_mem_type42,
    min_mem_type1,
    max_mem_type1,
  ) {
    (Err(err), _, _, _, _, _, _, _, _) => Err(err)
    (_, Err(err), _, _, _, _, _, _, _) => Err(err)
    (_, _, Err(err), _, _, _, _, _, _) => Err(err)
    (_, _, _, Err(err), _, _, _, _, _) => Err(err)
    (_, _, _, _, Err(err), _, _, _, _) => Err(err)
    (_, _, _, _, _, Err(err), _, _, _) => Err(err)
    (_, _, _, _, _, _, Err(err), _, _) => Err(err)
    (_, _, _, _, _, _, _, Err(err), _) => Err(err)
    (_, _, _, _, _, _, _, _, Err(err)) => Err(err)
    (
      Ok(version),
      Ok(italic_angle),
      Ok(underline_position),
      Ok(underline_thickness),
      Ok(is_fixed_pitch),
      Ok(min_mem_type42),
      Ok(max_mem_type42),
      Ok(min_mem_type1),
      Ok(max_mem_type1),
    ) => {
      let mut glyph_name_indices : Array[Int]? = None
      let mut custom_names : Array[Bytes]? = None
      if version == 0x00020000 {
        let num_glyphs = read_u16_int(data, 32)
        match num_glyphs {
          Err(err) => return Err(err)
          Ok(num_glyphs) => {
            let names = match parse_post_names(data, 34, num_glyphs) {
              Err(err) => return Err(err)
              Ok(value) => value
            }
            let (indices, names) = names
            glyph_name_indices = Some(indices)
            custom_names = Some(names)
          }
        }
      }
      Ok(PostTable::{
        version,
        italic_angle,
        underline_position,
        underline_thickness,
        is_fixed_pitch,
        min_mem_type42,
        max_mem_type42,
        min_mem_type1,
        max_mem_type1,
        glyph_name_indices,
        custom_names,
      })
    }
  }
}
