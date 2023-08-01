address 0x1{
    module HelloWorld{
        public fun gimme_five():u8{
            5
        }
    }
}

address 0x2{
module Shelf{
use 0x1::Vector;
struct Box<T>{
    value:T;
}
struct Shelf<T>{
    boxes:vector<Box<T>>
}

public fun create_box<T>(value:T):Box<T>{
    Box{value}
}
public fun create<T>():Shelf<T>{
    Shelf{boxes:Vector::empty<Box<T>>()}
}


}
}



