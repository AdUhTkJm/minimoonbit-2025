pub(open) trait Pass {
  operate(Self) -> Unit
  name(Self) -> String
}

pub(all) struct PassManager {
  module: Op
  passes: Array[&Pass]
}

pub fn PassManager::new(module: Op) -> PassManager {
  { module, passes: [] };
}

pub fn PassManager::add(self: PassManager, pass: &Pass) -> Unit {
  self.passes.push(pass);
}

pub fn PassManager::run(self: PassManager) -> Unit {
  for x in self.passes {
    let name = x.name();
    if (name == config.print_before) {
      println("===== Before \{name} =====");
      println(self.module);
    }
    x.operate();
    if (name == config.print_after) {
      println("===== After \{name} =====");
      println(self.module);
    }
  }
}
