# 结构体

1. ```struct```结构体内部使用```KAY:VALUE```的形式定义参数，其中```KEY```表示定义的字段名称，```VALUE```表示该字段的数据类型。 
2. 结构体只能在模块中进行定义，可以内部嵌套结构体实现复杂数据结构，也可以仅仅是简单类型的映射结构。一个结构体最多可以有65535个字段。
3. 在script脚本中通过```use <module>::<struct>;```使用模块中的结构体
4. 结构体字段默认是private,无法再外部使用，在被导入的脚本中只能当作类型使用，无法获取内部数据。因此，需要在模块中定义结构体的时候，为内部参数定义public 的 getter函数，通过getter函数获取结构体内部数据。

## 结构体定义

```text
module M {

    // struct can be without fields
    struct Foo { 
        field1: u8,
        field2: address,
        field3: u64,
        field4: bool,
        field5: bool
    }
    struct Bar {}
    struct Baz { foo: Foo, } //note: it is fine to have a trailing comma
}
```
## 初始化结构体
```text
module Country {
    struct Country {
        id: u8,
        population: u64
    }

    // Contry is a return type of this function!
    public fun new_country(c_id: u8, c_population: u64): Country {
        // structure creation is an expression
        let country = Country {
            id: c_id,
            population: c_population
        };

        country
    }

    // ...
public fun new_country(id: u8, population: u64): Country {
    // id matches id: u8 field
    // population matches population field
    Country {
        id,
        population
    }

    // or even in one line: Country { id, population }
}

    // don't forget to make these methods public!
    public fun id(country: &Country): u8 {
        country.id
    }

    // don't mind ampersand here for now. you'll learn why it's 
    // put here in references chapter 
    public fun population(country: &Country): u64 {
        country.population
    }
}
```
## 脚本中导入并使用结构体

```text
script {
    use {{sender}}::Country as C;
    use 0x1::Debug;

    fun main() {
        // variable here is of type C::Country
        let country = C::new_country(1, 10000000);

        Debug::print<u8>(
            &C::id(&country)
        ); // print id

        Debug::print<u64>(
            &C::population(&country)
        );

        // 结构体只是作为参数传递，无法直接获取内部数据，必须通过定义结构体的模块内部的getter函数返回具体数据
        // let id = country.id; //compile Error
        // let population = country.population. //compile Error
    }
}
```
## 销毁结构体
回收/销毁 结构体 ```let <STRUCT DEF> = <STRUCT>```,将已定义的结构体转为空。

MOVE中禁止定义不会被使用的变量，如果需要在不适用字段的情况下销毁结构体，就需要使用缺省```_```表示未使用的结构体字段。
```text
module Country {
    public fun destroy(country: Country) {
        // this way you destroy struct and don't create unused variables
        let Country { id: _, population: _ } = country;

        // or take only id and don't init `population` variable
        // let Country { id, population: _ } = country;
    }
}
```

Coin示例：
```text
address 0x2 {
module M {
    // We do not want the Coin to be copied because that would be duplicating this "money",
    // so we do not give the struct the 'copy' ability.
    // Similarly, we do not want programmers to destroy coins, so we do not give the struct the
    // 'drop' ability.
    // However, we *want* users of the modules to be able to store this coin in persistent global
    // storage, so we grant the struct the 'store' ability. This struct will only be inside of
    // other resources inside of global storage, so we do not give the struct the 'key' ability.
    struct Coin has store {
        value: u64,
    }

    public fun mint(value: u64): Coin {
        // You would want to gate this function with some form of access control to prevent
        // anyone using this module from minting an infinite amount of coins
        Coin { value }
    }

    public fun withdraw(coin: &mut Coin, amount: u64): Coin {
        assert!(coin.balance >= amount, 1000);
        coin.value = coin.value - amount;
        Coin { value: amount }
    }

    public fun deposit(coin: &mut Coin, other: Coin) {
        let Coin { value } = other;
        coin.value = coin.value + value;
    }

    public fun split(coin: Coin, amount: u64): (Coin, Coin) {
        let other = withdraw(&mut coin, amount);
        (coin, other)
    }

    public fun merge(coin1: Coin, coin2: Coin): Coin {
        deposit(&mut coin1, coin2);
        coin1
    }

    public fun destroy_zero(coin: Coin) {
        let Coin { value } = coin;
        assert!(value == 0, 1001);
    }
}
}
```

几何示例：
```text
address 0x2 {
module Point {
    struct Point has copy, drop, store {
        x: u64,
        y: u64,
    }

    public fun new(x: u64, y: u64): Point {
        Point {
            x, y
        }
    }

    public fun x(p: &Point): u64 {
        p.x
    }

    public fun y(p: &Point): u64 {
        p.y
    }

    fun abs_sub(a: u64, b: u64): u64 {
        if (a < b) {
            b - a
        }
        else {
            a - b
        }
    }

    public fun dist_squared(p1: &Point, p2: &Point): u64 {
        let dx = abs_sub(p1.x, p2.x);
        let dy = abs_sub(p1.y, p2.y);
        dx*dx + dy*dy
    }
}
}

address 0x2 {
module Circle {
    use 0x2::Point::{Self, Point};

    struct Circle has copy, drop, store {
        center: Point,
        radius: u64,
    }

    public fun new(center: Point, radius: u64): Circle {
        Circle { center, radius }
    }

    public fun overlaps(c1: &Circle, c2: &Circle): bool {
        let d = Point::dist_squared(&c1.center, &c2.center);
        let r1 = c1.radius;
        let r2 = c2.radius;
        d*d <= r1*r1 + 2*r1*r2 + r2*r2
    }
}
}
```

## 元组
```text
address 0x42 {
module Example {
    // all 3 of these functions are equivalent
    fun returns_unit() {}
    fun returns_2_values(): (bool, bool) { (true, false) }
    fun returns_4_values(x: &u64): (&u64, u8, u128, vector<u8>) { (x, 0, 1, b"foobar") }

    fun examples(cond: bool) {
        let () = ();
        let (x, y): (u8, u64) = (0, 1);
        let (a, b, c, d) = (@0x0, 0, false, b"");

        () = ();
        (x, y) = if (cond) (1, 2) else (3, 4);
        (a, b, c, d) = (@0x1, 1, true, b"1");
    }

    fun examples_with_function_calls() {
        let () = returns_unit();
        let (x, y): (bool, bool) = returns_2_values();
        let (a, b, c, d) = returns_4_values(&0);

        () = returns_unit();
        (x, y) = returns_2_values();
        (a, b, c, d) = returns_4_values(&1);
    }
}
}
```