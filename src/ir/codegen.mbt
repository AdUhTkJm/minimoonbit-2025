pub struct SymbolTable {
  locals: Map[String, Op]
  globals: Map[String, Op]
}

pub fn SymbolTable::op_get(self: SymbolTable, name: String) -> Op {
  if (self.locals.contains(name)) {
    return self.locals[name];
  }
  if (!self.globals.contains(name)) {
    die("unknown identifier: \{name}")
  }
  return self.globals[name];
}

pub struct CodeGen {
  // Records the address of a variable.
  symtbl: SymbolTable
  builder: Builder
  env: TypingEnv
}

pub fn CodeGen::new(env: TypingEnv) -> CodeGen {
  {
    symtbl: { locals: Map::new(), globals: Map::new() },
    builder: Builder::new(), env
  }
}

pub fn CodeGen::stmt(self: CodeGen, x: AST) -> Op {
  let builder = self.builder;
  match x {
    Fn(detail) => {
      let f = builder.create(Func, unit, [], attrs=[ArgCount(detail.args.length())]);
      ...
    }
    _ => die("unknown stmt: \{x}")
  }
}

pub fn CodeGen::build(self: CodeGen, x: AST) -> Op {
  let module = Builder::create_module();
  let region = module.append_region();
  self.builder.start(region.append_block());
  self.stmt(x) |> ignore;
  module
}
