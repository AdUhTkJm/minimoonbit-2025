pub fn MoveAlloca::run(self: MoveAlloca) -> Unit {
  for func in self.funcs() {
    MoveAlloca::run_fn(func);
  }
}

pub fn MoveAlloca::run_fn(func: Op) -> Unit {
  let allocas = func.find_all(Alloca);
  let bb = func.region().insert(func.block());
  
  for x in allocas {
    x.move_to_start(bb);
  }
}
