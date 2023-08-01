# resource合约示例
合约功能
1. 创建一个集合（vector）
2. 集合中添加、取出元素
3. 回收集合
## 创建模块

```text
// modules/Collection.move
module Collection {

    use 0x1::Vector;

//内部定义具体的合约变量值

    struct Item has store {}

//resource资源，默认和模块同名

    struct Collection has key,store {
        items: vector<Item>
    }

//Resource 将永久保存在发送者的地址下，没有人可以从所有者那里修改或取走此Resource

    public fun start_collection(account: &signer) {
        move_to<Collection>(account, Collection {
            items: Vector::empty<Collection>()
        })
    }
    
    /// this function will check if resource exists at address
    public fun exists_at(at: address): bool {
        exists<Collection>(at)
    }
}
```
1. 采用内置函数 ```native fun move_to<T: key>(account: &signer, value: T);```将resource资源移动到特定的account。只能将resource放置在自己的账户中，因为无权访问另一个账户的```signer```值。同一个账户只能存储一个同类型的resource，通过内置的```native fun exists<T: key>(addr: address): bool;```判断该账户是否存在resource资源。

## 读取和修改模块
move内置```native fun borrow_global<T: key>(addr: address): &T;```和```native fun borrow_global_mut<T: key>(addr: address): &mut T;```用来表示只读```&```和读写```&mut```

```text
// modules/Collection.move
module Collection {
    /// get collection size
    /// mind keyword acquires!
    public fun size(account: &signer): u64 acquires Collection {
        let owner = Signer::address_of(account);
        let collection = borrow_global<Collection>(owner);

        Vector::length(&collection.items)
    }

    public fun add_item(account: &signer) acquires T {
        let collection = borrow_global_mut<Collection>(Signer::address_of(account));

        Vector::push_back(&mut collection.items, Item {});
    }
}
```
## 回收resource
通过```native fun move_from<T: key>(addr: address): T;```从账户中取出resource资源，Resource 必须被使用。因此，从账户下取出 Resource 时，要么将其作为返回值传递，要么将其销毁。但是即使将此 Resource 传递到外部并在脚本中获取，接下来能做的操作也非常有限。因为脚本上下文不允许对结构体或 Resource 做任何事情，除非 Resource 模块中定义了操作 Resource 公开方法，否则只能将其传递到其它地方。这就要求在设计模块时，为用户提供操作 Resource 的函数。
```text
address 0xA1 {
module Collection {

    use 0x1::Vector;
    use 0x1::Signer;

    struct Item has store, drop {}

    struct Collection has key {
        items: vector<Item>
    }

    public fun start_collection(account: &signer) {
        move_to<Collection>(account, Collection {
            items: Vector::empty<Item>()
        });
    }

    public fun size(account: &signer): u64 acquires Collection {
        let owner = Signer::address_of(account);
        let collection = borrow_global<Collection>(owner);

        Vector::length(&collection.items)
    }

    public fun put_item(account: &signer) acquires Collection {
        let collection = borrow_global_mut<Collection>(Signer::address_of(account));

        Vector::push_back(&mut collection.items, Item {});
    }

    public fun exists_at(at: address): bool {
        exists<Collection>(at)
    }

    public fun destroy(account: &signer) acquires Collection {

        // account no longer has resource attached
        let collection = move_from<Collection>(Signer::address_of(account));

        // now we must use resource value - we'll destructure it
        let Collection { items: _ } = collection;
    }
}
}
```