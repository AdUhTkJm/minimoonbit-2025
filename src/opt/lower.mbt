pub fn Lower::run(self: Lower) -> Unit {
  for x in self.funcs() {
    Lower::runImpl(x);
  }
}

pub fn Lower::runImpl(func: Op) -> Unit {
  let builder = Builder::new();

  fn replace(from, to) {
    let all = func.findAll(from);
    for x in all {
      builder.replace(x, to, x.ty, x.operands, attrs=x.attrs);
    }
  }
  replace(IntOp, LiOp);
  replace(GetGlobalOp, LaOp);
  
  // Lower loads.
  let all = func.findAll(LoadOp);
  for x in all {
    if (x.ty == i32) {
      builder.replace(x, LwOp, x.ty, x.operands, attrs=x.attrs);
      continue;
    }
    if (x.ty == f64) {
      builder.replace(x, FldOp, x.ty, x.operands, attrs=x.attrs);
      continue;
    }
    die("unknown type \{x.ty}: \{x}")
  }

  // Lower stores.
  let all = func.findAll(StoreOp);
  for x in all {
    let ty = x.def(0).ty;
    if (ty == i32) {
      builder.replace(x, SwOp, ty, x.operands, attrs=x.attrs);
      continue;
    }
    if (ty == f64) {
      builder.replace(x, FsdOp, ty, x.operands, attrs=x.attrs);
      continue;
    }
    die("unknown type \{ty}: \{x}")
  }

  // Lower return.
  let all = func.findAll(ReturnOp);
  for x in all {
    if (x.operands.length() == 0) {
      continue;
    }

    builder.setBeforeOp(x);
    let a0 = builder.create(WriteRegOp, unit, [x.def(0)], attrs=[Reg(a0)])
  }
}
