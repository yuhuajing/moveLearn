# 编程概念

```struct```结构体内部使用```KAY:VALUE```的形式定义参数，其中```KEY```表示定义的字段名称，```VALUE```表示该字段的数据类型。 

结构体只能在模块中进行定义，可以内部嵌套结构体实现复杂数据结构，也可以仅仅是简单类型的映射结构。一个结构体最多可以有65535个字段。

```text
module M {

    // struct can be without fields
    // but it is a new type
    struct Empty {}

    struct MyStruct {
        field1: address,
        field2: bool,
        field3: Empty
    }

    struct Example {
        field1: u8,
        field2: address,
        field3: u64,
        field4: bool,
        field5: bool,

        // you can use another struct as type
        field6: MyStruct
    }
}
```

在script脚本中通过```use <module>::<struct>;```使用模块中的结构体

通过用结构体的定义创建实例或传递与结构体的字段名匹配的变量名进行简化结构体的创建过程。

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
}
```

空结构体的话只需要使用```{}```创建实例
```text
public fun empty(): Empty {
    Empty {}
}
```

结构体字段默认是private,无法再不外使用，在被导入的脚本中只能当作类型使用，无法获取内部数据。因此，需要在模块中定义结构体的时候，为内部参数定义public 的 getter函数，通过getter函数获取结构体内部数据。
```text
module Country {

    struct Country {
        id: u8,
        population: u64
    }

    public fun new_country(id: u8, population: u64): Country {
        Country {
            id, population
        }
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

    // ... fun destroy ... 
}
```

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

        // however this is impossible and will lead to compile error
        // let id = country.id;
        // let population = country.population.
    }
}
```

回收/销毁 结构体 ```let <STRUCT DEF> = <STRUCT>```,将已定义的结构体转为空。

```text
module Country {

    // ...

    // we'll return values of this struct outside
    public fun destroy(country: Country): (u8, u64) {

        // variables must match struct fields
        // all struct fields must be specified
        let Country { id, population } = country;

        // after destruction country is dropped
        // but its fields are now variables and
        // can be used
        (id, population)
    }
}
```
MOVE中禁止定义不会被使用的变量，如果需要在不适用字段的情况下销毁结构体，就需要使用缺省```_```表示未使用的结构体字段。
```text
module Country {
    // ...

    public fun destroy(country: Country) {

        // this way you destroy struct and don't create unused variables
        let Country { id: _, population: _ } = country;

        // or take only id and don't init `population` variable
        // let Country { id, population: _ } = country;
    }
}
```
