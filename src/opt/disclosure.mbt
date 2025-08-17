///|
/// Removes closure: turns them into normal functions.
/// 
pub fn Disclosure::run(self: Disclosure) -> Unit {
  let mut changed = true;
  while (changed) {
    changed = false;
    for x in self.funcs() {
      changed = self.runImpl(x) || changed;
    }
  }
}

pub fn Disclosure::count(self: Disclosure) -> Int {
  let x = self.count;
  self.count += 1;
  return x;
}

pub fn Disclosure::runImpl(self: Disclosure, func: Op) -> Bool {
  let funcs = func.findAll(FuncOp).filter((x) => !physical_equal(x, func));
  if (funcs.is_empty()) {
    return false;
  }

  let builder = Builder::new();
  let mapping: Map[Op, Op] = Map::new();

  fn copy(op: Op) {
    let copied = builder.copy(op);
    mapping[op] = copied;
    // Recursively copy its contents.
    for r in op.regions {
      for bb in r {
        for op in bb {
          copy(op);
        }
      }
    }
  }
  
  for f in funcs {
    mapping.clear();
    let captured = [];

    builder.setToRegionStart(self.module.region());
    let cf = builder.create(FuncOp, unit, [], attrs=[
      Name("__lambda_\{self.count()}"), ArgCount(f.getArgCount()),
    ]);
    let region = cf.appendRegion();
    builder.setToBlockStart(region.appendBlock());
    copy(f);

    // The function should be isolated from above.
    // We attempt to rewire operands; for all unmappable operands, they're captured.
    for _, v in mapping {
      let operands = v.operands.iter() |> Array::from_iter;
      for i, operand in operands {
        if (mapping.contains(operand)) {
          v.setOperand(i, mapping[operand]);
        } else {
          captured.push(operand);
        }
      }
    }

    // For every reference of this function, we must also supply the captured value.
    builder.replace(f, MakeTupleOp, Type::tuple([f.ty, ..captured.map((x) => x.ty)]), [f, ..captured], attrs=[]);
  }
  return true;
}
