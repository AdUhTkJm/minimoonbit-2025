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
}
