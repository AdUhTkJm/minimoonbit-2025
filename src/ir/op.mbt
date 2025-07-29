pub struct Op {
  id: Int
  kind: OpType
  ty: Type?
  operands: Array[Op]
  attrs: Map[String, Attr]
  regions: Array[Region]

  parent: Block?
  at: Node[Op]?
}

pub impl Eq for Op with op_equal(self, other) {
  return self.id == other.id;
}

pub impl Hash for Op with hash_combine(self, x) {
  return x.combine_int(self.id);
}

priv struct OpEnv {
  mut cnt: Int
}

let openv: OpEnv = { cnt: 0 };

pub fn Op::build(kind: OpType, ty: Type?, operands: Array[Op], attrs~: Map[String, Attr] = Map::new(), parent: Block?, at: Node[Op]?) -> Op {
  let cnt = openv.cnt;
  openv.cnt += 1;
  { id: cnt, kind, ty, operands, attrs, regions: [], parent, at }
}

///|
/// Gets the return type.
pub fn Op::ty(self: Op) -> Type {
  return self.ty.unwrap();
}

///|
/// Gets the i'th operand of the operation.
/// 
/// This is called `def`, which is an abbreviation of `op.getOperand(i)->getDefiningOp()` in MLIR.
/// It might be misleading at beginning, but once you're used to it, it's OK.
pub fn Op::def(self: Op, i: Int) -> Op {
  return self.operands[i];
}

pub fn Op::parent(self: Op) -> Block {
  return self.parent.unwrap();
}

pub fn Op::at(self: Op) -> Node[Op] {
  return self.at.unwrap();
}

///|
/// Removes self from parent.
/// 
pub fn Op::erase(self: Op) -> Unit {
  self.parent().ops.erase(self.at());
}

pub impl Show for Op with output(self, logger) {
  let ret = if (self.ty is None) { "" } else { "%\{self.id}: \{self.ty.unwrap()} = " }
  let operands = if (self.operands.is_empty()) { "" } else { " " + self.operands.map(_.to_string()).join(", ") }
  let regions = if (self.regions.is_empty()) { "" }  else { " " + self.regions.map(_.to_string()).join("\n"); }
  let attrs = if (self.attrs.size() == 0) { "" } else {
    " " + self.attrs.to_array().map((x) => { let (k, v) = x; "<\{k}: \{v}>" }).join(" ");
  }
  logger.write_string("\{ret}\{self.kind}\{operands}\{attrs}\{regions}")
}
