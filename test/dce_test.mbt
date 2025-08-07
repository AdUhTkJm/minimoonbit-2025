fn print_int(_: Int) -> Unit {}

fn side_effect() -> Unit {
  print_int(2);
}

fn main {
  let used = 42;
  print_int(used);
  let unused = 10;
  side_effect();
  let _ = 1 + 2;
}
