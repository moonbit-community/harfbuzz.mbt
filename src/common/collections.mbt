///|
pub let codepoint_invalid : UInt = 0xFFFF_FFFFU

///|
pub let map_value_invalid : UInt = codepoint_invalid

///|
pub struct CodepointSet {
  set : Set[UInt]
}

///|
pub fn CodepointSet::new() -> CodepointSet {
  CodepointSet::{ set: Set::new() }
}

///|
pub fn CodepointSet::clear(self : CodepointSet) -> Unit {
  self.set.clear()
}

///|
pub fn CodepointSet::is_empty(self : CodepointSet) -> Bool {
  self.set.is_empty()
}

///|
pub fn CodepointSet::population(self : CodepointSet) -> Int {
  self.set.length()
}

///|
pub fn CodepointSet::get_min(self : CodepointSet) -> UInt {
  let values = sorted_values(self)
  if values.is_empty() { map_value_invalid } else { values[0] }
}

///|
pub fn CodepointSet::get_max(self : CodepointSet) -> UInt {
  let values = sorted_values(self)
  if values.is_empty() { map_value_invalid } else { values[values.length() - 1] }
}

///|
pub fn CodepointSet::add(self : CodepointSet, value : UInt) -> Unit {
  self.set.add(value)
}

///|
pub fn CodepointSet::add_array(self : CodepointSet, values : ArrayView[UInt]) -> Unit {
  for value in values {
    self.set.add(value)
  }
}

///|
pub fn CodepointSet::add_sorted_array(
  self : CodepointSet,
  values : ArrayView[UInt],
) -> Bool {
  if values.is_empty() {
    return true
  }
  let mut prev = values[0]
  for i in 1..<values.length() {
    let value = values[i]
    if value < prev {
      return false
    }
    prev = value
  }
  for value in values {
    self.set.add(value)
  }
  true
}

///|
pub fn CodepointSet::add_range(
  self : CodepointSet,
  first : UInt,
  last : UInt,
) -> Bool {
  if first > last {
    return false
  }
  let mut value = first
  while true {
    self.set.add(value)
    if value == last {
      break
    }
    value = value + 1U
  }
  true
}

///|
pub fn CodepointSet::del(self : CodepointSet, value : UInt) -> Unit {
  self.set.remove(value)
}

///|
pub fn CodepointSet::del_range(
  self : CodepointSet,
  first : UInt,
  last : UInt,
) -> Unit {
  if first > last {
    return ()
  }
  let mut value = first
  while true {
    self.set.remove(value)
    if value == last {
      break
    }
    value = value + 1U
  }
}

///|
pub fn CodepointSet::has(self : CodepointSet, value : UInt) -> Bool {
  self.set.contains(value)
}

///|
pub fn CodepointSet::to_sorted_array(self : CodepointSet) -> Array[UInt] {
  let values = self.set.to_array()
  values.sort()
  values
}

///|
pub fn CodepointSet::union(self : CodepointSet, other : CodepointSet) -> CodepointSet {
  let merged = CodepointSet::new()
  for value in self.set.iter() {
    merged.set.add(value)
  }
  for value in other.set.iter() {
    merged.set.add(value)
  }
  merged
}

///|
pub fn CodepointSet::set_from(self : CodepointSet, other : CodepointSet) -> Unit {
  self.set.clear()
  for value in other.set.iter() {
    self.set.add(value)
  }
}

///|
pub fn CodepointSet::union_in_place(self : CodepointSet, other : CodepointSet) -> Unit {
  for value in other.set.iter() {
    self.set.add(value)
  }
}

///|
pub fn CodepointSet::intersect_in_place(self : CodepointSet, other : CodepointSet) -> Unit {
  let to_remove : Array[UInt] = []
  for value in self.set.iter() {
    if !other.set.contains(value) {
      to_remove.push(value)
    }
  }
  for value in to_remove {
    self.set.remove(value)
  }
}

///|
pub fn CodepointSet::subtract_in_place(self : CodepointSet, other : CodepointSet) -> Unit {
  for value in other.set.iter() {
    self.set.remove(value)
  }
}

