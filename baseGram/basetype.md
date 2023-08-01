# Move

## 安装环境

1. 安装Rust
> curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
2. 安装move脚手架
> cargo install --git https://github.com/move-language/move move-cli --branch main

## 基础语法
Move由脚本和模块组成：
> 模块是发布在特定地址下的打包在一起的一组函数和结构体,允许扩展区块链的功能，更加灵活的实现自定义智能合约。类似于库。

> 脚本文件可以调用模块库函数，内部函数作为交易执行，借助库函数在交易中加入更多逻辑，同时更加灵活的节省时间和资源。

1. Move的基本数据类型支持：整型(u8 u64 u128)、bool、Address、Vector动态数组、泛型
2. ```const```常量，常量定义后就无法修改，通过变量名称访问变量。
3. 脚本文件中使用```use```关键字导入模块名称```use <Address>::<ModuleName>;```,通过 ```::```访问导入模块内的函数或结构体
4. 通过```//``` ```/*  */```进行单/多行注释
5. move作用域是由```{ }```括起来的代码块，```let```关键字在当前作用域内创建新变量(初始化变量)。变量仅存在其作用域中，当作用域结束时变量随之消亡。变量只能存在于一个作用域中，因此在变量转移拷贝时需要注意是否需要在本地保留变量副本。

## 整型变量
整型变量(u8 u64 u128)运算符：```+ - * / % << >> & \ ^```
```text
script {
    fun main() {
        // define empty variable, set value later
        let a: u8;
        a = 10;

        // define variable, set type
        let a: u64 = 10;

        // finally simple assignment
        let a = 10;

        // simple assignment with defined value type
        let a = 10u128;

        // in function calls or expressions you can use ints as constant values
        if (a < 10) {};

        // or like this, with type
        if (a < 10u8) {}; // usually you don't need to specify type
    }
}
```

通过运算符```as```进行比较值的大小以及转换不同类型的整型变量

```text
script {
    fun main() {
        let a: u8 = 10;
        let b: u64 = 100;
        // we can only compare same size integers
        if (a == (b as u8)) abort 11;
        if ((a as u64) == b) abort 11;
    }
}
```
## bool
布尔类型的变量初始化和整型类似，默认值为false

```text
script {
    fun main() {
        // these are all the ways to do it
        let b : bool; b = true;
        let b : bool = true;
        let b = true
        let b = false; // here's an example with false
    }
}
```
## Address
Address地址是区块链中交易发送者的标识符，转账和导入模块等这些操作都需要指定地址

```text
script {
    fun main() {
        let addr: address; // type identifier

        // in this book I'll use {{sender}} notation;
        // always replace `{{sender}}` in examples with VM specific address!!!
        addr = {{sender}};

        // in Diem's Move VM and Starcoin - 16-byte address in HEX
        addr = 0x...;

        // in dfinance's DVM - bech32 encoded address with `wallet1` prefix
        addr = wallet1....;
    }
}
```
## 代码块作用域
1. 每个拥有返回值的表达式或代码块都必须以```;```结尾，代码块内的返回值可以不加```;```
2. let定义的变量的生命周期和作用域相同
3. Move 规定所有的变量必须被使用，即使是重定义时被覆盖的变量。

```text
script {
    fun block_ret_sample() {

        // since block is an expression, we can
        // assign it's value to variable with let
        let a = {

            let c = 10;

            c * 1000  // no semicolon!
        }; // scope ended, variable a got value 10000

        let b = {
            a * 1000  // no semi!
        };

        // variable b got value 10000000

        {
            10; // see semi!
        }; // this block does not return a value

        let _ = a + b; // both a and b get their values from blocks
    }
}
```
## If/Else

if 分支判断```if (<布尔表达式>) <表达式> else <表达式>;```,同样可以使用```let```关键字声明```if```的表达式，不过不能在声明中使用不带else分支的表达式赋值语句，如果if不满足条件，就会导致变量未被定义。

