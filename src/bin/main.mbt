fn compile(filename: String) -> Unit {
  let content = (try? @fs.read_file_to_string(filename)).unwrap()
  let (tokens, locs) = @parse.Lexer::new(content).lex()
  let mut ast = @parse.Parser::new(tokens, locs).parse() |> @parse.AST::Block;
  let env = @parse.TypingEnv::new();
  env.infer(ast) |> ignore;
  ast = env.solve(ast);
  if (config.dump_ast) {
    println(env.dump(ast, 1));
  }
  let cg = @ir.CodeGen::new(env);
  let module = cg.build(ast);
  let pm = opt(module);
  pm.run();
}

test {
  compile("test/basic.mbt")
}

fn main {
  @utils.parse(@sys.get_cli_args());
  compile(config.input);
  ignore(config.output);
}
