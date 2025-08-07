// Auto generated. Do not edit!

pub fn opt(module: @ir.Op) -> @opt.PassManager {
  let pm = @opt.PassManager::new(module);
  pm.add(@opt.create_move_alloca(module));
  pm.add(@opt.create_flatten(module));
  pm.add(@opt.create_mem2reg(module));
  return pm;
}
