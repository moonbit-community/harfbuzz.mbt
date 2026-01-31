///|
fn clusters_monotone(
  infos : ArrayView[GlyphInfo],
  direction : @common.Direction,
) -> Bool {
  if !direction.is_valid() {
    return true
  }
  let forward = direction.is_forward()
  for i in 1..<infos.length() {
    let prev = infos[i - 1].cluster
    let curr = infos[i].cluster
    if prev != curr && ((prev < curr) != forward) {
      return false
    }
  }
  true
}

///|
/// Verify basic buffer invariants (cluster monotonicity and length consistency).
pub fn Buffer::verify(self : Buffer) -> Bool {
  if self.infos.length() != self.positions.length() {
    return false
  }
  clusters_monotone(self.infos[:], self.direction)
}
