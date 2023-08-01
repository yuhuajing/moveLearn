# 集合
```Vector```集合提供动态、可扩展和可管理的功能，用于存储数据集合的内置类型，集合的数据可以是任意一种（仅一种）。向量可以存储大量数据，并且在索引的存储中使用。Vector 最多可以存储 18446744073709551615 u64（2^(64)-1）个非引用类型的值
```text
script {
    use 0x1::Vector;

    fun main() {
        // use generics to create an emtpy vector
        let a = Vector::empty<&u8>();
        let i = 0;

        // let's fill it with data
        while (i < 10) {
            Vector::push_back(&mut a, i);
            i = i + 1;
        }

        // now print vector length
        let a_len = Vector::length(&a);
        0x1::Debug::print<u64>(&a_len);

        // then remove 2 elements from it
        Vector::pop_back(&mut a);
        Vector::pop_back(&mut a);

        // and print length again
        let a_len = Vector::length(&a);
        0x1::Debug::print<u64>(&a_len);
    }
}
```

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