#!/bin/zsh

while [[ $# -gt 0 ]]; do
  case $1 in
  -t|--test)
    # Run the specified test case.
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -t <path to test file>"
      exit 1
    fi
    testcase=$2; shift 2;;
  -q|--print-before)
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -q <print before>"
      exit 1
    fi
    before=$2; shift 2;;
  -p|--print-after)
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -p <print after>"
      exit 1
    fi
    after=$2; shift 2;;
  -i|--input)
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -i <input file>"
      exit 1
    fi
    input=$2; shift 2;;
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
  -n|--no-run)
    norun=1; shift 1;;
  -s|--submit)
    git archive -o target/submit.zip HEAD; echo "done."; exit 1;;
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
  modified=$(find src/info scripts -type f -newermt "@$last" | head -n 1)
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

gcc=riscv64-linux-gnu-gcc
qemu=qemu-riscv64-static
out=out.txt
err=err.txt

if [[ -n $testcase ]]; then
  testcase=$(find test -regextype posix-egrep -regex ".*/$testcase(\.mbt)?")
  if [[ -z $testcase ]]; then
    echo "file not found."
    exit 1
  fi
  before_args=()
  if [[ -n $before ]]; then
    before_args=(-q "$before")
  fi
  after_args=()
  if [[ -n $after ]]; then
    after_args=(-p "$after")
  fi
  base=$(basename $testcase .mbt)
  moon run src/bin/main.mbt -- "$testcase" $withtype "${before_args[@]}" "${after_args[@]}" $dump_ast -o temp/$base.s > $out 2> $err
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

  cat $out
  if [[ $retval -ne 0 ]]; then
    echo "panicked."
    cat $err
  elif [[ -z $norun ]]; then
    $gcc -static temp/$base.s test/mbtlib.c -o temp/$base
    if [[ -n $input ]]; then
      $qemu temp/$base < $input
      retval=$?
    else
      $qemu temp/$base
      retval=$?
    fi
    if [[ $retval -ne 0 ]]; then
      echo "aborted: $retval"
    fi
  fi
fi

if [[ -n $clean ]]; then
  rm $out $err
  rm -rf temp
  mkdir temp
fi
