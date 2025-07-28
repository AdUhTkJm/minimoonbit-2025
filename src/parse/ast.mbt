struct LetDetail {
  name: String
  init: AST
  ty: Type
}

struct FnDetail {
  name: String
  args: Array[(String, Type)]
  body: AST
}

enum BKind {
  And; Or
  Add; Sub; Mul; Div; Mod
  Lt; Le; Eq; Ne
}

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
}

pub(all) struct TypedAST {
  ast: AST
  ty: Type
}
