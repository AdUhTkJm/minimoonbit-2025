import sys

def camel(x: str):
  return ''.join(word.title() for word in x.split('_'))

lines = [x.strip() for x in sys.stdin]
print("// Auto generated file. Do not edit!\n")
print("pub(all) enum OpType {")
for x in lines:
  print(f"  {camel(x)}")
print("} derive(Eq, Hash)\n")

print("pub impl Show for OpType with output(self, logger) {\n  let str = match self {")
for x in lines:
  print(f"    {camel(x)} => \"{x}\"")
print("  };\n  logger.write_string(str);\n}")
