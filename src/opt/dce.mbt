pub fn impure(op: Op) -> Bool {
  return op.isAny([ReturnOp, BrOp, GotoOp, StoreOp, CallOp])
}

pub fn Dce::run(self: Dce) -> Unit {
  for x in self.funcs() {
    Dce::runImpl(x.region());
  }
}

pub fn Dce::runImpl(region: Region) -> Unit {
  for bb in region {
    let ops = bb.ops.iter() |> Array::from_iter();
    for op in ops {
      if (op.uses.is_empty() && !impure(op)) {
        op.erase();
        continue;
      }

      for x in op.regions {
        Dce::runImpl(x);
      }
    }
  }
}
