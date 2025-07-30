pub(all) enum Type {
  Int
  Double
  Bool
  Unit
  Unresolved(String)
  Weak(Int)
  Function(Type, Array[Type])
} derive(Show, Hash, Eq)

priv struct WeakCounter {
  mut cnt: Int
}

fn WeakCounter::weak(self: WeakCounter) -> Type {
  let cnt = self.cnt;
  self.cnt += 1;
  Weak(cnt);
}

let wenv: WeakCounter = { cnt: 0 };
