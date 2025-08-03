fn flatten_if(func: Op) -> Bool {
  let mut changed = false;
  for op in func.block() {
    if (!op.isa(If)) {
      continue;
    }
    changed = true;

    // TODO
  }
  return changed;
}

pub fn Flatten::run_fn(func: Op) -> Unit {
  let mut changed = true;
  while (changed) {
    changed = false;
    changed = changed || flatten_if(func);
    // changed = changed || self.flatten_while();
  }

}

pub fn Flatten::run(self: Flatten) -> Unit {
  for func in self.funcs() {
    Flatten::run_fn(func);
  }
}
