fn main {
  let filename = "test/basic.mbt";
  let content = (try? @fs.read_file_to_string(filename)).unwrap()
  let tokens = @parse.Lexer::new(content).lex()
  println(tokens)
}
