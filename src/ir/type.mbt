pub(all) struct Type {
  name: String
  subtypes: Array[Type]
}

pub impl Show for Type with output(self, logger) {
  logger.write_string("\{self.name}");
  if (self.subtypes.length() > 0) {
    let sub = self.subtypes.map(_.to_string()).join(", ");
    logger.write_string("<\{sub}>");
  }
}

pub fn Type::new(name: String) -> Type {
  { name, subtypes: [] }
}

pub fn Type::make(name: String, subtypes: Array[Type]) -> Type {
  { name, subtypes }
}

pub fn ptr(x: Type) -> Type {
  Type::make("ptr", [x]);
}

pub let i32: Type = Type::new("i32");
pub let f64: Type = Type::new("f64");
pub let unit: Type = Type::new("unit");
