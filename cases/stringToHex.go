package main

import (
	"encoding/hex"
	"fmt"
)

func main() {
	str := "Hello, World!"
	hexStr := hex.EncodeToString([]byte(str))
	fmt.Println(hexStr)
}
