///| A map that supports an unchecked `operator[]`.
pub type Map[K, V](@builtin.Map[K, V]);

pub impl[K: Show, V: Show] Show for Map[K, V] with output(self, logger) {
  let w = self.to_array().map((x) => "\{x.0}: \{x.1}").join(", ");
  let str = "{ \{w} }";
  logger.write_string(str);
}

pub fn[K: Eq + Hash, V] Map::new() -> Map[K, V] {
  return {};
}

pub fn[K: Eq + Hash, V] Map::from_array(x: Array[(K, V)]) -> Map[K, V] {
  return @builtin.Map::from_array(x);
}

pub fn[K: Eq + Hash, V] Map::op_set(self: Map[K, V], x: K, y: V) -> Unit {
  self.inner().op_set(x, y);
}

pub fn[K: Eq + Hash, V] Map::op_get(self: Map[K, V], x: K) -> V {
  self.inner().get(x).unwrap();
}

pub fn[K: Eq + Hash, V] Map::get(self: Map[K, V], x: K) -> V? {
  self.inner().get(x);
}

pub fn[K: Eq + Hash, V] Map::remove(self: Map[K, V], x: K) -> Unit {
  self.inner().remove(x);
}

pub fn[K, V] Map::size(self: Map[K, V]) -> Int {
  self.inner().size();
}

pub fn[K, V] Map::to_array(self: Map[K, V]) -> Array[(K, V)] {
  self.inner().to_array();
}

pub fn[K, V] Map::iter(self: Map[K, V]) -> Iter[(K, V)] {
  self.inner().iter();
}

pub fn[K, V] Map::keys(self: Map[K, V]) -> Array[K] {
  self.to_array().map(fn (x) { x.0 })
}

pub fn[K, V] Map::values(self: Map[K, V]) -> Array[V] {
  self.to_array().map(fn (x) { x.1 })
}

pub fn[K: Eq + Hash, V] Map::contains(self: Map[K, V], k: K) -> Bool {
  self.inner().contains(k);
}

pub fn[K: Eq + Hash, V] Map::clone(self: Map[K, V]) -> Map[K, V] {
  Map::from_array(self.inner().to_array());
}

pub fn[K, V] Map::clear(self: Map[K, V]) -> Unit {
  self.inner().clear();
}
