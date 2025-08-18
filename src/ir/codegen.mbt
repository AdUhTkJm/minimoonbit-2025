pub struct SymbolTable {
  locals: Map[String, Op]
  globals: Map[String, Type]
  funcs: Set[String]
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
    symtbl: {
      locals: self.symtbl.locals.clone(),
      globals: self.symtbl.globals.clone(),
      funcs: self.symtbl.funcs.iter() |> Set::from_iter(),
      builder
    },
    builder,
    env: self.env,
    init: self.init
  }
}

pub fn CodeGen::new(env: TypingEnv) -> CodeGen {
  let builder = Builder::new();
  let cg = {
    symtbl: { locals: Map::new(), globals: Map::from_array({
      "print_int": Type::func(unit, [i32]),
      "print_double": Type::func(unit, [f64]),
      "print_endline": Type::func(unit, []),
    }.to_array()), funcs: [
      "print_int", "print_double", "print_endline"
    ] |> Set::from_array, builder },
    builder, env, init: Op::default()
  }
  return cg;
}

pub fn CodeGen::isRawFunction(self: CodeGen, name: String) -> Bool {
  return !self.symtbl.locals.contains(name) && self.symtbl.funcs.contains(name);
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
    Array(arr) => {  
      let values = arr.map(self.stmt(_));
      return builder.create(MakeArrayOp, self[x], values);
    }
    Tuple(arr) => {  
      let values = arr.map(self.stmt(_));
      return builder.create(MakeTupleOp, self[x], values);
    }
    Unit => return builder.create(MakeUnitOp, unit, []);
    BinOp(kind, l, r) => {
      if (kind is And) {
        let alloca = builder.create(AllocaOp, i32.ptr(), []);
        let l = self.stmt(l);
        let _if = builder.create(IfOp, unit, [l]);
        let ifso = _if.appendRegion();
        let ifnot = _if.appendRegion();

        // Emit `l ? r : 0`.
        let point = builder.getInsertionPoint();
        builder.setToBlockStart(ifso.appendBlock());
        let r = self.stmt(r);
        builder.creates(StoreOp, unit, [r, alloca]);

        builder.setToBlockStart(ifnot.appendBlock());
        let zero = builder.createInt(0);
        builder.creates(StoreOp, unit, [zero, alloca]);
        builder.setTo(point);
        return builder.create(LoadOp, i32, [alloca]);
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
        Ne => (NeOp, i32)
        Eq => (EqOp, i32)
        Lt => (LtOp, i32)
        Le => (LeOp, i32)
        _ => panic()
      }
      return builder.create(kind, ty, [l, r])
    }
    UnaryOp(kind, x) => {
      let x = self.stmt(x);
      match kind {
        Sub => {
          let zero = if (x.ty == i32) { builder.createInt(0) } else { builder.createDouble(0) };
          return builder.create(SubOp, x.ty, [zero, x]);
        }
      }
    }
    Let({ name, init, ty }) => {
      let addr = builder.create(AllocaOp, cvt(ty).ptr(), [], attrs=[Name(name)]);
      self.symtbl[name] = addr;
      let value = self.stmt(init);
      builder.creates(StoreOp, unit, [value, addr]);
      return builder.create(MakeUnitOp, unit, []);
    }
    Fn({ args, retTy: _, name, body }) => {
      let f = builder.create(FuncOp, unit, [], attrs=[ArgCount(args.length()), Name(name)]);
      let region = f.appendRegion();
      let block = region.appendBlock();
      self.symtbl[name] = f;
      self.symtbl.funcs.add(name);
      let subgen = self.clone();
      subgen.builder.setToBlockStart(block);
      for i, x in args {
        let ty = cvt(x.1);
        let getarg = subgen.builder.create(GetArgOp, ty, [], attrs=[Int(i)]);
        let alloca = subgen.builder.create(AllocaOp, ty.ptr(), []);
        subgen.symtbl[x.0] = alloca;
        subgen.builder.creates(StoreOp, unit, [getarg, alloca]);
      }
      let last = subgen.stmt(body);
      subgen.builder.creates(ReturnOp, unit, [last]);
      return builder.create(MakeUnitOp, unit, []);
    }
    Call(func, args) => {
      let func = self.stmt(func);
      let args = args.map(self.stmt(_));
      return builder.create(CallOp, self[x], [func, ..args]);
    }
    Var(name) => {
      let addr = self.symtbl[name];
      if (self.isRawFunction(name)) {
        return addr;
      }
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
      let _while = builder.create(WhileOp, unit, []);
      let point = builder.getInsertionPoint();

      let before = _while.appendRegion();
      builder.setToBlockStart(before.appendBlock());
      let cond = self.stmt(cond);
      builder.creates(ProceedOp, unit, [cond]);

      let after = _while.appendRegion();
      builder.setToBlockStart(after.appendBlock());
      self.stmt(body) |> ignore;
      
      builder.setTo(point);
      return _while;
    }
    If(cond, ifso, ifnot) => {
      let cond = self.stmt(cond);
      let ty = self[x];
      
      // The value address of the if-expression.
      let alloca = builder.create(AllocaOp, ty.ptr(), []);
      let _if = builder.create(IfOp, unit, [cond]);
      let region = _if.appendRegion();
      let block = region.appendBlock();
      let point = builder.getInsertionPoint();

      builder.setToBlockStart(block);
      let last = self.stmt(ifso);
      builder.creates(StoreOp, unit, [last, alloca]);

      if (ifnot is Some(ifnot)) {
        let region = _if.appendRegion();
        let block = region.appendBlock();
        builder.setToBlockStart(block);
        let last = self.stmt(ifnot);
        builder.creates(StoreOp, unit, [last, alloca]);
      }
      builder.setTo(point);
      return builder.create(LoadOp, ty, [alloca]);
    }
    _ => die("unknown statement: \{x}")
  }
}

