fn main {
  let filename = "test/basic.mbt";
  let content = (try? @fs.read_file_to_string(filename)).unwrap()
  let (tokens, locs) = @parse.Lexer::new(content).lex()
  println(tokens)
  let ast = @parse.Parser::new(tokens, locs).parse();
  println(ast)
}
