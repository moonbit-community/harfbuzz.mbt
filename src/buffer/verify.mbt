// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
    if prev != curr && (prev < curr) != forward {
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
