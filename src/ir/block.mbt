pub(all) struct Block {
  mut id: Int
  mut ops: List[Op]
  mut parent: Region
  mut at: Node[Block]
  mut preds: Set[Block]
  mut succs: Set[Block]
  mut doms: Set[Block] // These are blocks that dominate this.
  mut idom: Block?
  mut domfront: Set[Block] // Dominance frontier.
}

pub impl Eq for Block with op_equal(self, other) {
  return physical_equal(self, other);
}

pub impl Hash for Block with hash_combine(self, hasher) {
  hasher.combine_int(self.id);
}

priv struct BlockCounter {
  mut cnt: Int
}

let env: BlockCounter = { cnt: 0 };

pub fn Block::new(parent: Region, at: Node[Block]) -> Block {
  let id = env.cnt;
  env.cnt += 1;
  {
    id, ops: List::new(), parent, at,
    preds: Set::new(), succs: Set::new(),
    doms: Set::new(), idom: None, domfront: Set::new(),
  }
}

pub fn Block::dump(self: Block, depth: Int, with_tag~: Bool=true) -> String {
  guard depth >= 1;
  let indent = String::make(depth * 2 - 2, ' ');
  let preds = self.preds.iter().map((x) => x.id);
  let domfront = self.domfront.iter().map((x) => x.id);
  let tag = "\{indent}bb\{self.id}:    // preds = \{preds}, idom = \{self.idom.map_or(0, (x) => x.id)}, domfront = \{domfront}\n";
  return (if (with_tag) { tag } else { "" }) + self.ops.to_array().map(_.dump(depth)).join("\n")
}

pub impl Show for Block with output(self, logger) {
  logger.write_string(self.dump(1));
}

pub fn Block::iter(self: Block) -> Iter[Op] {
  return self.ops.iter();
}

///|
/// Splits the block into two, such that `op` is at the beginning of the next block.
/// 
pub fn Block::split(self: Block, op: Op) -> Block {
  let at = op.at();
  self.split_at(at);
}

///|
/// Splits the block into two, such that `op` is at the end of the original block.
/// 
pub fn Block::split_after(self: Block, op: Op) -> Block {
  let at = op.at().next();
  self.split_at(at);
}

pub fn Block::begin(self: Block) -> Node[Op] {
  return self.ops.begin
}

pub fn Block::end(self: Block) -> Node[Op] {
  return self.ops.end
}

pub fn Block::split_at(self: Block, at: Node[Op]) -> Block {
  let region = self.parent;
  let bb = region.insertAfter(self);
  let mut it = at;
  while it != self.end() {
    let next = it.next();
    it.v().moveToEnd(bb);
    it = next;
  }
  return bb;
}

///|
/// Create a copy of `self.ops`.
/// 
pub fn Block::ops(self: Block) -> List[Op] {
  return self.ops.to_array() |> List::from_array;
}

pub fn Block::dominates(self: Block, other: Block) -> Bool {
  return other.doms.contains(self);
}

pub fn Block::dominated_by(self: Block, other: Block) -> Bool {
  return other.dominates(self);
}

///|
/// Retrieves the last Op in the block.
/// 
pub fn Block::getLastOp(self: Block) -> Op {
  return self.ops.back();
}

///|
/// Gets the next basic block inside the region.
/// 
pub fn Block::next(self: Block) -> Block {
  return self.at.next().v();
}

///|
/// Returns true if the block is at the very end of the region.
/// 
pub fn Block::at_back(self: Block) -> Bool {
  return self.at.next() == self.parent.bbs.end;
}

///|
/// Returns the immediate dominator.
/// 
pub fn Block::idom(self: Block) -> Block {
  return self.idom.unwrap();
}

pub fn Block::getPhis(self: Block) -> Array[Op] {
  let phis = [];
  for x in self {
    if (!isa[PhiOp](x)) {
      break;
    }
    phis.push(x);
  }
  return phis;
}
