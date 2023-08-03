# 单元测试

Move单元测试通过三类注释实现：
* #[test] || #[test(arg = @0xC0FFEE)] ，表明函数处于测试
* #[test_only] 表明定义的模块、结构体、表达式、函数等只能在test中使用
* #[expected_failure] || #[expected_failure(abort_code = <u64>)] 预计测试会引发错误

1. 其中，单元测试的标注放置在具有任何可见性的函数上方，表明该函数用于测试，并且函数不会被编译到字节码中。
2. 测试标识符和函数保持一致，对于参数，测试注释采用 的形式`#[test(<param_name_1> = <address>, ..., <param_name_n> = <address>)]`。如果以这种方式注释函数，则该函数的参数必须是参数 `<param_name_1>, ..., <param_name_n>`，即这些参数在函数中出现的顺序与它们在测试注释中的顺序不必相同，但它们必须能够通过名称相互匹配。

```text
#[test]
#[expected_failure]
public fun this_test_will_abort_and_pass() { abort 1 }

#[test]
#[expected_failure]
public fun test_will_error_and_pass() { 1/0; }

#[test]
#[expected_failure(abort_code = 0)]
public fun test_will_error_and_fail() { 1/0; }

#[test, expected_failure] // Can have multiple in one attribute. This test will pass.
public(script) fun this_other_test_will_abort_and_pass() { abort 1 }

#[test, expected_failure(abort_code = 1)] // This test will fail
fun this_test_should_abort_and_fail() { abort 0 }

#[test]
#[expected_failure(abort_code = 0)] // This test will pass
fun this_test_should_abort_and_pass_too() { abort 0 }

#[test(a = @0xC0FFEE, b = @0xCAFE)] // OK. We support multiple signer arguments, but you must always provide a value for that argument
fun this_works(a: signer, b: signer) { ... }

// somewhere a named address is declared
#[test_only] // test-only named addresses are supported
address TEST_NAMED_ADDR = @0x1;
...
#[test(arg = @TEST_NAMED_ADDR)] // Named addresses are supported!
fun this_is_correct_now(arg: signer) { ... }
```

示例
```text
// filename: sources/MyModule.move
module 0x1::MyModule {

    struct MyCoin has key { value: u64 }

    public fun make_sure_non_zero_coin(coin: MyCoin): MyCoin {
        assert!(coin.value > 0, 0);
        coin
    }

    public fun has_coin(addr: address): bool {
        exists<MyCoin>(addr)
    }

    #[test]
    fun make_sure_non_zero_coin_passes() {
        let coin = MyCoin { value: 1 };
        let MyCoin { value: _ } = make_sure_non_zero_coin(coin);
    }

    #[test]
    // Or #[expected_failure] if we don't care about the abort code
    #[expected_failure(abort_code = 0)]
    fun make_sure_zero_coin_fails() {
        let coin = MyCoin { value: 0 };
        let MyCoin { value: _ } = make_sure_non_zero_coin(coin);
    }

    #[test_only] // test only helper function
    fun publish_coin(account: &signer) {
        move_to(account, MyCoin { value: 1 })
    }

    #[test(a = @0x1, b = @0x2)]
    fun test_has_coin(a: signer, b: signer) {
        publish_coin(&a);
        publish_coin(&b);
        assert!(has_coin(@0x1), 0);
        assert!(has_coin(@0x2), 1);
        assert!(!has_coin(@0x3), 1);
    }
}
```
测试命令
> move package test

* `-f <str>或者--filter <str>` 用于测试包含特定字符串的测试
```text
$ move package test -f zero_coin
CACHED MoveStdlib
BUILDING TestExample
Running Move unit tests
[ PASS    ] 0x1::MyModule::make_sure_non_zero_coin_passes
[ PASS    ] 0x1::MyModule::make_sure_zero_coin_fails
Test result: OK. Total tests: 2; passed: 2; failed: 0
```
* `-s或者--statistics` 展示测试的统计信息，报告每个测试的运行时和执行的指令。
```text
$ move package test -s
CACHED MoveStdlib
BUILDING TestExample
Running Move unit tests
[ PASS    ] 0x1::MyModule::make_sure_non_zero_coin_passes
[ PASS    ] 0x1::MyModule::make_sure_zero_coin_fails
[ PASS    ] 0x1::MyModule::test_has_coin

Test Statistics:

┌───────────────────────────────────────────────┬────────────┬───────────────────────────┐
│                   Test Name                   │    Time    │   Instructions Executed   │
├───────────────────────────────────────────────┼────────────┼───────────────────────────┤
│ 0x1::MyModule::make_sure_non_zero_coin_passes │   0.009    │             1             │
├───────────────────────────────────────────────┼────────────┼───────────────────────────┤
│ 0x1::MyModule::make_sure_zero_coin_fails      │   0.008    │             1             │
├───────────────────────────────────────────────┼────────────┼───────────────────────────┤
│ 0x1::MyModule::test_has_coin                  │   0.008    │             1             │
└───────────────────────────────────────────────┴────────────┴───────────────────────────┘

Test result: OK. Total tests: 3; passed: 3; failed: 0
```
* `-g或者--state-on-error`
测试案例
```text
module 0x1::MyModule {
    ...
    #[test(a = @0x1)]
    fun test_has_coin_bad(a: signer) {
        publish_coin(&a);
        assert!(has_coin(@0x1), 0);
        assert!(has_coin(@0x2), 1);
    }
}
```
输出
```text
$ move package test -g
CACHED MoveStdlib
BUILDING TestExample
Running Move unit tests
[ PASS    ] 0x1::MyModule::make_sure_non_zero_coin_passes
[ PASS    ] 0x1::MyModule::make_sure_zero_coin_fails
[ PASS    ] 0x1::MyModule::test_has_coin
[ FAIL    ] 0x1::MyModule::test_has_coin_bad

Test failures:

Failures in 0x1::MyModule:

┌── test_has_coin_bad ──────
│ error[E11001]: test failure
│    ┌─ /home/tzakian/TestExample/sources/MyModule.move:47:10
│    │
│ 44 │      fun test_has_coin_bad(a: signer) {
│    │          ----------------- In this function in 0x1::MyModule
│    ·
│ 47 │          assert!(has_coin(@0x2), 1);
│    │          ^^^^^^^^^^^^^^^^^^^^^^^^^^ Test was not expected to abort but it aborted with 1 here
│
│
│ ────── Storage state at point of failure ──────
│ 0x1:
│       => key 0x1::MyModule::MyCoin {
│           value: 1
│       }
│
└──────────────────

Test result: FAILED. Total tests: 4; passed: 3; failed: 1
```