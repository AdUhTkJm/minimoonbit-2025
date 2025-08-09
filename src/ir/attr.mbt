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
  Reg(Int)
  Rd(Int)
  Rs(Int)
  Rs2(Int)
  SpilledRd(Bool, Int, Op)
  SpilledRs(Bool, Int, Op)
  SpilledRs2(Bool, Int, Op)
  StackOffset(Int)
  Size(Int)
}

pub fn Op::getInt(self: Op) -> Int {
  for x in self.attrs {
    if (x is Int(_0)) {
      return (_0);
    }
  }
  die("no attribute 'int': \{self}");
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
  die("no attribute 'double': \{self}");
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
  die("no attribute 'arg_count': \{self}");
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
  die("no attribute 'from': \{self}");
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
  die("no attribute 'name': \{self}");
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
  die("no attribute 'target': \{self}");
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
  die("no attribute '_else': \{self}");
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

pub fn Op::getReg(self: Op) -> Int {
  for x in self.attrs {
    if (x is Reg(_0)) {
      return (_0);
    }
  }
  die("no attribute 'reg': \{self}");
}

pub fn Op::hasReg(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Reg(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeReg(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Reg(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getRd(self: Op) -> Int {
  for x in self.attrs {
    if (x is Rd(_0)) {
      return (_0);
    }
  }
  die("no attribute 'rd': \{self}");
}

pub fn Op::hasRd(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Rd(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeRd(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Rd(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getRs(self: Op) -> Int {
  for x in self.attrs {
    if (x is Rs(_0)) {
      return (_0);
    }
  }
  die("no attribute 'rs': \{self}");
}

pub fn Op::hasRs(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Rs(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeRs(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Rs(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getRs2(self: Op) -> Int {
  for x in self.attrs {
    if (x is Rs2(_0)) {
      return (_0);
    }
  }
  die("no attribute 'rs2': \{self}");
}

pub fn Op::hasRs2(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Rs2(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeRs2(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Rs2(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getSpilledRd(self: Op) -> (Bool, Int, Op) {
  for x in self.attrs {
    if (x is SpilledRd(_0, _1, _2)) {
      return (_0, _1, _2);
    }
  }
  die("no attribute 'spilled_rd': \{self}");
}

pub fn Op::hasSpilledRd(self: Op) -> Bool {
  for x in self.attrs {
    if (x is SpilledRd(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeSpilledRd(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is SpilledRd(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getSpilledRs(self: Op) -> (Bool, Int, Op) {
  for x in self.attrs {
    if (x is SpilledRs(_0, _1, _2)) {
      return (_0, _1, _2);
    }
  }
  die("no attribute 'spilled_rs': \{self}");
}

pub fn Op::hasSpilledRs(self: Op) -> Bool {
  for x in self.attrs {
    if (x is SpilledRs(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeSpilledRs(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is SpilledRs(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getSpilledRs2(self: Op) -> (Bool, Int, Op) {
  for x in self.attrs {
    if (x is SpilledRs2(_0, _1, _2)) {
      return (_0, _1, _2);
    }
  }
  die("no attribute 'spilled_rs2': \{self}");
}

pub fn Op::hasSpilledRs2(self: Op) -> Bool {
  for x in self.attrs {
    if (x is SpilledRs2(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeSpilledRs2(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is SpilledRs2(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getStackOffset(self: Op) -> Int {
  for x in self.attrs {
    if (x is StackOffset(_0)) {
      return (_0);
    }
  }
  die("no attribute 'stack_offset': \{self}");
}

pub fn Op::hasStackOffset(self: Op) -> Bool {
  for x in self.attrs {
    if (x is StackOffset(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeStackOffset(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is StackOffset(_)) {
      self.attrs = self.attrs[:i].to_array() + self.attrs[i+1:].to_array();
    }
  }
}

pub fn Op::getSize(self: Op) -> Int {
  for x in self.attrs {
    if (x is Size(_0)) {
      return (_0);
    }
  }
  die("no attribute 'size': \{self}");
}

pub fn Op::hasSize(self: Op) -> Bool {
  for x in self.attrs {
    if (x is Size(_)) {
      return true;
    }
  }
  return false;
}

pub fn Op::removeSize(self: Op) -> Unit {
  for i, x in self.attrs {
    if (x is Size(_)) {
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
    Reg(_0) => "<\{reg(_0)}>"
    Rd(_0) => "<rd = \{reg(_0)}>"
    Rs(_0) => "<rs = \{reg(_0)}>"
    Rs2(_0) => "<rs2 = \{reg(_0)}>"
    SpilledRd(_0, _1, _2) => "<rd = spilled \{_1}>"
    SpilledRs(_0, _1, _2) => "<rs = spilled \{_1}>"
    SpilledRs2(_0, _1, _2) => "<rs2 = spilled \{_1}>"
    StackOffset(_0) => "<offset = \{_0}>"
    Size(_0) => "<size = \{_0}>"
  }
  logger.write_string(str);
}
