fn flatten_if(func: Op) -> Bool {
  let builder = Builder::new();
  let region = func.region();
  for bb in region {
    let ops = bb.ops();
    for op in ops {
      if (!op.isa(If)) {
        continue;
      }
      // Non-unit `if`s should have been preprocessed.
      guard op.ty == unit;

      let parent = op.parent();
      let exit = parent.split(op);

      // Create an block for body.
      let ifso = region.insert(exit);
      let ops = op.block().ops();
      for op in ops {
        op.move_to_end(ifso);
      }
      // The block should jump to exit.
      builder.set_to_end(ifso);
      builder.creates(Goto, unit, [], attrs=[Target(exit)]);

      // There is an else region.
      let mut _else = exit;
      if (op.regions.length() == 2) {
        let ifnot = region.insert(exit);
        let ops = op.regions[1].block().ops();
        for op in ops {
          op.move_to_end(ifnot);
        }
        // The block should jump to exit.
        builder.set_to_end(ifnot);
        builder.creates(Goto, unit, [], attrs=[Target(exit)]);
        _else = ifnot;
      }

      // Create a branch at `parent`.
      builder.set_to_end(parent);
      builder.creates(Br, unit, [], attrs=[Target(ifso), Else(_else)]);

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
fn flatten_while(func: Op) -> Bool {
  let builder = Builder::new();
  let region = func.region();
  for bb in region {
    let ops = bb.ops();
    for op in ops {
      if (!op.isa(While)) {
        continue;
      }

      let header = op.parent();
      let exit = header.split(op);
      
      // Move the while's body between header and exit.
      let body = region.insert_after(header);
      let ops = op.block().ops();
      for op in ops {
        op.move_to_end(body);
      }

      // The condition must be checked by `bb`.
      builder.set_to_end(header);
      builder.creates(Br, unit, [], attrs=[Target(body), Else(exit)]);

      // The loop jumps back to header.
      builder.set_to_end(body);
      builder.creates(Goto, unit, [], attrs=[Target(header)]);

      // Erase the while itself.
      op.erase();
      return true;
    }
  }
  return false;
}

pub fn Flatten::run_fn(func: Op) -> Unit {
  let mut changed = true;
  while (changed) {
    changed = false;
    changed = changed || flatten_if(func);
    changed = changed || flatten_while(func);
  }

  // Use `goto` to connect fall-through blocks together.
  let region = func.region();
  let builder = Builder::new();
  for x in region {
    if x.ops.length() == 0 || !x.back().is_any([Goto, Br, Return]) {
      builder.set_to_end(x);
      if x.at_back() {
        builder.creates(Return, unit, []);
        break;
      }
      let next = x.next();
      builder.creates(Goto, unit, [], attrs=[Target(next)]);
    }
  }
}

pub fn Flatten::run(self: Flatten) -> Unit {
  for func in self.funcs() {
    Flatten::run_fn(func);
  }
}
