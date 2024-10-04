## Static Analysis

### Slither

```bash
docker pull ghcr.io/trailofbits/eth-security-toolbox:nightly
docker run -it --rm -v ${PWD}:/tmp -w /tmp ghcr.io/trailofbits/eth-security-toolbox:nightly bash

# inside container
slither src/DXIToken.sol
slither src/DXITokenMigration.sol
```

### Mythril

```bash
docker pull mythril/myth
docker run -it --rm -v ${PWD}:/tmp -w /tmp mythril/myth bash

# inside container
myth -v 5 analyze src/DXIToken.sol --solc-json mythril.config.json
```

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
