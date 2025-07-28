pub struct Lexer {
  mut loc: Int
  data: Array[Char]
}

pub fn Lexer::new(content: String) -> Lexer {
  { loc: 0, data: content.to_array() }
}

pub fn Lexer::lex(self: Lexer) -> (Array[Token], Array[Int]) {
  let tokens = [];
  let locs = [];
  while (self.has_next()) {
    locs.push(self.loc);
    tokens.push(self.next());
  }
  return (tokens, locs);
}

pub fn Lexer::has_next(self: Lexer) -> Bool {
  return self.loc < self.data.length() - 1 && self.peek(1) != '\u0000';
}

pub fn Lexer::ch(self: Lexer) -> Char {
  if (self.loc >= self.data.length()) {
    return '\u0000';
  }
  let ch = self.data[self.loc];
  self.loc += 1;
  return ch;
}

pub fn Lexer::peek(self: Lexer, i: Int) -> Char {
  if (self.loc + i >= self.data.length()) {
    return '\u0000';
  }
  return self.data[self.loc + i];
}

pub fn Lexer::advance(self: Lexer, i: Int) -> Unit {
  self.loc += i;
}

pub fn Lexer::check(self: Lexer, str: String) -> Bool {
  let arr = str.to_array();
  let len = arr.length();
  for i in 0..<len {
    if (self.peek(i) != arr[i]) {
      return false;
    }
  }
  self.advance(len);
  return true;
}

pub fn Lexer::retrace(self: Lexer) -> Unit {
  self.loc -= 1;
}

pub fn parse_int(digits: Array[Char], base: Int) -> Int {
  let str = String::from_array(digits);
  (try? @strconv.parse_int(str, base=base)).unwrap()
}

pub fn parse_double(digits: Array[Char]) -> Double {
  let str = String::from_array(digits);
  return safe(@strconv.parse_double, str);
}

pub fn Lexer::next(self: Lexer) -> Token {
  let c = self.ch();
  if (c is (' ' | '\t' | '\b' | '\r' | '\n')) {
    return self.next();
  }

  match c {
    '=' => {
      if (self.check("=")) {
        return Eq;
      }
      return Assign;
    }
    '!' => {
      if (self.check("=")) {
        return Eq;
      }
      return Not;
    }
    '<' => {
      if (self.check("=")) {
        return Le;
      }
      return Lt;
    }
    '>' => {
      if (self.check("=")) {
        return Ge;
      }
      return Gt;
    }
    '-' => {
      if (self.check(">")) {
        return Arrow;
      }
      return Sub;
    }
    '+' => Add
    '*' => Mul
    '/' => Div
    '%' => Mod
    '(' => LPar
    ')' => RPar
    '[' => LBrak
    ']' => RBrak
    '{' => LBrace
    '}' => RBrace
    ':' => Colon
    ';' => Semicolon
    '.' => Dot
    'a'..='z' => {
      let name = [c];
      for c = self.ch(); c is ('a'..='z' | 'A' ..= 'Z' | '_' | '0'..='9'); c = self.ch() {
        name.push(c);
      }
      self.retrace();
      let str = String::from_array(name);
      match str {
        "if" => If
        "else" => Else
        "not" => Not
        "struct" => Struct
        "enum" => Enum
        "fn" => Fn
        "match" => Match
        _ => Ident(str)
      }
    }
    'A'..='Z' => {
      let name = [c];
      for c = self.ch(); c is ('a'..='z' | 'A' ..= 'Z' | '_' | '0'..='9'); c = self.ch() {
        name.push(c);
      }
      self.retrace();
      let str = String::from_array(name);
      match str {
        "Bool" => Bool
        "Int" => Int
        "Double" => Double
        "Array" => Array
        "Unit" => Unit
        _ => Typename(str)
      }
    }
    '_' => Wildcard
    '0'..='9' => {
      let name = [c];
      for c = self.ch(); c is ('0'..='9'); c = self.ch() {
        name.push(c);
      }
      self.retrace();
      return Vi(parse_int(name, 10));
    }
    c => die("char: \{c}")
  }
}
