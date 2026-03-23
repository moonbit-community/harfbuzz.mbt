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

fn main {
  if false {
    ignore(@hb_buffer.Buffer::new())
    let _ : @hb_draw.DrawFuncs[Unit] = @hb_draw.DrawFuncs::new()
    ignore(@hb_font.Font::from_bytes(Bytes::from_array([])))
    ignore(@hb_shape.available_shapers())
  }
  println(
    "This example is intended for the JS target. Build with: moon build --target js src/examples/js_svg",
  )
}
