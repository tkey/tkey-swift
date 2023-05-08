# Tkey ios documentation

# install

1. open Xcode project > select File > Swift Packages > Add Package Dependency 

2. Enter the url https://github.com/torusresearch/tkey-rust-ios


# Initialize Web3auth CoreKit (tkey iOS) SDK

After installation, the next step to using Web3Auth CoreKit SDK is to Initialize the SDK. The Initialization takes a few steps, including initiating the tKey SDK with the service provider and modules.

## Configuration of service provider

Service Provider in tKey is used for generating a Share A, i.e. the private key share managed by a wallet service provider via their authentication flows. This share in our key infrastructure refers to the social login aspect, where we associate a private key share with the user's social login, enabling the seamless login experience.

In order to configure your service provider, you must use [CustomAuth Swift SDK](https://github.com/torusresearch/customauth-swift-sdk).
Since CustomAuth Swift SDK is not automatically installed when you install tkey ios SDK, let's start with installation first.

### Usage of CustomAuth Swift SDK

You can find more detailed [document here.](https://github.com/torusresearch/customauth-swift-sdk) 

#### 1. Installation

##### Swift package manager (SPM)

In project settings, add the Github URL as a swift package dependency.

```swift
import PackageDescription

let package = Package(
    name: "CustomAuth",
    dependencies: [
        .package(name: "CustomAuth", url: "https://github.com/torusresearch/customauth-swift-sdk", from: "2.4.0"))
    ]
)
```

##### Cocoapods

```ruby
pod 'CustomAuth', '~> 5.0.0'
```

##### Manual import or other packages

If you require a package manager other than SPM or Cocoapods, do reach out to
hello@tor.us or alternatively clone the repo manually and import as a framework
in your project

#### 2. Initialization

Initalize the SDK depending on the login you require. The example below does so
for a single google login. 
- `redirectURL` refers to a url for the login flow to
redirect into your app, it should have a scheme that is registered by your app,
for example `com.mycompany.myapp://redirect`. 
- `browserRedirectURL` refers to a
page that the browser should use in the login flow, it should have a http or
https scheme.

```swift
import CustomAuth

let sub = SubVerifierDetails(loginType: .web, // default .web
                            loginProvider: .google,
                            clientId: "<your-client-id>",
                            verifierName: "<verifier-name>",
                            redirectURL: "<your-redirect-url>",
                            browserRedirectURL: "<your-browser-redirect-url>")

let tdsdk = CustomAuth(aggregateVerifierType: "<type-of-verifier>", aggregateVerifierName: "<verifier-name>", subVerifierDetails: [sub], network: <etherum-network-to-use>)

// controller is used to present a SFSafariViewController.
tdsdk.triggerLogin(controller: <UIViewController>?, browserType: <method-of-opening-browser>, modalPresentationStyle: <style-of-modal>).done{ data in
    print("private key rebuild", data)
}.catch{ err in
    print(err)
}
```

Documentation of browser type and modal presentation style can be found in CustomAuth repo[https://github.com/torusresearch/customauth-swift-sdk].

Logins are dependent on verifier scripts/verifiers. There are other verifiers
including `single_id_verifier`, `and_aggregate_verifier`,
`or_aggregate_verifier` and `single_logins` of which you may need to use
depending on your required logins. To get your application's verifier script
setup, do reach out to hello@tor.us or to read more about verifiers do checkout
[the docs](https://docs.tor.us/customauth/supported-authenticators-verifiers).

### After finished configuration of CustomAuth SDK

1. `triggerLogin()` returns a promise that resolve with a Dictionary that contain at least `privateKey` and `publicAddress` field.
2. Initialize the service provider with the privateKey retrived by result of `triggerLogin()`.

```swift
tdsdk.triggerLogin(controller: <UIViewController>?, browserType: <method-of-opening-browser>, modalPresentationStyle: <style-of-modal>).done{ data in
    print("private key rebuild", data)
    let key = data["privateKey"]
    service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key)
}.catch{ err in
    print(err)
}
```


# Usage


### ThresholdKey

Natively, the instance of tKey, (ie. ThresholdKey) returns many functions, however, we have documented a few relevant ones here. You can check the table below for a list of all relevant functions.

| Function           | Description                | Arguments | Async     | return                                                                                                                                                                                   |
| ------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
`initialize` | Generates a Threshold Key object corresponding to your login provider. | `import_share: String`, `input: ShareStore?`, `never_initialize_new_key: Bool`, `include_local_metadata_transitions: Bool` | Yes | `KeyDetails` |
`reconstruct` | Reconstructs the user private key (minimum threshold no. of shares required) | `void` | Yes | `KeyReconstructionDetails` |
`reconstruct_latest_poly` | Returns the latest polynomial from all the available shares (for this pub-poly). We using Lagrange's interpolation to derive the polynomial | `void` | No | `Polynomial` |
`get_all_share_stores_for_latest_polynomial` | Get all available ShareStores from latest polynomial | `void` | No | `ShareStoreArray` |
`generate_new_share` | Generate a new share for the reconstructed private key. | `void` | Yes | `GenerateShareStoreResult` |
`delete_share` | Delete a share from private key. | `share_index: String` | Yes | `void` |
`CRITICAL_delete_tkey` | Deletes a threshold key, all shares will be removed, use with caution | `void` | Yes | `void` |
`get_key_details` | Get the details of the keys. | `void` | No | `KeyDetails` |
`output_share` | Output a share from the tKey | `shareIndex: String, shareType: String?` | No | `String` |
`share_to_share_store` | Convert Share to ShareStore | `share: String` | No | `ShareStore` |
`input_share` | Adds an existing share to tkey. | `share: String`, `shareType: String?` | Yes | `void` |
`output_share_store` | Output a share store from the tKey | `shareIndex: String, polyId: String?` | No | `ShareStore` |
`input_share_store` | Input a share store into the tKey | `shareStore: ShareStore` | Yes | `void` |
`get_shares_indexes` | Returns an array of all the share indexes from latest polynomial | `void` | No | `[String]` |
`encrypt` | Encrypt a message/data with the provided publicKey. | `msg: String` | No | `String` |
`decrypt` | Decrypt a message/data with the provided publicKey. | `msg: String` | No | `String` |
`get_tkey_store` | Returns data from tkey store given a module name | `moduleName: String` | No | `[[String:Any]]` |
`get_tkey_store_item` | Returns data from tkey store given id and a module name | `moduleName: String`, `id: String` | No | `String` |
`get_shares` | get shares from tKey | `void` | No | `ShareStorePolyIdIndexMap` |
`get_share_descriptions` | Get a description to a share | `void` | No | `[String: [String]]` |
`add_share_description` | Add a description to a share | `key: String, description: String, update_metadata: Bool` | Yes | `void` |
`update_share_description` | Update a description to a share | `key: String, oldDescription: String, newDescription: String, update_metadata: Bool` | Yes | `void` |
`delete_share_description` | Delete a description to a share | `key: String, description: String, update_metadata: Bool` | Yes | `void` |

### Making Tkey object
After setting stroage_layer and service_provider, you are ready to make the tkey object. 
You can call the functions described above with the tkey object created in this way.
```swift
threshold_key = try! ThresholdKey(
    storage_layer: storage_layer,
    service_provider: service_provider,
    enable_logging: true,
    manual_sync: false 
)
```

| Parameter | Type | Description | Mandatory |
| --------- | ---- | ----------- | --------- |
| storage_layer | StorageLayer | your storage layer object | No |
| service_provider | ServiceProvider | your service provider object | Yes |
| enable_logging | Bool | Client ID from your login service provider | Yes |
| manual_sync | Bool | manual sync provides atomicity to your tkey share. If `manual_sync` is true, you should sync your local metadata transitions manually to your storage_layer, which means your storage layer doesn't know the local changes of your tkey unless you manually sync, gives atomicity. Otherwise, If `manual_sync` is false, then your local metadata changes will be synced automatically to your storage layer. If `manual_sync = true` and want to synchronize manually, you need to call `sync_local_metadata_transitions()` manually. | Yes |


### Getting User Information

- `CustomAuth.triggerLogin()` returns a Dictionary which contains the user's information and details about the login. You can access the information within it to get the user details from the login provider. 
The contents of the dictionary may vary depending on the verifier (`single_id_verifier`, `and_aggregate_verifier`,
`or_aggregate_verifier` and `single_logins`).

`SubVerifierDetails`
 SubVerifierDetails are the details of each subverifiers to be used.

| Parameter | Type | Description | Mandatory |
| --------- | ---- | ----------- | --------- |
| loginType | SubVerifierType | Type of your login verifier | No |
| loginProvider | LoginProviders |  | Yes |
| clientId | String | Client ID from your login service provider | Yes |
| verifier | String | Verifier Name from Web3Auth Dashboard | Yes |
| redirectURL | String |  | Yes |
| browserRedirectURL | String? |  | No |
| jwtParams | [String: String] | Additional JWT Params | No |
| urlSession | URLSession |  | No |

```swift
import CustomAuth

let sub = SubVerifierDetails(loginType: .web, // web || installed
                            //example of login using a google
                            loginProvider: .google,
                            clientId: "<your-client-id>",
                            verifierName: "<verifier-name>",
                            redirectURL: "<your-redirect-url>",
                            browserRedirectURL: "<your-browser-redirect-url>")

let tdsdk = CustomAuth(aggregateVerifierType: "<type-of-verifier>", aggregateVerifierName: "<verifier-name>", subVerifierDetails: [sub], network: <etherum-network-to-use>)

// controller is used to present a SFSafariViewController.
tdsdk.triggerLogin(controller: <UIViewController>?, browserType: <method-of-opening-browser>, modalPresentationStyle: <style-of-modal>).done{ data in
    print("private key rebuild", data)
}.catch{ err in
    print(err)
}
```

```swift
# Example
let sub = SubVerifierDetails(loginType: .web,
                                loginProvider: .google,
                                clientId: <your-client-id>,
                                verifierName: "google-pepper",
                                redirectURL: "tdsdk://tdsdk/oauthCallback",
                                browserRedirectURL: "https://scripts.toruswallet.io/redirect.html")

let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin, aggregateVerifierName: "google-pepper", subVerifierDetails: [sub], network: .ROPSTEN)
tdsdk.triggerLogin().done { userdata in
    print("private key rebuild", userdata)
}.catch { err in
    print(err)
}

```

### Initializing tKey
Once you have triggered the login process, you're ready to initialize the tKey. This will generate a Threshold Key corresponding to your login provider.

```swift
let key_details = try! await threshold_key.initialize(never_initialize_new_key: false)
```


| Parameter | Type | Description | Mandatory |
| --------- | ---- | ----------- | --------- |
| import_share | String | Initialise tkey with an existing share store. This allows you to directly initialise tKey without using the service provider login. | No |
| input | ShareStore | Import a key into tkey for initialisation. | No |
| never_initialize_new_key | Bool | If it's true, it should be able to not create new key when initialize is called| Yes |
| include_local_metadata_transitions | Bool | Catch up to latest Share| No |

### Getting tKey Details

`let key_details = try! threshold_key.get_key_details()`

The function get_key_details() returns the details of the keys present generated for the specific user. This includes the public key X & Y of the user, alongside the shares details and the threshold.

#### Sample Key Details Return
```json
[
  {
    pubKey: {
      x: "471dbccd7e55eb2d24..329b8174f2339e516a3d1728d",
      y: "3f93da3597ded482fc..b23c5c79011a3deb8ccf8bf50",
    },
    requiredShares: -9,
    threshold: 2,
    totalShares: 11,
    shareDescriptions: {
      "1": [
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671429485524}',
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671429560829}',
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671454332687}',
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671454508464}',
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671454832067}',
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671506806091}',
      ],
      "94da7ea9b8680ea13d..1de31915c54c1cfa055134308969088": [
        '{"module":"webStorage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36","dateAdded":1671424397242}',
      ],
      "9b29f5c69bdcc4c79b..8c573e3001d72dc7a42866e88272866": [
        '{"module":"securityQuestions","questions":"whats your password?","dateAdded":1671424430842}',
      ],
    },
  },
];
```

### Reconstructing User's Private Key

The function `reconstruct()` reconstructs the private key of the user from the shares. This function returns the private key of the user once the threshold has been met.

```swift
let reconstructedKeyResult = try! await threshold_key.reconstruct()
```


### Generating a new Share

The function `generate_new_share()` generates a new share on the same threshold (e.g, 2/3 -> 2/4). This function returns the new share generated. 

```swift
let newShare = try! await threshold_key.generate_new_share()
```

### Deleting a Share


The function `delete_share()` deletes a share from the user's shares. This function returns the updated shareStore after the share has been deleted.

```swift
let shareStore = try! await threshold_key.delete_share(share_index: idx)
```


### Using Modules for Further Operations

For making advanced operations on tKey and to manipulate the keys, you can use the modules provided by tKey. As mentioned in the initialization section, you need to configure the modules beforehand to make it work with tKey. Once that is done, the instance of the respective module is available within your tKey instance and can be used for further operations.

### Consider multiple device environment

Imagine a situation where a user wants to use the same private key on multiple devices using the Tkey SDK.

If you want to get the same tkey on device B as the tkey created on device A, you need a minimum tkey setting of 2 out of 3. If you initialize a tkey on another device with 2 out of 2, without creating a separate share after initialization, you cannot reconstruct it because it requires the existing device share.

There are several ways to solve this problem. Below is an example guide, 

1. Initialize the tkey on Device A. (2/2 shares are needed)
2. Create an extra share using the Security question module and reconstruct it. (2/3)
3. Recover the final key from Device A' with the social login share and security question share.
4. Save the security question share locally. If you set up the device share like this, you don't need to ask the security question every time you log in.

In addition to this, there are also another ways. You can try
1. serialize a share created on device A and import it from device A' to reconstruct it.
2. use share Transfer Module

Here's an example of transfering a share using shareTransfer module.
``` swift
// assume that threshold_key, threshold_key2 are both initialized from same service provider and storage layer
let request_enc = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]")
let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
let encPubKey = lookup[0]
// generate a new share
let newShare = try! await threshold_key.generate_new_share()
// approve the corresponding share 
try! await ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex)
_ = try! await ShareTransferModule.add_custom_info_to_request(threshold_key: threshold_key2, enc_pub_key_x: request_enc, custom_info: "test info")
_ = try! await ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true)

let k2 = try! await threshold_key2.reconstruct()
```

### Making Blockchain Calls

Once you have generated the private key, you can use it to make blockchain calls. The key generated by tKey SDK (secp256k1 curve) is compatible with EVM-based blockchains like Ethereum, Polygon, and many others that use the same curve. However, you can also convert this key into other curves and utilize it. 

In addition to that, we have dedicated provider packages for EVM and Solana Blockchain libraries. You can check out their respective documentation here:

Getting a Ethereum Provider from tKey: Ethereum Provider
Getting a Solana Provider from tKey: Solana Provider

# PrivateKeysModule

The PrivateKeysModule module provides an interface for setting, getting and managing private keys for a ThresholdKey object.

To use the PrivateKeysModule in your Swift project, you will need to import the module as follows:
```
import tkey_pkg
```


| Function           | Description                | Arguments | Async     | return                                                                                                                                                                                   |
| ------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
`set_private_key` | Set private key to corresponding tKey | `threshold_key: ThresholdKey, key: String?, format: String` | Yes | `Bool` |
`get_private_keys` | Get Private Keys | `tthreshold_key: ThresholdKey` | No | `[[String:String]]` |
`get_private_key_accounts` | Get private Key accounts | `threshold_key: ThresholdKey` | No | `[String]` |


### `set_private_key(threshold_key: ThresholdKey, key: String?, format: String) async throws -> Bool`
Sets a private key for a ThresholdKey object.

Parameters:

- threshold_key: A ThresholdKey object.
- key: A private key in hex-encoded/mnemonic string format
- format: A string representing the format of the private key.

Returns:

- Bool: A boolean indicating whether the operation succeeded or not.

### `get_private_keys(threshold_key: ThresholdKey) throws -> [[String:String]]`
- Returns a list of private keys for a ThresholdKey object.

Parameters:

- threshold_key: A ThresholdKey object.

Returns:

- [[String:String]]: A list of private keys as dictionaries.

Throws:

- RuntimeError: If there is an error during runtime

### `get_private_key_accounts(threshold_key: ThresholdKey) throws -> [String]`
- Returns a list of accounts for which private keys are available.

Parameters:

- threshold_key: A ThresholdKey object.

Returns:

- [String]: A list of accounts for which private keys are available.

Throws:

- RuntimeError: If there is an error during runtime

# SecurityQuestionModule

| Function           | Description                | Arguments | Async     | return                                                                                                                                                                                   |
| ------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
`generate_new_share` | generate a new Share with security question | `threshold_key: ThresholdKey, questions: String, answer: String` | Yes | `GenerateShareStoreResult` |
`input_share` | input share from security question | `threshold_key: ThresholdKey, answer: String` | Yes | `Bool` |
`change_question_and_answer` | Get private Key accounts | `threshold_key: ThresholdKey, questions: String, answer: String` | Yes | `Bool` |
`store_answer` | Store answer of security question in tKey | `threshold_key: ThresholdKey, answer: String` | Yes | `Bool` |
`get_answer` | Get answer of security question stored in tKey | `threshold_key: ThresholdKey` | No | `String` |
`get_questions` | Get security questions stored in tKey  | `threshold_key: ThresholdKey` | No | `String` |

### `generate_new_share(threshold_key: ThresholdKey, questions: String, answer: String ) async throws -> GenerateShareStoreResult`
This function generates a new share for a given ThresholdKey, along with the user's security question and answer.

Parameters:
- threshold_key: A ThresholdKey object representing the key for which to generate a new share.
- questions: A String representing the user's security question.
- answer: A String representing the user's security answer.

Returns
- GenerateShareStoreResult: A struct that contains information about the new share that was generated.

Throws
- Error: An error if the operation failed.

### `input_share(threshold_key: ThresholdKey, answer: String ) async throws -> Bool`
A method that inputs a share for a threshold key based on a security question and answer.

Parameters
- threshold_key: A ThresholdKey instance for which to input a share.
- answer: A String representing the answer to the security questions.

Returns
- Bool: true if the share was successfully input, false otherwise.

Throws
- Error: An error if the operation failed.

### `change_question_and_answer(threshold_key: ThresholdKey, questions: String, answer: String ) async throws -> Bool`
A method that changes the security questions and answers for a threshold key.

Parameters
- threshold_key: A ThresholdKey instance for which to change the security questions and answers.
- questions: A String representing a new set of security questions to be answered.
- answer: A String representing the answer to the security questions.

Returns
- Bool: true if the security questions and answers were successfully changed, false otherwise.

Throws
- Error: An error if the operation failed.

### `store_answer(threshold_key: ThresholdKey, answer: String ) async throws -> Bool`
A method that stores the answer to a security question for a threshold key.

Parameters
- threshold_key: A ThresholdKey instance for which to store the answer to a security question.
- answer: A String representing the answer to the security question.

Returns
- Bool: true if the answer was successfully stored, false otherwise.

Throws
- Error: An error if the operation failed.

### `get_answer(threshold_key: ThresholdKey) throws -> String`
Get answer of security question stored in tKey.

Parameters
- threshold_key: A ThresholdKey instance for which to store the answer to a security question.

Returns
- String: A String representing the answer to the security questions.

Throws
- Error: An error if the operation failed.

### `get_questions(threshold_key: ThresholdKey) throws -> String`
This method gets security questions stored in tKey.

Parameters
- threshold_key: A ThresholdKey instance for which to store the answer to a security question.

Returns
- String: A String representing the user's security question.

Throws
- Error: An error if the operation failed.

# SeedPhraseModule

SeedPhraseModule is a Swift module that provides functionality for setting, changing, getting, and deleting seed phrases for a ThresholdKey object.

To use the SeedPhraseModule in your Swift project, you will need to import the module as follows:
```
import tkey_pkg
```

| Function           | Description                | Arguments | Async     | return                                                                                                                                                                                   |
| ------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
`set_seed_phrase` | Set seed phrase to corresponding tKey | `threshold_key: ThresholdKey, format: String, phrase: String?, number_of_wallets: UInt32` | Yes | `void` |
`change_phrase` | Changes specific seed phrase | `threshold_key: ThresholdKey, old_phrase: String, new_phrase: String` | Yes | `void` |
`get_seed_phrases` | Gets all seed phrases stored in tKey. | `threshold_key: ThresholdKey` | Yes | `[seedPhraseStruct] ` |
`delete_seed_phrase` | Delete the seed phrase | `threshold_key: ThresholdKey, phrase: String` | Yes | `void` |

### `set_seed_phrase(threshold_key: ThresholdKey, format: String, phrase: String?, number_of_wallets: UInt32) async throws`
This function sets the seed phrase for the given ThresholdKey.

Parameters
- threshold_key: The ThresholdKey object to set the seed phrase for.
- format: The format of the seed phrase.
- phrase: The seed phrase. If nil, a random seed phrase is generated.
- number_of_wallets: The number of wallets to derive from the seed phrase.

Throws
- Error: An error if the operation fails.


### `change_phrase(threshold_key: ThresholdKey, old_phrase: String, new_phrase: String) async throws`

This function changes the seed phrase of the given ThresholdKey. The old_phrase parameter specifies the old seed phrase, and the new_phrase parameter specifies the new seed phrase. The function is asynchronous and can throw an error.

Parameters
- threshold_key: The ThresholdKey object to change the seed phrase for.
- old_phrase: The old seed phrase.
- new_phrase: The new seed phrase.

Throws
- Error: An error if the operation fails.

### `get_seed_phrases(threshold_key: ThresholdKey) throws -> [seedPhraseStruct]`
This function returns an array of seedPhraseStruct objects, which contain the seed phrases and their type for the given ThresholdKey.

Parameters
- threshold_key: The ThresholdKey object to get the seed phrases for.

Returns
- seedPhraseStruct

Throws
- Error: An error if the operation fails.

### `delete_seed_phrase(threshold_key: ThresholdKey, phrase: String ) async throws`
This method deletes a seed phrase from the given ThresholdKey. 

Parameters
- threshold_key: The ThresholdKey instance from which to delete the seed phrase.
- phrase: The seed phrase to delete, as a string.

Throws
- Error: An error if the operation fails.


# ShareSerializationModule

The ShareSerializationModule is a Swift module that provides functionality for serializing and deserializing threshold key shares.

To use the ShareSerializationModule in your Swift project, you will need to import the module as follows:
```
import tkey_pkg
```


| Function           | Description                | Arguments | Async     | return                                                                                                                                                                                   |
| ------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
`serialize_share` | Serialize share | `threshold_key: ThresholdKey, share: String, format: String?` | No | `String` |
`deserialize_share` | Deserialize share | `threshold_key: ThresholdKey, share: String, format: String?` | No | `String` |


## `serialize_share(threshold_key: ThresholdKey, share: String, format: String?) throws -> String`
This method serializes a threshold key share and returns it as a string.

### Parameters
- threshold_key: A ThresholdKey object that represents the threshold key to which the share belongs.
- share: A string that represents the share to be serialized.
- format: An optional string that represents the serialization format. If it is not specified, the default format will be used.
### Returns
- A string that represents the serialized share.
### Throws
- RuntimeError: If the serialization operation fails, a RuntimeError will be thrown.


## `deserialize_share(threshold_key: ThresholdKey, share: String, format: String?) throws -> String`
This method deserializes a threshold key share and returns it as a string.

### Parameters
- threshold_key: A ThresholdKey object that represents the threshold key to which the share belongs.
- share: A string that represents the share to be deserialized.
- format: An optional string that represents the serialization format. If it is not specified, the default format will be used.
### Returns
- A string that represents the deserialized share.
### Throws
- RuntimeError: If the deserialization operation fails, a RuntimeError will be thrown.

# ShareTransferModule

The ShareTransferModule is a Swift module that provides functions for requesting, approving and transfering a share to another device.

To use the ShareTransferModule in your Swift project, you will need to import the module as follows:
```
import tkey_pkg
```

| Function           | Description                | Arguments | Async     | return                                                                                                                                                                                   |
| ------------------- | ------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
`request_new_share` | request a new share  | `threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String` | Yes | `String` |
`add_custom_info_to_request` | Add custom info to share request | `threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String` | Yes | `void` |
`look_for_request` | Returns an array of indexes of pending requests | `threshold_key: ThresholdKey ` | Yes | `[String]` |
`approve_request` | approve the shareStore to be shared | `threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore` | Yes | `void` |
`approve_request_with_share_index` | approve sharing with share index | `threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String` | Yes | `void` |
`get_store` | Get share transfer store  | `threshold_key: ThresholdKey` | Yes | `ShareTransferStore` |
`set_store` | Set share transfer store  | `threshold_key: ThresholdKey, store: ShareTransferStore` | Yes | `Bool` |
`delete_store` | Delete share transfer store  | `threshold_key: ThresholdKey, enc_pub_key_x: String` | Yes | `Bool` |
`get_current_encryption_key` | Get security questions stored in tKey  | `threshold_key: ThresholdKey` | No | `String` |
`request_status_check` | start request status checking | `threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool` | Yes | `ShareStore` |
`cleanup_request` | cleanup the request  | `threshold_key: ThresholdKey` | No | `Bool` |


### `request_new_share(threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String ) async throws -> String`

Request a new share for the given user.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.
- user_agent: A string representing the user's user agent.
- available_share_indexes: A string representing the available share indexes for the user.

Returns:
- String: A string representing the requested share.

### `add_custom_info_to_request(threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String ) async throws`

Adds custom information to a share request.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.
- enc_pub_key_x: A string representing the user's encryption public key.
- custom_info: A string representing the custom information to add to the request.
 
 ### `look_for_request(threshold_key: ThresholdKey ) async throws -> [String]`

 Check the status of the user's share request.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.

Returns:
- [String]: An array of strings representing the status of the user's share request.

### `approve_request(threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore ) async throws`

Approves a share request for the user.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.
- enc_pub_key_x: A string representing the user's encryption public key.
- share_store: A ShareStore object representing the user's share store.

### `approve_request_with_share_index(threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String ) async throws`

Approves a share request for the user using a specific share index.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.
- enc_pub_key_x: A string representing the user's encryption public key.
- share_index: A string representing the specific share index to use for the share request.

### `get_store(threshold_key: ThresholdKey ) async throws -> ShareTransferStore`

Get the user's share store.


Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.

Returns:
- ShareTransferStore: A ShareTransferStore object representing the user's share store.

### `set_store(threshold_key: ThresholdKey, store: ShareTransferStore ) async throws -> Bool 

Set the user's share store.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.
- store: A ShareTransferStore object representing the user's share store.

Returns:
- Bool: A boolean value indicating whether the operation was successful.

### `delete_store(threshold_key: ThresholdKey, enc_pub_key_x: String ) async throws -> Bool`
Delete the user's share store.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.
- enc_pub_key_x: A string representing the user's encryption public key.

Returns:
- Bool: A boolean value indicating whether the operation was successful.


### `get_current_encryption_key(threshold_key: ThresholdKey) throws -> String`
This method is used to get the current encryption key for the given threshold_key.

Parameters:
- threshold_key: A ThresholdKey object representing the user's threshold key.

Returns:
- String: A string value representing the current encryption key.

Throws:

- ShareTransferError: If there is an issue with the underlying share transfer module.
- RuntimeError: If there is an issue with the runtime environment.

### `request_status_check(threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool ) async throws -> ShareStore`
This method is used to check the status of a request for the specified enc_pub_key_x under the given threshold_key.

Parameters:

- threshold_key: The ThresholdKey object for the associated share transfer module.
- enc_pub_key_x: The encrypted public key X for the request to be checked.
- delete_request_on_completion: A boolean value indicating whether the request should be deleted upon completion.

Returns:

- ShareStore: A ShareStore object representing the current status of the request.

Throws:

- ShareTransferError: If there is an issue with the underlying share transfer module.
- RuntimeError: If there is an issue with the runtime environment.

### `cleanup_request(threshold_key: ThresholdKey) throws`
This method is used to clean up any remaining requests for the specified threshold_key.

Parameters:

- threshold_key: The ThresholdKey object for the associated share transfer module.

Throws:

- ShareTransferError: If there is an issue with the underlying share transfer module.
- RuntimeError: If there is an issue with the runtime environment.
