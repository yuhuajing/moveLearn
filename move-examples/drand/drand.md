## 随机值选取彩票中奖人
- 付款账号：拥有coin转账的账户
- 普通用户：买彩票
- 中奖用户：中奖后，从付款账户转账一定金额到中奖用户

1. 根据drand轮次产生的随机值计算博彩合约中的概率
> https://api.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/info

公钥会对特定的轮次签名,用于判断当前轮次的随机值和签名的匹配状况
```text
        let pk = extract(&mut deserialize<G2, FormatG2Compr>(&DRAND_PUBKEY));
        let sig = extract(&mut deserialize<G1, FormatG1Compr>(&signature));
        let msg_hash = hash_to<G1, HashG1XmdSha256SswuRo>(&DRAND_DST, &round_number_to_bytes(round));
        assert!(eq(&pairing<G1, G2, Gt>(&msg_hash, &pk), &pairing<G1, G2, Gt>(&sig, &one<G2>())), 1);
```
本合约的示例使用加密签名的方式提供随机值，并非是drand网络的随机值
> https://api3.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/public/202
```text
        option::some(Randomness {
            bytes: sha3_256(signature)
        })
```

2. drand轮次的生成和校验都是严格通过绝对时间计算，因此项目方和随机值API两部分的时间应该保持一致，否则会造成数据校验不通过的问题。
```text
    /// Returns the next round `i` that `drand` will sign after having signed the round corresponding to the
    /// timestamp `unix_time_in_secs`.
    public fun next_round_after(unix_time_in_secs: u64): u64 {
        let (next_round, _) = next_round_and_timestamp_after(unix_time_in_secs);

        next_round
    }

    /// Returns the next round and its UNIX time (after the round at time `unix_time_in_secs`).
    /// (Round at time `GENESIS_TIMESTAMP` is round # 1. Round 0 is fixed.)
    public fun next_round_and_timestamp_after(unix_time_in_secs: u64): (u64, u64) {
        if(unix_time_in_secs < GENESIS_TIMESTAMP) {
            return (1, GENESIS_TIMESTAMP)
        };

        let duration = unix_time_in_secs - GENESIS_TIMESTAMP;

        // As described in https://github.com/drand/drand/blob/0678331f90c87329a001eca4031da8259f6d1d3d/chain/time.go#L57:
        //  > We take the time from genesis divided by the periods in seconds.
        //  > That gives us the number of periods since genesis.
        //  > We add +1 since we want the next round.
        //  > We also add +1 because round 1 starts at genesis time.

        let next_round = (duration / PERIOD_SECS) + 1;
        let next_time = GENESIS_TIMESTAMP + next_round * PERIOD_SECS;

        (next_round + 1, next_time)
    }
```

输出的test示例
```text
INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY MoveStdlib
BUILDING Drand lottery
Running Move unit tests
[debug] 0xa438d55a0a3aeff6c6b78ad40c2dfb55dae5154d86eeb8163138f2bf96294f90841e75ad952bf8101630da7bb527da21
[debug] 202
[debug] Some(0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::drand::Randomness {
  bytes: 0x2096bc08f2859922921def0e53804a5956e6b401eb04c2227656023e830db288
})
[debug] 0x346fc9ce2f4343c370746a5d24d3f21bb14a7c04ff3eabba622e90488e26be70
[debug] 0
[debug] "The winner is: "
[debug] @0xa001
[debug] 0xb0e64fd43f49f3cf20135e7133112c0ae461e6a7b2961ef474f716648a9ab5b67f606af2980944344de131ab970ccb5d
[debug] 602
[debug] Some(0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::drand::Randomness {
  bytes: 0x32b451c67abc305fa54c52cb3176b950f9ba1f0732f086fe21ec808737151300
})
[debug] 0xfc741ad4aace3a3b3a80487228224e7cc8f6b93424ad4a3b6867ecdc0a1d07fe
[debug] 0
[debug] "The winner is: "
[debug] @0xa001
[debug] 0x8a9b54d4790bcc1e0b8b3e452102bfc091d23ede4b488cb81580f37a52762a283ed8c8dd844f0a112fda3d768ec3f9a2
[debug] 1002
[debug] Some(0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::drand::Randomness {
  bytes: 0x9d7de5bc53aff2bcc658670d41cbb2e53fbf6a3a20b4627193fc6c44423df37f
})
[debug] 0xf3655b0b4b63d2a7d3a5f6f0a1fbbe13f21ea56221f82b1c93f330287f2b4ed9
[debug] 3
[debug] "The winner is: "
[debug] @0xa004
[debug] 0x8eaca04732b0de0c2a385f0ccaab9504592fcae7ca621bef58302d4ef0bd2ce3dd9c90153688dedd47efdbeb4d9ecde5
[debug] 1402
[debug] Some(0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::drand::Randomness {
  bytes: 0x7ce7ae1535c9106796565eee0d00dcc847c7c7815e34eb664ad961eb3a2d41cb
})
[debug] 0x6eedf54f28a0832ea4fa2528b1a2215a7cb8b1456aa85ca83ba06f2f13370838
[debug] 2
[debug] "The winner is: "
[debug] @0xa003
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::lottery::test_lottery
Test result: OK. Total tests: 1; passed: 1; failed: 0
{
  "Result": "Success"
}
```