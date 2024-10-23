# Dacxi Coin Contract

This repository hosts the DXI coin smart contract codebase until we get ready to open it up completely.
The initial development took place in a private repository from which this repository is derived.

## Overview

### DXIToken

DXIToken is a standard ERC20 and EIP2612 ( `permit()` ) functionality token.
It's also a burnable token. Token holders can burn their DXI through the `burn` method.

It's initial supply is 10,000,000,000 DXI and has no supply cap (although this can
be changed in the future).

An external smart contract is responsible to control the DXI inflation through the `mint()` method.
The inflation smart contract will be developed and attached to the DXIToken in some future. Until than
the supply will stay 10,000,000,000 DXI.

Note that the `mint()` method has an internal safety system that avoids the MINTER to mint unlimited
amount of tokens, see `updateMintCap()`. The DXIToken mint cap can be set up according to the rules
defined by the new inflation external smart contract that will be attached to it. The mint cap must
allow the inflation smart contract to properly mint new token over time, but at the same time 
will avoid it to mint unlimited amount of tokens. 

#### About Immutability

Although the rules for the DXI inflation can be updated by attaching a new inflation
external smart contract in the future, Dacxi Chain team agrees that the core contracts and protocol of
the Dacxi Chain ecosystem must be immutable. The DXIToken inflation rules can become immutable in the future
by renouncing the owership of the DXIToken contract (ADMIN role) which will permanently disable the ability
to attach a new inflation external smart contract.

### DXITokenMigration

DXITokenMigration is a smart contract to swap DACXI token to DXI token at 1:1 ratio.

All the DXI initial supply (10,000,000,000 DXI) will be sent to DXITokenMigration during the
DXIToken deployment, meaning that all the initial DXI supply will only be claimable by DACXI token holders.

| Contract      | Address (Ethereum Network)                  |
|---------------|---------------------------------------------|
| DACXI Token   | 0xefab7248d36585e2340e5d25f8a8d243e6e3193f  |

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## How to develop

### Setup

```sh
git clone git@github.com:dacxi/dacxi-coin-contract.git
cd dacxi-coin-contract
forge install
```

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
