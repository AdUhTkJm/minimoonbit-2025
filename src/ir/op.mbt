pub(all) struct Op {
  id: Int
  kind: OpKind
  mut ty: Type
  mut operands: Array[Op]
  mut attrs: Array[Attr]
  mut regions: Array[Region]

  mut parent: Block?
  mut at: Node[Op]?

  // We need a mutable multiset here. Unfortunately we don't have such thing in Moonbit.
  mut uses: Array[Op]
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

let openv: OpEnv = { cnt: 1 };

pub fn Op::build(kind: OpKind, ty: Type, operands: Array[Op], attrs~: Array[Attr] = [], parent: Block?, at: Node[Op]?) -> Op {
  let cnt = openv.cnt;
  openv.cnt += 1;
  let self = { id: cnt, kind, ty, operands, attrs, regions: [], parent, at, uses: [] };
  for x in operands {
    x.uses.push(self);
  }
  return self;
}

///|
/// Gets the i'th operand of the operation.
/// 
/// This is called `def`, which is an abbreviation of `op.getOperand(i)->getDefiningOp()` in MLIR.
/// It might be misleading at beginning, but once you're used to it, it's OK.
pub fn Op::def(self: Op, i: Int) -> Op {
  return self.operands[i];
}

///|
/// Gets the block that the operation is in.
/// 
pub fn Op::parent(self: Op) -> Block {
  return self.parent.unwrap();
}

///|
/// Gets the iterator pointing to the location of the operation within its parent block.
/// 
pub fn Op::at(self: Op) -> Node[Op] {
  return self.at.unwrap();
}

///|
/// Removes `other` from `self`'s uses.
/// 
pub fn Op::removeUse(self: Op, other: Op) -> Unit {
  for i, user in self.uses {
    if (user == other) {
      self.uses = self.uses[:i].to_array() + self.uses[i+1:].to_array();
      break;
    }
  }
}

///|
/// `Self` is no longer using `other`, so `other`'s uses should no longer contain `self`.
/// 
pub fn Op::stopUsing(self: Op, other: Op) -> Unit {
  other.removeUse(self);
}

///|
/// Removes self from parent.
/// 
pub fn Op::erase(self: Op) -> Unit {
  if (!self.uses.is_empty()) {
    println("removing non-empty op: \{self}");
    println("uses:")
    for x in self.uses {
      println(x);
    }
    panic();
  }
  self.parent().ops.erase(self.at());
  self.removeAllOperands();
  let regions = self.regions[:].to_array();
  for region in regions {
    region.erase();
  }
}

pub fn Op::dump(self: Op, depth: Int) -> String {
  let ty = if (@utils.config.with_type) { ": \{self.ty}" } else { "" };
  let ret = "%\{self.id}\{ty} = "
  let operands = if (self.operands.is_empty()) { "" } else { " " + self.operands.map((x) => "%\{x.id}").join(", ") }
  let regions = if (self.regions.is_empty()) { "" }  else { " " + self.regions.map(_.dump(depth + 1)).join(" "); }
  let attrs = if (self.attrs.is_empty()) { "" } else { " " + self.attrs.map(_.to_string()).join(" "); }
  let indent = String::make(2 * depth, ' ');
  return "\{indent}\{ret}\{self.kind}\{operands}\{attrs}\{regions}";
}

pub impl Show for Op with output(self, logger) {
  logger.write_string(self.dump(0));
}

pub fn Op::appendRegion(self: Op) -> Region {
  let region = Region::new(self);
  self.regions.push(region);
  return region;
}

///|
/// Obtains the operation's first region.
/// 
pub fn Op::region(self: Op) -> Region {
  return self.regions[0];
}

///|
/// Obtains the first block inside the operation's first region.
/// 
pub fn Op::block(self: Op) -> Block {
  return self.region().block();
}

///|
/// Returns true if the operation is of kind `kind`.
/// 
pub fn Op::isa(self:Op, kind: OpKind) -> Bool {
  return self.kind == kind;
}

pub fn Op::isAny(self: Op, kinds: Array[OpKind]) -> Bool {
  return @utils.any(kinds, self.isa(_));
}

pub fn Op::moveToEnd(self: Op, bb: Block) -> Unit {
  self.parent().ops.erase(self.at());
  bb.ops.push_back(self);
  self.parent = Some(bb);
  self.at = bb.end().prev() |> Some;
}

pub fn Op::moveToStart(self: Op, bb: Block) -> Unit {
  self.parent().ops.erase(self.at());
  bb.ops.insert(bb.begin(), self);
  self.parent = Some(bb);
  self.at = bb.begin() |> Some;
}

pub fn Op::moveBefore(self: Op, other: Op) -> Unit {
  self.parent().ops.erase(self.at());
  let bb = other.parent();
  bb.ops.insert(other.at(), self);
  self.parent = Some(bb);
  self.at = other.at().prev() |> Some;
}

pub fn Op::moveAfter(self: Op, other: Op) -> Unit {
  self.parent().ops.erase(self.at());
  let bb = other.parent();
  bb.ops.insert(other.at().next(), self);
  self.parent = Some(bb);
  self.at = other.at().next() |> Some;
}

pub fn Op::findAll(self: Op, kind: OpKind) -> Array[Op] {
  let result = [];
  if (self.isa(kind)) {
    result.push(self);
  }
  for region in self.regions {
    for bb in region {
      for op in bb {
        result.append(op.findAll(kind));
      }
    }
  }
  return result;
}

pub fn Op::replaceAllUsesWith(self: Op, other: Op) -> Unit {
  // We are modifying `uses` and `operands` in place.
  let uses = self.uses[:].to_array();
  for x in uses {
    let operands = x.operands[:].to_array();
    for i, w in operands {
      if (w == self) {
        x.setOperand(i, other);
      }
    }
  }
}

pub fn Op::setOperand(self: Op, i: Int, v: Op) -> Unit {
  let op = self.operands[i];
  self.operands[i] = v;
  self.stopUsing(op);
  v.uses.push(self);
}

pub fn Op::pushOperand(self: Op, operand: Op) -> Unit {
  self.operands.push(operand);
  operand.uses.push(self);
}

pub fn Op::add(self: Op, x: Attr) -> Unit {
  self.attrs.push(x);
}

pub fn Op::removeAllOperands(self: Op) -> Unit {
  for x in self.operands {
    self.stopUsing(x);
  }
  self.operands = [];
}

pub fn Op::removeRegion(self: Op, region: Region) -> Unit {
  for i, x in self.regions {
    if (physical_equal(x, region)) {
      self.regions = self.regions[:i].to_array() + self.regions[i+1:].to_array();
    }
  }
}

pub fn Op::removeOperand(self: Op, i: Int) -> Unit {
  let x = self.operands[i];
  self.stopUsing(x);
  self.operands = self.operands[:i].to_array() + self.operands[i+1:].to_array();
}

pub fn Op::getOperands(self: Op) -> Array[Op] {
  return self.operands;
}

pub fn Op::getOperandCount(self: Op) -> Int {
  return self.operands.length();
}

pub fn Op::atFront(self: Op) -> Bool {
  return self.at() == self.parent().ops.begin;
}

pub fn Op::atBack(self: Op) -> Bool {
  return self.at().next() == self.parent().ops.end;
}

pub fn Op::prevOp(self: Op) -> Op {
  if (self.atFront()) {
    return Op::default();
  }
  return self.at().prev().v();
}

pub fn Op::nextOp(self: Op) -> Op {
  if (self.atBack()) {
    return Op::default();
  }
  return self.at().next().v();
}

pub fn Op::valid(self: Op) -> Bool {
  return self.id != 0;
}
