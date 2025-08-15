///|
/// Removes closure: turns them into normal functions.
/// 
pub fn Disclosure::run(self: Disclosure) -> Unit {
  for x in self.funcs() {
    self.runImpl(x);
  }
}

pub fn Disclosure::runImpl(self: Disclosure, func: Op) -> Unit {
  
}
