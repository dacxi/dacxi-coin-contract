# Dacxi Coin Contract

This repository hosts the DXI coin smart contract codebase until we get ready to open it up completely.
The initial development took place in a private repository from which this repository is derived.

## Overview

### DXIToken

DXIToken is a standard ERC20 and EIP2612 ( `permit()` ) functionality token.
It's also a burnable token. Token holders can burn their DXI through the `burn` method.

It's initial supply is 10,000,000,000 DXI and has no supply cap (although this can
be changed in the future through the emission smart contract).

An external smart contract is responsible to control the DXI emission through the `mint()` method.
The emission smart contract will be developed and attached to the DXIToken in the future. Until then
the supply will stay fixed at 10,000,000,000 DXI.

Note that the `mint()` method has an internal safety system that avoids the MINTER to mint unlimited
amount of tokens (see `updateMintCap()`). The DXIToken's mint cap (the number of DXI tokens that can be
minted per second) must be set according to the external emission smart contract attached to it,
allowing the emission smart contract to properly mint new token over time.

Although the supply expansion rules can be updated in the future by attaching a new emission smart contract, 
DXIToken has immutable safety validations ensuring that there will never be the possibility to mint more 
than 47 DXI tokens per second, regardless the emission smart contract attached to it.

#### About Immutability

Dacxi Chain team believes that the core contracts and protocols of the Dacxi Chain ecosystem must be immutable. 
The DXIToken supply expansion rules can become immutable by renouncing the owership of the DXIToken contract 
(renouncing the ADMIN role) which will permanently remove the ability to attach new emission smart contracts
to the DXIToken.

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
