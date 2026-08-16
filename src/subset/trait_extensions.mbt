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
pub extend SubsetDataSuite with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SubsetDataSuite with ToJson::{to_json}

///|
pub extend SubsetError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SubsetError with Eq::{not_equal, equal}

///|
pub extend SubsetError with ToJson::{to_json}

///|
pub extend SubsetInput with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SubsetInput with ToJson::{to_json}

///|
pub extend SubsetPlan with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SubsetPlan with ToJson::{to_json}