///|
pub fn CodepointSet::symmetric_difference_in_place(
  self : CodepointSet,
  other : CodepointSet,
) -> Unit {
  let to_remove : Array[UInt] = []
  for value in other.set.iter() {
    if self.set.contains(value) {
      to_remove.push(value)
    } else {
      self.set.add(value)
    }
  }
  for value in to_remove {
    self.set.remove(value)
  }
}

///|
pub fn CodepointSet::intersect(self : CodepointSet, other : CodepointSet) -> CodepointSet {
  let out = CodepointSet::new()
  for value in self.set.iter() {
    if other.set.contains(value) {
      out.set.add(value)
    }
  }
  out
}

///|
pub fn CodepointSet::subtract(self : CodepointSet, other : CodepointSet) -> CodepointSet {
  let out = CodepointSet::new()
  for value in self.set.iter() {
    if !other.set.contains(value) {
      out.set.add(value)
    }
  }
  out
}

///|
pub fn CodepointSet::is_equal(self : CodepointSet, other : CodepointSet) -> Bool {
  self.set.equal(other.set)
}

///|
pub fn CodepointSet::is_subset(self : CodepointSet, other : CodepointSet) -> Bool {
  for value in self.set.iter() {
    if !other.set.contains(value) {
      return false
    }
  }
  true
}

///|
pub fn CodepointSet::may_intersect(self : CodepointSet, other : CodepointSet) -> Bool {
  for value in self.set.iter() {
    if other.set.contains(value) {
      return true
    }
  }
  false
}

///|
pub fn CodepointSet::intersects(self : CodepointSet, first : UInt, last : UInt) -> Bool {
  if first > last {
    return false
  }
  let values = sorted_values(self)
  for value in values {
    if value < first {
      continue
    }
    if value > last {
      break
    }
    return true
  }
  false
}

///|
pub fn CodepointSet::hash(self : CodepointSet) -> Int {
  let values = sorted_values(self)
  let hasher = Hasher::new(seed=0)
  for value in values {
    hasher.combine_uint(value)
  }
  hasher.finalize()
}

fn sorted_values(set : CodepointSet) -> Array[UInt] {
  set.to_sorted_array()
}

///|
/// Return the next value after `after` (exclusive). Use `codepoint_invalid` to start.
pub fn CodepointSet::next(self : CodepointSet, after? : UInt = codepoint_invalid) -> UInt? {
  let values = sorted_values(self)
  if values.is_empty() {
    return None
  }
  if after == codepoint_invalid {
    return Some(values[0])
  }
  for value in values {
    if value > after {
      return Some(value)
    }
  }
  None
}

///|
pub fn CodepointSet::next_many(
  self : CodepointSet,
  after? : UInt = codepoint_invalid,
  size? : Int = 0,
) -> Array[UInt] {
  if size <= 0 {
    return []
  }
  let values = sorted_values(self)
  if values.is_empty() {
    return []
  }
  let out : Array[UInt] = []
  let mut started = after == codepoint_invalid
  for value in values {
    if !started {
      if value > after {
        started = true
      } else {
        continue
      }
    }
    out.push(value)
    if out.length() >= size {
      break
    }
  }
  out
}

///|
/// Return the previous value before `before` (exclusive). Use `codepoint_invalid` to start.
pub fn CodepointSet::previous(self : CodepointSet, before? : UInt = codepoint_invalid) -> UInt? {
  let values = sorted_values(self)
  if values.is_empty() {
    return None
  }
  if before == codepoint_invalid {
    return Some(values[values.length() - 1])
  }
  for value in values.rev_iter() {
    if value < before {
      return Some(value)
    }
  }
  None
}

///|
/// Return the next contiguous range at or after `start`.
pub fn CodepointSet::next_range(
  self : CodepointSet,
  start? : UInt = codepoint_invalid,
) -> (UInt, UInt)? {
  let values = sorted_values(self)
  if values.is_empty() {
    return None
  }
  let mut idx = 0
  if start != codepoint_invalid {
    while idx < values.length() && values[idx] < start {
      idx = idx + 1
    }
  }
  if idx >= values.length() {
    return None
  }
  let first = values[idx]
  let mut last = first
  idx = idx + 1
  while idx < values.length() {
    let value = values[idx]
    if value == last + 1U {
      last = value
      idx = idx + 1
    } else {
      break
    }
  }
  Some((first, last))
}

