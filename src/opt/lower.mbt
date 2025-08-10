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
  replace(GotoOp, JOp);
  
  // Lower loads.
  let all = func.findAll(LoadOp);
  for x in all {
    let mut kind: OpKind = BadOp;
    if (x.ty == i32) {
      kind = LwOp;
    }
    if (x.ty == i64) {
      kind = LdOp;
    }
    if (x.ty == f64) {
      kind = FldOp;
    }
    builder.replace(x, kind, x.ty, x.getOperands(), attrs=[..x.attrs, Int(0)]);
  }

  // Lower stores.
  let all = func.findAll(StoreOp);
  for x in all {
    let ty = x.def(0).ty;
    let mut kind: OpKind = BadOp;
    if (ty == i32) {
      kind = SwOp;
    }
    if (x.ty == i64) {
      kind = SdOp;
    }
    if (x.ty == f64) {
      kind = FsdOp;
    }
    builder.replace(x, kind, ty, x.getOperands(), attrs=[..x.attrs, Int(0)]);
  }

  // Lower return.
  let all = func.findAll(ReturnOp);
  for x in all {
    if (x.getOperandCount() == 0) {
      builder.replace(x, RetOp, x.ty, x.getOperands(), attrs=x.attrs);
      continue;
    }

    builder.setBeforeOp(x);
    let a0 = builder.create(WriteRegOp, unit, [x.def(0)], attrs=[Reg(a0)])
    builder.replace(x, RetOp, x.ty, x.getOperands(), attrs=x.attrs);
  }

  // Lower arithmetics.
  fn lowerArithmetic(kind: OpKind, i64_: OpKind, i32_: OpKind, f64_: OpKind) {
    let all = func.findAll(kind);
    for x in all {
      if (x.ty == i64) {
        builder.replace(x, i64_, x.ty, x.getOperands(), attrs=x.attrs);
        continue;
      }
      if (x.ty == i32) {
        builder.replace(x, i32_, x.ty, x.getOperands(), attrs=x.attrs);
        continue;
      }
      if (x.ty == f64) {
        builder.replace(x, f64_, x.ty, x.getOperands(), attrs=x.attrs);
        continue;
      }
      die("unknown type \{x.ty} for \{x}");
    }
  }

  lowerArithmetic(AddOp, AddOp, AddwOp, FaddOp);
  lowerArithmetic(SubOp, SubOp, SubwOp, FsubOp);
  lowerArithmetic(MulOp, MulOp, MulwOp, FmulOp);
  lowerArithmetic(DivOp, DivOp, DivwOp, FdivOp);
  lowerArithmetic(ModOp, RemOp, RemwOp, BadOp);

  // Lower branches.
  let all = func.findAll(BrOp);
  for op in all {
    let cond = op.def(0);
    match cond.kind {
      LtOp => builder.replace(op, BltOp, op.ty, cond.getOperands(), attrs=op.attrs);
      LeOp => builder.replace(op, BleOp, op.ty, cond.getOperands(), attrs=op.attrs);
      EqOp => builder.replace(op, BeqOp, op.ty, cond.getOperands(), attrs=op.attrs);
      NeOp => builder.replace(op, BneOp, op.ty, cond.getOperands(), attrs=op.attrs);
      _ => {
        builder.setBeforeOp(op);
        let zero = builder.create(LiOp, i32, [], attrs=[Int(0)]);
        builder.replace(op, BneOp, op.ty, [cond, zero], attrs=op.attrs);
      }
    }
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

    let mut name = op.getName();
    if (["print_int", "print_double", "print_endline"].contains(name)) {
      name = "minimbt_\{name}"
    }
    builder.creates(CallOp, unit, argsNew, attrs=[
      Name(name),
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

  let region = func.region();
  let block = region.block();

  // All alloca's are in the first block.
  let mut offset = 0; // Offset from sp.
  let mut total = 0; // Total stack frame size
  let allocas: Array[Op] = [];
  for op in block {
    if (!isa[AllocaOp](op)) {
      continue;
    }

    let size = if (op.ty == f64 || op.ty == i64) { 8 } else { 4 };
    total += size;
    allocas.push(op);
  }

  for op in allocas {
    // Translate itself into `sp + offset`.
    builder.setBeforeOp(op);
    let spValue = builder.create(ReadRegOp, i32, [], attrs=[Reg(sp)]);
    let offsetValue = builder.create(LiOp, i32, [], attrs=[Int(offset)]);
    let add = builder.create(AddOp, i32, [spValue, offsetValue]);
    op.replaceAllUsesWith(add);

    let size = if (op.ty == f64 || op.ty == i64) { 8 } else { 4 };
    offset += size;
    op.erase();
  }

  func.add(StackOffset(offset));
}
