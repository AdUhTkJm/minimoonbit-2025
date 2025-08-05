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
