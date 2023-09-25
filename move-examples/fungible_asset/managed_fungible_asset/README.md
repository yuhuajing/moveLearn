1. 首先定义资产owner的resources，定义owner对资产的权限（mint/transfer/burn）

The Init signer拥有resource结构体资源，内部定义权限并记录每条权限的owner

```text
    struct ManagingRefs has key {
        mint_ref: Option<MintRef>,
        transfer_ref: Option<TransferRef>,
        burn_ref: Option<BurnRef>,
    }

            // Optionally create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = if (*vector::borrow(&ref_flags, 0)) {
            option::some(fungible_asset::generate_mint_ref(constructor_ref)) //signer address and coin symbol
        } else {
            option::none()
        };
        let transfer_ref = if (*vector::borrow(&ref_flags, 1)) {
            option::some(fungible_asset::generate_transfer_ref(constructor_ref))
        } else {
            option::none()
        };
        let burn_ref = if (*vector::borrow(&ref_flags, 2)) {
            option::some(fungible_asset::generate_burn_ref(constructor_ref))
        } else {
            option::none()
        };
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagingRefs { mint_ref, transfer_ref, burn_ref }
        )
```

ERC20元数据
```text
    struct Metadata has key {
        /// Name of the fungible metadata, i.e., "USDT".
        name: String,
        /// Symbol of the fungible metadata, usually a shorter version of the name.
        /// For example, Singapore Dollar is SGD.
        symbol: String,
        /// Number of decimals used for display purposes.
        /// For example, if `decimals` equals `2`, a balance of `505` coins should
        /// be displayed to a user as `5.05` (`505 / 10 ** 2`).
        decimals: u8,
        /// The Uniform Resource Identifier (uri) pointing to an image that can be used as the icon for this fungible
        /// asset.
        icon_uri: String,
        /// The Uniform Resource Identifier (uri) pointing to the website for the fungible asset.
        project_uri: String,
    }
```
默认值：
```text
    const MAX_NAME_LENGTH: u64 = 32;
    const MAX_SYMBOL_LENGTH: u64 = 10;
    const MAX_DECIMALS: u8 = 32;
    const MAX_URI_LENGTH: u64 = 512;
```

2. 
```text
root@DESKTOP-UUE34HN:/data/aptos-core/aptos-move/move-examples/fungible_asset/managed_fungible_asset# aptos move test
INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY AptosTokenObjects
INCLUDING DEPENDENCY MoveStdlib
BUILDING ManagedFungibleAsset
Running Move unit tests
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::coin_example::test_basic_flow
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::managed_fungible_asset::test_basic_flow
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::coin_example::test_permission_denied
[ PASS    ] 0x91a7e539806ff68caf1bcba305c8f694182898949c581586b4c9676e6bf35392::managed_fungible_asset::test_permission_denied
Test result: OK. Total tests: 4; passed: 4; failed: 0
{
  "Result": "Success"
}
```