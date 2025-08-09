typealias @utils.(Config, Map)
typealias @ir.(Op, Builder, Block, Region, Type, OpKind)

fnalias @utils.(die, reg)

// Import variables.
let config: Config = @utils.config;
let unit = @ir.unit;
let i32 = @ir.i32;
let i64 = @ir.i64;
let f64 = @ir.f64;
let isa = @ir.isa;
