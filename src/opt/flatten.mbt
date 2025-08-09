fn flattenIf(func: Op) -> Bool {
  let builder = Builder::new();
  let region = func.region();
  for bb in region {
    for op in bb.ops() {
      if (!isa[IfOp](op)) {
        continue;
      }

      let parent = op.parent();
      let exit = parent.split(op);

      // Create an block for body.
      let ifso = region.insert(exit);
      let ops = op.block().ops();
      for op in ops {
        op.moveToEnd(ifso);
      }
      // The block should jump to exit.
      builder.setToBlockEnd(ifso);
      builder.creates(GotoOp, unit, [], attrs=[Target(exit)]);

      // There is an else region.
      let mut _else = exit;
      if (op.regions.length() == 2) {
        let ifnot = region.insert(exit);
        let ops = op.regions[1].block().ops();
        for op in ops {
          op.moveToEnd(ifnot);
        }
        // The block should jump to exit.
        builder.setToBlockEnd(ifnot);
        builder.creates(GotoOp, unit, [], attrs=[Target(exit)]);
        _else = ifnot;
      }

      // Create a branch at `parent`.
      builder.setToBlockEnd(parent);
      let cond = op.def(0);
      builder.creates(BrOp, unit, [cond], attrs=[Target(ifso), Else(_else)]);

      // Erase the `if` itself.
      op.erase();
      return true;
    }
  }
  return false;
}

///|
/// Flattens a single while at a time, as it's easier to get track of.
/// 
fn flattenWhile(func: Op) -> Bool {
  let builder = Builder::new();
  let region = func.region();
  for bb in region {
    for op in bb.ops() {
      if (!isa[WhileOp](op)) {
        continue;
      }

      let preheader = op.parent();
      let exit = preheader.split(op);
      
      // Create an empty block as header.
      // Move the while's body between header and exit.
      let header = region.insertAfter(preheader);
      let body = region.insertAfter(header);
      let ops = op.regions[1].block().ops();
      for op in ops {
        op.moveToEnd(body);
      }

      // The condition must be checked by `bb`.
      builder.setToBlockEnd(header);
      let ops = op.regions[0].block().ops();
      for op in ops {
        op.moveToEnd(header);
      }
      let term = ops.back();
      guard isa[ProceedOp](term) else { die("\{term}: proceed") }
      builder.creates(BrOp, unit, [term.def(0)], attrs=[Target(body), Else(exit)]);

      // The loop jumps back to header.
      builder.setToBlockEnd(body);
      builder.creates(GotoOp, unit, [], attrs=[Target(header)]);

      // The preheader jumps to header.
      builder.setToBlockEnd(preheader);
      builder.creates(GotoOp, unit, [], attrs=[Target(header)]);

      // Erase the while itself.
      op.erase();
      return true;
    }
  }
  return false;
}

pub fn Flatten::runImpl(func: Op) -> Unit {
  let mut changed = true;
  while (changed) {
    changed = false;
    changed = flattenIf(func) || changed;
    changed = flattenWhile(func) || changed;
  }

  // Use `goto` to connect fall-through blocks together.
  let region = func.region();
  let builder = Builder::new();
  for x in region {
    if x.ops.length() == 0 || !x.getLastOp().isAny([GotoOp, BrOp, ReturnOp]) {
      builder.setToBlockEnd(x);
      if x.atBack() {
        builder.creates(ReturnOp, unit, []);
        break;
      }
      let next = x.next();
      builder.creates(GotoOp, unit, [], attrs=[Target(next)]);
    }
  }
}

pub fn Flatten::run(self: Flatten) -> Unit {
  for func in self.funcs() {
    Flatten::runImpl(func);
  }
}
