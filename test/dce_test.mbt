// Test dead code elimination with comprehensive cases
fn main() {
  // 1. Basic variable usage test, should not be eliminated
  let used_var = 42;
  println(used_var);
  
  // 2. Unused variable should be eliminated
  let unused_var = 10;
  
  // 3. Function call with side effect, should not be eliminated
  side_effect();
  
  // 4. Pure computation should be eliminated
  let _ = 1 + 2;
}

fn side_effect() {
  println("This has side effect");
}