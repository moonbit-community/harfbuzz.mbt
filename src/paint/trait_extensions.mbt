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
pub extend Affine2x3 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Affine2x3 with Eq::{not_equal, equal}

///|
pub extend Affine2x3 with ToJson::{to_json}

///|
pub extend Color with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Color with Eq::{not_equal, equal}

///|
pub extend Color with ToJson::{to_json}

///|
pub extend ColorLine with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ColorLine with Eq::{not_equal, equal}

///|
pub extend ColorLine with ToJson::{to_json}

///|
pub extend ColorStop with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ColorStop with Eq::{not_equal, equal}

///|
pub extend ColorStop with ToJson::{to_json}

///|
pub extend Paint with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Paint with ToJson::{to_json}
