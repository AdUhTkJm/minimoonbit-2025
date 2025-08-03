pub(all) struct Op {
  id: Int
  kind: OpType
  ty: Type
  operands: Array[Op]
  attrs: Array[Attr]
  regions: Array[Region]

  mut parent: Block?
  mut at: Node[Op]?

  // We need a mutable multiset here. Unfortunately we don't have such thing in Moonbit.
  mut users: Array[Op]
} derive(Default)

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

pub fn Op::build(kind: OpType, ty: Type, operands: Array[Op], attrs~: Array[Attr] = [], parent: Block?, at: Node[Op]?) -> Op {
  let cnt = openv.cnt;
  openv.cnt += 1;
  { id: cnt, kind, ty, operands, attrs, regions: [], parent, at, users: [] }
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

pub fn Op::remove_user(self: Op, other: Op) -> Unit {
  for i, user in self.users {
    if (user == other) {
      self.users = self.users[:i].to_array() + self.users[i+1:].to_array();
      break;
    }
  }
}

///|
/// Removes self from parent.
/// 
pub fn Op::erase(self: Op) -> Unit {
  for x in self.operands {
    x.remove_user(self);
  }
  self.parent().ops.erase(self.at());
}

pub fn Op::dump(self: Op, depth: Int) -> String {
  let ret = "%\{self.id}: \{self.ty} = "
  let operands = if (self.operands.is_empty()) { "" } else { " " + self.operands.map((x) => "%\{x.id}").join(", ") }
  let regions = if (self.regions.is_empty()) { "" }  else { " " + self.regions.map(_.dump(depth + 1)).join(" "); }
  let attrs = if (self.attrs.is_empty()) { "" } else { " " + self.attrs.map(_.to_string()).join(" "); }
  let indent = String::make(2 * depth, ' ');
  return "\{indent}\{ret}\{self.kind}\{operands}\{attrs}\{regions}";
}

pub impl Show for Op with output(self, logger) {
  logger.write_string(self.dump(0));
}

pub fn Op::append_region(self: Op) -> Region {
  let region = Region::new(self);
  self.regions.push(region);
  return region;
}

pub fn Op::region(self: Op) -> Region {
  return self.regions[0];
}

pub fn Op::block(self: Op) -> Block {
  return self.region().block();
}

pub fn Op::isa(self:Op, kind: OpType) -> Bool {
  return self.kind == kind;
}

pub fn Op::is_any(self: Op, kinds: Array[OpType]) -> Bool {
  return @utils.any(kinds, self.isa(_));
}

pub fn Op::move_to_end(self: Op, bb: Block) -> Unit {
  self.parent().ops.erase(self.at());
  bb.ops.push_back(self);
  self.parent = Some(bb);
  self.at = bb.end().prev() |> Some;
}

pub fn Op::move_to_start(self: Op, bb: Block) -> Unit {
  self.parent().ops.erase(self.at());
  bb.ops.insert(bb.begin(), self);
  self.parent = Some(bb);
  self.at = bb.begin() |> Some;
}

pub fn Op::move_before(self: Op, other: Op) -> Unit {
  self.parent().ops.erase(self.at());
  let bb = other.parent();
  bb.ops.insert(other.at(), self);
  self.parent = Some(bb);
  self.at = other.at().prev() |> Some;
}

pub fn Op::move_after(self: Op, other: Op) -> Unit {
  self.parent().ops.erase(self.at());
  let bb = other.parent();
  bb.ops.insert(other.at().next(), self);
  self.parent = Some(bb);
  self.at = other.at().next() |> Some;
}
