module AniDeployer::AnimeCoin {
    use std::signer;
    use std::string::utf8;
    use std::event;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin, MintCapability, FreezeCapability, BurnCapability};

    /// When user not register ANI.
    const ERR_ANI_NOT_REGISTERED: u64 = 101;
    /// When user has no unlocked amount.
    const ERR_NO_UNLOCKED: u64 = 102;
    /// When user is not admin.
    const ERR_FORBIDDEN: u64 = 103;

    const DEPLOYER: address = @AniDeployer;
    const RESOURCE_ACCOUNT_ADDRESS: address = @AniResourceAccount;
    const TEAM_ADDRESS: address = @AniDeployer;

    /// ANI coin
    struct ANI {}

    /// locked ANI
    struct LockedANI has key {
        coins: Coin<ANI>,
        vec : vector<LockedItem>,
    }

    struct LockedItem has key, store, drop {
        amount: u64,
        owner: address,
        unlock_timestamp: u64,
    }

    struct Caps has key {
        admin_address: address, // admin address, control direct mint ANI and other setting
        staking_address: address,   // staking address (masterchef resource address), which can also mint ANI
        direct_mint: bool,
        mint: MintCapability<ANI>,
        freeze: FreezeCapability<ANI>,
        burn: BurnCapability<ANI>,
        mint_event: event::EventHandle<MintBurnEvent>,
        burn_event: event::EventHandle<MintBurnEvent>,
    }

    struct MintBurnEvent has drop, store {
        value: u64,
    }

    /**
     * ANI mint & burn
     */

    /// Direct mint ANI. Admin address only.
    public entry fun mint_ANI(
        admin: &signer,
        amount: u64,
        to: address
    ) acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        assert!(caps.direct_mint, ERR_FORBIDDEN);
        let coins = coin::mint<ANI>(amount, &caps.mint);
        coin::deposit(to, coins);
        event::emit_event(&mut caps.mint_event, MintBurnEvent {
            value: amount,
        });
    }

    /// Mint ANI. Staking address only.
    public fun staking_mint_ANI(
        account: &signer,
        amount: u64,
    ): Coin<ANI> acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        assert!(signer::address_of(account) == caps.staking_address, ERR_FORBIDDEN);
        let coins = coin::mint<ANI>(amount, &caps.mint);
        coins
    }

    /// Burn ANI from account amount.
    public entry fun burn_ANI(
        account: &signer,
        amount: u64
    ) acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        let coins = coin::withdraw<ANI>(account, amount);
        coin::burn(coins, &caps.burn);
        event::emit_event(&mut caps.burn_event, MintBurnEvent {
            value: amount,
        });
    }

    /// Burn ANI coins
    public fun burn_ANI_coin(
        coins: Coin<ANI>,
    ) acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        let amount = coin::value(&coins);
        coin::burn(coins, &caps.burn);
        event::emit_event(&mut caps.burn_event, MintBurnEvent {
            value: amount,
        });
    }

    /// Mint ANI with a lock period.
    public entry fun mint_lock_ANI(
        admin: &signer,
        to: address,
        amount: u64,
        days_to_unlock: u64,
    ) acquires Caps, LockedANI {
        assert!(days_to_unlock >= 1, ERR_FORBIDDEN);
        let admin_addr = signer::address_of(admin);
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        assert!(admin_addr == caps.admin_address, ERR_FORBIDDEN);
        let locked_ANI = borrow_global_mut<LockedANI>(DEPLOYER);
        let coins = coin::mint<ANI>(amount, &caps.mint);
        coin::merge(&mut locked_ANI.coins, coins);
        vector::push_back(&mut locked_ANI.vec, LockedItem {
            amount: amount,
            owner: to,
            unlock_timestamp: timestamp::now_seconds() + days_to_unlock * 86400,
        });
        event::emit_event(&mut caps.mint_event, MintBurnEvent {
            value: amount,
        });
    }

    // Withdraw unlocked ANI.
    public entry fun withdraw_unlocked_ANI(
        account: &signer,
    ) acquires LockedANI {
        let acc_addr = signer::address_of(account);
        assert!(coin::is_account_registered<ANI>(acc_addr), ERR_ANI_NOT_REGISTERED);
        let locked_ANI = borrow_global_mut<LockedANI>(DEPLOYER);
        let index = 0;
        let is_succ = false;
        let now = timestamp::now_seconds();
        while (index < vector::length(&locked_ANI.vec)) {
            let item = vector::borrow_mut(&mut locked_ANI.vec, index);
            if (item.owner == acc_addr && item.unlock_timestamp <= now) {
                // find an unlocked item
                let coins = coin::extract(&mut locked_ANI.coins, item.amount);
                coin::deposit<ANI>(acc_addr, coins);
                let _removed_item = vector::swap_remove(&mut locked_ANI.vec, index);
                is_succ = true;
            } else {
                index = index + 1;
            }
        };
        assert!(is_succ, ERR_NO_UNLOCKED);
    }

    /// initialize
    fun init_module(admin: &signer) acquires Caps, LockedANI {
        // init ANI Coin
        let (coin_b, coin_f, coin_m) =
            coin::initialize<ANI>(admin, utf8(b"AnimeSwap Coin"), utf8(b"ANI"), 8, true);
        move_to(admin, Caps {
            admin_address: DEPLOYER,
            staking_address: RESOURCE_ACCOUNT_ADDRESS,
            direct_mint: true,
            mint: coin_m,
            freeze: coin_f,
            burn: coin_b,
            mint_event: account::new_event_handle<MintBurnEvent>(admin),
            burn_event: account::new_event_handle<MintBurnEvent>(admin),
        });
        coin::register<ANI>(admin);
        move_to(admin, LockedANI {
            coins: coin::zero<ANI>(),
            vec: vector::empty(),
        });
        team_emission(admin);
    }

    /// AnimeSwap Labs emission
    fun team_emission(admin: &signer) acquires Caps, LockedANI {
        let count = 1;
        while (count <= 16) {
            mint_lock_ANI(admin, TEAM_ADDRESS, 50000000000000, count * 90);
            count = count + 1;
        };
    }

    /// user should call this first, for approve ANI
    public entry fun register_ANI(account: &signer) {
        coin::register<ANI>(account);
    }

    /// Set admin address
    public entry fun set_admin_address(
        admin: &signer,
        new_admin_address: address,
    ) acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        caps.admin_address = new_admin_address;
    }

    /// Set staking address
    public entry fun set_staking_address(
        admin: &signer,
        new_staking_address: address,
    ) acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        caps.staking_address = new_staking_address;
    }

    /// After call this, direct mint will be disabled forever
    public entry fun set_disable_direct_mint(
        admin: &signer
    ) acquires Caps {
        let caps = borrow_global_mut<Caps>(DEPLOYER);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        caps.direct_mint = false;
    }

    #[test_only]
    use aptos_framework::genesis;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    const TEST_ERROR:u64 = 10000;

    #[test_only]
    public fun test_init_module(admin: &signer) acquires Caps, LockedANI {
        init_module(admin);
    }

    #[test_only]
    fun test_init(creator: &signer, someone: &signer) acquires Caps, LockedANI {
        genesis::setup();
        create_account_for_test(signer::address_of(creator));
        create_account_for_test(signer::address_of(someone));
        init_module(creator);
        register_ANI(someone);
    }

    #[test(creator = @AniDeployer, someone = @0x11)]
    fun test_lock_mint(creator: &signer, someone: &signer) acquires Caps, LockedANI {
        test_init(creator, someone);

        mint_lock_ANI(creator, signer::address_of(someone), 100000000, 1);
        mint_lock_ANI(creator, signer::address_of(creator), 100000000, 1);
        mint_lock_ANI(creator, signer::address_of(someone), 100000000, 1);

        // 1 day pass
        timestamp::fast_forward_seconds(86400);
        withdraw_unlocked_ANI(someone);
        assert!(coin::balance<ANI>(signer::address_of(someone)) == 200000000, TEST_ERROR);
    }

    #[test(creator = @AniDeployer, someone = @0x11)]
    #[expected_failure(abort_code = 102)]
    fun test_lock_mint_error(creator: &signer, someone: &signer) acquires Caps, LockedANI {
        test_init(creator, someone);

        mint_lock_ANI(creator, signer::address_of(someone), 100000000, 1);
        mint_lock_ANI(creator, signer::address_of(creator), 100000000, 1);
        mint_lock_ANI(creator, signer::address_of(someone), 100000000, 1);

        // less than 1 day pass
        timestamp::fast_forward_seconds(86300);
        withdraw_unlocked_ANI(someone);
    }
}