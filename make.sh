#!/bin/zsh

if [[ $# -eq 0 ]]; then
  echo "warning: 'make.sh' does nothing without arguments"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case $1 in
  -t|--test)
    # Run the specified test case.
    if [[ $# -eq 1 ]]; then
      echo "usage: make.sh -t <path to test file>"
    fi
    testcase=$2; shift 2;;
  -p|--preserve)
    # Preserves output files.
    preserve=1; shift 1;;
  *) echo "unknown option $1"; exit 1;;
  esac
done

if [[ -n $testcase ]]; then
  out=out.txt
  err=err.txt
  moon run src/bin/main.mbt -- "$testcase" > $out 2> $err
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
  fi

  if [[ -z $preserve ]]; then
    rm $out $err
  fi
fi
