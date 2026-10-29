///|
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
