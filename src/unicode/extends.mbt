///|
pub extend SpaceFallbackType with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SpaceFallbackType with Eq::{not_equal, equal}

///|
pub extend SpaceFallbackType with ToJson::{to_json}
