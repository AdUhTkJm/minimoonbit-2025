let spillReg: Int = s10;
let spillReg2: Int = s11;
let fspillReg: Int = fs10;
let fspillReg2: Int = fs11;

let leafOrder: Array[Int] = [
  a0, a1, a2, a3,
  a4, a5, a6, a7,

  t0, t1, t2, t3,
  t4, t5, t6,
  
  s0, s1, s2, s3, 
  s4, s5, s6, s7,
  s8, s9,
];

let normalOrder: Array[Int] = [
  a0, a1, a2, a3,
  a4, a5, a6, a7,
  ra,

  t0, t1, t2, t3,
  t4, t5, t6,

  s0, s1, s2, s3, 
  s4, s5, s6, s7,
  s8, s9,
];

let argRegs: Array[Int] = [
  a0, a1, a2, a3,
  a4, a5, a6, a7,
];

let callerSaved: Set[Int] = [
  t0, t1, t2, t3,
  t4, t5, t6,

  a0, a1, a2, a3,
  a4, a5, a6, a7,
  ra,

  ft0, ft1, ft2, ft3,
  ft4, ft5, ft6, ft7,
  ft8, ft9, ft10, ft11,

  fa0, fa1, fa2, fa3,
  fa4, fa5, fa6, fa7,
] |> Set::from_array;

let calleeSaved: Set[Int] = [
  s0, s1, s2, s3, 
  s4, s5, s6, s7,
  s8, s9, s10, s11,

  fs0, fs1, fs2, fs3, 
  fs4, fs5, fs6, fs7,
  fs8, fs9, fs10, fs11,
] |> Set::from_array;

let leafRegCnt = 25;
let normalRegCnt = 26;

let leafOrderf: Array[Int] = [
  fa0, fa1, fa2, fa3,
  fa4, fa5, fa6, fa7,

  ft0, ft1, ft2, ft3,
  ft4, ft5, ft6, ft7,
  ft8, ft9, ft10, ft11,
  
  fs0, fs1, fs2, fs3, 
  fs4, fs5, fs6, fs7,
  fs8, fs9,
];

// Order for non-leaf functions.
let normalOrderf: Array[Int] = [
  ft0, ft1, ft2, ft3,
  ft4, ft5, ft6, ft7,
  ft8, ft9, ft10, ft11,

  fa0, fa1, fa2, fa3,
  fa4, fa5, fa6, fa7,

  fs0, fs1, fs2, fs3, 
  fs4, fs5, fs6, fs7,
  fs8, fs9,
];

let fargRegs: Array[Int] = [
  fa0, fa1, fa2, fa3,
  fa4, fa5, fa6, fa7,
];

let leafRegCntf = 30;
let normalRegCntf = 30;

fn fpreg(ty: Type) -> Bool {
  return ty == f64;
}

fn isFP(reg: Int) -> Bool {
  return reg >= 32;
}

priv struct Event {
  timestamp: Int
  start: Bool
  op: Op
}

impl Eq for Event with op_equal(a, b) {
  return a.timestamp == b.timestamp && a.start == b.start;
}

impl Compare for Event with compare(a, b) {
  fn lt(a: Event, b: Event) -> Bool {
    if (a.timestamp == b.timestamp) {
      !a.start && b.start
    } else {
      a.timestamp < b.timestamp
    }
  }
  if (lt(a, b)) {
    return -1;
  }
  if (lt(b, a)) {
    return 1;
  }
  return 0;
}

fn hasRd(x: Op) -> Bool {
  return !x.isAny([JOp, BeqOp, BgeOp, BltOp, BneOp, BgtOp, BleOp, WriteRegOp, CallOp, SwOp, SdOp, FsdOp, RetOp])
}

pub fn Regalloc::run(self: Regalloc) -> Unit {
  let funcs = self.funcs();
  let leaves: Set[Op] = Set::new();

  for func in funcs {
    let isLeaf = func.findAll(CallOp).is_empty();
    if (isLeaf) {
      leaves.add(func);
    }
    self.runImpl(func.region(), isLeaf);
  }

  for func in funcs {
    let set = self.usedRegisters[func];
    for bb in func.region() {
      for op in bb {
        if (op.hasRd()) {
          set.add(op.getRd());
        }
        if (op.hasRs()) {
          set.add(op.getRs());
        }
        if (op.hasRs2()) {
          set.add(op.getRs2());
        }
      }
    }
  }

  for func in funcs {
    self.proEpilogue(func, leaves.contains(func));
    self.tidyup(func.region());
  }
}