///|
/// Return the previous contiguous range ending at or before `end`.
pub fn CodepointSet::previous_range(
  self : CodepointSet,
  end? : UInt = codepoint_invalid,
) -> (UInt, UInt)? {
  let values = sorted_values(self)
  if values.is_empty() {
    return None
  }
  let mut idx = values.length() - 1
  if end != codepoint_invalid {
    while idx >= 0 && values[idx] > end {
      if idx == 0 {
        return None
      }
      idx = idx - 1
    }
  }
  let last = values[idx]
  let mut first = last
  while idx > 0 {
    let prev = values[idx - 1]
    if prev + 1U == first {
      first = prev
      idx = idx - 1
    } else {
      break
    }
  }
  Some((first, last))
}

///|
pub struct CodepointMap {
  map : Map[UInt, UInt]
}

///|
pub fn CodepointMap::new() -> CodepointMap {
  CodepointMap::{ map: Map::new() }
}

///|
pub fn CodepointMap::clear(self : CodepointMap) -> Unit {
  self.map.clear()
}

///|
pub fn CodepointMap::is_empty(self : CodepointMap) -> Bool {
  self.map.is_empty()
}

///|
pub fn CodepointMap::population(self : CodepointMap) -> Int {
  self.map.length()
}

///|
pub fn CodepointMap::is_equal(self : CodepointMap, other : CodepointMap) -> Bool {
  self.map.equal(other.map)
}

///|
pub fn CodepointMap::copy(self : CodepointMap) -> CodepointMap {
  CodepointMap::{ map: self.map.copy() }
}

///|
pub fn CodepointMap::set(self : CodepointMap, key : UInt, value : UInt) -> Unit {
  if key == map_value_invalid {
    return ()
  }
  if value == map_value_invalid {
    self.map.remove(key)
  } else {
    self.map.set(key, value)
  }
}

///|
pub fn CodepointMap::get(self : CodepointMap, key : UInt) -> UInt {
  match self.map.get(key) {
    None => map_value_invalid
    Some(value) => value
  }
}

///|
pub fn CodepointMap::del(self : CodepointMap, key : UInt) -> Unit {
  self.map.remove(key)
}

///|
pub fn CodepointMap::has(self : CodepointMap, key : UInt) -> Bool {
  self.map.contains(key)
}

///|
pub fn CodepointMap::update(self : CodepointMap, other : CodepointMap) -> Unit {
  for key, value in other.map.iter2() {
    self.map.set(key, value)
  }
}

///|
pub fn CodepointMap::keys(self : CodepointMap) -> Array[UInt] {
  Array::from_iter(self.map.keys())
}

///|
pub fn CodepointMap::values(self : CodepointMap) -> Array[UInt] {
  Array::from_iter(self.map.values())
}

///|
pub fn CodepointMap::iter(self : CodepointMap) -> Iter[(UInt, UInt)] {
  self.map.iter()
}

///|
pub struct CodepointBiMap {
  forward : CodepointMap
  backward : CodepointMap
}

///|
pub fn CodepointBiMap::new() -> CodepointBiMap {
  CodepointBiMap::{ forward: CodepointMap::new(), backward: CodepointMap::new() }
}

///|
pub fn CodepointBiMap::clear(self : CodepointBiMap) -> Unit {
  self.forward.clear()
  self.backward.clear()
}

///|
pub fn CodepointBiMap::is_empty(self : CodepointBiMap) -> Bool {
  self.forward.is_empty()
}

///|
pub fn CodepointBiMap::population(self : CodepointBiMap) -> Int {
  self.forward.population()
}

