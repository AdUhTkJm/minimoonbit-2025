pub(all) enum Token {
  // Literals
  // Int and Double are reserved for type names, so we use Vi and Vd.
  Vi(Int); Vd(Double); True; False

  // Types
  Int; Double; Array; Bool; Unit

  // Keywords
  Not; If; Else; Fn; Let; Struct; Enum; Match
  While; Mut

  // Names
  Typename(String); Ident(String); Wildcard // _
  
  // Operators
  Eq; Ne; Gt; Ge; Lt; Le;
  Add; Sub; Mul; Div; Mod; Assign;
  AddEq; SubEq; MulEq; DivEq; ModEq
  And; Or; BitAnd; BitOr

  // Punctuation
  LPar; RPar; LBrak; RBrak; LBrace; RBrace
  Arrow; Colon; Semicolon; Comma; Dot; Arrrow // =>

  // Special
  EOF
} derive(Show, Eq, Hash)

pub fn Token::isa(self: Token, ty: Token) -> Bool {
  if (self == ty) {
    return true;
  }

  match (ty, self) {
    (Ident(_), Ident(_)) => true
    (Typename(_), Typename(_)) => true
    (Int(_), Int(_)) => true
    (Double(_), Double(_)) => true
    _ => false
  }
}

pub fn Token::is_any(self: Token, tys: Array[Token]) -> Bool {
  return @utils.any(tys, fn (ty) { self.isa(ty) });
}
