///|
pub struct AotsTestCase {
  font : String
  input : Array[UInt]
  expected : String
  feature_values : Array[Int]
  no_positions : Bool
  no_advances : Bool
} derive(Show, ToJson)
