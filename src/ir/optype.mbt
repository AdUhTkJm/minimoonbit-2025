// Auto generated file. Do not edit!

pub(all) enum OpType {
  Module
  Func
  Add
  Sub
  Mul
  Div
  Mod
  Phi
  If
  For
  While
  Call
  Alloca
  Malloc
  Load
  Store
  Gep
  GetGlobal
  Global
  Int
  Double
  MakeTuple
  GetItem
} derive(Eq, Hash)

pub impl Show for OpType with output(self, logger) {
  let str = match self {
    Module => "module"
    Func => "func"
    Add => "add"
    Sub => "sub"
    Mul => "mul"
    Div => "div"
    Mod => "mod"
    Phi => "phi"
    If => "if"
    For => "for"
    While => "while"
    Call => "call"
    Alloca => "alloca"
    Malloc => "malloc"
    Load => "load"
    Store => "store"
    Gep => "gep"
    GetGlobal => "get_global"
    Global => "global"
    Int => "int"
    Double => "double"
    MakeTuple => "make_tuple"
    GetItem => "get_item"
  };
  logger.write_string(str);
}