pub fn Regalloc::runImpl(self: Regalloc, region: Region, isLeaf: Bool) -> Unit {
  let order = if (isLeaf) { leafOrder } else { normalOrder };
  let orderf = if (isLeaf) { leafOrderf } else { normalOrderf };
  let regcount = if (isLeaf) { leafRegCnt } else { normalRegCnt };
  let regcountf = if (isLeaf) { leafRegCntf } else { normalRegCntf };

  let builder = Builder::new();
  let funcOp = region.getParent();
  let assignment: Map[Op, Int] = Map::new();

  // First of all, add 35 precolored placeholders before each call.
  // This denotes that a CallOp clobbers those registers.
  let all = funcOp.findAll(CallOp);
  for op in all {
    // Make sure arguments don't conflict.
    let writes = [];
    for runner = op.prevOp(); runner.valid() && isa[WriteRegOp](runner); runner = runner.prevOp() {
      writes.push(runner);
    }

    // `writes` are in backward order.
    // We need to add a placeholder for everything after this writereg in the vector.
    for i in 0..<(writes.length() - 1) {
      builder.setBeforeOp(writes[i]);
      for j in (i + 1)..<writes.length() {
        let reg = writes[j].getReg();
        let placeholder = builder.create(PlaceholderOp, unit, []);
        assignment[placeholder] = reg;
        if (isFP(reg)) {
          placeholder.ty = f64;
        }
      }
    }

    builder.setBeforeOp(op);
    for reg in callerSaved {
      let placeholder = builder.create(PlaceholderOp, unit, []);
      assignment[placeholder] = reg;
      if (isFP(reg)) {
        placeholder.ty = f64;
      }
    }
  }

  // Similarly, add placeholders around each GetArg.
  // First create placeholders for a0-a7.
  builder.setToRegionStart(region);
  let argHolders = [];
  let fargHolders = [];
  let argcnt = funcOp.getArgCount();
  for i in 0..<@cmp.minimum(8, argcnt) {
    let placeholder = builder.create(PlaceholderOp, unit, []);
    assignment[placeholder] = argRegs[i];
    argHolders.push(placeholder);

    let fplaceholder = builder.create(PlaceholderOp, unit, []);
    assignment[fplaceholder] = fargRegs[i];
    fargHolders.push(fplaceholder);
  }

  let rawGets = funcOp.findAll(GetArgOp);
  // We might find some getArgs missing by DCE, so it's not necessarily consecutive.
  let getArgs = Array::make(argcnt, Op::default());
  for x in rawGets {
    getArgs[x.getInt()] = x;
  }

  let mut fcnt = 0;
  let mut cnt = 0;
  let entry = region.block();
  for i in 0..<getArgs.length() {
    // A missing argument.
    if (!getArgs[i].valid()) {
      continue;
    }

    let op = getArgs[i];
    let ty = op.ty;

    // It is necessary to put those GetArgs to the front.
    if (fpreg(ty) && fcnt < 8) {
      op.moveToStart(entry);
      builder.setBeforeOp(op);
      builder.creates(PlaceholderOp, unit, [ fargHolders[fcnt] ]);
      builder.replace(op, ReadRegOp, f64, [], attrs=[Reg(fargRegs[fcnt])]);
      fcnt += 1;
      continue;
    }
    if (!fpreg(ty) && cnt < 8) {
      op.moveToStart(entry);
      builder.setBeforeOp(op);
      builder.creates(PlaceholderOp, unit, [ fargHolders[fcnt] ]);
      builder.replace(op, ReadRegOp, i32, [], attrs=[Reg(argRegs[fcnt])]);
      cnt += 1;
      continue;
    }
    // Spilled to stack; don't do anything.
  }

  region.updateLiveness();

  // Interference graph.
  let interf: Map[Op, Set[Op]] = Map::new();
  let spillInterf: Map[Op, Set[Op]] = Map::new();

  // Values of readreg, or operands of writereg, or phis (mvs), are prioritzed.
  let priority: Map[Op, Int] = Map::new();
  // The `key` is preferred to have the same value as `value`.
  let prefer: Map[Op, Op] = Map::new();
  // Maps a phi to its operands.
  let phiOperand: Map[Op, Array[Op]] = Map::new();

  let mut currentPriority = 2;
  for bb in region {
    // Scan through the block and see the place where the value's last used.
    let lastUsed: Map[Op, Int] = Map::new();
    let defined: Map[Op, Int] = Map::new();
    let ops = bb.ops;
    let mut it = ops.end;
    for i = ops.size() - 1; i >= 0; i = i - 1 {
      it = it.prev();
      let op = it.v();
      for v in op.getOperands() {
        if (!lastUsed.contains(v)) {
          lastUsed[v] = i;
        }
      }
      defined[op] = i;

      // Even though the op is not used, it still lives in the instruction that defines it.
      // Actually this should be eliminated with DCE, but we need to take care of it.
      if (!lastUsed.contains(op)) {
        lastUsed[op] = i + 1;
      }

      // Precolor.
      if (isa[WriteRegOp](op)) {
        assignment[op] = op.getReg();
        priority[op] = 1;
      }
      if (isa[ReadRegOp](op)) {
        priority[op] = 1;
      }
      
      if (isa[LiOp](op) && (op.getInt() <= 2047 && op.getInt() >= -2048)) {
        priority[op] = -2;
      }

      if (isa[PhiOp](op)) {
        priority[op] = currentPriority + 1;
        for x in op.getOperands() {
          priority[x] = currentPriority;
          prefer[x] = op;
          phiOperand[op].push(x);
        }
        currentPriority += 2;
      }
    }

    // For all liveOuts, they are last-used at place size().
    // If they aren't defined in this block, then `defined[op]` will be zero, which is intended.
    for op in bb.liveout {
      lastUsed[op] = ops.size();
    }

    // We use event-driven approach to optimize it into O(n log n + E).
    let events: Array[Event] = [];
    for op, v in lastUsed {
      // Don't push empty live range. It's not handled properly.
      if (defined[op] == v) {
        continue;
      }
      
      events.push(Event :: { timestamp: defined[op], start: true, op });
      events.push(Event :: { timestamp: v, start: false, op });
    }

    // Sort with ascending time (i.e. instruction contains).
    events.sort();

    let active: Set[Op] = Set::new();
    for event in events {
      let op = event.op;
      // Jumps will never interfere.
      if (isa[JOp](op)) {
        continue;
      }

      if (event.start) {
        for activeOp in active {
          // FP and int are using different registers.
          // However, they are using the same stack,
          // so that must be taken into accontains when spilling.
          if ((fpreg(activeOp.ty) && !fpreg(op.ty)) || (!fpreg(activeOp.ty) && fpreg(op.ty))) {
            spillInterf[op].add(activeOp);
            spillInterf[activeOp].add(op);
            continue;
          }

          interf[op].add(activeOp);
          interf[activeOp].add(op);
        }
        active.add(op);
      } else {
        active.remove(op);
      }
    }
  }

  let ops: Array[Op] = [];
  for k, v in interf {
    ops.push(k);
  }

  // Even though registers in `priority` might not be colliding,
  // we still allocate them here to respect their preference.
  for k, v in priority {
    ops.push(k);
  }

  // Sort by **descending** degree.
  ops.sort_by((a, b) => {
    fn lt(a: Op, b: Op) {
      let pa = priority[a];
      let pb = priority[b];
      return if (pa == pb) { interf[a].size() > interf[b].size() } else { pa > pb };
    }
    if (lt(a, b)) {
      return -1;
    }
    if (lt(b, a)) {
      return 1;
    }
    return 0;
  });

  let spillOffset: Map[Op, Int] = Map::new();
  let currentOffset = funcOp.getStackOffset();
  let mut highest = 0;

  for op in ops {
    // Do not allocate colored instructions.
    if (assignment.contains(op)) {
      continue;
    }

    let bad: Set[Int] = Set::new();
    let unpreferred: Set[Int] = Set::new();

    for v in interf[op] {
      // In the whole function, `sp` and `zero` are read-only.
      if (assignment.contains(v) && assignment[v] != sp && assignment[v] != zero) {
        bad.add(assignment[v]);
      }
    }

    if (isa[PhiOp](op)) {
      // Dislike everything that might interfere with phi's operands.
      let operands = phiOperand[op];
      for x in operands {
        for v in interf[x] {
          if (assignment.contains(v) && assignment[v] != sp && assignment[v] != zero) {
            unpreferred.add(assignment[v]);
          }
        }
      }
    }

    if (prefer.contains(op)) {
      let ref = prefer[op];
      // Try to allocate the same register as `ref`.
      if (assignment.contains(ref) && !bad.contains(assignment[ref])) {
        assignment[op] = assignment[ref];
        continue;
      }
    }

    // See if there's any preferred registers.
    let mut preferred = -1;
    for use in op.uses {
      if (isa[WriteRegOp](use)) {
        let reg = use.getReg();
        if (!bad.contains(reg)) {
          preferred = reg;
          break;
        }
      }
    }
    if (isa[ReadRegOp](op)) {
      let reg = op.getReg();
      if (!bad.contains(reg)) {
        preferred = reg;
      }
    }

    if (preferred != -1) {
      assignment[op] = preferred;
      continue;
    }

    let rcnt = if (!fpreg(op.ty)) { regcount } else { regcountf };
    let rorder = if (!fpreg(op.ty)) { order } else { orderf };

    for i in 0..<rcnt {
      if (!bad.contains(rorder[i]) && !unpreferred.contains(rorder[i])) {
        assignment[op] = rorder[i];
        break;
      }
    }

    // We have excluded too much. Try it again.
    if (!assignment.contains(op) && unpreferred.size() != 0) {
      for i in 0..<rcnt {
        if (!bad.contains(rorder[i])) {
          assignment[op] = rorder[i];
          break;
        }
      }
    }

    if (assignment.contains(op)) {
      continue;
    }

    // Spilled. Try to see all spill offsets of conflicting ops.
    let mut desired = currentOffset;
    let conflict: Set[Int] = Set::new();

    // Consider both `interf` (of the same register type)
    // and `spillInterf` (of different register type).
    for v in interf[op] {
      if (!spillOffset.contains(v)) {
        continue;
      }

      conflict.add(spillOffset[v]);
    }
    for v in spillInterf[op] {
      if (!spillOffset.contains(v)) {
        continue;
      }

      conflict.add(spillOffset[v]);
    }

    // Try find a space.
    while (conflict.contains(desired)) {
      desired += 8;
    }

    spillOffset[op] = desired;

    // Update `highest`, which will indicate the size allocated.
    if (desired > highest) {
      highest = desired;
    }
  }

  // Only a single register is spilled. Let's use s10.
  if (highest == currentOffset) {
    for op, _ in spillOffset {
      assignment[op] = if (fpreg(op.ty)) { fspillReg } else { spillReg; }
    }
    spillOffset.clear();
  }

  // Only 2 registers are spilled. Let's use s10 and s11.
  if (highest == currentOffset + 8) {
    for op, offset in spillOffset {
      let fp = fpreg(op.ty);
      assignment[op] = if (offset != 0) {
        if (fp) { fspillReg2 } else { spillReg2 }
      } else {
        if (fp) { fspillReg } else { spillReg }
      }
    }
    spillOffset.clear();
  }

  // If possible, map some offsets to floating-point registers.
  if (spillOffset.size() != 0) {
    // Try to reuse floating-point registers for spilling.
    let used: Set[Int] = Set::new();
    for op, x in assignment {
      if (isa[PlaceholderOp](op)) {
        continue;
      }
      used.add(x);
    }

    let fpmv: Map[Int, Int] = Map::new();
    let off = funcOp.getStackOffset();
    for reg in leafOrderf {
      if (highest <= off) {
        break;
      }
      if (used.contains(reg) || (!isLeaf && !calleeSaved.contains(reg))) {
        continue;
      }

      fpmv[highest] = reg;
      highest -= 8;
    }

    for k, offset in spillOffset {
      if (fpmv.contains(offset)) {
        spillOffset[k] = -fpmv[offset];
      }
    }
  }

  // Allocate more stack space for it.
  if (spillOffset.size() != 0) {
    funcOp.removeStackOffset();
    funcOp.add(StackOffset(highest + 8));
  }

  fn getReg(op: Op) -> Int {
    if (assignment.contains(op)) {
      return assignment[op];
    } else if (fpreg(op.ty)) {
      return orderf[0];
    } else {
      return order[0];
    }
  };

  fn lowerBinary(kind: OpKind) -> Unit {
    let all = funcOp.findAll(kind);
    for op in all {
      if (op.getOperandCount() == 0) {
        continue;
      }
      let v0 = op.def(0);
      if (!spillOffset.contains(v0)) {
        op.add(Rs(getReg(v0)));
      } else {
        op.add(SpilledRs(fpreg(v0.ty), spillOffset[v0], v0));
      }
      let v1 = op.def(0);
      if (!spillOffset.contains(v1)) {
        op.add(Rs2(getReg(v1)));
      } else {
        op.add(SpilledRs2(fpreg(v1.ty), spillOffset[v1], v1));
      }
      op.removeAllOperands();
    }
  }

  fn lowerUnary(kind: OpKind) -> Unit {
    let all = funcOp.findAll(kind);
    for op in all {
      if (op.getOperandCount() == 0) {
        continue;
      }
      let v0 = op.def(0);
      if (!spillOffset.contains(v0)) {
        op.add(Rs(getReg(v0)));
      } else {
        op.add(SpilledRs(fpreg(op.ty), spillOffset[op], op));
      }
      op.removeAllOperands();
    }
  }

  // Convert all operands to registers.
  lowerBinary(AddOp);
  lowerBinary(AddwOp);
  lowerBinary(SubOp);
  lowerBinary(SubwOp);
  lowerBinary(MulwOp);
  lowerBinary(MulhOp);
  lowerBinary(MulhuOp);
  lowerBinary(MulOp);
  lowerBinary(DivwOp);
  lowerBinary(DivOp);
  lowerBinary(RemwOp);
  lowerBinary(RemOp);
  lowerBinary(BneOp);
  lowerBinary(BeqOp);
  lowerBinary(BltOp);
  lowerBinary(BgeOp);
  lowerBinary(BleOp);
  lowerBinary(BgtOp);
  lowerBinary(SwOp);
  lowerBinary(SdOp);
  lowerBinary(FsdOp);
  lowerBinary(AndOp);
  lowerBinary(OrOp);
  lowerBinary(XorOp);
  lowerBinary(SltOp);
  lowerBinary(FaddOp);
  lowerBinary(FsubOp);
  lowerBinary(FmulOp);
  lowerBinary(FdivOp);
  lowerBinary(FeqOp);
  lowerBinary(FltOp);
  lowerBinary(FleOp);
  lowerBinary(SllwOp);
  lowerBinary(SrlwOp);
  lowerBinary(SrawOp);
  lowerBinary(SraOp);
  lowerBinary(SllOp);
  lowerBinary(SrlOp);
  
  lowerUnary(LdOp);
  lowerUnary(LwOp);
  lowerUnary(FldOp);
  lowerUnary(AddiwOp);
  lowerUnary(AddiOp);
  lowerUnary(SlliwOp);
  lowerUnary(SrliwOp);
  lowerUnary(SraiwOp);
  lowerUnary(SraiOp);
  lowerUnary(SlliOp);
  lowerUnary(SrliOp);
  lowerUnary(SeqzOp);
  lowerUnary(SnezOp);
  lowerUnary(SltiOp);
  lowerUnary(AndiOp);
  lowerUnary(OriOp);
  lowerUnary(XoriOp);
  lowerUnary(FcvtsdOp);
  lowerUnary(FcvtdsRtzOp);
  lowerUnary(FmvdxOp);

  // Note that some ops are dealt with later.
  // We can't remove all operands here.
  for bb in region {
    for op in bb {
      if (isa[PlaceholderOp](op) || isa[CallOp](op) || isa[RetOp](op)) {
        op.removeAllOperands();
      }
    }
  }

  // Remove placeholders added previously.
  // We cannot directly remove that, otherwise `new`s might reuse the memory,
  // so that a newly constructed op might accidentally fall in `spillOffset`;
  // this means all ops must be removed at the end of the function.
  let holders = funcOp.findAll(PlaceholderOp);
  for holder in holders {
    holder.erase();
  }

  fn create_mv(fp: Bool, rd: Int, rs: Int) -> Op {
    if (!fp) {
      builder.create(MvOp, unit, [], attrs=[ Rd(rd), Rs(rs) ]);
    } else {
      builder.create(FmvOp, unit, [], attrs=[ Rd(rd), Rs(rs) ]);
    }
  }

  fn creates_mv(fp: Bool, rd: Int, rs: Int) -> Unit {
    create_mv(fp, rd, rs) |> ignore;
  }

  //   writereg %1, <reg = a0>
  // becomes
  //   mv a0, assignment[%1]
  // As RdAttr is supplied, though `assignment[]` won't have the new op recorded, it's fine.
  let all = funcOp.findAll(WriteRegOp);
  for op in all {
    builder.setBeforeOp(op);
    creates_mv(isFP(op.getReg()), op.getReg(), getReg(op.def(0)));
    let mv = op.prevOp();

    if (spillOffset.contains(op.def(0))) {
      mv.removeRs();
      let v = op.def(0);
      mv.add(SpilledRs(fpreg(v.ty), spillOffset[v], v));
    }

    op.erase();
  };

  //   readreg %1, <reg = a0>
  // becomes
  //   mv assignment[%1], a0
  let all = funcOp.findAll(ReadRegOp);
  for op in all {
    builder.setBeforeOp(op);
    creates_mv(isFP(op.getReg()), getReg(op), op.getReg());
    let mv = op.prevOp();
    assignment[mv] = getReg(op);

    if (spillOffset.contains(op)) {
      mv.removeRd();
      mv.add(SpilledRd(fpreg(op.ty), spillOffset[op], op));
      spillOffset[mv] = spillOffset[op];
    }

    // We can't directly remove it because it might get used by phi's later.
    op.replaceAllUsesWith(mv);
    op.erase();
  };

  // Finally, after everything has been erased:
  // Destruct phi.

  // This contains all phis to be erased.
  let allPhis: Array[Op] = [];
  let bbs = region.bbs.to_array();

  // Split edges.
  for bb in bbs {
    // If a block has multiple successors with phi, then we split the edges. As an example:
    // 
    // bb0:
    //   %0 = ...
    //   %1 = ...
    //   br %1 [bb1] [bb2]
    // bb1:
    //   phi %2, %0, ...
    // bb2:
    //   phi %3, %0, ...
    //
    // If we naively create a move at the end of bb0, then it's wrong.
    // We need to rewrite it into
    //
    // bb0:
    //   br %1 [bb3] [bb4]
    // bb3:
    //   j bb1
    // bb4:
    //   j bb2
    // ...
    //
    // To actually make it work.
    if (bb.succs.size() <= 1) {
      continue;
    }

    // Note that we need to split even if there's no phi in one of the blocks.
    // This is because the registers of branch operation can be clobbered if that's not done.
    // Consider:
    //   b %1, [bb1], [bb2]
    // bb1:
    //   %3 = phi ...
    // It is entirely possible for %3 to have the same register as %1.
    
    let edge1 = region.insertAfter(bb);
    let edge2 = region.insertAfter(bb);
    let bbTerm = bb.getLastOp();

    // Create edge for target branch.
    let target = bbTerm.getTarget();
    bbTerm.removeTarget();
    bbTerm.add(Target(edge1));

    builder.setToBlockEnd(edge1);
    builder.creates(JOp, unit, [], attrs=[ Target(target) ]);

    // Create edge for else branch.
    let ifnot = bbTerm.getElse();
    bbTerm.removeElse();
    bbTerm.add(Else(edge2));

    builder.setToBlockEnd(edge2);
    builder.creates(JOp, unit, [], attrs=[ Target(ifnot) ]);

    // Rename the blocks of the phis.
    for succ in bb.succs {
      for phi in succ.getPhis() {
        let bbs = [];
        for fromBB in phi.getFrom() {
          if (fromBB != bb) {
            continue;
          }
          let mut bb = fromBB;
          if (succ == target) {
            bb = edge1;
          }
          if (succ == ifnot) {
            bb = edge2;
          }
          bbs.push(bb);
        }
        phi.removeFrom();
        phi.add(From(bbs));
      }
    }
  }

  // Detect circular copies and calculate a correct order.
  let moveMap: Map[Block, Array[(Int, Int)]] = Map::new();
  let revMap: Map[Block, Map[(Int, Int), Op]] = Map::new();

  for bb in bbs {
    let phis = bb.getPhis();
    let moves: Array[Op] = [];

    for phi in phis {
      let ops = phi.getOperands();
      let bbs = phi.getFrom();
      for i in 0..<ops.length() {
        let bb = bbs[i];
        let term = bb.getLastOp();
        builder.setBeforeOp(term);
        let def = ops[i];
        let mv = if (fpreg(phi.ty)) {
          builder.create(FmvOp, unit, [], attrs=[
            if (spillOffset.contains(phi)) { SpilledRd(fpreg(phi.ty), spillOffset[phi], phi) } else { Rd(getReg(phi)) },
            if (spillOffset.contains(def)) { SpilledRs(fpreg(def.ty), spillOffset[def], def) } else { Rs(getReg(def)) },
          ]);
        } else {
          builder.create(MvOp, unit, [], attrs=[
            if (spillOffset.contains(phi)) { SpilledRd(fpreg(phi.ty), spillOffset[phi], phi) } else { Rd(getReg(phi)) },
            if (spillOffset.contains(def)) { SpilledRs(fpreg(def.ty), spillOffset[def], def) } else { Rs(getReg(def)) },
          ]);
        }
        moves.push(mv);
      }
    }

    allPhis.append(phis);

    for mv in moves {      
      let dst = if (mv.hasRd()) { mv.getRd() } else { -mv.getSpilledRd().1 - 1000 };
      let src = if (mv.hasRs()) { mv.getRs() } else { -mv.getSpilledRs().1 - 1000 };
      if (src == dst) {
        mv.erase();
        continue;
      }

      let parent = mv.parent();
      moveMap[parent].push((dst, src));
      revMap[parent][(dst, src)] = mv;
    }
  }

  for bb, mvs in moveMap {
    let moveGraph: Map[Int, Int] = Map::new();
    for elem in mvs {
      let (dst, src) = elem;
      moveGraph[dst] = src;
    }

    // Detect cycles.
    let visited: Set[Int] = Set::new();
    let visiting: Set[Int] = Set::new();
    let mut sorted: Array[(Int, Int)] = [];
    let headers: Array[Int] = [];
    let members: Map[Int, Array[Int]] = Map::new();
    let inCycle: Set[Int] = Set::new();

    // Do a topological sort; it will decide whether there's a cycle.
    fn dfs(node: Int) {
      visiting.add(node);
      let src = moveGraph[node];

      if (visiting.contains(src)) {
        // A node is visited twice. Here's a cycle.
        headers.push(node);
      } else if (!visited.contains(src) && moveGraph.contains(src)) {
        dfs(src);
      }
    
      visiting.remove(node);
      visited.add(node);
      sorted.push((node, src));
    };

    for elem in mvs {
      let (dst, src) = elem;
      if (!visited.contains(dst)) {
        dfs(dst);
      }
    }

    sorted = sorted.rev();

    // Fill in record of cycles.
    for header in headers {
      let mut runner: Int = header;
      members[header].push(runner);
      runner = moveGraph[runner];
      while (runner != header) {
        members[header].push(runner);
        runner = moveGraph[runner];
      }

      for member in members[header] {
        inCycle.add(member);
      }
    }

    // Move sorted phis so that they're in the correct order.
    let term = bb.getLastOp();
    let emitted: Set[Int] = Set::new();

    for elem in sorted {
      let (dst, src) = elem;
      if (dst == src || emitted.contains(dst) || inCycle.contains(dst)) {
        continue;
      }

      revMap[bb][(dst, src)].moveBefore(term);
      emitted.add(dst);
    }

    if (members.size() == 0) {
      continue;
    }

    for header in headers {
      let cycle = members[header];

      // Move the header's value to temp.
      let headerSrc = moveGraph[header];
      let mv = revMap[bb][(header, headerSrc)];
      let fp = isFP(header);
      let tmp = if (fp) { fspillReg2 } else { spillReg2 }
      mv.removeRd();
      mv.add(Rd(tmp));
      mv.moveBefore(term);

      // For the rest of the cycle, perform the moves in order.
      let mut curr = headerSrc;
      while (curr != header) {
        let nextSrc = moveGraph[curr];
        revMap[bb][(curr, nextSrc)].moveBefore(term);
        curr = nextSrc;
      }

      // Move from temp into the header.
      builder.setBeforeOp(term);
      creates_mv(fp, header, tmp);
    }
  }

  // erase all phi's properly. There might be cross-reference across blocks,
  // so we need to erase all operands first.
  for phi in allPhis {
    phi.removeAllOperands();
  }

  for phi in allPhis {
    if (phi.uses.length() != 0) {
      println(self.module);
    }
    
    phi.erase();
  }

  for bb in region {
    for op in bb {
      if (hasRd(op) && !op.hasRd() && !op.hasSpilledRd()) {
        if (!spillOffset.contains(op)) {
          op.add(Rd(getReg(op)));
        } else {
          op.add(SpilledRd(fpreg(op.ty), spillOffset[op], op));
        }
      }
    }
  }

  // Deal with spilled variables.
  let remove: Array[Op] = [];
  for bb in region {
    let mut delta = 0;
    for op in bb {
      // We might encontainser spilling around calls.
      // For example:
      //   addi sp, sp, -192    ; setting up 24 extra arguments
      //   mv a0, ...
      //   ld s11, OFFSET(sp)   ; !!! ADJUST HERE
      //
      // That's why we need an extra "delta".
      // No need for dominance analysis etc. because the SubSp is well-bracketed inside a block.
      if (isa[SubSpOp](op)) {
        delta += op.getInt();
        continue;
      }

      if (op.hasSpilledRd()) {
        let rd = op.getSpilledRd();
        // We will rematerialize them later.
        if (isa[LiOp](rd.2) || isa[LaOp](rd.2)) {
          remove.push(op);
          continue;
        }

        let offset = delta + rd.1;
        let fp = rd.0;
        let reg = if (fp) { fspillReg } else { spillReg; }

        builder.setAfterOp(op);
        let kind: OpKind = if (fp) { FsdOp } else if (op.ty == i32) { SwOp } else { SdOp }
        if (offset < delta) {
          builder.creates(FmvdxOp, unit, [], attrs=[Rd(delta - offset), Rs(reg)]);
        } else if (offset < 2048) {
          builder.creates(kind, unit, [], attrs=[Rs(reg), Rs2(sp), Int(offset)]);
        } else if (offset < 4096) {
          builder.creates(AddiOp, unit, [], attrs=[Rd(spillReg2), Rs(sp), Int(2047)]);
          builder.creates(kind, unit, [], attrs=[Rs(reg), Rs2(spillReg2), Int(offset - 2047)]);
        } else {
          die("> 4096");
        }
        op.add(Rd(reg));
      }

      if (op.hasSpilledRs()) {
        let rs = op.getSpilledRs();
        let offset = delta + rs.1;
        let fp = rs.0;
        let reg = if (fp) { fspillReg } else { spillReg };
        let kind: OpKind = if (fp) { FldOp } else if (op.ty == i32) { LwOp } else { LdOp }

        builder.setBeforeOp(op);
        // Rematerialized.
        let ref = rs.2;
        if (isa[LiOp](ref)) {
          builder.creates(LiOp, unit, [], attrs=[Rd(reg), Int(ref.getInt())]);
        } else if (isa[LaOp](ref)) {
          builder.creates(LaOp, unit, [], attrs=[Rd(reg), Name(ref.getName())]);
        } else if (offset < delta) {
          builder.creates(FmvxdOp, unit, [], attrs=[Rd(reg), Rs(delta - offset)]);
        } else if (offset < 2048) {
          builder.creates(kind, unit, [], attrs=[Rd(reg), Rs(sp), Int(offset)]);
        } else if (offset < 4096) {
          builder.creates(AddiOp, unit, [], attrs=[Rd(spillReg), Rs(sp), Int(2047)]);
          builder.creates(kind, unit, [], attrs=[Rd(reg), Rs(spillReg), Int(offset - 2047)]);
        } else {
          die("> 4096");
        }
        op.add(Rs(reg));
      }

      if (op.hasSpilledRs2()) {
        let rs = op.getSpilledRs2();
        let offset = delta + rs.1;
        let fp = rs.0;
        let reg = if (fp) { fspillReg2 } else { spillReg2 };
        let kind: OpKind = if (fp) { FldOp } else if (op.ty == i32) { LwOp } else { LdOp }

        builder.setBeforeOp(op);
        // Rematerialized.
        let ref = rs.2;
        if (isa[LiOp](ref)) {
          builder.creates(LiOp, unit, [], attrs=[Rd(reg), Int(ref.getInt())]);
        } else if (isa[LaOp](ref)) {
          builder.creates(LaOp, unit, [], attrs=[Rd(reg), Name(ref.getName())]);
        } else if (offset < delta) {
          builder.creates(FmvxdOp, unit, [], attrs=[Rd(reg), Rs(delta - offset)]);
        } else if (offset < 2048) {
          builder.creates(kind, unit, [], attrs=[Rd(reg), Rs(sp), Int(offset)]);
        } else if (offset < 4096) {
          builder.creates(AddiOp, unit, [], attrs=[Rd(spillReg2), Rs(sp), Int(2047)]);
          builder.creates(kind, unit, [], attrs=[Rd(reg), Rs(spillReg2), Int(offset - 2047)]);
        } else {
          die("> 4096");
        }
        op.add(Rs2(reg));
      }
    }
  }

  for op in remove {
    op.erase();
  }
}

