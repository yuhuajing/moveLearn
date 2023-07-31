# 参数权限

每种类型的数据拥有四种修饰符"copy drop store key"

四种权限的功能限制为：
1. Copy - 被修饰的值可以被复制。
2. Drop - 被修饰的值在作用域结束时可以被丢弃。
3. Key - 被修饰的值可以作为键值对全局状态进行访问。
4. Store - 被修饰的值可以被存储到全局状态

基本变量类型具有预置的"copy drop store"权限（u8 u64 u128 bool address）,结构体等需要在定义时指定权限```struct NAME has ABILITY [, ABILITY] { [FIELDS] }```.

```text
module Library {
    
    // each ability has matching keyword
    // multiple abilities are listed with comma
    struct Book has store, copy, drop {
        year: u64
    }

    // single ability is also possible
    struct Storage has key {
        books: vector<Book>
    }

    // this one has no abilities 
    struct Empty {}
}
```

例如：Drop权限

```text
module Country {
    struct Country {
        id: u8,
        population: u64
    }
    
    public fun new_country(id: u8, population: u64): Country {
        Country { id, population }
    }
}
```
```text
script {
    use {{sender}}::Country;

    fun main() {
        Country::new_country(1, 1000000);
    }   
}
```
代码报错：
```text
error: 
   ┌── scripts/main.move:5:9 ───
   │
 5 │     Country::new_country(1, 1000000);
   │     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cannot ignore values without the 'drop' ability. The value must be used
   │
```
方法 ```Country::new_country()``` 创建了一个值，这个值没有被传递到任何其它地方，所以它应该在函数结束时被丢弃。但是 Country 类型没有 Drop ability，所以运行时报错了.

按照 abilities 语法我们为这个结构体增加 drop ability，这个结构体的所有实例将可以被丢弃.
```text
module Country {
    struct Country has drop { // has <ability>
        id: u8,
        population: u64
    }
    // ...
}
```

例如： copy

结构体按值传递，创建新的副本需要```copy```关键字
```text
script {
    use {{sender}}::Country;

    fun main() {
        let country = Country::new_country(1, 1000000);
        let _ = copy country;
    }   
}
```
报错：
```text
   ┌── scripts/main.move:6:17 ───
   │
 6 │         let _ = copy country;
   │                 ^^^^^^^^^^^^ Invalid 'copy' of owned value without the 'copy' ability
   │
```
缺少 copy ability 限制符的类型在进行复制时会报错
```text
module Country {
    struct Country has drop, copy { // see comma here!
        id: u8,
        population: u64
    }
    // ...
}
```

