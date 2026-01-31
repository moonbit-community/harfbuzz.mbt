///|
fn push_u16_tv(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(((value >> 8) & 0xff).to_byte())
  bytes.push((value & 0xff).to_byte())
}

///|
fn push_i16_tv(bytes : Array[Byte], value : Int) -> Unit {
  let adjusted = if value < 0 { value + 0x10000 } else { value }
  push_u16_tv(bytes, adjusted)
}

///|
fn build_tuple_variation_bytes() -> Bytes {
  let bytes : Array[Byte] = []
  push_u16_tv(bytes, 1) // tuple var count
  push_u16_tv(bytes, 10) // data offset
  push_u16_tv(bytes, 10) // tuple data size
  push_u16_tv(bytes, 0xA000) // embedded peak + private points
  push_i16_tv(bytes, 0x4000) // peak 1.0
  bytes.push(2) // point count
  bytes.push(1) // run length 2
  bytes.push(1)
  bytes.push(2)
  bytes.push(1) // x deltas: bytes
  bytes.push(0x32)
  bytes.push(0xec)
  bytes.push(1) // y deltas: bytes
  bytes.push(0x0A)
  bytes.push(0)
  Bytes::from_array(bytes)
}

///|
test "tuple variation decode" {
  let data = build_tuple_variation_bytes()
  let parsed = match TupleVariationData::parse(data[:], 1, []) {
    Err(err) => fail("parse failed: \{err}")
    Ok(value) => value
  }
  let tuples = match parsed.decode(4, true) {
    Err(err) => fail("decode failed: \{err}")
    Ok(value) => value
  }
  guard tuples.length() == 1 else {
    fail("expected 1 tuple")
  }
  let tuple = tuples[0]
  inspect(tuple.indices, content="Some([1, 3])")
  inspect(tuple.deltas_x, content="[50, -20]")
  inspect(tuple.deltas_y, content="Some([10, 0])")
  let applied = match parsed.apply([16384], 4, true) {
    Err(err) => fail("apply failed: \{err}")
    Ok(value) => value
  }
  let deltas_x = applied.0.map(delta => delta.round().to_int())
  inspect(deltas_x, content="[0, 50, 0, -20]")
  let deltas_y = match applied.1 {
    None => []
    Some(values) => values.map(delta => delta.round().to_int())
  }
  inspect(deltas_y, content="[0, 10, 0, 0]")
}