pub fn Regalloc::latePeephole(funcOp: Op) -> Bool {
  let builder = Builder::new();
  let mut converted = false;

  fn create_mv(fp: Bool, rd: Int, rs: Int) -> Op {
    if (!fp) {
      builder.create(MvOp, unit, [], attrs=[ Rd(rd), Rs(rs) ]);
    } else {
      builder.create(FmvOp, unit, [], attrs=[ Rd(rd), Rs(rs) ]);
    }
  }

  fn creates_mv(fp: Bool, rd: Int, rs: Int) -> Unit {
    create_mv(fp, rd, rs) |> ignore;
  }

  let changes: Array[(OpKind, OpKind)] = [(SwOp, LwOp), (SdOp, LdOp), (FsdOp, FldOp)];
  for elem in changes {
    let (store, load) = elem;
    let all = funcOp.findAll(store);
    for op in all {
      if (op.atBack()) {
        continue;
      }

      //   sw a0, N(addr)
      //   lw a1, N(addr)
      // becomes
      //   sw a0, N(addr)
      //   mv a1, a0
      let next = op.nextOp();
      if (isa[load](next) &&
          next.getRs() == op.getRs2() &&
          next.getInt() == op.getInt()) {
        converted = true;
        builder.setBeforeOp(next);
        creates_mv(isFP(next.getRd()), next.getRd(), op.getRs());
        next.erase();
      }
    };
  }

  let all = funcOp.findAll(FmvdxOp);
  for op in all {
    if (op.atBack()) {
      continue;
    }

    let next = op.nextOp();
    if (isa[FmvxdOp](next) && next.getRs() == op.getRd()) {
      converted = true;
      builder.setBeforeOp(next);
      creates_mv(isFP(next.getRd()), next.getRd(), op.getRs());
      next.erase();
    }
  };

  let mut changed = true;
  let mut stores: Array[Op] = [];
  while (changed) {
    changed = false;
    stores = funcOp.findAll(SwOp);
    for op in stores {
      if (op.atBack()) {
        continue;
      }
      let next = op.nextOp();

      //   sw zero, N(sp)
      //   sw zero, N+4(sp)
      // becomes
      //   sd zero, N(sp)
      // only when N is a multiple of 8.
      //
      // We know `sp` is 16-aligned, but we don't know for other registers.
      // That's why we fold it only for `sp`.
      if (isa[SwOp](next) &&
          op.getRs() == zero && op.getRs2() == sp &&
          next.getRs() == zero && next.getRs2() == sp &&
          op.getInt() % 8 == 0 && next.getInt() == op.getInt() + 4) {
        converted = true;
        changed = true;

        let offset = op.getInt();
        builder.replace(op, SdOp, unit, [], attrs=[Rs(zero), Rs2(sp), Int(offset)]);
        next.erase();
        break;
      }

      // Similarly:
      //   sw zero, N(sp)
      //   sw zero, N-4(sp)
      // becomes
      //   sd zero, N-4(sp)
      // only when N-4 is a multiple of 8.
      if (isa[SwOp](next) &&
          op.getRs() == zero && op.getRs2() == sp &&
          next.getRs() == zero && next.getRs2() == sp &&
          op.getInt() % 8 == 0 && next.getInt() == op.getInt() - 4) {
        converted = true;
        changed = true;

        let offset = op.getInt();
        builder.replace(op, SdOp, unit, [], attrs=[Rs(zero), Rs2(sp), Int(offset - 4)]);
        next.erase();
        break;
      }
    }
  }

  // Eliminate useless MvOp.
  let all = funcOp.findAll(MvOp);
  for op in all {
    if (op.getRd() == op.getRs()) {
      converted = true;
      op.erase();
      continue;
    }

    // mv  a0, a1    <-- op
    // mv  a1, a0    <-- mv2
    // We can delete the second operation, `mv2`.
    if (!op.atBack()) {
      let mv2 = op.nextOp();
      if (isa[MvOp](mv2) && op.getRd() == mv2.getRs() && op.getRs() == mv2.getRd()) {
        // We can't erase `mv2` because it might be explored afterwards.
        // We need to change the content of mv2 and erase this one.
        mv2.removeRd();
        mv2.removeRs();
        mv2.add(Rd(op.getRd()));
        mv2.add(Rs(op.getRs()));
        op.erase();
      }
    }
  };

  let all = funcOp.findAll(FmvOp);
  for op in all {
    if (op.getRd() == op.getRs()) {
      converted = true;
      op.erase();
    }
  };

  return converted;
}

