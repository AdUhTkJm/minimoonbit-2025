pub fn MoveAlloca::run(self: MoveAlloca) -> Unit {
  for func in self.funcs() {
    MoveAlloca::runImpl(func);
  }
}

pub fn MoveAlloca::runImpl(func: Op) -> Unit {
  let allocas = func.findAll(AllocaOp);
  let bb = func.region().insert(func.block());
  
  for x in allocas {
    x.moveToStart(bb);
  }
}
