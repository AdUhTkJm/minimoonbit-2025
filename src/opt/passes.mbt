// Auto generated. Do not edit!


pub(all) struct Dce {
  mut module: Op
}

pub impl Pass for Dce with name(_self) {
  return "dce";
}

pub impl Pass for Dce with operate(self) {
  Dce::run(self);
}

pub fn create_dce(module: Op) -> Dce {
  return Dce :: { module }
}

pub fn Dce::funcs(self: Dce) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[FuncOp](op)) {
      result.push(op);
    }
  }
  return result;
}
pub fn Dce::globals(self: Dce) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[GlobalOp](op)) {
      result.push(op);
    }
  }
  return result;
}

pub(all) struct Flatten {
  mut module: Op
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
    if (isa[FuncOp](op)) {
      result.push(op);
    }
  }
  return result;
}
pub fn Flatten::globals(self: Flatten) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[GlobalOp](op)) {
      result.push(op);
    }
  }
  return result;
}

pub(all) struct MoveAlloca {
  mut module: Op
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
    if (isa[FuncOp](op)) {
      result.push(op);
    }
  }
  return result;
}
pub fn MoveAlloca::globals(self: MoveAlloca) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[GlobalOp](op)) {
      result.push(op);
    }
  }
  return result;
}

pub(all) struct Mem2Reg {
  mut module: Op
  mut visited: Set[Block]
  mut converted: Set[Op]
  mut domtree: Map[Block, Array[Block]]
  mut phiFrom: Map[Op, Op]
}

pub impl Pass for Mem2Reg with name(_self) {
  return "mem2reg";
}

pub impl Pass for Mem2Reg with operate(self) {
  Mem2Reg::run(self);
}

pub fn create_mem2reg(module: Op) -> Mem2Reg {
  return Mem2Reg :: { module, visited: Set::new(), converted: Set::new(), domtree: Map::new(), phiFrom: Map::new() }
}

pub fn Mem2Reg::funcs(self: Mem2Reg) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[FuncOp](op)) {
      result.push(op);
    }
  }
  return result;
}
pub fn Mem2Reg::globals(self: Mem2Reg) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[GlobalOp](op)) {
      result.push(op);
    }
  }
  return result;
}

pub(all) struct Lower {
  mut module: Op
}

pub impl Pass for Lower with name(_self) {
  return "lower";
}

pub impl Pass for Lower with operate(self) {
  Lower::run(self);
}

pub fn create_lower(module: Op) -> Lower {
  return Lower :: { module }
}

pub fn Lower::funcs(self: Lower) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[FuncOp](op)) {
      result.push(op);
    }
  }
  return result;
}
pub fn Lower::globals(self: Lower) -> Array[Op] {
  let bb = self.module.region().block();
  let result = [];
  for op in bb {
    if (isa[GlobalOp](op)) {
      result.push(op);
    }
  }
  return result;
}
