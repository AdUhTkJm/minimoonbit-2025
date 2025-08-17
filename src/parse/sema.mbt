pub struct TypingEnv {
  mut map: Map[AST, Type]
  binding: Map[String, Type]
  mut constraints: Set[(Int, Type)]
}

///|
/// Moonbit doesn't let me overload, but I do want to.
/// 
/// I'll have to use this to emulate the functionality.
pub enum Overloaded {
  AST(AST)
  String(String)
}

pub trait Typable {
  overload(Self) -> Overloaded
}

pub impl Typable for AST with overload(self) {
  return AST(self);
}

pub impl Typable for String with overload(self) {
  return String(self);
}

pub fn[T: Typable] TypingEnv::op_get(self: TypingEnv, k: T) -> Type {
  match k.overload() {
    AST(x) => {
      if (!self.map.contains(x)) {
        die("AST not inferred: \{x}")
      }
      return self.map[x];
    }
    String(x) => {
      if (!self.binding.contains(x)) {
        die("unknown name: \{x}")
      }
      return self.binding[x];
    }
  }
}

pub fn[T: Typable] TypingEnv::op_set(self: TypingEnv, k: T, v: Type) -> Unit {
  match k.overload() {
    AST(x) => self.map[x] = v;
    String(x) => self.binding[x] = v;
  }
}

pub fn TypingEnv::dump(self: TypingEnv, ast: AST, depth: Int) -> String {
  match ast {
    Int(x) => "\{x}"
    Double(x) => "\{x}"
    Bool(x) => "\{x}"
    Var(x) => x
    Let({ name, init, ty }) => "let \{name}: \{ty} = \{self.dump(init, depth)}"
    Fn({ name, args, retTy, body }) => {
      let args = args.map((x) => "\{x.0}: \{x.1}").join(", ");
      "fn \{name}(\{args}) -> \{retTy} \{self.dump(body, depth)}"
    }
    BinOp(kind, x, y) => {
      let op = match kind {
        Add => "+"; Sub => "-"; Mul => "*"; Div => "/"; Mod => "%"
        And => "&&"; Or => "||"
        Lt => "<"; Le => "<="; Eq => "=="; Ne => "!="
      }
      "\{self.dump(x, depth)} \{op} \{self.dump(y, depth)}";
    }
    UnaryOp(kind, x) => {
      let op = match kind {
        Sub => "-";
      }
      "\{op}\{self.dump(x, depth)}"
    }
    Block(arr) => {
      let indent = String::make(depth * 2 - 2, ' ');
      let content = arr.map(self.dump(_, depth + 1)).join(";\n\{indent}  ");
      "{\n\{indent}  \{content}\n\{indent}}"
    }
    Call(func, args) => {
      let args = args.map(self.dump(_, depth)).join(", ");
      "\{self.dump(func, depth)}(\{args})"
    }
    While(cond, body) => {
      "while (\{self.dump(cond, depth)}) \{self.dump(body, depth)}"
    }
    If(cond, ifso, ifnot) => {
      let ifnot = if (ifnot is Some(ifnot)) { self.dump(ifnot, depth) } else { "" }
      "if (\{self.dump(cond, depth)}) \{self.dump(ifso, depth)} \{ifnot}"
    }
    Assign(l, r) => "\{self.dump(l, depth)} = \{self.dump(r, depth)}"
    CompoundAssign(kind, l, r) => {
      let op = match kind {
        Add => "+"; Sub => "-"; Mul => "*"; Div => "/"; Mod => "%"
        _ => panic();
      }
      "\{self.dump(l, depth)} \{op}= \{self.dump(r, depth)}"
    }
    x => die("unknown dumped ast \{x}")
  }
}

pub fn TypingEnv::new() -> TypingEnv {
  let env = { map: Map::new(), binding: Map::new(), constraints: Set::new() };
  // Add predefined functions.
  env["print_int"] = Function(Unit, [Int])
  env["print_double"] = Function(Unit, [Double])
  env["print_endline"] = Function(Unit, [])
  return env;
}

pub fn TypingEnv::clone(self: TypingEnv) -> TypingEnv {
  {
    map: self.map.clone(),
    binding: self.binding.clone(),
    constraints: self.constraints.iter() |> Set::from_iter
  };
}

///|
/// Joins the AST map, but ignores binding.
/// 
pub fn TypingEnv::join(self: TypingEnv, other: TypingEnv) -> Unit {
  for x in other.map {
    self.map[x.0] = x.1;
  }
  self.constraints = self.constraints.union(other.constraints);
}

