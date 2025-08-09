pub fn Dump::run(self: Dump) -> Unit {
  let str = self.dump();
  if (config.output != "") {
    (try? @fs.write_string_to_file(config.output, str)) |> ignore;
  } else {
    println(str);
  }
}

pub fn Dump::o(self: Dump, x: String) -> Unit {
  self.builder.write_string(x);
}

pub fn Dump::dump(self: Dump) -> String {
  self.o(".global minimbt_main\n");
  for func in self.funcs() {
    let mut name = func.getName();
    // Special treatment for entry point.
    if (name == "main") {
      name = "minimbt_main";
    }
    self.o("\{name}:\n");
    for bb in func.region() {
      self.o(".Lbb\{bb.id}:\n");
      for op in bb {
        self.o("  ");
        self.dumpOp(op);
        self.o("\n");
      }
    }
    self.o("\n\n")
  }

  for global in self.globals() {
    // TODO
  }
  return self.builder.to_string();
}

let names: Map[String, String] = Map::from_array([
  ("fadd", "fadd.d"),
  ("fsub", "fsub.d"),
  ("fmul", "fmul.d"),
  ("fdiv", "fdiv.d"),
  ("flt", "flt.d"),
  ("feq", "feq.d"),
  ("fle", "fle.d"),
  ("fmvdx", "fmv.d.x"),
  ("fmvxd", "fmv.x.d"),
  ("fmv", "fmv.d"),
  ("fcvtsd", "fcvt.s.d"),
])

pub fn Dump::dumpOp(self: Dump, op: Op) -> Unit {
  let mut name = "\{op.kind}";
  if (names.contains(name)) {
    name = names[name];
  }

  if (isa[FcvtdsRtzOp](op)) {
    self.o("fcvt.d.s \{op.getRd() |> reg}, \{op.getRs() |> reg}, rtz");
  }

  if (op.isAny([SwOp, SdOp, FsdOp])) {
    self.o("\{op.kind} \{op.getRs() |> reg}, \{op.getInt()}(\{op.getRs2() |> reg})");
    return;
  }

  if (op.isAny([LwOp, LdOp, FldOp])) {
    self.o("\{op.kind} \{op.getRd() |> reg}, \{op.getInt()}(\{op.getRs() |> reg})");
    return;
  }

  let mut str = "\{name} ";
  if (op.hasRd()) {
    str += "\{op.getRd() |> reg}, ";
  }
  if (op.hasRs()) {
    str += "\{op.getRs() |> reg}, ";
  }
  if (op.hasRs2()) {
    str += "\{op.getRs2() |> reg}, ";
  }
  if (op.hasInt()) {
    str += "\{op.getInt()}, ";
  }
  if (op.hasTarget()) {
    str += ".Lbb\{op.getTarget().id}, ";
  }
  if (op.hasName()) {
    str += "\{op.getName()}, ";
  }
  let arr = str.to_array();
  if (arr.length() >= 2 && arr[arr.length() - 2] == ',') {
    str = arr[:arr.length() - 2].iter() |> String::from_iter;
  }
  self.o(str);
}
