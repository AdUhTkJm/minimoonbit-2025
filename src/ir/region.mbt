pub struct Region {
  bbs: List[Block]
}

pub impl Show for Region with output(self, logger) {
  logger.write_string(self.dump(1))
}

pub fn Region::dump(self: Region, depth: Int) -> String {
  guard depth >= 1;
  let indent = String::make(depth * 2 - 2, ' ');
  let bbs = self.bbs.map(_.dump(depth)).join("\n");
  return "\{indent}{\n\{bbs}\n\{indent}}"
}

pub fn Region::new() -> Region {
  { bbs: List::new() }
}