///|
/// Creates a new scope by cloning a new TypingEnv.
/// 
pub fn TypingEnv::fork(self: TypingEnv, x: AST) -> Type {
  let e = self.clone();
  e.infer(x) |> ignore;
  self.join(e);
  return self.map[x];
}

pub fn TypingEnv::unify(self: TypingEnv, x: Type, y: Type) -> Unit {
  fn die() { @utils.die("cannot unify \{x} and \{y}") }

  match (x, y) {
    (Int, Int) | (Double, Double) | (Bool, Bool) | (Unit, Unit) => ()
    (Weak(i), y) | (y, Weak(i)) => self.constraints.add((i, y));
    (Function(ret, arg), Function(ret2, arg2)) => {
      self.unify(ret, ret2)
      guard arg.length() == arg2.length() else { die(); }
      for i, _ in arg {
        self.unify(arg[i], arg2[i])
      }
    }
    _ => die()
  }
}

pub fn TypingEnv::infer(self: TypingEnv, x: AST) -> Type {
  match x {
    Int(_) => self[x] = Int
    Double(_) => self[x] = Double
    Bool(_) => self[x] = Bool
    Fn({ name, args, retTy, body }) => {
      self[x] = Unit;
      self[name] = Function(retTy, args.map((x) => x.1));
      let fork = self.clone();
      for arg in args {
        fork[arg.0] = arg.1;
      }
      self.unify(fork.infer(body), retTy);
      self.join(fork);
    }
    Let({ name, init, ty }) => {
      self.unify(self.infer(init), ty);
      self[x] = Unit;
      self[name] = ty;
    }
    BinOp(kind, l, r) => {
      let lty = self.infer(l);
      let rty = self.infer(r);
      self.unify(lty, rty);
      let ty: Type = match kind {
        Lt | Le | Ne | Eq => Bool
        _ => rty
      }
      self[x] = ty;
    }
    UnaryOp(_kind, v) => {
      let ty = self.infer(v);
      guard ty is Int || ty is Double;
      self[x] = ty;
    }
    Block(arr) => {
      let mut ty: Type = Unit;
      for x in arr {
        ty = self.infer(x);
      }
      self[x] = ty;
    }
    Call(func, args) => {
      let fty = self.infer(func);
      guard fty is Function(ret, params) && params.length() == args.length() else {
        die("\{fty}(\{args}) is not a proper call");
      }
      for i, _ in params {
        self.unify(params[i], self.infer(args[i]));
      }
      self[x] = ret;
    }
    Var(name) => self[x] = self[name];
    While(cond, body) => {
      self.unify(self.infer(cond), Bool);
      self.unify(self.infer(body), Unit);
      self[x] = Unit;
    }
    If(cond, ifso, ifnot) => {
      self.unify(self.infer(cond), Bool);
      let ty = self.infer(ifso);
      if (ifnot is Some(ifnot)) {
        self.unify(self.infer(ifnot), ty);
      }
      self[x] = ty;
    }
    Assign(l, r) => {
      self.unify(self.infer(l), self.infer(r));
      self[x] = Unit;
    }
    CompoundAssign(_, l, r) => {
      self.unify(self.infer(l), Int);
      self.unify(self.infer(r), Int);
      self[x] = Unit;
    }
    x => die("sema: unknown AST: \{x}")
  }
  return self[x];
}

fn TypingEnv::map(self: TypingEnv, f: (Type) -> Type) -> Unit {
  let map = Map::new();
  for t in self.map {
    let (k, v) = t;
    map[k] = v.map(f);
  }
  self.map = map;
}

pub fn TypingEnv::solve(self: TypingEnv, x: AST) -> AST {
  // First, solve constraints.
  let solution: Map[Int, Type] = Map::new();
  for x in self.constraints {
    let (i, ty) = x;
    if (ty is Weak(j)) {
      // Convert all Weak(i) to Weak(j).
      self.map((x) => if (x is Weak(z) && z == i) { Weak(j) } else { x })
    } else {
      solution[i] = ty;
    }
  }
  // Then map the solutions.
  let mapper = (x) => if (x is Weak(z) && solution.contains(z)) { solution[z] } else { x };
  self.map(mapper);
  
  x.walk((x) => match x {
    Fn(x) => {
      x.retTy = mapper(x.retTy);
      x.args = x.args.map((x) => (x.0, mapper(x.1)));
    }
    Let(x) => {
      x.ty = mapper(x.ty);
    }
    _ => ()
  });
  return x;
}