pub fn Regalloc::tidyup(self: Regalloc, region: Region) -> Unit {
  let builder = Builder::new();
  let funcOp = region.parent;
  region.updatePreds();

  // Say the before is `blt`, then we might see
  //   blt %1 %2 <target = bb1> <else = bb2>
  // which means `if (%1 < %2) goto bb1 else goto bb2`.
  //
  // If the next block is just <bb1>, then we flip it to bge, and make the target <bb2>.
  // if the next block is <bb2>, then we make the target <bb2>.
  // otherwise, make the target <bb1>, and add another `j <bb2>`.
  fn replaceBranchImpl(before: OpKind, after: OpKind) -> Unit {
    let all = funcOp.findAll(before);
    for op in all {
      if (!op.hasElse()) {
        continue;
      }
      let target = op.getTarget();
      let ifnot = op.getElse();
      let me = op.parent();
      if (me == me.parent.getLastBlock()) {
        builder.setAfterOp(op);
        builder.creates(JOp, unit, [], attrs=[Target(ifnot)]);
        op.removeElse();
        continue;
      }
      if (me.nextBlock() == target) {
        builder.replace(op, after, unit, [], attrs=[Rs(op.getRs()), Rs2(op.getRs2()), Target(ifnot)]);
        continue;
      }
      if (me.nextBlock() == ifnot) {
        continue;
      }
      builder.setAfterOp(op);
      builder.creates(JOp, unit, [], attrs=[Target(ifnot)]);
      op.removeElse();
    }
  }

  fn replaceBranch(t1: OpKind, t2: OpKind) -> Unit {
    replaceBranchImpl(t1, t2);
    replaceBranchImpl(t2, t1);
  }

  // Replace blocks with only a single `j` as terminator.
  let jumpTo: Map[Block, Block] = Map::new();
  for bb in region {
    if (bb.getOpCount() == 1 && isa[JOp](bb.getLastOp())) {
      let target = bb.getLastOp().getTarget();
      jumpTo[bb] = target;
    }
  }

  // Calculate jump-to closure.
  let mut changed = true;
  while (changed) {
    changed = false;
    for k, v in jumpTo {
      if (jumpTo.contains(v)) {
        jumpTo[k] = jumpTo[v];
        changed = true;
      }
    }
  }

  for bb in region { 
    let term = bb.getLastOp();
    if (term.hasTarget()) {
      let target = term.getTarget();
      if (jumpTo.contains(target)) {
        term.removeTarget();
        term.add(Target(jumpTo[target]));
      }
    }

    if (term.hasElse()) {
      let target = term.getElse();
      if (jumpTo.contains(target)) {
        term.removeElse();
        term.add(Else(jumpTo[target]));
      }
    }
  }

  // Erase all those single-j's.
  region.updatePreds();

  for bb, _ in jumpTo {
    bb.erase();
  }
  
  // After lowering, combine sequential blocks into one.
  // Simpler than simplify-cfg, because no phis could remain now.
  changed = true;
  while (changed) {
    changed = false;
    for bb in region {
      if (bb.succs.size() != 1) {
        continue;
      }

      let succ = bb.succs.to_array()[0];
      if (succ.preds.size() != 1) {
        continue;
      }

      // Remove the jump to `succ`.
      let term = bb.getLastOp();
      if (isa[JOp](term)) {
        term.erase();
      }
      
      // All successors of `succ` now have pred `bb`.
      // `bb` also regard them as successors.
      for s in succ.succs {
        s.preds.remove(succ);
        s.preds.add(bb);
        bb.succs.add(s);
      }
      // Remove `succ` from the successors of `bb`.
      bb.succs.remove(succ);

      // Then move all instruction in `succ` to `bb`.
      let ops = succ.ops.to_array();
      for op in ops {
        op.moveToEnd(bb);
      }

      succ.erase();
      changed = true;
      break;
    }
  }

  // Now branches are still having both TargetAttr and ElseAttr.
  // Replace them (perform split when necessary), so that they only have one target.
  replaceBranch(BltOp, BgeOp);
  replaceBranch(BeqOp, BneOp);
  replaceBranch(BleOp, BgtOp);

  while (Regalloc::latePeephole(funcOp)) { }

  // Also, eliminate useless JOp.
  let all = funcOp.findAll(JOp);
  for op in all {
    let target = op.getTarget();
    let me = op.parent();
    if (me.atBack()) {
      continue;
    }

    if (me.nextBlock() == target) {
      op.erase();
    }
  };
}

