# 可编程resources
1. resoruce 结构体的定义需要在特定的账户地址下定义，因此，只有在分配账户地址后，才能定义resource结构体以及通过该账户才能访问内部资源。
2. 一个账户同一时刻只能容纳一个某类型的resource
3. resource是拥有 key 和 store 两种权限的结构体，无法被复制、丢弃和重用，但是可以存储和转移。
4. resource必须被使用，当资源被赋值转移时必须被解构或存储在另一个账户中
5. resource 只能由定义该类型的模块创建或销毁，以上检查由Move虚拟机通过字节码校验执行

```text
module M {
    struct T has key, store {
        field: u8
    }
}
```

## signer Type
1. signer 只具备drop权限，代表了发送者权限，用于表示交易发送者的地址。使用signer表示可以访问发送者的地址和其内部定义的resource资源。

模块库中的signer定义
```text
module Signer {
    native public fun borrow_address(s: &signer): &address;

    public fun address_of(s: &signer): address {
        *borrow_address(s)
    }
}
```
脚本文件的使用示例：
```text
script {
    fun main(account: signer) {
        let _ : address = 0x1::Signer::address_of(&account);
    }
}
```
引入signer类型的原因之一是要明确显示哪些函数需要发送者权限，哪些不需要。因此，函数不能欺骗用户未经授权访问其 Resource。