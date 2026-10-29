///|
pub extend DrawExtents with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DrawExtents with ToJson::{to_json}

///|
pub extend DrawState with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DrawState with ToJson::{to_json}

///|
pub extend Outline with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Outline with ToJson::{to_json}

///|
pub extend OutlinePoint with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend OutlinePoint with Eq::{not_equal, equal}

///|
pub extend OutlinePoint with ToJson::{to_json}

///|
pub extend OutlinePointKind with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend OutlinePointKind with Eq::{not_equal, equal}

///|
pub extend OutlinePointKind with ToJson::{to_json}
