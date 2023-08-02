address MyCoinAddr{
    module MyCoin{
        use std::signer;
        const MODULE_OWNER:address = @MyCoinAddr;
        const ENOT_OWNER:u64=0;
        const EINSUFFICIENT_BALANCE:u64=1;
        const EALREADLY_HAS_BALANCE:u64=2;
        const ACCOUNT_INITIALIZED:u64=3;

        struct Coin has store{
            value:u64
        }
        struct Balance has key{
            coin:Coin
        }

        public fun init_account(account: &signer) {
            let account_addr = signer::address_of(account);
            // TODO: add an assert to check that `account` doesn't already have a `Balance` resource.
            assert!(!exists<Balance>(account_addr), ACCOUNT_INITIALIZED);
            if(!exists<Balance>(account_addr)){
                move_to(account, Balance {coin: Coin {value: 0}});
            }
        }
        
        public fun mint(module_owner:&signer,mint_address:address,count:u64)acquires Balance{
            assert!(signer::address_of(module_owner)==MODULE_OWNER,ENOT_OWNER);
            deposit(mint_address,Coin{value:count});
        }

        fun deposit(_addr:address,check:Coin)acquires Balance{
            let balance = balance_of(_addr);
            let balance_ref = &mut borrow_global_mut<Balance>(_addr).coin.value;
            let Coin{value}=check;
            *balance_ref=balance+value;
        }

        public fun balance_of(_addr:address):u64 acquires Balance{
            borrow_global<Balance>(_addr).coin.value
        }

        public fun transfer(from :&signer, to:address,amount:u64)acquires Balance{
            let check = withdraw(signer::address_of(from),amount);
            deposit(to,check);
        }

        fun withdraw(addr:address,amount:u64):Coin acquires Balance{
            let balance = balance_of(addr);
            assert!(balance >= amount, EINSUFFICIENT_BALANCE);
            let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.value;
            *balance_ref=balance-amount;
            Coin{value:amount}
        }
    }
}