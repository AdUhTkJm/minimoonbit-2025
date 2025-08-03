import yaml
import sys
import textwrap

def camel(x: str):
  return ''.join(word.title() for word in x.split('_'))

data = yaml.safe_load(sys.stdin)
passes = data["passes"]

print("// Auto generated. Do not edit!\n")

for name in passes:
  Name = camel(name)
  print(textwrap.dedent(f"""
    pub struct {Name} {{
      module: Op
    }}

    pub impl Pass for {Name} with name(_self) {{
      return "{name}";
    }}

    pub impl Pass for {Name} with operate(self) {{
      {Name}::run(self);
    }}

    pub fn create_{name}(module: Op) -> {Name} {{
      return {Name} :: {{ module }}
    }}
  """), end='')
  # Generate some helper functions as well.
  print(textwrap.dedent(f"""
    pub fn {Name}::funcs(self: {Name}) -> Array[Op] {{
      let bb = self.module.region().block();
      let result = [];
      for op in bb {{
        if (op.isa(Func)) {{
          result.push(op);
        }}
      }}
      return result;
    }}
  """), end='')

