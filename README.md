# Minimoonbit-2025

## 运行方法

这个编译器内有一部分代码是根据配置文件生成的。至于具体生成的文件，以及对应的配置文件格式，请见[生成](#生成)。

在第一次运行前，需要使用 `make.sh`，无需添加参数。它会自动生成需要的代码。

你也可以使用 `make.sh` 辅助调试。目前支持的参数如下：

**test**

`-t` (`--test`): 运行一个特定的 .mbt 文件，并且如果产生语法错误，给出它的位置。

用 moon run 运行时，只会给出字符的序号，而 `make.sh -t` 可以给出当前行，并以红色显示导致错误的字符。就算是多个字符组成的 token，它也只会显示构成 token 的第一个字符，不过这在通常的调试中已经足够。

**preserve**

`-p` (`--preserve`): 在运行上述 .mbt 文件时，将 stderr 和 stdout 保留为 err.txt 和 out.txt。

**rebuild**

`-r` (`--rebuild`): 重新根据配置生成代码。

**with-type**

`-w` (`--with-type`): 在输出 IR 时，同时输出每个 Op 返回值的类型。

## 生成

目前编译器中有三个配置文件。它们都在 `info` 文件夹下。

**op-types.txt**

每行一个名称，以 `snake_case` 形式书写。

它会在 `ir/optype.mbt` 中生成 `OpKind` 的定义，以及对应的 Show trait。

**attrs.yaml**

以 YAML 格式书写。每个属性可以有 `fields`, `format` 以及 `tag` 三个字段。

如果 `tag` 被指定为 1，那么 `fields` 和 `format` 都会被忽略，这个属性是纯粹的标记（类似 MLIR 的 UnitAttr）。一个例子是 `Impure` 属性。

否则，`fields` 代表属性所携带的信息，而 `format` 则是打印 IR 时的格式。

**passes.yaml**

以 YAML 格式书写。其中的 `passes` 是不重复的 pass 列表，而 `pipeline` 则是真正被注册的 pass。在 pipeline 中，一个 pass 可以在不同位置注册多次，也可以完全不被注册（而是被其他 pass 隐式地调用）。
