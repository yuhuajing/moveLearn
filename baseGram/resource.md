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

## acquire
acquires关键字```fun <name>(<args...>): <ret_type> acquires T, T1 ... {}```，用于标记在函数调用期间，该函数将获取对某些资源（Resource）的所有权。资源是Move语言中的一种特殊类型，代表一些数据结构或资产，其所有权具有严格的借用规则。使用acquires关键字可以明确地指示一个函数在执行期间会获取特定资源的所有权,确保了资源在合约执行期间的正确管理，避免了资源泄漏和数据竞争等问题.

1. 表明资源所有权转移： 当一个函数在其参数列表中使用acquires关键字来标记某个资源，它表明在函数调用期间，该函数将获取对该资源的所有权。这意味着在函数执行期间，调用者不再拥有该资源，并且只有函数内部可以使用该资源。
2. 编译时借用检查： 使用acquires关键字有助于进行资源借用检查。Move语言的设计目标之一是确保资源的安全性和正确性。通过在函数签名中指定acquires，编译器可以对资源所有权进行静态检查，确保函数在使用资源时符合资源借用规则，防止资源的多重所有权或悬空指针等错误。
