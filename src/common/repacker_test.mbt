///|
test "repacker resolves simple overflow" {
  let obj0 = SerializeObject::new(Bytes::from_array([0, 0]))
  let obj1 = SerializeObject::new(Bytes::make(300, 0))
  let obj2 = SerializeObject::new(Bytes::from_array([0, 0]))
  obj0.real_links.push(SerializeLink::new(1, 0, 2))
  let order = repack_object_order([obj0, obj1, obj2])
  inspect(order, content="Ok([0, 2, 1])")
  let result = serialize_objects_repacked([obj0, obj1, obj2])
  match result {
    Err(err) => fail("serialize failed: \{err}")
    Ok(bytes) => {
      let arr = bytes.to_array()
      let prefix = [
        arr[0].to_int(),
        arr[1].to_int(),
        arr[2].to_int(),
        arr[3].to_int(),
      ]
      inspect(prefix, content="[2, 0, 0, 0]")
    }
  }
}

///|
test "serialize width zero link ordering" {
  let obj0 = SerializeObject::new(Bytes::from_array([1]))
  let obj1 = SerializeObject::new(Bytes::from_array([2]))
  obj0.real_links.push(SerializeLink::new(0, 0, 1))
  let result = serialize_objects([obj0, obj1])
  match result {
    Err(err) => fail("serialize failed: \{err}")
    Ok(bytes) => {
      let arr = bytes.to_array().map(b => b.to_int())
      inspect(arr, content="[1, 2]")
    }
  }

  let obj2 = SerializeObject::new(Bytes::from_array([1]))
  let obj3 = SerializeObject::new(Bytes::from_array([2]))
  obj3.real_links.push(SerializeLink::new(0, 0, 0))
  let result2 = serialize_objects([obj2, obj3])
  match result2 {
    Err(SerializeError::VirtualOrder) => ()
    Err(err) => fail("unexpected error: \{err}")
    Ok(_) => fail("expected virtual order error")
  }
}
