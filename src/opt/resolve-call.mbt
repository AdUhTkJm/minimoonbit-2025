pub fn ResolveCall::run(self: ResolveCall) -> Unit {
  // TODO: deal with closures

  let calls = self.module.findAll(CallOp);
  for call in calls {
    let func = call.def(0);
    guard (isa[GetGlobalOp](func)) else { die("Bad call: \{call}"); }
    call.removeOperand(0);
    call.add(Name(func.getName()));
  }
}
