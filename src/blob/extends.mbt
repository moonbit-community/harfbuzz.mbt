///|
pub extend Blob with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Blob with Eq::{not_equal, equal}

///|
pub extend Blob with ToJson::{to_json}

///|
pub extend BlobError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BlobError with Eq::{not_equal, equal}

///|
pub extend BlobError with ToJson::{to_json}

///|
pub extend MemoryMode with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MemoryMode with Eq::{not_equal, equal}

///|
pub extend MemoryMode with ToJson::{to_json}
