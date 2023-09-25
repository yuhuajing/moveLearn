> aptos move test
```text
warning: unused alias
  ┌─ /data/aptos-core/aptos-move/move-examples/hello_blockchain/sources/hello_blockchain.move:5:14
  │
5 │     use std::debug;
  │              ^^^^^ Unused 'use' of alias 'debug'. Consider removing it

INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY MoveStdlib
BUILDING Examples
Running Move unit tests
[debug] "Hello, Blockchain"
[debug] "Hello, Blockchain again!!"
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::message::sender_can_set_message
Test result: OK. Total tests: 1; passed: 1; failed: 0
{
  "Result": "Success"
}
```
> aptos move publish
```text
Compiling, may take a little while to download git dependencies...
INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY MoveStdlib
BUILDING Examples
package size 1805 bytes
Do you want to submit a transaction for a range of [143200 - 214800] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
{
  "Result": {
    "transaction_hash": "0xe3f32985acfdcdc4d9f7e139f91d1817aefff9d90a229ea5867d77bf88320ebe",
    "gas_used": 1432,
    "gas_unit_price": 100,
    "sender": "91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392",
    "sequence_number": 0,
    "success": true,
    "timestamp_us": 1691133032510636,
    "version": 396455,
    "vm_status": "Executed successfully"
  }
}
```

## 脚本
```text
script{
    use hello_blockchain::message;
    use std::debug;
    use std::string;
    use std::signer;

    fun main(account: signer){
        message::set_message(&account, string::utf8(b"Hello, Blockchain"));
        let str = message::get_message(signer::address_of(&account));
        debug::print(&str);
        message::set_message(&account, string::utf8(b"Hello, Blockchain again"));
        let str2 = message::get_message(signer::address_of(&account));
        debug::print(&str2);
    }
}
```