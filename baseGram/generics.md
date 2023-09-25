# 泛型
通过泛型定义结构体、函数，实现和参数无关的通用的定义。
```text
module Storage {
    struct Box<T> {
        value: T
    }
}
```
结构体的权限和泛型内部参数的权限应保持一致，参数的ability通过```+```定义：
```text
struct Box<T: copy + drop> has copy, drop {
    contents: T
}
```

## 泛型示例
```text
module Storage {
    struct Box<T> {
        value: T
    }

    public fun create_box<T>(value: T): Box<T> {
        Box<T> { value }
    }

    // we'll get to this a bit later, trust me
    public fun value<T: copy>(box: &Box<T>): T {
        *&box.value
    }
}
```
```text
script {
    use {{sender}}::Storage;
    use 0x1::Debug;

    fun main() {
        // value will be of type Storage::Box<bool>
        let bool_box = Storage::create_box<bool>(true);
        let bool_val = Storage::value(&bool_box);

        assert(bool_val, 0);

        // we can do the same with integer
        let u64_box = Storage::create_box<u64>(1000000);

        let u64_box_in_box = Storage::create_box<Storage::Box<u64>>(u64_box);

        let value: u64 = Storage::value<u64>(
            &Storage::value<Storage::Box<u64>>( // Box<u64> type
                &u64_box_in_box // Box<Box<u64>> type
            )
        );

        Debug::print<u64>(&value);
    }
}
```

## 未使用的类型参数
并非泛型中指定的每种类型参数都必须被使用
```text
module Storage {

    // these two types will be used to mark
    // where box will be sent when it's taken from shelf
    struct Abroad {}
    struct Local {}

    // modified Box will have target property
    struct Box<T, Destination> {
        value: T
    }

    public fun create_box<T, Dest>(value: T): Box<T, Dest> {
        Box { value }
    }
}
```
脚本文件的使用
```text

script {
    use {{sender}}::Storage;

    fun main() {
        // value will be of type Storage::Box<bool>
        let _ = Storage::create_box<bool, Storage::Abroad>(true);
        let _ = Storage::create_box<u64, Storage::Abroad>(1000);

        let _ = Storage::create_box<u128, Storage::Local>(1000);
        let _ = Storage::create_box<address, Storage::Local>(0x1);

        // or even u64 destination!
        let _ = Storage::create_box<address, u64>(0x1);
    }
}
```