pub fn CodeGen::top(self: CodeGen, x: AST) -> Unit {
  let builder = self.builder;
  match x {
    Fn({ args, retTy, name, body }) => {
      let f = builder.create(FuncOp, unit, [], attrs=[ArgCount(args.length()), Name(name)]);
      let region = f.appendRegion();
      let block = region.appendBlock();
      self.symtbl.globals[name] = cvt(Function(retTy, args.map((x) => x.1)));
      self.symtbl.funcs.add(name);
      let subgen = self.clone();
      subgen.builder.setToBlockStart(block);
      for i, x in args {
        let ty = cvt(x.1);
        let getarg = subgen.builder.create(GetArgOp, ty, [], attrs=[Int(i)]);
        let alloca = subgen.builder.create(AllocaOp, ty.ptr(), []);
        subgen.symtbl[x.0] = alloca;
        subgen.builder.creates(StoreOp, unit, [getarg, alloca]);
      }
      let last = subgen.stmt(body);
      subgen.builder.creates(ReturnOp, unit, [last]);
    }
    Let({ name, init, ty }) => {
      builder.creates(GlobalOp, cvt(ty).ptr(), [], attrs=[Name(name)]);
      self.symtbl.globals[name] = ty |> cvt;
      let point = builder.getInsertionPoint();
      builder.setToBlockEnd(self.init.block());
      let value = self.stmt(init);
      let getglobal = builder.create(GetGlobalOp, cvt(ty).ptr(), [], attrs=[Name(name)]);
      builder.creates(StoreOp, unit, [value, getglobal]);
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
  self.init = self.builder.create(FuncOp, unit, [], attrs=[Name("__init"), ArgCount(0)]);
  let region = self.init.appendRegion();
  region.appendBlock() |> ignore;
  guard x is Block(arr);
  for x in arr {
    self.top(x);
  }
  module
}