///|
pub fn CodepointBiMap::set(self : CodepointBiMap, lhs : UInt, rhs : UInt) -> Unit {
  if lhs == map_value_invalid {
    return ()
  }
  if rhs == map_value_invalid {
    self.del(lhs)
    return ()
  }
  self.forward.set(lhs, rhs)
  self.backward.set(rhs, lhs)
}

///|
pub fn CodepointBiMap::get(self : CodepointBiMap, lhs : UInt) -> UInt {
  self.forward.get(lhs)
}

///|
pub fn CodepointBiMap::backward(self : CodepointBiMap, rhs : UInt) -> UInt {
  self.backward.get(rhs)
}

///|
pub fn CodepointBiMap::has(self : CodepointBiMap, lhs : UInt) -> Bool {
  self.forward.has(lhs)
}

///|
pub fn CodepointBiMap::del(self : CodepointBiMap, lhs : UInt) -> Unit {
  let rhs = self.forward.get(lhs)
  if rhs != map_value_invalid {
    self.backward.del(rhs)
    self.forward.del(lhs)
  }
}

///|
pub fn CodepointBiMap::keys(self : CodepointBiMap) -> Array[UInt] {
  self.forward.keys()
}

///|
pub fn CodepointBiMap::values(self : CodepointBiMap) -> Array[UInt] {
  self.forward.values()
}

///|
pub struct CodepointIncBiMap {
  forward : CodepointMap
  back : Array[UInt]
}

///|
pub fn CodepointIncBiMap::new() -> CodepointIncBiMap {
  CodepointIncBiMap::{ forward: CodepointMap::new(), back: [] }
}

///|
pub fn CodepointIncBiMap::clear(self : CodepointIncBiMap) -> Unit {
  self.forward.clear()
  self.back.clear()
}

///|
pub fn CodepointIncBiMap::population(self : CodepointIncBiMap) -> Int {
  self.forward.population()
}

///|
pub fn CodepointIncBiMap::get_next_value(self : CodepointIncBiMap) -> UInt {
  self.back.length().reinterpret_as_uint()
}

///|
pub fn CodepointIncBiMap::add(self : CodepointIncBiMap, lhs : UInt) -> UInt {
  let existing = self.forward.get(lhs)
  if existing != map_value_invalid {
    return existing
  }
  let rhs = self.back.length().reinterpret_as_uint()
  self.forward.set(lhs, rhs)
  self.back.push(lhs)
  rhs
}

///|
pub fn CodepointIncBiMap::skip(self : CodepointIncBiMap, count? : Int = 1) -> UInt {
  let start = self.back.length().reinterpret_as_uint()
  if count <= 0 {
    return start
  }
  for _ in 0..<count {
    self.back.push(map_value_invalid)
  }
  start
}

///|
pub fn CodepointIncBiMap::get(self : CodepointIncBiMap, lhs : UInt) -> UInt {
  self.forward.get(lhs)
}

///|
pub fn CodepointIncBiMap::backward(self : CodepointIncBiMap, rhs : UInt) -> UInt {
  let idx = rhs.reinterpret_as_int()
  if idx < 0 || idx >= self.back.length() {
    map_value_invalid
  } else {
    self.back[idx]
  }
}

///|
pub fn CodepointIncBiMap::has(self : CodepointIncBiMap, lhs : UInt) -> Bool {
  self.forward.has(lhs)
}

///|
pub fn CodepointIncBiMap::add_set(self : CodepointIncBiMap, set : CodepointSet) -> Unit {
  for value in set.to_sorted_array() {
    ignore(self.add(value))
  }
}

///|
pub fn CodepointIncBiMap::identity(self : CodepointIncBiMap, size : Int) -> Bool {
  self.clear()
  if size < 0 {
    return false
  }
  for i in 0..<size {
    ignore(self.add(i.reinterpret_as_uint()))
  }
  true
}

///|
pub fn CodepointIncBiMap::sort(self : CodepointIncBiMap) -> Unit {
  let values = self.back.copy()
  values.sort()
  self.clear()
  for value in values {
    if value != map_value_invalid {
      ignore(self.add(value))
    } else {
      ignore(self.skip())
    }
  }
}
