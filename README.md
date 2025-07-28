# Minimoonbit-2025

## 运行方法

对于一般的运行，实际上只需要 `moon run src/bin/main.mbt -- <program arguments>` 即可。

然而，为了方便调试，可以考虑使用 `make.sh`。目前支持的参数如下：

**test**

`-t` (`--test`): 运行一个特定的 .mbt 文件，并且如果产生语法错误，给出它的位置。

用 moon run 运行时，只会给出字符的序号，而 `make.sh -t` 可以给出当前行，并以红色显示导致错误的字符。就算是多个字符组成的 token，它也只会显示构成 token 的第一个字符，不过这在通常的调试中已经足够。

**preserve**

`-p` (`--preserve`): 在运行上述 .mbt 文件时，将 stderr 和 stdout 保留为 err.txt 和 out.txt。
