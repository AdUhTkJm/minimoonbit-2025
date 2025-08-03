import yaml
import sys
import textwrap

def camel(x: str):
  return ''.join(word.title() for word in x.split('_'))

data = yaml.safe_load(sys.stdin)
pipeline = data["pipeline"]

print("// Auto generated. Do not edit!\n")

print("pub fn opt(module: @ir.Op) -> @opt.PassManager {")
print("  let pm = @opt.PassManager::new(module);")
for name in pipeline:
  Name = camel(name)
  print("  ", end='')
  print(f"pm.add(@opt.create_{name}(module));")
print("  return pm;")
print("}")
