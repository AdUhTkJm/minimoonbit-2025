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

pub fn Region::appendBlock(self: Region) -> Block {
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
pub fn Region::insertAfter(self: Region, bb: Block) -> Block {
  let block = Block::new(self, self.bbs.end);
  self.bbs.insert(bb.at.next(), block);
  block.at = bb.at.next();
  return block;
}

pub fn Region::updatePreds(self: Region) -> Unit {
  for bb in self.bbs {
    let term = bb.getLastOp();
    if term.hasTarget() {
      bb.succs.add(term.getTarget());
    }
    if term.hasElse() {
      bb.succs.add(term.getElse());
    }
  }

  for bb in self.bbs {
    for succ in bb.succs {
      succ.preds.add(bb);
    }
  }
}

pub fn Region::updateDoms(self: Region) -> Unit {
  self.updatePreds();
  for bb in self.bbs {
    bb.doms = self.bbs.iter() |> Set::from_iter();
  }
  let start = self.front();
  start.doms = Set::from_array([ start ]);
  
  let mut changed = true;
  while (changed) {
    changed = false;
    for bb in self.bbs {
      if (bb == start) {
        continue;
      }

      let mut doms = self.bbs.iter() |> Set::from_iter();
      for pred in bb.preds {
        doms = doms.intersection(pred.doms);
      }
      doms.add(bb);
      if (bb.doms != doms) {
        changed = true;
      }
      bb.doms = doms;
    }
  }

  for bb in self.bbs {
    let doms = bb.doms.iter() |> Array::from_iter;
    for dom in doms {
      if (dom == bb) {
        continue;
      }
      if @utils.none(doms, (x) => dom != x && x != bb && dom.dominates(x)) {
        bb.idom = Some(dom);
        break;
      }
    }
  }
}

pub fn Region::updateDomfront(self: Region) -> Unit {
  self.updateDoms();
  for bb in self.bbs {
    bb.domfront = Set::new();
  }
  for bb in self.bbs {
    if bb.preds.size() <= 1 {
      continue;
    }
    for p in bb.preds {
      let mut runner = p;
      while runner != bb.idom() {
        runner.domfront.add(bb);
        runner = runner.idom();
      }
    }
  }
}

pub fn Region::front(self: Region) -> Block {
  return self.bbs.begin.v();
}

pub fn Region::back(self: Region) -> Block {
  return self.bbs.end.prev().v();
}

pub fn Region::domtree(self: Region) -> Map[Block, Array[Block]] {
  let result: Map[Block, Array[Block]] = Map::new();
  for bb in self.bbs {
    result[bb] = [];
  }
  for bb in self.bbs {
    for x in bb.doms {
      result[x].push(bb);
    }
  }
  return result;
}

pub fn Region::erase(self: Region) -> Unit {
  for bb in self.bbs {
    for op in bb {
      op.removeAllOperands();
      for region in op.regions {
        region.erase();
      }
    }
  }
  let copy = self.bbs.to_array();
  for bb in copy {
    bb.erase();
  }
  self.parent.removeRegion(self);
}
