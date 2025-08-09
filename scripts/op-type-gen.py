import sys

def camel(x: str):
  return ''.join(word.title() for word in x.split('_'))

lines = [x.strip() for x in sys.stdin]
with open("src/info/rv-op-types.txt") as f:
  lines.extend([x.strip() for x in f if x.strip() not in lines])

print("// Auto generated file. Do not edit!\n")
print("pub(all) enum OpKind {")
for x in lines:
  print(f"  {camel(x)}Op")
print("} derive(Eq, Hash)")

print("""
pub impl Default for OpKind with default() {
  return BadOp;
}
""")

print("pub impl Show for OpKind with output(self, logger) {\n  let str = match self {")
for x in lines:
  print(f"    {camel(x)}Op => \"{x}\"")
print("  };\n  logger.write_string(str);\n}")
