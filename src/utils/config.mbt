pub(all) struct Config {
  mut input: String
  mut output: String
  mut print_after: String
  mut print_before: String
  mut dump_ast: Bool
  mut with_type: Bool
} derive(Default)

pub let config: Config = Config::default();

pub fn parse(args: Array[String]) -> Unit {
  // Note that args[0] is the path to the executable, and should be ignored.
  let mut i = 1;
  while (i < args.length()) {
    if (args[i] == "-o") {
      config.output = args[i + 1];
      i += 2;
      continue;
    }
    if (args[i] == "-p") {
      config.print_after = args[i + 1];
      i += 2;
      continue;
    }
    if (args[i] == "-q") {
      config.print_before = args[i + 1];
      i += 2;
      continue;
    }
    if (args[i] == "--ast") {
      config.dump_ast = true;
      i += 1;
      continue;
    }
    if (args[i] == "--types") {
      config.with_type = true;
      i += 1;
      continue;
    }
    config.input = args[i];
    i += 1;
  }
}
