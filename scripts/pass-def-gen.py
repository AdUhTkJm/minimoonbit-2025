import yaml
import sys
import textwrap

def camel(x: str):
  return ''.join(word.title() for word in x.split('_'))

data = yaml.safe_load(sys.stdin)
passes = data["passes"]

print("// Auto generated. Do not edit!\n")

for name in passes:
  if isinstance(name, dict):
    values = name
    name = list(values.keys())[0];
    fields: list[dict] = values[name]
    names = list(list(entry.keys())[0] for entry in fields)
    types = list(list(entry.values())[0][0] for entry in fields)
    defaults = list(list(entry.values())[0][1] for entry in fields)

    decl = "".join(f"\n  mut {name}: {type}" for name, type in zip(names, types))
    default = "".join(f", {k}: {v}" for k, v in zip(names, defaults))
  else:
    decl = ""
    default = ""


  Name = camel(name)
  print(textwrap.dedent(f"""
pub(all) struct {Name} {{
  mut module: Op{decl}
}}

pub impl Pass for {Name} with name(_self) {{
  return "{name}";
}}

pub impl Pass for {Name} with operate(self) {{
  {Name}::run(self);
}}

pub fn create_{name}(module: Op) -> {Name} {{
  return {Name} :: {{ module{default} }}
}}
  """), end='')
  # Generate some helper functions as well.
  print(textwrap.dedent(f"""
pub fn {Name}::funcs(self: {Name}) -> Array[Op] {{
  let bb = self.module.region().block();
  let result = [];
  for op in bb {{
    if (isa[FuncOp](op)) {{
      result.push(op);
    }}
  }}
  return result;
}}
pub fn {Name}::globals(self: {Name}) -> Array[Op] {{
  let bb = self.module.region().block();
  let result = [];
  for op in bb {{
    if (isa[GlobalOp](op)) {{
      result.push(op);
    }}
  }}
  return result;
}}
  """), end='')

