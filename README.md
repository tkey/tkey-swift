# tkey iOS SDK - TSS

Web3Auth uses tKey MPC to manage user wallets in a distributed fashion, leveraging various factors or shares managed by users, including their devices, private inputs, backup locations, and cloud service providers. As long as a user can access 2 out of n (2/n) of these shares, they can access their key.

The companion example application is [here](https://github.com/torusresearch/tkey-rust-ios-example/tree/alpha).

### Add the [MPC tKey iOS SDK](https://github.com/tkey/tkey-ios/tree/alpha)

1. In Xcode, with your app project open, navigate to **File > Add Packages**.

1. When prompted, add the tKey iOS SDK repository:

   ```sh
   https://github.com/tkey/tkey-ios
   ```

   From the `Dependency Rule` dropdown, select `Branch` and type `alpha` as the branch.

1. When finished, Xcode will automatically begin resolving and downloading your dependencies in the background.

## Documentation

Follow the full documentation [here](https://web3auth.io/docs/sdk/core-kit/mpc-tkey-ios).
