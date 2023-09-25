A framework for sharing a single resource account across multiple accounts.

1. 部署资源的账号A，根据A账号生成的资源账号IA，其余账号B
2. A生成资源账号IA,IA的management结构体中A为管理员，动态Vector为待授权的账号地址
3. A作为管理员，能够添加账户地址到资源账号的动态数组，或者从资源账号的动态数组中删除账号/或者删除已授权的账号
4. B作为待授权的账号，可以申请对资源账号的调用权限

```text
INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY MoveStdlib
BUILDING CommonAccount
Running Move unit tests
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_account_no_capability
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_account_revoke_acl
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_account_revoke_capability
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_account_revoke_none
[debug] @0xa11c3
[debug] @0xb0b
[debug] @0xc3f1d3b25e0bfeb2040d599858bdb580bdd92ca508a0ffe6b0c23692715403d3
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_end_to_end
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_no_account_capability
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_no_account_signer
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_wrong_admin
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::common_account::test_wrong_cap
Test result: OK. Total tests: 9; passed: 9; failed: 0
{
  "Result": "Success"
}
```