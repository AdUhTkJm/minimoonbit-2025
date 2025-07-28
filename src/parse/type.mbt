pub(all) enum Type {
  Int
  Double
  Bool
  Unit
  Unknown
  Unresolved(String)
  Weak(Int)
} derive(Show)
