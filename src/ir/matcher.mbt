pub enum Sexp {
  Atom(String)
  List(Array[String])
}

pub impl Show for Sexp with output(self, logger) {
  logger.write_string(match self {
    Atom(x) => x
    List(arr) => ((x) => "(\{x})")(arr.join(" "))
  })
}

pub struct Rule {
  sexp: Sexp
}

pub fn Rule::new(str: String) -> Rule {
  ...
}