fn save(builder: Builder, regs: Array[Int], offset: Int) -> Unit {
  fn create_store(addr: Int, reg: Int, offset: Int) {
    let kind: OpKind = if (isFP(reg)) { FsdOp } else { SdOp }
    builder.creates(FsdOp, unit, [], attrs=[Rs(reg), Rs2(addr), Int(offset)]);
  }

  let mut offset = offset;
  for reg in regs {
    offset -= 8;
    if (offset < 2048) {
      create_store(sp, reg, offset)
    } else {
      builder.creates(LiOp, unit, [], attrs=[Rd(spillReg2), Int(offset)]);
      builder.creates(AddOp, unit, [], attrs=[Rd(spillReg2), Rs(spillReg2), Rs2(sp)]);
      create_store(spillReg2, reg, 0);
    }
  }
}

fn load(builder: Builder, regs: Array[Int], offset: Int) -> Unit {
  fn create_load(addr: Int, reg: Int, offset: Int) {
    let kind: OpKind = if (isFP(reg)) { FldOp } else { LdOp }
    builder.creates(FldOp, unit, [], attrs=[Rd(reg), Rs(addr), Int(offset)]);
  }

  let mut offset = offset;
  for reg in regs {
    offset -= 8;
    if (offset < 2048) {
      create_load(sp, reg, offset)
    } else {
      builder.creates(LiOp, unit, [], attrs=[Rd(spillReg), Int(offset)]);
      builder.creates(AddOp, unit, [], attrs=[Rd(spillReg), Rs(spillReg), Rs2(sp)]);
      create_load(spillReg2, reg, 0);
    }
  }
}

