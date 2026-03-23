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
/// Public version string for the module.
/// This is a placeholder while the port is bootstrapped.
pub let version_major : Int = 0

///|
pub let version_minor : Int = 0

///|
pub let version_micro : Int = 0

///|
pub let version : String = "\{version_major}.\{version_minor}.\{version_micro}"

///|
pub fn version_tuple() -> (Int, Int, Int) {
  (version_major, version_minor, version_micro)
}

///|
pub fn version_string() -> String {
  version
}

///|
pub fn version_atleast(major : Int, minor : Int, micro : Int) -> Bool {
  if version_major > major {
    true
  } else if version_major < major {
    false
  } else if version_minor > minor {
    true
  } else if version_minor < minor {
    false
  } else {
    version_micro >= micro
  }
}
