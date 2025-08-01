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

pub fn Type::map(self: Type, f: (Type) -> Type) -> Type {
  (match self {
    Function(t, arr) => Function(t.map(f), arr.map(_.map(f)));
    c => c
  }) |> f;
}
