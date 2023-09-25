## 锁仓合约
1. 指定拥有Coin的账户地址（注册并mint一部分初始资金）
2. 添加锁仓记录，记录中表明该条记录的中coin数量和recipient

resource的结构体：
```text
    struct Locks<phantom CoinType> has key {
        // Map from recipient address => locked coins.
        locks: Table<address, Lock<CoinType>>,
        // Predefined withdrawal address. This cannot be changed if there's any active lock.
        withdrawal_address: address,
        // Number of locks that have not yet been claimed.
        total_locks: u64,

        cancel_lockup_events: EventHandle<CancelLockupEvent>,
        claim_events: EventHandle<ClaimEvent>,
        update_lockup_events: EventHandle<UpdateLockupEvent>,
        update_withdrawal_address_events: EventHandle<UpdateWithdrawalAddressEvent>,
    }
```