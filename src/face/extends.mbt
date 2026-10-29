///|
pub extend Face with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Face with ToJson::{to_json}

///|
pub extend FaceTableError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FaceTableError with Eq::{not_equal, equal}

///|
pub extend FaceTableError with ToJson::{to_json}
