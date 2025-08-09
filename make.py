#!/usr/bin/env python3
import os
import sys
import subprocess
import re
from datetime import datetime

def main():
    testcase = None
    clean = False
    rebuild = False
    
    # 解析命令行参数
    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg in ('-t', '--test'):
            if i + 1 >= len(sys.argv):
                print("usage: make.py -t <path to test file>")
                sys.exit(1)
            testcase = sys.argv[i+1]
            i += 2
        elif arg == '--clean':
            clean = True
            i += 1
        elif arg in ('-r', '--rebuild'):
            rebuild = True
            i += 1
        else:
            print(f"unknown option {arg}")
            sys.exit(1)
    
    os.makedirs('build', exist_ok=True)
    
    # 检测文件变更
    timestamp = int(datetime.now().timestamp())
    cache = 'build/timestamp'
    no_rebuild = False
    
    if os.path.exists(cache):
        with open(cache, 'r') as f:
            last = int(f.read())
        modified = None
        for root, _, files in os.walk('src/info'):
            for file in files:
                path = os.path.join(root, file)
                if os.path.getmtime(path) > last:
                    modified = path
                    break
            if modified:
                break
        if not modified:
            no_rebuild = True
    
    with open(cache, 'w') as f:
        f.write(str(timestamp))
    
    if rebuild:
        no_rebuild = False
    
    # 重新构建
    if not no_rebuild:
        with open('src/info/op-types.txt', 'r') as f:
            subprocess.run(['python', 'scripts/op-type-gen.py'], stdin=f, stdout=open('src/ir/optype.mbt', 'w'))
        with open('src/info/attrs.yaml', 'r') as f:
            subprocess.run(['python', 'scripts/attr-gen.py'], stdin=f, stdout=open('src/ir/attr.mbt', 'w'))
    
    if testcase:
        # 查找测试文件
        for root, _, files in os.walk('test'):
            for file in files:
                if re.match(f'.*{testcase}(\.mbt)?$', file):
                    testcase = os.path.join(root, file)
                    break
            if testcase:
                break
        
        out = 'out.txt'
        err = 'err.txt'
        
        # 运行测试
        result = subprocess.run(['moon', 'run', 'src/bin/main.mbt', '--', testcase], 
                              stdout=open(out, 'w'), stderr=open(err, 'w'))
        retval = result.returncode
        
        # 处理错误
        with open(out, 'r') as f:
            output = f.read()
            errpos_match = re.search(r'.*error: .*\(character: ([0-9]+)\)', output)
            if errpos_match:
                errpos = int(errpos_match.group(1))
                with open(testcase, 'r') as test_file:
                    total = 0
                    for line_num, line in enumerate(test_file, 1):
                        line_len = len(line) + 1  # 包括换行符
                        if total + line_len >= errpos:
                            charpos = errpos - total
                            if charpos < 1:
                                charpos = 1
                            print(f"syntax error on line {line_num}:")
                            print(f"{line[:charpos-1]}\033[31m{line[charpos-1]}\033[0m{line[charpos:]}")
                            break
                        total += line_len
        
        if retval != 0:
            print("panicked. program output:")
            with open(out, 'r') as f:
                print(f.read())
        
        if clean:
            os.remove(out)
            os.remove(err)
            if os.path.exists('temp'):
                for file in os.listdir('temp'):
                    os.remove(os.path.join('temp', file))
                os.rmdir('temp')
            os.makedirs('temp', exist_ok=True)

if __name__ == '__main__':
    main()