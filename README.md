# moveLearn
1. https://move-book.com/cn/index.html
2. https://aptos.dev/tutorials/your-first-transaction
3. https://developers.diem.com/docs/welcome-to-diem/
4. https://diem.github.io/move/modules-and-scripts.html


1. ``` move new <name>```创建新的move目录，生成```move.toml```配置文件和```sources```文件。
```text
[package]
name = <string>                  # e.g., "mymove"
version = "<uint>.<uint>.<uint>" # e.g., "0.1.1"
license* = <string>              # e.g., "MIT", "GPL", "Apache 2.0"
authors* = [<string>]            # e.g., ["Joe Smith (joesmith@noemail.com)", "Jane Smith (janesmith@noemail.com)"]

[addresses]  # (Optional section) Declares named addresses in this package and instantiates named addresses in the package graph
# One or more lines declaring named addresses in the following format
<addr_name> = "_" | "<hex_address>" # e.g., std = "ox1" or Addr = "0x1"

[dependencies] # (Optional section) Paths to dependencies and instantiations or renamings of named addresses from each dependency
# One or more lines declaring dependencies in the following format
<string> = { local = <string>, addr_subst* = { (<string> = (<string> | "<hex_address>"))+ } } # local dependencies
<string> = { git = <URL ending in .git>, subdir=<path to dir containing Move.toml inside git repo>, rev=<git commit hash>, addr_subst* = { (<string> = (<string> | "<hex_address>"))+ } } # git dependencies

[dev-addresses] # (Optional section) Same as [addresses] section, but only included in "dev" and "test" modes
# One or more lines declaring dev named addresses in the following format
<addr_name> = "_" | "<hex_address>" # e.g., Std = "_" or Addr = "0xC0FFEECAFE"

[dev-dependencies] # (Optional section) Same as [dependencies] section, but only included in "dev" and "test" modes
# One or more lines declaring dev dependencies in the following format
<string> = { local = <string>, addr_subst* = { (<string> = (<string> | <address>))+ } }
```
选用remote的git依赖的方式会造成编译速度慢，可以先下载本地
> https://github.com/move-language/move/tree/main/language
```text
[dependencies]
AptosStdlib = { local = "../aptos-stdlib" }
MoveStdlib = { local = "../move-stdlib" }
```
2. sources 目录用于创建module和scripts文件

编译并检查模块:
> move build

```text
address 0x2 {
    module Coin{
        struct Coin has copy,drop{
            value:u64
        }
        public fun mint(value:u64):Coin{
            Coin{value}
        }
        public fun value(coin:&Coin):u64{
            *&coin.value
        }
        public fun burn(coin:&Coin){
            let Coin{value:_}=coin;
        }
    }
}
```

发布之前查询编译的字节码
> move disassemble --name `<Addr>`
```text
// Move bytecode v6
module 2.Coin {
struct Coin has copy, drop {
        value: u64
}

public burn(coin: &Coin) {
B0:
        0: MoveLoc[0](coin: &Coin)
        1: ImmBorrowField[0](Coin.value: u64)
        2: Pop
        3: Ret
}
public mint(value: u64): Coin {
B0:
        0: MoveLoc[0](value: u64)
        1: Pack[0](Coin)
        2: Ret
}
public value(coin: &Coin): u64 {
B0:
        0: MoveLoc[0](coin: &Coin)
        1: ImmBorrowField[0](Coin.value: u64)
        2: ReadRef
        3: Ret
}
}
```

编译并发布模块
> move sandbox publish -v
```text
Found 1 modules
Publishing a new module 00000000000000000000000000000002::Coin (wrote 167 bytes)
Wrote 167 bytes of module ID's and code
```

查询发布的模块：
> ls storage/`<Addr>`/modules

> move sandbox view storage/`<Addr>`/modules/`<moduleName>`.mv


执行脚本文件 的命令： 
> move sandbox run sources/xxx_script.move

```text
script {
    use std::debug;
    use 0x2::Coin;

    fun main() {
        let coin = Coin::mint(100);

        debug::print(&Coin::value(&coin));

        Coin::burn(&coin);
    }
}
```
```text
[debug] 100
```

清理沙盒环境数据
> move sandbox clean


