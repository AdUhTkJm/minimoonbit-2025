pub fn impure(op: Op) -> Bool {
  return op.isAny([
    // IR ops
    ReturnOp, BrOp, GotoOp, StoreOp, CallOp,
    // RV ops
    RetOp, BleOp, BltOp, BgeOp, BgtOp, BeqOp, BneOp, JOp, SwOp, SdOp, FsdOp, CallOp, WriteRegOp,
  ])
}

pub fn Dce::run(self: Dce) -> Unit {
  for x in self.funcs() {
    while (Dce::runImpl(x.region())) {}
  }
}

pub fn Dce::runImpl(region: Region) -> Bool {
  let mut changed = false;
  for bb in region {
    let ops = bb.ops.iter() |> Array::from_iter();
    for op in ops {
      if (op.uses.is_empty() && !impure(op)) {
        changed = true;
        op.erase();
        continue;
      }

      for x in op.regions {
        changed = Dce::runImpl(x) || changed;
      }
    }
  }
  return changed;
}
