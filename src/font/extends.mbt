///|
pub extend Font with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Font with ToJson::{to_json}

///|
pub extend FontError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FontError with Eq::{not_equal, equal}

///|
pub extend FontError with ToJson::{to_json}

///|
pub extend PointDelta with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PointDelta with ToJson::{to_json}
