pub fn RemoveUnit::run(self: RemoveUnit) -> Unit {
  // Remove loads and stores to units.
  let module = self.module;
  let all = module.findAll(LoadOp);
  for op in all {
    if (op.ty == unit) {
      op.erase();
    }
  }

  let all = module.findAll(StoreOp);
  for op in all {
    if (op.def(0).ty == unit) {
      op.erase();
    }
  }

  // Remove returns of unit.
  let all = module.findAll(ReturnOp);
  for op in all {
    if (op.getOperandCount() > 0 && op.def(0).ty == unit) {
      op.removeAllOperands();
    }
  }
}
