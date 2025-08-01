struct Config {
  mut input: String
  mut output: String
} derive(Default)

fn parse(args: Array[String]) -> Config {
  // Note that args[0] is the path to the executable, and should be ignored.
  let mut i = 1;
  let config = Config::default();
  while (i < args.length()) {
    if (args[i] == "-o") {
      config.output = args[i + 1];
      i += 2;
      continue;
    }
    config.input = args[i];
    i += 1;
  }
  return config;
}

test {
  let content = (try? @fs.read_file_to_string("test/basic.mbt")).unwrap()
  let (tokens, locs) = @parse.Lexer::new(content).lex()
  let mut ast = @parse.Parser::new(tokens, locs).parse() |> @parse.AST::Block;
  let env = @parse.TypingEnv::new();
  env.infer(ast) |> ignore;
  ast = env.solve(ast);
  println(env.dump(ast, 1));
  println(env.constraints);
}

fn main {
  let config = parse(@sys.get_cli_args());
  let content = (try? @fs.read_file_to_string(config.input)).unwrap()
  let (tokens, locs) = @parse.Lexer::new(content).lex()
  let ast = @parse.Parser::new(tokens, locs).parse() |> @parse.AST::Block;
  let env = @parse.TypingEnv::new();
  env.infer(ast) |> ignore;
  println(env.dump(ast, 1));
  ignore(config.output); // TODO
}
