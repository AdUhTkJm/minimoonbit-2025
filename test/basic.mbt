fn print_int(_: Int) -> Unit { }

fn main {
  let mut count = 0;
  let mut x = 0;
  while x != 1 {
    if (x % 2 == 0) {
      x /= 2;
    } else {
      x = x * 3 + 1;
    }
    count += 1;
  }
  print_int(count);
}
