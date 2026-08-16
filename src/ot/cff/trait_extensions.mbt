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
/// Keeps trait methods available through dot syntax.
pub extend Cff1Table with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Cff1Table with Eq::{not_equal, equal}

///|
pub extend Cff1Table with ToJson::{to_json}

///|
pub extend Cff2PrivateDict with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Cff2PrivateDict with Eq::{not_equal, equal}

///|
pub extend Cff2PrivateDict with ToJson::{to_json}

///|
pub extend Cff2Table with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Cff2Table with Eq::{not_equal, equal}

///|
pub extend Cff2Table with ToJson::{to_json}

///|
pub extend CffBounds with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CffBounds with Eq::{not_equal, equal}

///|
pub extend CffBounds with ToJson::{to_json}

///|
pub extend CffDict with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CffDict with Eq::{not_equal, equal}

///|
pub extend CffDict with ToJson::{to_json}

///|
pub extend CffError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CffError with Eq::{not_equal, equal}

///|
pub extend CffError with ToJson::{to_json}

///|
pub extend CffIndex with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CffIndex with Eq::{not_equal, equal}

///|
pub extend CffIndex with ToJson::{to_json}

///|
pub extend CffNumber with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CffNumber with Eq::{not_equal, equal}

///|
pub extend CffNumber with ToJson::{to_json}
