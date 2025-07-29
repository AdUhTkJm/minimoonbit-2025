pub struct Block {
  id: Int
  ops: List[Op]
}

priv struct BlockCounter {
  mut cnt: Int
}

let env: BlockCounter = { cnt: 0 };

pub fn Block::new() -> Block {
  let id = env.cnt;
  env.cnt += 1;
  { id, ops: List::new() }
}

pub fn Block::dump(self: Block, depth: Int) -> String {
  guard depth >= 1;
  let indent = String::make(depth * 2 - 2, ' ');
  return "\{indent}bb\{self.id}:\n" + self.ops.to_array().map(_.dump(depth)).join("\n")
}

pub impl Show for Block with output(self, logger) {
  logger.write_string(self.dump(1));
}
