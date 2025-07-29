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
pub fn Builder::create_module() -> Op {
  return Op::build(Module, None, [], None, None);
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

pub fn Builder::create(self: Builder, kind: OpType, ty: Type, operands: Array[Op], attrs~: Array[Attr]=[]) -> Op {
  let op = Op::build(kind, Some(ty), operands, attrs~, self.bb, self.at);
  self.block().ops.insert(self.at(), op);
  return op;
}

///|
/// Same as `create`, but silently discards the return value.
/// 
pub fn Builder::creates(self: Builder, kind: OpType, ty: Type, operands: Array[Op], attrs~: Array[Attr]=[]) -> Unit {
  self.create(kind, ty, operands, attrs~) |> ignore;
}

pub fn Builder::before(self: Builder, op: Op) -> Unit {
  self.at = op.at;
  self.bb = op.parent;
}

pub fn Builder::start(self: Builder, block: Block) -> Unit {
  self.at = block.ops.begin |> Some;
  self.bb = block |> Some;
}

pub fn Builder::after(self: Builder, op: Op) -> Unit {
  self.at = op.at().next;
  self.bb = op.parent;
}

pub fn Builder::end(self: Builder, block: Block) -> Unit {
  self.at = block.ops.end |> Some;
  self.bb = block |> Some;
}

test {
  let builder = Builder::new();
  let unit = Builder::create_module();
  let region = unit.append_region();
  let block = region.append_block();
  builder.start(block);
  builder.creates(Int, i32, [], attrs=[Int(3)]);
  println(unit);
}
