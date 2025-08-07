// Auto generated file. Do not edit!

pub(all) enum OpKind {
  ModuleOp
  FuncOp
  AddOp
  SubOp
  MulOp
  DivOp
  ModOp
  PhiOp
  IfOp
  ForOp
  WhileOp
  CallOp
  AllocaOp
  MallocOp
  LoadOp
  StoreOp
  GepOp
  GetGlobalOp
  GlobalOp
  IntOp
  DoubleOp
  MakeTupleOp
  GetItemOp
  GetArgOp
  MakeUnitOp
  AndOp
  OrOp
  NeOp
  EqOp
  LtOp
  LeOp
  BrOp
  GotoOp
  ReturnOp
} derive(Eq, Hash)

pub impl Default for OpKind with default() {
  return ModuleOp;
}

pub impl Show for OpKind with output(self, logger) {
  let str = match self {
    ModuleOp => "module"
    FuncOp => "func"
    AddOp => "add"
    SubOp => "sub"
    MulOp => "mul"
    DivOp => "div"
    ModOp => "mod"
    PhiOp => "phi"
    IfOp => "if"
    ForOp => "for"
    WhileOp => "while"
    CallOp => "call"
    AllocaOp => "alloca"
    MallocOp => "malloc"
    LoadOp => "load"
    StoreOp => "store"
    GepOp => "gep"
    GetGlobalOp => "get_global"
    GlobalOp => "global"
    IntOp => "int"
    DoubleOp => "double"
    MakeTupleOp => "make_tuple"
    GetItemOp => "get_item"
    GetArgOp => "get_arg"
    MakeUnitOp => "make_unit"
    AndOp => "and"
    OrOp => "or"
    NeOp => "ne"
    EqOp => "eq"
    LtOp => "lt"
    LeOp => "le"
    BrOp => "br"
    GotoOp => "goto"
    ReturnOp => "return"
  };
  logger.write_string(str);
}
