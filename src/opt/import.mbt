typealias @utils.(Config, Map)
typealias @ir.(Op, Builder, Block, Region)

fnalias @utils.(die)

// Import variables.
let config: Config = @utils.config;
let unit = @ir.unit;
let i32 = @ir.i32;
let f64 = @ir.f64;
let isa = @ir.isa;
