## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Script
#### Deployment
##### Simulation
```shell
$ source .env
$ forge script script/Stash.s.sol:DeployScript --rpc-url $FUJI_RPC_URL --sig 'run()' -vvv
$ forge script script/GameResult.s.sol:DeployScript --rpc-url $FUJI_RPC_URL --sig 'run()' -vvv
```
##### Broadcast
```shell
$ source .env
$ forge script script/Stash.s.sol:DeployScript --rpc-url $FUJI_RPC_URL --sig 'run()' --broadcast --verify -vvv
$ forge script script/GameResult.s.sol:DeployScript --rpc-url $FUJI_RPC_URL --sig 'run()' --broadcast --verify -vvv
```
#### Upgrade
##### Simulation
```shell
$ source .env
$ forge script script/Stash.s.sol:UpgradeScript "deployment" --rpc-url $FUJI_RPC_URL --sig 'run(string memory)' -vvv
$ forge script script/GameResult.s.sol:UpgradeScript "deployment" --rpc-url $FUJI_RPC_URL --sig 'run(string memory)' -vvv
```
##### Broadcast & Verify
```shell
$ source .env
$ forge script script/Stash.s.sol:UpgradeScript "deployment" --rpc-url $FUJI_RPC_URL --sig 'run(string memory)' --broadcast --verify -vvv
$ forge script script/GameResult.s.sol:UpgradeScript "deployment" --rpc-url $FUJI_RPC_URL --sig 'run(string memory)' --broadcast --verify -vvv
```

#### Verify
```shell
$ source .env
$ forge verify-contract  --chain fuji --watch --etherscan-api-key $ETHERSCAN_API_KEY 0x1BC64b7b907F2ef3aD5551d9605Dd14702dDaF48 src/token/Stash.sol:Stash
$ forge verify-contract  --chain fuji --watch --etherscan-api-key $ETHERSCAN_API_KEY 0x1BC64b7b907F2ef3aD5551d9605Dd14702dDaF48 src/GameResult.sol:GameResult
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
