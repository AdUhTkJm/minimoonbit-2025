pub(all) struct Block {
  id: Int
  ops: List[Op]
  mut parent: Region
  mut at: Node[Block]
}

priv struct BlockCounter {
  mut cnt: Int
}

let env: BlockCounter = { cnt: 0 };

pub fn Block::new(parent: Region, at: Node[Block]) -> Block {
  let id = env.cnt;
  env.cnt += 1;
  { id, ops: List::new(), parent, at }
}

pub fn Block::dump(self: Block, depth: Int, with_tag~: Bool=false) -> String {
  guard depth >= 1;
  let indent = String::make(depth * 2 - 2, ' ');
  return (if (with_tag) { "\{indent}bb\{self.id}:\n" } else { "" }) + self.ops.to_array().map(_.dump(depth)).join("\n")
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
  let bb = region.insert_after(self);
  for it = at; it != self.end(); it = it.next() {
    at.v().move_to_end(bb);
  }
  return bb;
}
