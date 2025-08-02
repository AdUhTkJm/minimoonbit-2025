import yaml
import sys
import textwrap

def camel(x: str):
  return ''.join(word.title() for word in x.split('_'))

def die(msg: str):
  print(msg)
  exit(1)

def canonicalize(k, v):
  if "tag" in v:
    return { "tag": True }
  
  required = ["fields", "format"]
  if any(x not in v for x in required):
    die(f"fields missing for {k}, required {required}")

  fields = v["fields"]
  if isinstance(fields, str):
    fields = [fields]
  
  return { "tag": False, "fields": fields, "format": v["format"] }

data: dict = yaml.safe_load(sys.stdin)

# First, generate a definition.
data = { k: canonicalize(k, v) for k, v in data.items() }
print("pub(all) enum Attr {")
for k, v in data.items():
  if v["tag"]:
    print(f"  {camel(k)}")
    continue

  fields = ", ".join(v["fields"])
  print(f"  {camel(k)}({fields})")
print("}")

# Then generate retrieval functions.
for k, v in data.items():
  if v["tag"]:
    print(textwrap.dedent(f"""
      pub fn Op::{k}(self: Op) -> Bool {{
        for x in self.attrs {{
          if (x is {camel(k)}) {{
            return true;
          }}
        }}
        return false;
      }}"""))
    continue

  fields = v["fields"]
  l = len(fields)
  retTy = ", ".join(fields)
  if l > 1:
    retTy = f"({retTy})"
  retval = ", ".join([f"_{i}" for i in range(l)])
  
  print(textwrap.dedent(f"""
    pub fn Op::{k}(self: Op) -> {retTy} {{
      for x in self.attrs {{
        if (x is {camel(k)}({retval})) {{
          return ({retval});
        }}
      }}
      die("no attribute '{k}'");
    }}

    pub fn Op::has_{k}(self: Op) -> Bool {{
      for x in self.attrs {{
        if (x is {camel(k)}(_)) {{
          return true;
        }}
      }}
      return false;
    }}"""))

# Now dump them.
print("pub impl Show for Attr with output(self, logger) {\n  let str = match self {")
for k, v in data.items():
  print("    ", end="")
  if v["tag"]:
    print(f'{camel(k)} => "<{k}>"')
    continue

  fields = v["fields"]
  l = len(fields)
  format: str = v["format"]
  matcher = ", ".join([f"_{i}" for i in range(l)])
  for i in range(l):
    format = format.replace(f"${i}", f"\\{{_{i}}}")
  print(f'{camel(k)}({matcher}) => "{format}"')
print("  }\n  logger.write_string(str);\n}")
