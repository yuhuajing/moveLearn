# 结构体

1. ```struct```结构体内部使用```KAY:VALUE```的形式定义参数，其中```KEY```表示定义的字段名称，```VALUE```表示该字段的数据类型。 
2. 结构体只能在模块中进行定义，可以内部嵌套结构体实现复杂数据结构，也可以仅仅是简单类型的映射结构。一个结构体最多可以有65535个字段。
3. 在script脚本中通过```use <module>::<struct>;```使用模块中的结构体
4. 结构体字段默认是private,无法再外部使用，在被导入的脚本中只能当作类型使用，无法获取内部数据。因此，需要在模块中定义结构体的时候，为内部参数定义public 的 getter函数，通过getter函数获取结构体内部数据。

## 结构体定义

```text
module M {

    // struct can be without fields
    // 空结构体
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

        // 复杂结构体
        field6: MyStruct
    }
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
