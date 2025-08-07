#!/bin/zsh

while [[ $# -gt 0 ]]; do
  case $1 in
  -t|--test)
    # Run the specified test case.
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -t <path to test file>"
    fi
    testcase=$2; shift 2;;
  -q|--print-before)
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -q <print before>"
    fi
    before=$2; shift 2;;
  -p|--print-after)
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -p <print after>"
    fi
    after=$2; shift 2;;
  --ast)
    dump_ast="--ast"; shift 1;;
  --clean)
    # Cleans test files.
    clean=1; shift 1;;
  -r|--rebuild)
    # Forces a rebuild.
    rebuild=1; shift 1;;
  -w|--with-type)
    withtype="--types"; shift 1;;
  *) echo "unknown option $1"; exit 1;;
  esac
done

mkdir -p build

if [[ ! -d test/official ]]; then
  git clone https://github.com/moonbitlang/contest-2025-data.git test/contest
  mv test/contest/test_cases test/official
  rm -rf test/contest
fi

# Detect file changes.
timestamp=$(date +%s)
cache=build/timestamp
if [[ -f $cache ]]; then
  last=$(cat $cache)
  modified=$(find src/info -type f -newermt "@$last" | head -n 1)
  if [[ -z $modified ]]; then
    no_rebuild=1
  fi
fi
echo $timestamp > $cache

if [[ -n $rebuild ]]; then
  unset no_rebuild
fi

# Rebuild.
if [[ -z $no_rebuild ]]; then
  cat src/info/op-types.txt | python3 scripts/op-type-gen.py > src/ir/optype.mbt
  cat src/info/attrs.yaml | python3 scripts/attr-gen.py > src/ir/attr.mbt
  cat src/info/passes.yaml | python3 scripts/pass-def-gen.py > src/opt/passes.mbt
  cat src/info/passes.yaml | python3 scripts/pass-pipeline-gen.py > src/bin/pipeline.mbt
fi

if [[ -n $testcase ]]; then
  testcase=$(find test -regextype posix-egrep -regex ".*/$testcase(\.mbt)?")
  out=out.txt
  err=err.txt
  before_args=()
  if [[ -n $before ]]; then
    before_args=(-q "$before")
  fi
  after_args=()
  if [[ -n $after ]]; then
    after_args=(-p "$after")
  fi
  moon run src/bin/main.mbt -- "$testcase" $withtype "${before_args[@]}" "${after_args[@]}" $dump_ast > $out 2> $err
  retval=$?

  errpos=$(sed -En 's/.*error: .*\(character: ([0-9]+)\)/\1/p' $out)

  # We detected a parse error.
  if [[ -n $errpos ]]; then
    awk -v errpos=$errpos '
      BEGIN { total = 0 }
      {
        # Also count the newline.
        line_len = length($0) + 1
        if (total + line_len >= errpos) {
          charpos = errpos - total
          if (charpos < 1) charpos = 1
          printf "syntax error on line %d:\n", NR
          printf "%s\033[31m%s\033[0m%s\n", 
            substr($0, 1, charpos - 1),
            substr($0, charpos, 1),
            substr($0, charpos + 1) 
          exit
        }
        total += line_len
      }
    ' $testcase
  fi

  if [[ $retval -ne 0 ]]; then
    echo "panicked."
    cat $err
  fi
  cat $out

  if [[ -n $clean ]]; then
    rm $out $err
    rm -rf temp
    mkdir temp
  fi
fi
