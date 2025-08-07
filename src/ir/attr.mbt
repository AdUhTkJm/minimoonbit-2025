// Auto generated. Do not edit!

pub(all) enum Attr {
  Int(Int)
  Double(Double)
  ArgCount(Int)
  From(Array[Block])
  Name(String)
  Impure
  Target(Block)
  Else(Block)
}

pub fn Op::getInt(self: Op) -> Int {
  for x in self.attrs {
    if (x is Int(_0)) {
      return (_0);
    }
  }
  die("no attribute 'int'");
}

pub fn Op::hasInt(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Int(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeInt(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Int(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getDouble(self: Op) -> Double {
  for x in self.attrs {
    if (x is Double(_0)) {
      return (_0);
    }
  }
  die("no attribute 'double'");
}

pub fn Op::hasDouble(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Double(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeDouble(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Double(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getArgCount(self: Op) -> Int {
  for x in self.attrs {
    if (x is ArgCount(_0)) {
      return (_0);
    }
  }
  die("no attribute 'arg_count'");
}

pub fn Op::hasArgCount(self: Op) -> Bool {
  for x in self.attrs {
    if (x is ArgCount(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeArgCount(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is ArgCount(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getFrom(self: Op) -> Array[Block] {
  for x in self.attrs {
    if (x is From(_0)) {
      return (_0);
    }
  }
  die("no attribute 'from'");
}

pub fn Op::hasFrom(self: Op) -> Bool {
  for x in self.attrs {
    if (x is From(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeFrom(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is From(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getName(self: Op) -> String {
  for x in self.attrs {
    if (x is Name(_0)) {
      return (_0);
    }
  }
  die("no attribute 'name'");
}

pub fn Op::hasName(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Name(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeName(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Name(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::impure(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Impure) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeImpure(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Impure(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getTarget(self: Op) -> Block {
  for x in self.attrs {
    if (x is Target(_0)) {
      return (_0);
    }
  }
  die("no attribute 'target'");
}

pub fn Op::hasTarget(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Target(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeTarget(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Target(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getElse(self: Op) -> Block {
  for x in self.attrs {
    if (x is Else(_0)) {
      return (_0);
    }
  }
  die("no attribute '_else'");
}

pub fn Op::hasElse(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Else(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeElse(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Else(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}
pub impl Show for Attr with output(self, logger) {
  let str = match self {
    Int(_0) => "<\{_0}>"
    Double(_0) => "<\{_0}>"
    ArgCount(_0) => "<count = \{_0}>"
    From(_0) => "<from = \{_0.map((x) => x.id)}>"
    Name(_0) => "<name = \{_0}>"
    Impure => "<impure>"
    Target(_0) => "<bb\{_0.id}>"
    Else(_0) => "<else = bb\{_0.id}>"
  }
  logger.write_string(str);
}
