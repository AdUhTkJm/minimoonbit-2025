pub fn Mem2Reg::run(self: Mem2Reg) -> Unit {
  for x in self.funcs() {
    Mem2Reg::run_fn(x);
  }
}

pub fn Mem2Reg::run_fn(func: Op) -> Unit {
  let region = func.region();
  region.update_doms();
}
