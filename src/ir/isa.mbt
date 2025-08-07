pub struct IsaImpl {}

pub let isa: IsaImpl = IsaImpl :: {};

pub fn IsaImpl::op_get(_self: IsaImpl, kind: OpKind) -> (Op) -> Bool {
  return (x) => x.kind == kind
}
