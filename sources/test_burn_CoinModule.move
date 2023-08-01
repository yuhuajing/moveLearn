script{
    use 0x2::Coin;
    use Std::Debug;
    fun main(){
        let coin = Coin:mint(100);
        Debug::print(&Coin::value(&coin));
        Coin::burn(&coin);
    }
}