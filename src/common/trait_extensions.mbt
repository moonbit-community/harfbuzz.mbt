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
pub extend Direction with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Direction with Eq::{not_equal, equal}

///|
pub extend Direction with ToJson::{to_json}

///|
pub extend Language with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Language with Eq::{not_equal, equal}

///|
pub extend Language with ToJson::{to_json}

///|
pub extend OverflowRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend OverflowRecord with Eq::{not_equal, equal}

///|
pub extend Script with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Script with Eq::{not_equal, equal}

///|
pub extend Script with ToJson::{to_json}

///|
pub extend SerializeError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SerializeError with Eq::{not_equal, equal}

///|
pub extend SerializeWhence with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SerializeWhence with Eq::{not_equal, equal}

///|
pub extend Tag with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Tag with Eq::{not_equal, equal}

///|
pub extend Tag with Hash::{hash, hash_combine}

///|
pub extend Tag with Show::{output}

///|
pub extend Tag with ToJson::{to_json}
