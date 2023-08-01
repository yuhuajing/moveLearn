# 引用

move中每个变量都只有一个作用域，在当前作用域结束时，变量将被删除。其中，变量通过```let```在作用域中定义或者通过参数传递，但是在参数传递过程中，由于变量只拥有一个作用域，所以参数传递伴随着所有权的转移。旧函数将不拥有该变量的所有权，新函数成为新的所有者，接管变量的所有权。
```text
script {
    use {{sender}}::M;

    fun main() {
        // Module::T is a struct
        let a : Module::T = Module::create(10);

        // here variable `a` leaves scope of `main` function
        // and is being put into new scope of `M::value` function
        M::value(a);

        // variable a no longer exists in this scope
        // this code won't compile
        M::value(a);
    }
}
```
模块内部关于函数的定义为：
```text
module M {
    // create_fun skipped
    struct T { value: u8 }

    public fun create(value: u8): T {
        T { value }
    }

    // variable t of type M::T passed
    // `value()` function takes ownership
    public fun value(t: T): u8 {
        // we can use t as variable
        t.value
    }
    // function scope ends, t dropped, only u8 result returned
    // t no longer exists
}
```
当value函数返回结构体数值后，传递的t值将会被销毁，只是返回内部的值

## move
当参数被传递到另一个函数时，内部参数会隐式使用move关键字
```text
script {
    use {{sender}}::M;

    fun main() {
        let a : Module::T = Module::create(10);

        M::value(move a); // variable a is moved

        // local a is dropped
    }
}
```
## copy
参数只拥有一个作用域，在参数传递后通过```copy```关键字拷贝变量，本地保留该变量的值，同时将拷贝的副本传递给函数。但是使用copy拷贝变量的操作会增加占用内存的大小，同时在区块链中交易执行时占用的内存资源和gas花销成正比，因此无限制的copy会大幅增加交易手续费。
```text
script {
    use {{sender}}::M;

    fun main() {
        let a : Module::T = Module::create(10);

        // we use keyword copy to clone structure
        // can be used as `let a_copy = copy a`
        M::value(copy a);
        M::value(a); // won't fail, a is still here
    }
}
```
## & &mut
数据在内存中存储，通过执行该存储位置的链接就可以访问特定的数据变量，从而实现将数据传递但是不移动变量值（直接通过内存位置读取数据，降低数据的访问时间。通过内存地址实现数据的 传递，降低数据拷贝带来的本地内存资源的消耗）。其中 ```&```关键字表示只读的传递内存地址，```&mut```表示读写的传递内存地址，允许后续函数修改内存地址的变量值。

不可变的函数定义模块：
```text
module M {
    struct T { value: u8 }
    // ...
    // ...
    // instead of passing a value, we'll pass a reference
    public fun value(t: &T): u8 { //传递指针地址
        t.value
    }
}
```
带有可变函数的定义模块：
```text
module M {
    struct T { value: u8 }

    // returned value is of non-reference type
    public fun create(value: u8): T {
        T { value }
    }

    // immutable references allow reading
    public fun value(t: &T): u8 {
        t.value
    }

    // mutable references allow reading and changing the value
    public fun change(t: &mut T, value: u8) {
        t.value = value;
    }
}
```
脚本函数：
1. 首先创建内部变量为10的结构体
2. 传递读写数据指针地址，修改内部值为20
3. 定义新的读写指针地址并进行传递，修改内部值为100
4. 传递只读指针获取内部值
```text
script {
    use {{sender}}::M;

    fun main() {
        let t = M::create(10);

        // create a reference directly
        M::change(&mut t, 20);

        // or write reference to a variable
        let mut_ref_t = &mut t;

        M::change(mut_ref_t, 100);

        // same with immutable ref
        let value = M::value(&t);

        // this method also takes only references
        // printed value will be 100
        0x1::Debug::print<u8>(&value);
    }
}
```

在只读和读写指针地址传递的过程中，需要注意定义顺序，当一个值被引用时，就无法在move该变量（值传递或引用地址传递），因为存在其他值的依赖关系

例如：
```text
let mut_a = &mut a;
let mut_b = Borrow::ref_from_mut_a(mut_a);

let _ = Borrow::ref_from_mut_a(mut_a);

Borrow::change_b(mut_b, 100000);
```
报错：
```text
    ┌── /scripts/script.move:10:17 ───
    │
 10 │         let _ = Borrow::ref_from_mut_a(mut_a);
    │                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid usage of reference as function argument. Cannot transfer a mutable reference that is being borrowed
    ·
  8 │         let mut_b = Borrow::ref_from_mut_a(mut_a);
    │                     ----------------------------- It is still being mutably borrowed by this reference
    │
```
其中第二行表示A的地址已经被B引用，第三行再次将A的地址作为读写变量传递，则会因为已经存在变量的依赖而报错。矛盾点在于A的地址被引用，同时A的值又可以被修改，那么引用A的变量会存在不知道指向何处的问题？

## *
```*```关键字表示将数据从特定的内存地址取出来，实际时执行```copy``` 操作，因此需要保证参数具有copy的权限。通过拷贝操作不会造成变量作用域的转移，只是在当前作用域内生成一个副本。
```text
module M {
    struct T has copy {}

    // value t here is of reference type
    public fun deref(t: &T): T {
        *t
    }
}
```
同时为保证内部变量作用域的稳定，通过```*&```联动可以取出相应的变量值
```text
module M {
    struct H has copy {}
    struct T { inner: H }

    // ...

    // we can do it even from immutable reference!
    public fun copy_inner(t: &T): H {
        *&t.inner
    }
}
```

## 传递基本类型
基本类型（整型 bool Address）的大小很小，因此在作为参数传递时会默认采用```copy```关键字生成数据副本，并且将数据副本作为变量传递，本地仍然保留变量。当然也可以使用```move```关键字强制不生成副本传递。
```text
script {
    use {{sender}}::M;

    fun main() {
        let a = 10;
        M::do_smth(a);  // M::do_smth(copy a); //default
        let _ = a;
    }
}
```