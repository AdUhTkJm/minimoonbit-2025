pub struct Builder {
  mut at: Node[Op]?
  mut bb: Block?
}

pub fn Builder::new() -> Builder {
  { at: None, bb: None }
}

///|
/// Generates the top-level ModuleOp.
/// 
pub fn Builder::createModule() -> Op {
  return Op::build(ModuleOp, unit, [], None, None);
}

///|
/// Gets the current block.
/// 
pub fn Builder::block(self: Builder) -> Block {
  return self.bb.unwrap();
}

///|
/// Gets the current insertion point inside a block.
/// 
pub fn Builder::at(self: Builder) -> Node[Op] {
  return self.at.unwrap();
}

pub fn Builder::create(self: Builder, kind: OpKind, ty: Type, operands: Array[Op], attrs~: Array[Attr]=[]) -> Op {
  let op = Op::build(kind, ty, operands, attrs~, self.bb, self.at);
  self.block().ops.insert(self.at(), op);
  op.at = self.at().prev;
  return op;
}

///|
/// Same as `create`, but silently discards the return value.
/// 
pub fn Builder::creates(self: Builder, kind: OpKind, ty: Type, operands: Array[Op], attrs~: Array[Attr]=[]) -> Unit {
  self.create(kind, ty, operands, attrs~) |> ignore;
}

pub fn Builder::replace(self: Builder, op: Op, kind: OpKind, ty: Type, operands: Array[Op], attrs~: Array[Attr]=[]) -> Unit {
  self.setAfterOp(op);
  let created = self.create(kind, ty, operands, attrs~);
  op.replaceAllUsesWith(created);
  op.erase();
}

pub fn Builder::createInt(self: Builder, x: Int) -> Op {
  return self.create(IntOp, i32, [], attrs=[Int(x)])
}

pub fn Builder::createDouble(self: Builder, x: Double) -> Op {
  return self.create(DoubleOp, f64, [], attrs=[Double(x)])
}

pub fn Builder::setBeforeOp(self: Builder, op: Op) -> Unit {
  self.at = op.at;
  self.bb = op.parent;
}

pub fn Builder::setToBlockStart(self: Builder, block: Block) -> Unit {
  self.at = block.ops.begin |> Some;
  self.bb = block |> Some;
}

pub fn Builder::setToRegionStart(self: Builder, region: Region) -> Unit {
  self.setToBlockStart(region.block());
}

pub fn Builder::setAfterOp(self: Builder, op: Op) -> Unit {
  self.at = op.at().next;
  self.bb = op.parent;
}

pub fn Builder::setToBlockEnd(self: Builder, block: Block) -> Unit {
  self.at = block.ops.end |> Some;
  self.bb = block |> Some;
}

pub fn Builder::setToRegionEnd(self: Builder, region: Region) -> Unit {
  self.setToBlockEnd(region.block());
}

pub fn Builder::getInsertionPoint(self: Builder) -> (Node[Op], Block) {
  return (self.at(), self.block());
}

pub fn Builder::setTo(self: Builder, point: (Node[Op], Block)) -> Unit {
  self.at = Some(point.0);
  self.bb = Some(point.1);
}

///|
/// Shallow copies an operation, without rewiring operands.
/// 
pub fn Builder::copy(self: Builder, op: Op) -> Op {
  return self.create(op.kind, op.ty, op.operands, attrs=op.attrs);
}
