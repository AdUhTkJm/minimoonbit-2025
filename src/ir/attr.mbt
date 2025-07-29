pub(all) enum Attr {
  Int(Int)
  Double(Double)
}

pub impl Show for Attr with output(self, logger) {
  let str = match self {
    Int(x) => "\{x}"
    Double(x) => "\{x}"
  }
  logger.write_string(str);
}
