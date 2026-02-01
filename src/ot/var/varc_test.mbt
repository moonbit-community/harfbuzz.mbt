///|
fn push_u32_varc(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 24) & 0xff).to_byte())
  bytes.push(((value >> 16) & 0xff).to_byte())
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_u16_varc(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_varc(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_varc(bytes, adjusted)
}

///|
fn build_varc_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_varc(bytes, 0x00010000) // version
  push_u32_varc(bytes, 24) // coverage offset
  push_u32_varc(bytes, 0) // var store offset
  push_u32_varc(bytes, 0) // condition list offset
  push_u32_varc(bytes, 24) // axis indices offset
  push_u32_varc(bytes, 24) // glyph records offset
  // CFF2 INDEX for axis indices list with one entry [1,2,3]
  bytes.push(0)
  bytes.push(0)
  bytes.push(0)
  bytes.push(1) // count
  bytes.push(1) // offSize
  bytes.push(1) // offset[0]
  bytes.push(5) // offset[1]
  bytes.push(2) // tuple values control (3 bytes)
  bytes.push(1)
  bytes.push(2)
  bytes.push(3)
  Bytes::from_array(bytes)
}

///|
fn build_varc_bytes_with_condition() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_varc(bytes, 0x00010000) // version
  push_u32_varc(bytes, 0) // coverage offset
  push_u32_varc(bytes, 0) // var store offset
  push_u32_varc(bytes, 24) // condition list offset
  push_u32_varc(bytes, 0) // axis indices offset
  push_u32_varc(bytes, 0) // glyph records offset
  // ConditionList: count=1, offset=8
  push_u32_varc(bytes, 1)
  push_u32_varc(bytes, 8)
  // ConditionAxisRange format1
  push_u16_varc(bytes, 1)
  push_u16_varc(bytes, 0) // axis index
  push_i16_varc(bytes, -0x4000)
  push_i16_varc(bytes, 0x4000)
  Bytes::from_array(bytes)
}

///|
fn build_varc_bytes_with_glyph_record() -> Bytes {
  let bytes : Array[Byte] = []
  push_u32_varc(bytes, 0x00010000) // version
  push_u32_varc(bytes, 24) // coverage offset
  push_u32_varc(bytes, 0) // var store offset
  push_u32_varc(bytes, 0) // condition list offset
  push_u32_varc(bytes, 0) // axis indices offset
  push_u32_varc(bytes, 30) // glyph records offset
  // Coverage format 1 for glyph 5
  push_u16_varc(bytes, 1)
  push_u16_varc(bytes, 1)
  push_u16_varc(bytes, 5)
  // CFF2 INDEX with one record: [0xAA]
  push_u32_varc(bytes, 1)
  bytes.push(1) // offSize
  bytes.push(1) // offset[0]
  bytes.push(2) // offset[1]
  bytes.push((170).to_byte())
  Bytes::from_array(bytes)
}

///|
test "varc parse" {
  let varc = match VarcTable::parse(build_varc_bytes()[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  inspect((varc.coverage_offset, varc.glyph_records_offset), content="(24, 24)")
}

///|
test "varc axis indices list" {
  let varc = match VarcTable::parse(build_varc_bytes()[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let indices = match varc.axis_indices(0) {
    Err(err) => fail("axis indices failed: \{err}")
    Ok(value) => value
  }
  inspect(indices, content="[1, 2, 3]")
}

///|
test "varc condition list" {
  let varc = match VarcTable::parse(build_varc_bytes_with_condition()[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let conditions = match varc.conditions() {
    Err(err) => fail("conditions failed: \{err}")
    Ok(value) => value
  }
  inspect(conditions.length(), content="1")
  let cond = conditions[0]
  inspect(cond.evaluate([0], None), content="true")
  inspect(cond.evaluate([20000], None), content="false")
}

///|
test "varc glyph record" {
  let varc = match VarcTable::parse(build_varc_bytes_with_glyph_record()[:]) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let record = match varc.glyph_record(5) {
    Err(err) => fail("glyph record failed: \{err}")
    Ok(value) => value
  }
  inspect(record.map(bytes => bytes.to_array().map(b => b.to_int())), content="Some([170])")
  let missing = match varc.glyph_record(6) {
    Err(err) => fail("glyph record missing failed: \{err}")
    Ok(value) => value
  }
  inspect(missing, content="None")
}
