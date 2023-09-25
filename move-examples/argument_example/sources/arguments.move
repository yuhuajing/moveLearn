module deploy_address::number {
    use std::error;
    use std::signer;
    use std::vector;
    use std::debug;
    // use aptos_framework::account;

//:!:>resource
    struct NumberHolder has key {
        u8: u8,
        u16: u16,
        u32: u32,
        u64: u64,
        u128: u128,
        u256: u256,
        vec_u256: vector<u256>,
    }
//<:!:resource

    /// There is no holder present
    const ENOT_INITIALIZED: u64 = 0;

    #[view]
    public fun get_number(addr: address): (u8, u16, u32, u64, u128, u256, vector<u256>) acquires NumberHolder {
        assert!(exists<NumberHolder>(addr), error::not_found(ENOT_INITIALIZED));
        let holder = borrow_global<NumberHolder>(addr);

        (holder.u8, holder.u16, holder.u32, holder.u64,holder.u128, holder.u256, holder.vec_u256)
    }

    public entry fun set_number(
        account: &signer,
        u8: u8,
        u16: u16,
        u32: u32,
        u64: u64,
        u128: u128,
        u256: u256,
        vec_u256: vector<u256>)
    acquires NumberHolder {
        let account_addr = signer::address_of(account);
        if (!exists<NumberHolder>(account_addr)) {
            move_to(account, NumberHolder {
                u8,
                u16,
                u32,
                u64,
                u128,
                u256,
                vec_u256,
            })
        } else {
            let old_holder = borrow_global_mut<NumberHolder>(account_addr);
            old_holder.u8 = u8;
            old_holder.u16 = u16;
            old_holder.u32 = u32;
            old_holder.u64 = u64;
            old_holder.u128 = u128;
            old_holder.u256 = u256;
            old_holder.vec_u256 = vec_u256;
        }
    }

    #[test(account=@0x1)]
    public entry fun test_set_get_number(account: signer) acquires NumberHolder{
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        set_number(&account,1u8,2u16,3u32,4u64,5u128,6u256,vector::empty<u256>());
        let (u8value, _, _, u64value, _, _, _) = get_number(addr);
        debug::print(&u8value);
        debug::print(&u64value);
    }
}
