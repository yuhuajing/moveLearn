address 0x2 {
    module Coin{
        struct Coin has copy,drop{
            value:u64;
        }
        public fun mint(value:u64):Coin{
            Coin{value}
        }
        public fun value(coin &Coin):u64{
            *&coin.value
        }
        public fun burn(coin &coin){
            let Coin{value:_}=coin;
        }
    }
}