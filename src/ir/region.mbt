pub(all) struct Region {
  bbs: List[Block]
  mut parent: Op
}

pub impl Show for Region with output(self, logger) {
  logger.write_string(self.dump(1))
}

pub fn Region::dump(self: Region, depth: Int) -> String {
  guard depth >= 1;
  let indent = String::make(depth * 2 - 2, ' ');
  if (self.bbs.size() == 1) {
    // Ignore the basic block count.
    return "{\n\{self.bbs.begin.v().dump(depth, with_tag=false)}\n\{indent}};"
  }
  let bbs = self.bbs.to_array().map(_.dump(depth)).join("\n");
  return "{\n\{bbs}\n\{indent}}"
}

pub fn Region::new(parent: Op) -> Region {
  { bbs: List::new(), parent }
}

pub fn Region::append_block(self: Region) -> Block {
  let block = Block::new(self, self.bbs.end);
  self.bbs.push_back(block);
  block.at = self.bbs.end.prev();
  return block;
}

///|
/// Retrieves the first block in this region.
/// 
pub fn Region::block(self: Region) -> Block {
  return self.bbs.begin.v();
}

pub fn Region::iter(self: Region) -> Iter[Block] {
  return self.bbs.iter();
}

///|
/// Inserts an empty block before the given block.
/// 
pub fn Region::insert(self: Region, bb: Block) -> Block {
  let block = Block::new(self, self.bbs.end);
  self.bbs.insert(bb.at, block);
  block.at = bb.at.prev();
  return block;
}

///|
/// Inserts an empty block after the given block.
/// 
pub fn Region::insert_after(self: Region, bb: Block) -> Block {
  let block = Block::new(self, self.bbs.end);
  self.bbs.insert(bb.at.next(), block);
  block.at = bb.at.next();
  return block;
}

pub fn Region::update_preds(self: Region) -> Unit {
  for bb in self.bbs {
    let term = bb.back();
    if term.has_target() {
      bb.succs.add(term.target());
    }
    if term.has_else() {
      bb.succs.add(term._else());
    }
  }

  for bb in self.bbs {
    for succ in bb.succs {
      succ.preds.add(bb);
    }
  }
}

pub fn Region::update_doms(self: Region) -> Unit {
  self.update_preds();
}
