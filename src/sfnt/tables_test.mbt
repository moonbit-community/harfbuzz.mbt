///|
fn build_bytes(len : Int) -> Array[Byte] {
  let bytes : Array[Byte] = []
  for _ in 0..<len {
    bytes.push(0x00)
  }
  bytes
}

///|
fn build_cmap_table(
  subtable : Bytes,
  platform_id : Int,
  encoding_id : Int,
) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(((platform_id >> 8) & 0xff).to_byte())
  bytes.push((platform_id & 0xff).to_byte())
  bytes.push(((encoding_id >> 8) & 0xff).to_byte())
  bytes.push((encoding_id & 0xff).to_byte())
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x0c)
  for b in subtable {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format12(start : UInt, end : UInt, start_gid : UInt) -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x0c)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x1c)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x01)
  let start_arr = [
    (start >> 24).to_byte(),
    (start >> 16).to_byte(),
    (start >> 8).to_byte(),
    start.to_byte(),
  ]
  let end_arr = [
    (end >> 24).to_byte(),
    (end >> 16).to_byte(),
    (end >> 8).to_byte(),
    end.to_byte(),
  ]
  let gid_arr = [
    (start_gid >> 24).to_byte(),
    (start_gid >> 16).to_byte(),
    (start_gid >> 8).to_byte(),
    start_gid.to_byte(),
  ]
  for b in start_arr {
    bytes.push(b)
  }
  for b in end_arr {
    bytes.push(b)
  }
  for b in gid_arr {
    bytes.push(b)
  }
  Bytes::from_array(bytes)
}

///|
fn build_cmap_format4() -> Bytes {
  let bytes : Array[Byte] = []
  bytes.push(0x00)
  bytes.push(0x04)
  bytes.push(0x00)
  bytes.push(0x20)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x04)
  bytes.push(0x00)
  bytes.push(0x04)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x41)
  bytes.push(0xff)
  bytes.push(0xff)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x41)
  bytes.push(0xff)
  bytes.push(0xff)
  bytes.push(0xff)
  bytes.push(0xc4)
  bytes.push(0x00)
  bytes.push(0x01)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  bytes.push(0x00)
  Bytes::from_array(bytes)
}

///|
test "head table parse" {
  let bytes = build_bytes(54)
  bytes[18] = 0x03
  bytes[19] = 0xe8
  bytes[50] = 0x00
  bytes[51] = 0x01
  let head = match HeadTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(head.units_per_em, content="1000")
  inspect(head.index_to_loc_format, content="1")
}

///|
test "maxp table parse" {
  let bytes = build_bytes(6)
  bytes[4] = 0x00
  bytes[5] = 0x0a
  let maxp = match MaxpTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(maxp.num_glyphs, content="10")
}

///|
test "hhea table parse" {
  let bytes = build_bytes(36)
  bytes[34] = 0x00
  bytes[35] = 0x05
  let hhea = match HheaTable::parse(Bytes::from_array(bytes)[:]) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(hhea.number_of_hmetrics, content="5")
}

///|
test "hmtx table parse" {
  let bytes : Array[Byte] = [
    0x00, 0xc8, 0x00, 0x0a, 0x01, 0x2c, 0x00, 0x14, 0x00, 0x1e,
  ]
  let hmtx = match HmtxTable::parse(Bytes::from_array(bytes)[:], 3, 2) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  inspect(hmtx.advances, content="[200, 300, 300]")
  inspect(hmtx.lsbs, content="[10, 20, 30]")
}

///|
test "cmap format 12" {
  let subtable = build_cmap_format12(0x41U, 0x41U, 5U)
  let cmap_bytes = build_cmap_table(subtable, 3, 10)
  let cmap = match CmapTable::parse(@blob.Blob::from_bytes(cmap_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let gid = match cmap.glyph_for(0x41U) {
    Err(err) => fail("lookup error: \{err}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  inspect(gid, content="5")
}

///|
test "cmap format 4" {
  let subtable = build_cmap_format4()
  let cmap_bytes = build_cmap_table(subtable, 3, 1)
  let cmap = match CmapTable::parse(@blob.Blob::from_bytes(cmap_bytes)) {
    Err(err) => fail("parse error: \{err}")
    Ok(value) => value
  }
  let gid = match cmap.glyph_for(0x41U) {
    Err(err) => fail("lookup error: \{err}")
    Ok(None) => fail("missing glyph")
    Ok(Some(value)) => value
  }
  inspect(gid, content="5")
}