pub fn Regalloc::proEpilogue(self: Regalloc, funcOp: Op, isLeaf: Bool) -> Unit {
  let builder = Builder::new();
  let usedRegs = self.usedRegisters[funcOp];
  let region = funcOp.region();

  // Preserve return address if this calls another function.
  let preserve: Array[Int] = [];
  for x in usedRegs {
    if (calleeSaved.contains(x)) {
      preserve.push(x);
    }
  }
  if (!isLeaf) {
    preserve.push(ra);
  }

  // If there's a SubSpOp, then it must be at the top of the first block.
  let mut offset = funcOp.getStackOffset();
  offset += 8 * preserve.length();

  // Round op to the nearest multiple of 16.
  // This won't be entered in the special case where offset == 0.
  if (offset % 16 != 0) {
    offset = offset / 16 * 16 + 16;
  }

  // Add function prologue, preserving the regs.
  let entry = region.block();
  builder.setToBlockStart(entry);
  if (offset != 0) {
    builder.creates(SubSpOp, unit, [], attrs=[Int(offset)]);
  }

  save(builder, preserve, offset);

  // Similarly add function epilogue.
  if (offset != 0) {
    let rets = funcOp.findAll(RetOp);
    let bb = region.appendBlock();
    for ret in rets {
      builder.replace(ret, JOp, unit, [], attrs=[Target(bb)]);
    }

    builder.setToBlockStart(bb);

    load(builder, preserve, offset);
    builder.creates(SubSpOp, unit, [], attrs=[Int(-offset)]);
    builder.creates(RetOp, unit, []);
  }

  // Caller preserved registers are marked correctly as interfered,
  // because of the placeholders.

  // Deal with remaining GetArg.
  // The arguments passed by registers have already been eliminated.
  // Now all remaining ones are passed on stack; sort them according to index.
  let remainingGets = funcOp.findAll(GetArgOp);
  remainingGets.sort_by((a, b) => Compare::compare(a.getInt(), b.getInt()));
  let argOffsets: Map[Op, Int] = Map::new();
  let mut argOffset = 0;

  for op in remainingGets {
    argOffsets[op] = argOffset;
    argOffset += 8;
  }

  let all = funcOp.findAll(GetArgOp);
  for op in all {
    let myoffset = offset + argOffsets[op];
    builder.setBeforeOp(op);
    builder.replace(op, if (isFP(op.getRd())) { FsdOp } else { SdOp }, unit, [], attrs=[Rd(op.getRd()), Rs(sp), Int(myoffset)]);
  };

  //   subsp <4>
  // becomes
  //   addi <rd = sp> <rs = sp> <-4>
  let all = funcOp.findAll(SubSpOp);
  for op in all {
    let offset = op.getInt();
    if (offset <= 2048 && offset > -2048) {
      builder.replace(op, AddiOp, unit, [], attrs=[Rd(sp), Rs(sp), Int(-offset)]);
    } else {
      builder.setBeforeOp(op);
      builder.creates(LiOp, unit, [], attrs=[Rd(t0), Int(offset)]);
      builder.replace(op, SubOp, unit, [], attrs=[Rd(sp), Rs(sp), Rs2(t0)]);
    }
  };
}
