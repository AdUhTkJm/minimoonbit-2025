// Auto generated file. Do not edit!

pub(all) enum OpKind {
  ModuleOp
  FuncOp
  AddOp
  SubOp
  MulOp
  DivOp
  ModOp
  PhiOp
  IfOp
  ForOp
  WhileOp
  CallOp
  AllocaOp
  MallocOp
  LoadOp
  StoreOp
  GepOp
  GetGlobalOp
  GlobalOp
  IntOp
  DoubleOp
  MakeTupleOp
  GetItemOp
  GetArgOp
  MakeUnitOp
  AndOp
  OrOp
  NeOp
  EqOp
  LtOp
  LeOp
  BrOp
  GotoOp
  ReturnOp
  ProceedOp
  ReadRegOp
  WriteRegOp
  LiOp
  LaOp
  AddiOp
  AddwOp
  SubwOp
  MulwOp
  DivwOp
  DivuOp
  DivuwOp
  RemOp
  RemwOp
  RemuOp
  RemuwOp
  LdOp
  SdOp
  LwOp
  SwOp
  FldOp
  FsdOp
  RetOp
  JOp
  BeqOp
  BneOp
  BltOp
  BleOp
  BgtOp
  BgeOp
  AndiOp
  OriOp
  XorOp
  XoriOp
  SllOp
  SlliOp
  SrlOp
  SrliOp
  SraOp
  SraiOp
  MvOp
  FmvOp
} derive(Eq, Hash)

pub impl Default for OpKind with default() {
  return ModuleOp;
}

pub impl Show for OpKind with output(self, logger) {
  let str = match self {
    ModuleOp => "module"
    FuncOp => "func"
    AddOp => "add"
    SubOp => "sub"
    MulOp => "mul"
    DivOp => "div"
    ModOp => "mod"
    PhiOp => "phi"
    IfOp => "if"
    ForOp => "for"
    WhileOp => "while"
    CallOp => "call"
    AllocaOp => "alloca"
    MallocOp => "malloc"
    LoadOp => "load"
    StoreOp => "store"
    GepOp => "gep"
    GetGlobalOp => "get_global"
    GlobalOp => "global"
    IntOp => "int"
    DoubleOp => "double"
    MakeTupleOp => "make_tuple"
    GetItemOp => "get_item"
    GetArgOp => "get_arg"
    MakeUnitOp => "make_unit"
    AndOp => "and"
    OrOp => "or"
    NeOp => "ne"
    EqOp => "eq"
    LtOp => "lt"
    LeOp => "le"
    BrOp => "br"
    GotoOp => "goto"
    ReturnOp => "return"
    ProceedOp => "proceed"
    ReadRegOp => "read_reg"
    WriteRegOp => "write_reg"
    LiOp => "li"
    LaOp => "la"
    AddiOp => "addi"
    AddwOp => "addw"
    SubwOp => "subw"
    MulwOp => "mulw"
    DivwOp => "divw"
    DivuOp => "divu"
    DivuwOp => "divuw"
    RemOp => "rem"
    RemwOp => "remw"
    RemuOp => "remu"
    RemuwOp => "remuw"
    LdOp => "ld"
    SdOp => "sd"
    LwOp => "lw"
    SwOp => "sw"
    FldOp => "fld"
    FsdOp => "fsd"
    RetOp => "ret"
    JOp => "j"
    BeqOp => "beq"
    BneOp => "bne"
    BltOp => "blt"
    BleOp => "ble"
    BgtOp => "bgt"
    BgeOp => "bge"
    AndiOp => "andi"
    OriOp => "ori"
    XorOp => "xor"
    XoriOp => "xori"
    SllOp => "sll"
    SlliOp => "slli"
    SrlOp => "srl"
    SrliOp => "srli"
    SraOp => "sra"
    SraiOp => "srai"
    MvOp => "mv"
    FmvOp => "fmv"
  };
  logger.write_string(str);
}
