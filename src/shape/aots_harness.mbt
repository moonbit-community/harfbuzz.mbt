///|
pub struct AotsTestCase {
  font : String
  input : Array[UInt]
  expected : String
  no_positions : Bool
  no_advances : Bool
} derive(Show, ToJson)
