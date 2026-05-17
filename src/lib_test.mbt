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
test "version api" {
  let (major, minor, micro) = version_tuple()
  @debug.debug_inspect((major, minor, micro), content="(0, 0, 0)")
  let expected = "\{major}.\{minor}.\{micro}"
  inspect(version, content=expected)
  inspect(version_string(), content=expected)
  assert_true(version_atleast(major, minor, micro))
  assert_true(!version_atleast(major + 1, minor, micro))
  assert_true(!version_atleast(major, minor + 1, micro))
  assert_true(!version_atleast(major, minor, micro + 1))
}
