# tkey iOS SDK

The tKey SDK manages private keys by generating shares of it using Shamir Secret Sharing. Multi-party computation of shares is also planned for this SDK and is currently in an advanced stage of development but not quite ready to be merged into the main codebase yet.

The companion example application is [here](https://github.com/torusresearch/tkey-rust-ios-example/).

If you are instead seeking the Android implementation, please see [here](https://github.com/torusresearch/tkey-rust-android).

## Including this package

1. Open Xcode project > select File > Swift Packages > Add Package Dependency 

2. Enter the url https://github.com/torusresearch/tkey-rust-ios


## Integration with CustomAuth

This standalone package can be used with CustomAuth. Please refer to the example application for a more comprehensive overview of the code.

The integration process is simple:
1. Log in with CustomAuth, for detailed documentation on how to do this please refer to the documentation [here](https://github.com/torusresearch/customauth-swift-sdk).

2. Use the `userData["privateKey"]` field result as the postbox key when setting up the ServiceProvider.

3. Continue initialization as normal.

4. Remember to save the device share or the account will need to be reset. For existing accounts, shares will need to be imported, either by making use of a security share or via manual entry depending on how the ThresholdKey was initially setup.

## SDK Design Overview

The design of the SDK is relatively straight forward. 

* It makes use of the underlying libtkey.xcframework which contains arm64 and arm64-simulator binaries. 
* These binaries are built from a common cross-compilable codebase which is a native port of the original implementation of (tkey)[https://github.com/tkey/tkey]. 
* All marshalling of types across the foreign function interface as well as memory safety is handled by the SDK.

This SDK can be split into methods which are synchronous and methods which are asynchronous:
* Methods which are synchronous are expected to return immediately with no underlying network operations.
* Methods which are asyncronous are dispatched to a serial execution queue and perform network operations with the Metadata Server. The relevant network implementation is already supplied as part of the SDK.

All classes that are part of the modules namespace are static in nature and can only operate on a ThresholdKey object which has been properly setup.

Currently only the Secp256k1 curve is supported.

Please note that all code examples are minimilistic in nature, this is intentionally done for clarity, since most functions can throw.

## SDK Overview

### ThresholdKey

The instance of tkey, this can be considered the most important object in the SDK. 

##### Creation

To create a ThresholdKey object at minimum a StorageLayer is required, however it is more practical to use a ServiceProvider as well.

```swift
    let postbox = try! PrivateKey.generate()
    let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
    let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox.hex)
    let threshold_key = try! ThresholdKey(
        storage_layer: storage_layer,
        service_provider: service_provider,
        enable_logging: true,
        manual_sync: false)
```

#### Initiation

Once you have created a ThresholdKey object, it can then be initialized.

A KeyDetails object is returned from the initialization call.

```swift
    let key_details = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
```

Additionally the following optional parameters can be supplied to this call
| Parameter | Type | Description |
| --------- | ---- | ----------- |
| import_share | String | Initialise tkey with an existing share. This allows you to directly initialise tKey without using the service provider login. |
| input | ShareStore | Import an existing ShareStore into tkey. | 

#### Reconstructing the Private Key

Once the required number of shares are available to the ThresholdKey object or existing shares have been inserted into it, the private key can then be reconstructed.

This method returns a KeyReconstructionResult.

```swift
    let reconstructedKeyResult = try! await threshold_key.reconstruct()
```

#### Getting the key details.

```swift
    let key_details = try! threshold_key.get_key_details()
```

This returns a KeyDetails object.

Whenever a method is called which affects the state of the ThresholdKey, this method will need to be called again if updated details of the ThresholdKey is needed.


#### Generating a new Share

Shares are generated on the same threshold (e.g, 2/3 -> 2/4). A GenerateShareStoreResult object is returned by the function. 

```swift
   let newShare = try! await threshold_key.generate_new_share()
```

#### Deleting a Share

Shares can be deleted by their share index. Note that deleting a share will invaidate any persisted share.

```swift
    let shareStore = try! await threshold_key.delete_share(share_index: idx)
```

### Modules for additonal functionality

For more advanced operations on a ThresholdKey object, you can make use of the provided modules.

#### PrivateKeysModule

This module provides an interface for setting, getting and managing private keys for a ThresholdKey object.

#### SecurityQuestionModule

This module allows the creation of a security share with a password. This is particularly useful to recover a ThresholdKey 

#### SeedPhraseModule

This module provides functionality for setting, changing, getting, and deleting seed phrases for a ThresholdKey object.

#### ShareSerializationModule

The ShareSerializationModule allows the serialization and deserialization of shares between mnemonic and hex formats.

#### ShareTransferModule

The ShareTransferModule is used to transfering an existing share to another device.