```text
script {
    use 0x1::Debug;

    fun main() {

        // try switching to false
        let a = true;
        let b = if (a) { // 1st branch
            10
        } else { // 2nd branch
            20
        };

        Debug::print<u8>(&b);
    }
}
```
## while/loop

```while (<布尔表达式>) <表达式>;```
```text
script {
    fun main() {

        let i = 0; // define counter

        // iterate while i < 5
        // on every iteration increase i
        // when i is 5, condition fails and loop exits
        while (i < 5) {
            i = i + 1;
        };
    }
}
```

```loop```关键字提供无限循环的方法，只有内部达成预置条件，整个循环才会停止。内部可通过```break```和```continue```关键字实现中断或跳出这一轮循环

```text
script {
    fun main() {
        let i = 0;

        loop {
            i = i + 1;

            if (i == 5) {
                break; // will result in compiler error. correct is `break` without semi
                       // Error: Unreachable code
            }; //需要将代码块中的值返回到外部执行，因此不能在代码块中加；

            // same with continue here: no semi, never;
            if (true) {
                continue
            };

            // however you can put semi like this, because continue and break here
            // are single expressions, hence they "end their own scope"
            if (true) continue;
            if (i == 5) break;
        }
    }
}
```

有条件退出，中断程序的同时报告错误代码的关键字```abort```,用于中止当前的执行并抛出异常。它类似于其他编程语言中的异常处理机制。当在合约执行过程中遇到某种错误或不可预测的情况时，可以使用abort关键字来终止合约执行并抛出异常信息

```text
script {
public fun example_function(amount: u64) {
    if (amount <= 0) {
        abort("Invalid amount: amount must be greater than 0");
    }
    // 合约继续执行其他操作
}
}
```

```assert(condition,code)```内部封装了```abort```关键字，通过assert进行前置条件判断.在不满足条件时进行中止并报告错误代码，在满足条件时不执行任何操作。

```text
script {

    fun main(a: u8) {
        assert(a == 10, 0);
        // code here will be executed if (a == 10)
    }
}
```
## Module
模块类似合约中的```library```和其他语言的库, 以```module```关键字开头，后面跟随模块名称和大括号，大括号内部定义该模块封装的一组函数和结构体。默认情况下，模块将在发布者的地址下进行编译和发布，需要执行特定的address地址：
```text
address 0x1{
    module HelloWorld{
        public fun gimme_five():u8{
            5
        }
    }
}
```
在script脚本中导入模块```use <Address>::<ModuleName>;```，其中，address表示模块的发布者，后者收i模块的名字。
```text
// scripts/run_hello.move
script {
    use 0x1::HelloWorld;
    use 0x1::Debug;

    fun main() {
        let five = HelloWorld::gimme_five();

        Debug::print<u8>(&five);
    }
}
```
模块中也可以导入另外的模块，在当前模块的代码块中执行 ```use```,同样可以通过 ```as```关键字重命名导入的模块 ```use <Address>::<ModuleName> as <Alias>;```
```text
module Math {
    use 0x1::Vector;

    // the same way as in scripts
    // you are free to import any number of modules

    public fun empty_vec(): vector<u64> {
        Vector::empty<u64>();
    }
}
```

## Function修饰符

函数修饰符：public/private/native

通过函数修饰符定义函数的可见性，默认在模块中定义的函数都是private，无法再其他模块或脚本中访问。私有函数只能在当前定义的模块中使用。通过```public```关键字修改函数的可见性。表明该函数外部可调用。
```text
module Math {

    public fun is_zero(a: u8): bool {
        a == zero()
    }

    fun zero(): u8 {
        0
    }
}
```

```native```函数修饰符表明函数时内置函数，这种方法由VM本身定义，在不同的VM中存在不同的实现。这意味着native函数没有使用MOVE语法，没有函数体。
```text
module Signer {

    native public fun borrow_address(s: &signer): &address;

    // ... some other functions ...
}
```