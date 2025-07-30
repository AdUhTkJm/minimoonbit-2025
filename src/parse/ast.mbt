pub struct LetDetail {
  name: String
  init: AST
  ty: Type
} derive(Show)

pub struct FnDetail {
  name: String
  args: Array[(String, Type)]
  retTy: Type
  body: AST
} derive(Show)

pub struct StructDetail {
  name: String
  fields: Array[(String, Type)]
} derive(Show)

pub enum BKind {
  And; Or
  Add; Sub; Mul; Div; Mod
  Lt; Le; Eq; Ne
} derive(Show)

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
} derive(Show)

pub(all) struct TypedAST {
  ast: AST
  ty: Type
} derive(Show)
