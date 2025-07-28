pub struct Parser {
  mut place: Int
  data: Array[Token]
  locs: Array[Int]
}

pub fn Parser::new(data: Array[Token], locs: Array[Int]) -> Parser {
  { place: 0, data, locs }
}

pub fn Parser::consume(self: Parser) -> Token {
  if self.place >= self.data.length() {
    return EOF;
  }
  let t = self.data[self.place];
  self.place += 1;
  return t;
}

///|
/// Consumes the next token from the parser's token stream and advances
/// through it. Does not return the token.
///
pub fn Parser::advance(self: Parser) -> Unit {
  self.consume() |> ignore;
}

///|
/// Returns the current token at the parser's position without advancing the
/// position.
///
pub fn Parser::peek(self: Parser) -> Token {
  if self.place >= self.data.length() {
    return EOF;
  }
  return self.data[self.place];
}

///|
/// Returns the previous token at the parser's position. Does not perform any
/// boundary checks; panics if there's no such token.
///
pub fn Parser::last(self: Parser) -> Token {
  self.data[self.place - 1]
}

///|
/// Retraces (goes back) by one token.
/// 
pub fn Parser::retrace(self: Parser) -> Unit {
  self.place -= 1;
}

pub fn Parser::check(self: Parser, ty: Token) -> Bool {
  let old = self.place;
  if (not(self.consume().isa(ty))) {
    self.place = old;
    return false;
  }
  return true;
}

pub fn[T] Parser::die(self: Parser, msg: String) -> T {
  die("error: \{msg} (character: \{self.locs[self.place]})");
}

pub fn Parser::expect(self: Parser, ty: Token) -> Unit {
  let tok = self.consume();
  if (not(tok.isa(ty))) {
    self.die("expected \{ty}, but got \{tok}");
  }
}

pub fn Parser::ident(self: Parser) -> String {
  match self.consume() {
    Ident(x) => x
    Wildcard => "_"
    c => self.die("expected ident, but got \{c}")
  }
}

pub fn Parser::typename(self: Parser) -> String {
  match self.consume() {
    Typename(x) => x
    Wildcard => "_"
    c => self.die("expected typename, but got \{c}")
  }
}

pub fn Parser::base_type(self: Parser) -> Type {
  match self.consume() {
    Int => Int
    Bool => Bool
    Unit => Unit
    Double => Double
    Typename(x) => Unresolved(x)
    c => self.die("expected type, but got \{c}")
  }
}

pub fn Parser::read_type(self: Parser) -> Type {
  // TODO: more types
  let ty = self.base_type();
  return ty;
}

pub fn Parser::func(self: Parser, top~: Bool = false) -> AST {
  let name = self.ident();
  let args = [];
  let non_main = not(top && (name == "main"));
  if (non_main) {
    self.expect(LPar);
  }
  while (non_main && not(self.check(RPar))) {
    let name = self.ident();
    let ty = if (self.check(Colon)) { self.read_type() } else { Unknown }
    args.push((name, ty));
    if (not(self.peek().isa(RPar))) {
      self.expect(Comma);
    }
  }
  let retTy = if (self.check(Arrow)) { self.read_type() } else { Unknown }
  let body = self.block();
  Fn({ name, args, retTy, body })
}

pub fn Parser::block(self: Parser) -> AST {
  self.expect(LBrace);
  let stmts = []
  while (not(self.check(RBrace))) {
    stmts.push(self.stmt())
  }
  return Block(stmts);
}

pub fn Parser::primary(self: Parser) -> AST {
  match self.consume() {
    Vi(x) => Int(x)
    Vd(x) => Double(x)
    True => Bool(true)
    False => Bool(false)
    Ident(x) => Var(x)
    c => self.die("unexpected token \{c}")
  }
}

pub fn Parser::call(self: Parser) -> AST {
  let x = self.primary();
  while (self.peek().is_any([LPar, LBrak, Dot])) {
    match self.consume() {
      LPar => {
        let args = [];
        while (not(self.check(RPar))) {
          args.push(self.expr());
          if (not(self.peek().isa(RPar))) {
            self.expect(Comma);
          }
        }
        return Call(x, args);
      }
      _ => panic()
    }
  }
  x
}

pub fn Parser::_if(self: Parser) -> AST {
  if (self.check(If)) {
    let cond = self.expr();
    let ifso = self.block();
    let ifnot = if (self.check(Else)) { Some(self.block()) } else { None }
    return If(cond, ifso, ifnot);
  }
  if (self.check(Match)) {
    ...
  }
  return self.call();
}

pub fn Parser::mul(self: Parser) -> AST {
  let mut x = self._if();
  while (self.peek().is_any([Mul, Div, Mod])) {
    x = BinOp(match self.consume() {
      Mul => Mul
      Div => Div
      Mod => Mod
      _ => panic()
    }, x, self._if())
  }
  x
}

pub fn Parser::add(self: Parser) -> AST {
  let mut x = self.mul();
  while (self.peek().is_any([Add, Sub])) {
    x = BinOp(match self.consume() {
      Add => Add
      Sub => Sub
      _ => panic()
    }, x, self.mul())
  }
  x
}

// It's different from C.
pub fn Parser::cmp(self: Parser) -> AST {
  let mut x = self.add();
  while (self.peek().is_any([Lt, Le, Gt, Ge, Eq, Ne])) {
    match self.consume() {
      Lt => x = BinOp(Lt, x, self.add())
      Le => x = BinOp(Le, x, self.add())
      Gt => x = BinOp(Lt, self.add(), x)
      Ge => x = BinOp(Lt, self.add(), x)
      Eq => x = BinOp(Eq, x, self.add())
      Ne => x = BinOp(Ne, x, self.add())
      _ => panic()
    }
  }
  x
}

// "and" is a keyword.
pub fn Parser::_and(self: Parser) -> AST {
  let mut x = self.cmp();
  while (self.check(And)) {
    x = BinOp(And, x, self.cmp())
  }
  x
}

pub fn Parser::or(self: Parser) -> AST {
  let mut x = self._and();
  while (self.check(Or)) {
    x = BinOp(Or, x, self._and())
  }
  x
}

pub fn Parser::expr(self: Parser) -> AST {
  return self.or();
}

pub fn Parser::stmt(self: Parser) -> AST {
  match self.consume() {
    Fn => self.func();
    Let => self._let();
    _ => {
      self.retrace();
      let expr = self.expr();
      self.check(Semicolon) |> ignore;
      return expr;
    }
  }
}

pub fn Parser::_let(self: Parser, top~: Bool = false) -> AST {
  self.expect(Let);
  let name = self.ident();
  // We don't allow `name == '_'` in toplevel let.
  guard not(top) || name != "_";
  let mut ty = Unknown;
  if (self.check(Colon)) {
    ty = self.read_type();
  }
  self.expect(Assign);
  let init = self.expr();
  self.expect(Semicolon);
  Let({ name, ty, init })
}

pub fn Parser::toplevel(self: Parser) -> AST {
  match self.consume() {
    Let => self._let(top = true);
    Fn => self.func(top = true);
    c => self.die("unexpected toplevel \{c}")
  }
}

pub fn Parser::parse(self: Parser) -> Array[AST] {
  let result = [];
  while (not(self.peek().isa(EOF))) {
    result.push(self.toplevel());
  }
  return result;
}
