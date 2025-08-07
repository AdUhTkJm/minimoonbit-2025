pub fn[T] die(msg: String) -> T {
  println(msg)
  panic()
}

///|
/// Let it panic when an error occurs.
/// 
pub fn[K, T] safe(f: (K) -> T raise?, v: K) -> T {
  (try? f(v)).unwrap()
}

pub fn[T] any(arr: Array[T], f: (T) -> Bool) -> Bool {
  for x in arr {
    if (f(x)) {
      return true;
    }
  }
  return false;
}

pub fn[T] none(arr: Array[T], f: (T) -> Bool) -> Bool {
  return !any(arr, f);
}

pub fn[T] all(arr: Array[T], f: (T) -> Bool) -> Bool {
  for x in arr {
    if (!f(x)) {
      return false;
    }
  }
  return true;
}
