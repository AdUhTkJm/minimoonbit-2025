pub fn Mem2Reg::run(self: Mem2Reg) -> Unit {
  for x in self.funcs() {
    self.runImpl(x);
  }
}

pub fn Mem2Reg::runImpl(self: Mem2Reg, func: Op) -> Unit {
  let region = func.region();
  region.updateDomfront();

  self.domtree.clear();
  self.converted.clear();
  self.phiFrom.clear();
  self.visited.clear();

  self.domtree = region.domtree();

  let builder = Builder::new();

  // We need to put PhiOp at places where a StoreOp doesn't dominate,
  // because it means at least 2 possible values.
  let allocas = func.findAll(AllocaOp);
  for alloca in allocas {
    let mut good = true;

    // If the alloca is used for, as an example, AddOp, then
    // it's an array and can't be promoted to registers.
    for use in alloca.uses {
      if (!isa[LoadOp](use) && !isa[StoreOp](use)) {
        good = false;
        break;
      }
      // If the alloca is used as a value in a StoreOp, then it has to be an array.
      if (isa[StoreOp](use) && use.def(0) == alloca) {
        good = false;
        break;
      }
    }

    if (!good) {
      continue;
    }
    
    self.converted.add(alloca);

    // Now find all blocks where stores reside in. Use set to de-duplicate.
    let bbs: Set[Block] = Set::new();
    for use in alloca.uses {
      if (isa[StoreOp](use)) {
        bbs.add(use.parent());
      }
    }

    let worklist = bbs.iter() |> Array::from_iter;
    let visited: Set[Block] = Set::new();

    while (!worklist.is_empty()) {
      let bb = worklist.pop().unwrap();

      for dom in bb.domfront {
        if (visited.contains(dom)) {
          continue;
        }
        visited.add(dom);

        // Insert a PhiOp at the dominance frontier of each StoreOp, as described above.
        // The PhiOp is broken; we only record which AllocaOp it's from.
        // We'll fill it in later.
        builder.setToBlockStart(dom);
        let phi = builder.create(PhiOp, unit, [], attrs=[From([])]);
        self.phiFrom[phi] = alloca;
        worklist.push(dom);
      }
    }
  }

  self.fillPhi(func.block(), Map::new());

  for alloca in self.converted {
    alloca.erase();
  }
}


fn Mem2Reg::fillPhi(self: Mem2Reg, bb: Block, symbols: Map[Op, Op]) -> Unit {
  if (self.visited.contains(bb)) {
    return;
  }
  self.visited.add(bb);

  let builder = Builder::new();

  let removed: Array[Op] = [];
  for op in bb {
    // Loads are now ordinary reads.
    if (isa[LoadOp](op)) {
      let alloca = op.def(0);
      if (!self.converted.contains(alloca)) {
        continue;
      }
  
      if (!symbols.contains(alloca)) {
        builder.setBeforeOp(op);
        let fp = op.ty.fp();
        symbols[alloca] = if (fp) {
          builder.createDouble(0);
        } else {
          builder.createInt(0);
        }
      }
      
      op.replaceAllUsesWith(symbols[alloca]);
      removed.push(op);
    }
    
    // Stores are now mutating symbol table.
    if (isa[StoreOp](op)) {
      let value = op.def(0);
      let alloca = op.def(1);
      if (!self.converted.contains(alloca)) {
        continue;
      }
      symbols[alloca] = value;
      removed.push(op);
    }

    if (isa[PhiOp](op)) {
      if (!self.phiFrom.contains(op)) {
        continue;
      }
      let alloca = self.phiFrom[op];
      symbols[alloca] = op;
    }
  }

  for succ in bb.succs {
    let phis = succ.getPhis();
    for op in phis {
      let alloca = self.phiFrom[op];

      // We meet a PhiOp. This means the promoted register might hold value `symbols[alloca]` when it reaches here.
      // So this PhiOp should have that value as operand as well.
      let value = (
      
      // It doesn't have an initial value from this path.
      // It's acceptable (for example a variable defined only in a loop)
      // Treat it as zero from this branch.
      if (!symbols.contains(alloca)) {
        // Create a zero at the back of the incoming edge.
        let term = bb.getLastOp();
        builder.setBeforeOp(term);
        builder.createInt(0);
      } else {
        symbols[alloca];
      })

      op.pushOperand(value);
      let from = op.getFrom();
      op.removeFrom();
      op.add(From([..from, bb]));
    }
  }

  for x in removed {
    x.erase();
  }
  
  for child in self.domtree[bb] {
    self.fillPhi(child, symbols.clone());
  }
}
