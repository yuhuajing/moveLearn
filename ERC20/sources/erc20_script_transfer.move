// sources/Main.move
script {

    use MyCoinAddr::MyCoin;
    use std::signer;
    use std::debug;

    fun main(account: signer, mint_addr: signer) {
        MyCoin::transfer(&mint_addr, signer::address_of(&account), 10);
        // balance
        let accountBalance = MyCoin::balance_of(signer::address_of(&account));
        debug::print(&accountBalance);
        let mintNewBalance = MyCoin::balance_of(signer::address_of(&mint_addr));
        debug::print(&mintNewBalance);
    }
}
