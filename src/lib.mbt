///|
/// Public version string for the module.
/// This is a placeholder while the port is bootstrapped.
pub let version_major : Int = 0

///|
pub let version_minor : Int = 0

///|
pub let version_micro : Int = 0

///|
pub let version : String = "\{version_major}.\{version_minor}.\{version_micro}"

///|
pub fn version_tuple() -> (Int, Int, Int) {
  (version_major, version_minor, version_micro)
}

///|
pub fn version_string() -> String {
  version
}

///|
pub fn version_atleast(major : Int, minor : Int, micro : Int) -> Bool {
  if version_major > major {
    true
  } else if version_major < major {
    false
  } else if version_minor > minor {
    true
  } else if version_minor < minor {
    false
  } else {
    version_micro >= micro
  }
}
