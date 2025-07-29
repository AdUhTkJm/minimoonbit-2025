pub(all) struct List[T] {
  mut begin: Node[T]
  mut end: Node[T]
};

pub(all) struct Node[T] {
  w: () -> T
  mut next: Node[T]?
  mut prev: Node[T]?
};

///|
/// Retrieves the value stored in the list.
/// 
pub fn[T] Node::v(self: Node[T]) -> T {
  (self.w)()
}

pub impl[T] Eq for Node[T] with op_equal(self, other) {
  physical_equal(self, other)
}

pub impl[T: Show] Show for List[T] with to_string(self) {
  if (self.empty()) {
    return "[]";
  }
  
  let sb = StringBuilder::new();
  let first = self.begin;
  sb.write_string(first.v().to_string());
  for c = first.next.unwrap(); c != self.end; c = c.next.unwrap() {
    sb.write_string(", ");
    sb.write_string(c.v().to_string());
  }
  "[\{sb.to_string()}]"
}

pub impl[T: Show] Show for List[T] with output(self, writer) {
  writer.write_string(self.to_string())
}

///|
/// I still can't understand how this works.
/// Looks still buggy.
/// 
pub fn[T] List::iter(self: List[T]) -> Iter[T] {
  return Iter::new(fn (x: (T) -> IterResult) -> IterResult {
    for c = self.begin; c != self.end; c = c.next.unwrap() {
      if (x(c.v()) is IterEnd) {
        return IterEnd;
      }
    }
    IterEnd
  });
}

///|
/// Applies `f` to every element in the list. Returns a new list.
/// 
pub fn[T, V] List::map(self: List[T], f: (T) -> V) -> List[V] {
  List::from_iter(self.iter().map(f));
}

///|
/// Create a list from an iterator.
/// 
pub fn[T] List::from_iter(iter: Iter[T]) -> List[T] {
  let l = List::new();
  iter.each((x) => l.push_back(x));
  l
}

///|
/// Create a list from an array. The elements are shallow-copied.
/// 
pub fn[T] List::from_array(arr: Array[T]) -> List[T] {
  let l = List::new();
  arr.each((x) => l.push_back(x));
  l
}

///|
/// Create a list from a separator.
/// 
pub fn[T: Show] List::join(self: List[T], sep: String) -> String {
  self.map(_.to_string()).join(sep)
}

///|
/// Create an empty list.
/// 
pub fn[T] List::new() -> List[T] {
  let sentinel = { w: () => { panic() }, next: None, prev: None };
  { begin: sentinel, end: sentinel }
}

///|
/// Create a standalone node.
/// 
pub fn[T] Node::from(w: T) -> Node[T] {
  { w: () => w, next: None, prev: None }
}

///|
/// Converts to array.
/// 
pub fn[T] List::to_array(self: List[T]) -> Array[T] {
  Array::from_iter(self.iter());
}

///|
/// Inserts an element before `it`.
/// 
pub fn[T] List::insert(self: List[T], it: Node[T], v: T) -> Unit {
  let new = Node::from(v)
  
  new.next = Some(it)
  if (it == self.begin) {
    self.begin.prev = Some(new);
    self.begin = new;
  } else {
    it.prev.unwrap().next = Some(new);
    new.prev = it.prev;
  }
  
  it.prev = Some(new);
}

///|
/// Removes an element pointed to by the iterator `it`.
/// 
pub fn[T] List::erase(self: List[T], it: Node[T]) -> Unit {
  if (self.begin == it && it.next.unwrap() == self.end) {
    self.begin = self.end;
    self.end.prev = None;
    return;
  }
  
  if (self.begin == it) {
    self.begin = it.next.unwrap();
    self.begin.prev = None;
  } else {
    it.prev.unwrap().next = it.next;
  }
  
  if (it.next.unwrap() == self.end) {
    self.end.prev = it.prev;
  } else {
    it.next.unwrap().prev = it.prev;
  }
  
  // Clean up the removed node
  it.next = None;
  it.prev = None;
}

///|
/// Append an element to the end of the list.
///
pub fn[T] List::push_back(self: List[T], v: T) -> Unit {
  if (self.empty()) {
    let new = Node::from(v);
    new.next = Some(self.end);
    self.end.prev = Some(new);
    self.begin = new;
    return;
  }

  self.insert(self.end, v);
}

pub fn[T] List::empty(self: List[T]) -> Bool {
  return self.begin == self.end;
}
