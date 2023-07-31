# 基础语法

Move的基本数据类型支持：整型(u8 u64 u128)、bool类型 和 地址

变量的基础定义：

通过```//``` ```/*  */```进行单/多行注释

```let```关键字在当前作用域内创建新变量(初始化变量),move作用域是由```{ }```括起来的代码块。变量仅存在其作用域中，当作用域结束时变量随之消亡。

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

整型变量(u8 u64 u128)运算符：```+ - * / % << >> & \ ^```

以```{}```的代码块是一个表达式，内部最后一个```;```的表达式是该块的返回值。

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
1. 每个拥有返回值的表达式或代码块都必须以```;```结尾，代码块内的返回值可以不加```;```
2. let定义的变量的生命周期和作用域相同
3. Move 规定所有的变量必须被使用，即使是重定义时被覆盖的变量。

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

通过```while```或```loop```关键字定义条件循环。

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

有条件退出，中断程序的同时报告错误代码的关键字```abort```

```text
script {
    fun main(a: u8) {

        if (a != 10) {
            abort 0;
        }

        // code here won't be executed if a != 10
        // transaction aborted
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