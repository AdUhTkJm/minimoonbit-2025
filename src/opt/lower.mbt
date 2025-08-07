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
      builder.replace(x, to, x.ty, x.getOperands(), attrs=x.attrs);
    }
  }
  replace(IntOp, LiOp);
  replace(GetGlobalOp, LaOp);
  
  // Lower loads.
  let all = func.findAll(LoadOp);
  for x in all {
    if (x.ty == i32) {
      builder.replace(x, LwOp, x.ty, x.getOperands(), attrs=x.attrs);
      continue;
    }
    if (x.ty == f64) {
      builder.replace(x, FldOp, x.ty, x.getOperands(), attrs=x.attrs);
      continue;
    }
    die("unknown type \{x.ty}: \{x}")
  }

  // Lower stores.
  let all = func.findAll(StoreOp);
  for x in all {
    let ty = x.def(0).ty;
    if (ty == i32) {
      builder.replace(x, SwOp, ty, x.getOperands(), attrs=x.attrs);
      continue;
    }
    if (ty == f64) {
      builder.replace(x, FsdOp, ty, x.getOperands(), attrs=x.attrs);
      continue;
    }
    die("unknown type \{ty}: \{x}")
  }

  // Lower return.
  let all = func.findAll(ReturnOp);
  for x in all {
    if (x.getOperandCount() == 0) {
      continue;
    }

    builder.setBeforeOp(x);
    let a0 = builder.create(WriteRegOp, unit, [x.def(0)], attrs=[Reg(a0)])
  }

  // Lower calls.
  let all = func.findAll(CallOp);
  let regs = [a0, a1, a2, a3, a4, a5, a6, a7];
  let fregs = [fa0, fa1, fa2, fa3, fa4, fa5, fa6, fa7];
  for op in all {
    builder.setBeforeOp(op);
    let args = op.getOperands();

    let argsNew: Array[Op] = [];
    let fargsNew: Array[Op] = [];
    let spilled: Array[Op] = [];
    for i, arg in args {
      let ty = arg.ty;
      let fcnt = fargsNew.length();
      let cnt = argsNew.length();

      if (ty == f64 && fcnt < 8) {
        fargsNew.push(builder.create(WriteRegOp, unit, [arg], attrs=[Reg(fregs[fcnt])]));
        continue;
      }
      if (ty != f64 && cnt < 8) {
        argsNew.push(builder.create(WriteRegOp, unit, [arg], attrs=[Reg(regs[cnt])]));
        continue;
      }
      spilled.push(arg);
    }

    // More registers must get spilled to stack.
    let mut stackOffset = spilled.length() * 8;
    // Align to 16 bytes.
    if (stackOffset % 16 != 0) {
      stackOffset = stackOffset / 16 * 16 + 16;
    }
    if (stackOffset > 0) {
      builder.creates(SubSpOp, unit, [], attrs=[Int(stackOffset)]);
    }

    for i, spill in spilled {
      let sp = builder.create(ReadRegOp, i64, [], attrs=[Reg(sp)]);
      builder.creates(SdOp, unit, [spill, sp], attrs=[Int(i * 8)]);
    }

    builder.creates(CallOp, unit, argsNew, attrs=[
      Name(op.getName()),
      ArgCount(args.length())
    ]);

    // Restore stack pointer.
    if (stackOffset > 0) {
      builder.creates(SubSpOp, unit, [], attrs=[Int(-stackOffset)]);
    }

    // Read result from a0.
    if (op.ty == f64) {
      builder.replace(op, ReadRegOp, f64, [], attrs=[Reg(fa0)]);
    } else {
      builder.replace(op, ReadRegOp, i32, [], attrs=[Reg(a0)]);
    }
  }
}
