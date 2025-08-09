pub(all) struct LetDetail {
  name: String
  init: AST
  mut ty: Type
} derive(Show, Hash, Eq)

pub(all) struct FnDetail {
  name: String
  mut args: Array[(String, Type)]
  mut retTy: Type
  body: AST
} derive(Show, Hash, Eq)

pub(all) struct StructDetail {
  name: String
  fields: Array[(String, Type)]
} derive(Show, Hash, Eq)

pub enum BKind {
  And; Or
  Add; Sub; Mul; Div; Mod
  Lt; Le; Eq; Ne
} derive(Show, Hash, Eq)

pub(all) enum AST {
  Int(Int)
  Double(Double)
  Bool(Bool)
  Let(LetDetail)
  Fn(FnDetail)
  Var(String)
  BinOp(BKind, AST, AST)
  Call(AST, Array[AST])
  Block(Array[AST])
  If(AST, AST, AST?)
  Struct(StructDetail)
  While(AST, AST)
  Return(AST?)
  Assign(AST, AST)
  CompoundAssign(BKind, AST, AST)
  Unit
  Array(Array[AST])
  Tuple(Array[AST])
} derive(Show, Hash, Eq)

pub fn AST::walk(self: AST, f: (AST) -> Unit) -> Unit {
  f(self);
  match self {
    Let({ init, .. }) => init.walk(f);
    Fn({ body, .. }) => body.walk(f);
    BinOp(_, x, y) | While(x, y) | Assign(x, y) | CompoundAssign(_, x, y) => { x.walk(f); y.walk(f); }
    Call(call, args) => { call.walk(f); args.each(_.walk(f)); }
    Tuple(arr) | Block(arr) | Array(arr) => { arr.each(_.walk(f)); }
    If(cond, ifso, ifnot) => { cond.walk(f); ifso.walk(f); if (ifnot is Some(x)) { x.walk(f); }; }
    Return(ret) => if (ret is Some(ret)) { ret.walk(f); }
    Struct(_) | Var(_) | Int(_) | Double(_) | Bool(_) | Unit => ()
  }
}
