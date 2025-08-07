// Auto generated. Do not edit!


pub struct Flatten {
  module: Op
}

pub impl Pass for Flatten with name(_self) {
  return "flatten";
}

pub impl Pass for Flatten with operate(self) {
  Flatten::run(self);
}

pub fn create_flatten(module: Op) -> Flatten {
  return Flatten :: { module }
}

pub fn Flatten::funcs(self: Flatten) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (op.isa(Func)) {
      result.push(op);
    }
  }
  return result;
}

pub struct MoveAlloca {
  module: Op
}

pub impl Pass for MoveAlloca with name(_self) {
  return "move_alloca";
}

pub impl Pass for MoveAlloca with operate(self) {
  MoveAlloca::run(self);
}

pub fn create_move_alloca(module: Op) -> MoveAlloca {
  return MoveAlloca :: { module }
}

pub fn MoveAlloca::funcs(self: MoveAlloca) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (op.isa(Func)) {
      result.push(op);
    }
  }
  return result;
}

pub struct Mem2Reg {
  module: Op
  visited: Set[Op]
}

pub impl Pass for Mem2Reg with name(_self) {
  return "mem2reg";
}

pub impl Pass for Mem2Reg with operate(self) {
  Mem2Reg::run(self);
}

pub fn create_mem2reg(module: Op) -> Mem2Reg {
  return Mem2Reg :: { module, visited: Set::new() }
}

pub fn Mem2Reg::funcs(self: Mem2Reg) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (op.isa(Func)) {
      result.push(op);
    }
  }
  return result;
}
