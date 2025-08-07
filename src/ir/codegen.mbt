pub struct SymbolTable {
  locals: Map[String, Op]
  globals: Map[String, Type]
  builder: Builder
}

// Mimics Python's ast module.
pub enum Ctx {
  Load; Store
}

pub fn SymbolTable::op_get(self: SymbolTable, name: String) -> Op {
  if (self.locals.contains(name)) {
    return self.locals[name];
  }
  if (!self.globals.contains(name)) {
    die("unknown identifier: \{name}")
  }
  return self.builder.create(GetGlobalOp, self.globals[name], [], attrs=[Name(name)]);
}

pub fn SymbolTable::op_set(self: SymbolTable, name: String, addr: Op) -> Unit {
  self.locals[name] = addr;
}

pub struct CodeGen {
  // Records the address of a variable.
  symtbl: SymbolTable
  builder: Builder
  env: TypingEnv
  mut init: Op
}

///|
/// Retrieves the IR-type of an AST.
/// 
pub fn CodeGen::op_get(self: CodeGen, x: AST) -> Type {
  return self.env[x] |> cvt;
}

pub fn cvt(x: @parse.Type) -> Type {
  match x {
    Int => i32
    Unit => unit
    Double => f64
    Function(x, arr) => Type::make("func", [cvt(x), ..arr.map(cvt(_))])
    _ => die("unknown type \{x}")
  }
}

pub fn CodeGen::clone(self: CodeGen) -> CodeGen {
  let builder = Builder::new();
  {
    symtbl: { locals: self.symtbl.locals.clone(), globals: self.symtbl.globals.clone(), builder },
    builder,
    env: self.env,
    init: self.init
  }
}

pub fn CodeGen::new(env: TypingEnv) -> CodeGen {
  let builder = Builder::new();
  {
    symtbl: { locals: Map::new(), globals: Map::new(), builder },
    builder, env, init: Op::default()
  }
}

pub fn CodeGen::stmt(self: CodeGen, x: AST, ctx~: Ctx = Load) -> Op {
  let builder = self.builder;
  match x {
    Block(arr) => {
      // Create a scope.
      let subgen = self.clone();
      subgen.builder.setTo(builder.getInsertionPoint());
      let last = arr.map(subgen.stmt(_)).last();
      if (last is Some(x)) {
        return x;
      }
      return builder.create(MakeUnitOp, unit, []);
    }
    BinOp(kind, l, r) => {
      if (kind is And) {
        die("&&: NYI")
      }
      if (kind is Or) {
        die("||: NYI");
      }
      let l = self.stmt(l);
      let r = self.stmt(r);
      let (kind, ty) = match kind {
        Add => (AddOp, l.ty)
        Sub => (SubOp, l.ty)
        Mul => (MulOp, l.ty)
        Div => (DivOp, l.ty)
        Mod => (ModOp, l.ty)
        Ne => (NeOp, bool)
        Eq => (EqOp, bool)
        Lt => (LtOp, bool)
        Le => (LeOp, bool)
        _ => panic()
      }
      return builder.create(kind, ty, [l, r])
    }
    Let({ name, init, ty }) => {
      let addr = builder.create(AllocaOp, cvt(ty).ptr(), [], attrs=[Name(name)]);
      self.symtbl[name] = addr;
      let value = self.stmt(init);
      builder.creates(StoreOp, unit, [value, addr]);
      return builder.create(MakeUnitOp, unit, []);
    }
    Call(func, args) => {
      let func = self.stmt(func);
      let args = args.map(self.stmt(_));
      return builder.create(CallOp, self[x], [func, ..args]);
    }
    Var(name) => {
      let addr = self.symtbl[name];
      if (ctx is Store) {
        return addr;
      }
      return builder.create(LoadOp, self[x], [addr]);
    }
    Int(x) => builder.create(IntOp, i32, [], attrs=[Int(x)]);
    Double(x) => builder.create(DoubleOp, i32, [], attrs=[Double(x)]);
    Assign(tgt, value) => {
      let addr = self.stmt(tgt, ctx=Store);
      let value = self.stmt(value);
      builder.creates(StoreOp, unit, [value, addr]);
      return builder.create(MakeUnitOp, unit, []);
    }
    CompoundAssign(bkind, tgt, value) => {
      let addr = self.stmt(tgt, ctx=Store);
      let value = self.stmt(value);
      let load = builder.create(LoadOp, self[tgt], [addr]);
      let modif = builder.create(match bkind {
        Add => AddOp; Sub => SubOp; Mul => MulOp; Div => DivOp; Mod => ModOp;
        _ => panic()
      }, self[tgt], [load, value]);
      builder.creates(StoreOp, unit, [modif, addr]);
      return builder.create(MakeUnitOp, unit, []);
    }
    While(cond, body) => {
      let cond = self.stmt(cond);
      let _while = builder.create(WhileOp, unit, [cond]);
      let region = _while.appendRegion();
      let block = region.appendBlock();
      let point = builder.getInsertionPoint();
      builder.setToBlockStart(block);
      self.stmt(body) |> ignore;
      builder.setTo(point);
      return _while;
    }
    If(cond, ifso, ifnot) => {
      let cond = self.stmt(cond);
      let _if = builder.create(IfOp, self[x], [cond]);
      let region = _if.appendRegion();
      let block = region.appendBlock();
      let point = builder.getInsertionPoint();
      builder.setToBlockStart(block);
      self.stmt(ifso) |> ignore;
      if (ifnot is Some(ifnot)) {
        let region = _if.appendRegion();
        let block = region.appendBlock();
        builder.setToBlockStart(block);
        self.stmt(ifnot) |> ignore;
      }
      builder.setTo(point);
      return _if;
    }
    _ => die("unknown statement: \{x}")
  }
}

pub fn CodeGen::top(self: CodeGen, x: AST) -> Unit {
  let builder = self.builder;
  match x {
    Fn(detail) => {
      let f = builder.create(FuncOp, unit, [], attrs=[ArgCount(detail.args.length()), Name(detail.name)]);
      let region = f.appendRegion();
      let block = region.appendBlock();
      let subgen = self.clone();
      self.symtbl.globals[detail.name] = cvt(Function(detail.retTy, detail.args.map((x) => x.1)));
      subgen.builder.setToBlockStart(block);
      for i, x in detail.args {
        subgen.symtbl[x.0] = subgen.builder.create(GetArgOp, cvt(x.1).ptr(), [], attrs=[Int(i)]);
      }
      subgen.stmt(detail.body) |> ignore;
    }
    Let({ name, init, ty }) => {
      let addr = builder.create(GlobalOp, cvt(ty).ptr(), [], attrs=[Name(name)]);
      self.symtbl.globals[name] = ty |> cvt;
      let point = builder.getInsertionPoint();
      builder.setToBlockEnd(self.init.block());
      let value = self.stmt(init);
      builder.creates(StoreOp, unit, [value, addr]);
      builder.setTo(point);
    }
    _ => die("unknown toplevel: \{x}")
  }
}

pub fn CodeGen::build(self: CodeGen, x: AST) -> Op {
  let module = Builder::createModule();
  let region = module.appendRegion();
  self.builder.setToBlockStart(region.appendBlock());
  // Create an __init() function.
  self.init = self.builder.create(FuncOp, unit, [], attrs=[Name("__init")]);
  let region = self.init.appendRegion();
  region.appendBlock() |> ignore;
  guard x is Block(arr);
  for x in arr {
    self.top(x);
  }
  module
}
