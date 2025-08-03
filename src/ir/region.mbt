pub struct Region {
  bbs: List[Block]
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

pub fn Region::new() -> Region {
  { bbs: List::new() }
}

pub fn Region::append_block(self: Region) -> Block {
  let block = Block::new();
  self.bbs.push_back(block);
  return block;
}

pub fn Region::block(self: Region) -> Block {
  return self.bbs.begin.v();
}
