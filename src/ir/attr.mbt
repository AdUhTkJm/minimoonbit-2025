// Auto generated. Do not edit!

pub(all) enum Attr {
  Int(Int)
  Double(Double)
  ArgCount(Int)
  From(Array[Block])
  Name(String)
  Impure
}

pub fn Op::int(self: Op) -> Int {
  for x in self.attrs {
    if (x is Int(_0)) {
      return (_0);
    }
  }
  die("no attribute 'int'");
}

pub fn Op::has_int(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Int(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::double(self: Op) -> Double {
  for x in self.attrs {
    if (x is Double(_0)) {
      return (_0);
    }
  }
  die("no attribute 'double'");
}

pub fn Op::has_double(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Double(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::arg_count(self: Op) -> Int {
  for x in self.attrs {
    if (x is ArgCount(_0)) {
      return (_0);
    }
  }
  die("no attribute 'arg_count'");
}

pub fn Op::has_arg_count(self: Op) -> Bool {
  for x in self.attrs {
    if (x is ArgCount(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::from(self: Op) -> Array[Block] {
  for x in self.attrs {
    if (x is From(_0)) {
      return (_0);
    }
  }
  die("no attribute 'from'");
}

pub fn Op::has_from(self: Op) -> Bool {
  for x in self.attrs {
    if (x is From(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::name(self: Op) -> String {
  for x in self.attrs {
    if (x is Name(_0)) {
      return (_0);
    }
  }
  die("no attribute 'name'");
}

pub fn Op::has_name(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Name(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::impure(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Impure) {
      return true;
    }
  }
  return false;
}
pub impl Show for Attr with output(self, logger) {
  let str = match self {
    Int(_0) => "<\{_0}>"
    Double(_0) => "<\{_0}>"
    ArgCount(_0) => "<count = \{_0}>"
    From(_0) => "<from = \{_0}>"
    Name(_0) => "<name = \{_0}>"
    Impure => "<impure>"
  }
  logger.write_string(str);
}
