# 集合
```Vector```集合提供动态、可扩展和可管理的功能，用于存储数据集合的内置类型，集合的数据可以是任意一种（仅一种）。向量可以存储大量数据，并且在索引的存储中使用。Vector 最多可以存储 18446744073709551615 u64（2^(64)-1）个非引用类型的值，如 ```vector<T>```可以用任何类型实例化T。例如，```vector<u64>```、```vector<address>```、 ```vector<0x42::MyModule::MyResource>```和```vector<vector<u8>>```都是有效的向量类型.

1. 显式创建vector
```text
vector<T>[]: vector<T>
vecctor<T>[e1, ..., en]: vector<T>
```
示例：
```text
(vector[]: vector<bool>);
(vector[0u8, 1u8, 2u8]: vector<u8>);
(vector<u128>[]: vector<u128>);
(vector<address>[@0x42, @0x100]: vector<address>);
```
2. 字节字符串是带有引号的字符串文字，前缀为```b```, ```b"Hello!\n"```.
十六进制字符串是引号的字符串文字，前缀为```x```, ```x"48656C6C6F210A"```.
```text
script {
fun byte_and_hex_strings() {
    assert!(b"" == x"", 0);
    assert!(b"Hello!\n" == x"48656C6C6F210A", 1);
    assert!(b"\x48\x65\x6C\x6C\x6F\x21\x0A" == x"48656C6C6F210A", 2);
    assert!(
        b"\"Hello\tworld!\"\n \r \\Null=\0" ==
            x"2248656C6C6F09776F726C6421220A200D205C4E756C6C3D00",
        3
    );
}
}
```

## Vector内置函数的速查表
1. 创建一个类型为E的空向量
```text
Vector::empty<E>(): vector<E>;
```
2. 获得向量的长度
```text
Vector::length<E>(v: &vector<E>): u64;
```
3. push，元素e添加至元素末尾
```text
Vector::push_back<E>(v: &mut vector<E>, e: E);
```
4. pop 从元素末尾取出数据E
```text
Vector::pop_back<E>(v: &mut vector<E>): E;
```
5. 获取向量元素的可变引用,不可变引用可使用Vector::borrow()
```text
Vector::borrow_mut<E>(v: &mut vector<E>, i: u64): &E;
```
6.  获取向量元素的只读引用
```text
Vector::borrow<E>(v:  &vector<E>, i: u64): &E;
```
6. 添加元素到V1末尾
```text
Vector::append<T>(v1: &mut vector<T>, v2: vector<T>)
```
7. 在向量为空的情况下删除向量
```text
Vector::destroy_empty<T>(v: vector<T>)
```

示例
```text
use Std::Vector;

let v = Vector::empty<u64>();
Vector::push_back(&mut v, 5);
Vector::push_back(&mut v, 6);

assert!(*Vector::borrow(&v, 0) == 5, 42);
assert!(*Vector::borrow(&v, 1) == 6, 42);
assert!(Vector::pop_back(&mut v) == 6, 42);
assert!(Vector::pop_back(&mut v) == 5, 42);
```

示例 module + script
存储结构体数据的向量示例：
```text
module Shelf {

    use 0x1::Vector;

    struct Box<T> {
        value: T
    }

    struct Shelf<T> {
        boxes: vector<Box<T>>
    }

    public fun create_box<T>(value: T): Box<T> {
        Box { value }
    }

    // this method will be inaccessible for non-copyable contents
    public fun value<T: copy>(box: &Box<T>): T {
        *&box.value
    }

    public fun create<T>(): Shelf<T> {
        Shelf {
            boxes: Vector::empty<Box<T>>()
        }
    }

    // box value is moved to the vector
    public fun put<T>(shelf: &mut Shelf<T>, box: Box<T>) {
        Vector::push_back<Box<T>>(&mut shelf.boxes, box);
    }

    public fun remove<T>(shelf: &mut Shelf<T>): Box<T> {
        Vector::pop_back<Box<T>>(&mut shelf.boxes)
    }

    public fun size<T>(shelf: &Shelf<T>): u64 {
        Vector::length<Box<T>>(&shelf.boxes)
    }
}
```
脚本文件中使用：
```text
script {
    use {{sender}}::Shelf;

    fun main() {

        // create shelf and 2 boxes of type u64
        let shelf = Shelf::create<u64>();
        let box_1 = Shelf::create_box<u64>(99);
        let box_2 = Shelf::create_box<u64>(999);

        // put both boxes to shelf
        Shelf::put(&mut shelf, box_1);
        Shelf::put(&mut shelf, box_2);

        // prints size - 2
        0x1::Debug::print<u64>(&Shelf::size<u64>(&shelf));

        // then take one from shelf (last one pushed)
        let take_back = Shelf::remove(&mut shelf);
        let value     = Shelf::value<u64>(&take_back);

        // verify that the box we took back is one with 999
        assert(value == 999, 1);

        // and print size again - 1
        0x1::Debug::print<u64>(&Shelf::size<u64>(&shelf));
    }
}
```