# chainbridge-goquorum

This repo provides an example of setting up ChainBridge to connect two GoQuorum networks.

It includes all the required scripts & genesis files for starting and running the networks.

Note that for the purposes of this example, the GoQuorum nodes are run without privacy enabled (so Tessera is not started).

## Pre-requisites

A GoQuorum `geth` executable must exist on the path. This can either be a binary download, or a [go-quorum](https://github.com/ConsenSys/quorum) repository that has been checked out and built.

## References

- [ChainBridge docs](https://chainbridge.chainsafe.io/)
  - [ChainBridge docs showing an example of deploying an EVM-EVM network](https://chainbridge.chainsafe.io/live-evm-bridge/)
- [ChainBridge repo](https://github.com/ChainSafe/ChainBridge)
- [ChainBridge contract deployment tool repo](https://github.com/ChainSafe/chainbridge-deploy)

Note that the two ChainBridge repos listed above have actually been deprecated in favour of [chainbridge-core](https://github.com/ChainSafe/chainbridge-core), which is a framework rather than an executable and requires a bit more work to get running. However the new repo is going through a lot of change; it seems quite unstable and lacks documentation, so I‘ve used the deprecated version for now.

It's also worth mentioning at this point that ChainBridge maintains its own keystore, which is a security concern. I would expect a future enhancement to allow integration with an external vault.

# Local GoQuorum networks setup

For this, I set up two quorum networks, each one running 4 nodes. Both networks are a 4-node version of the quorum-examples.
Network 1 node1 is listening on port 22000 and has ChainId 10. Network 2 node1 is listening on port 29000, and has ChainId 20. ChainBridge is attaching to these nodes to use as gateways.

In the example below, I will transfer tokens from network 1 to network 2, and then back again.

### Run geth network1 and network2

```sh
cd <working directory>
git clone https://github.com/SatpalSandhu61/chainbridge-goquorum.git
cd chainbridge-quorum
./istanbul-init1.sh
./istanbul-start1.sh
./istanbul-init2.sh
./istanbul-start2.sh
```

Set up environment variables with quorum networks & account details, for use in commands further below.

```sh
SRC_GATEWAY=http://localhost:22000
DST_GATEWAY=http://localhost:29000
SRC_ADDR=0xed9d02e382b34818e88b88a309c7fe71e65f419d                                                              # network1, node1 ‘from’ account (key1) – also need in ChainBridge config file
SRC_PK=e6181caaffff94a09d7e332fc8da9884d99902c7874eb74354bdcadf411929f1                        # private key for this account
DST_ADDR=0x0638e1574728b6d862dd5d3a3e0942c3be47d996                                                            # network2, node1 ‘from’ account (key5) – also need in ChainBridge config file
DST_PK=30bee17b2b8b1e774115f785e92474027d45d900a12a9d5d99af637c2d1a61bd                  # private key for this account
```

### Checkout chainbridge-deploy and deploy contracts onto the quorum networks

```sh
cd <working directory>
git clone https://github.com/ChainSafe/chainbridge-deploy
cd chainbridge-deploy/cb-sol-cli/
npm install
make install
```

### Deploy ChainBridge contracts to quorum network 1

```sh
cb-sol-cli deploy --url ${SRC_GATEWAY} --privateKey ${SRC_PK} --relayers ${SRC_ADDR} --relayerThreshold 1 --chainId 10 --all

Contract Addresses
================================================================
Bridge:             0x1932c48b2bF8102Ba33B4A6B545C32236e342f34
----------------------------------------------------------------
Erc20 Handler:      0x1349F3e1B8D71eFfb47B840594Ff27dA7E603d17
----------------------------------------------------------------
Erc721 Handler:     0x9d13C6D3aFE1721BEef56B55D303B09E021E27ab
----------------------------------------------------------------
Generic Handler:    0xd9d64b7DC034fAfDbA5DC2902875A67b5d586420
----------------------------------------------------------------
Erc20:              0x8a5E2a6343108bABEd07899510fb42297938D41F
----------------------------------------------------------------
Erc721:             0x938781b9796aeA6376E40ca158f67Fa89D5d8a18
----------------------------------------------------------------
Centrifuge Asset:   Not Deployed
----------------------------------------------------------------
WETC:               Not Deployed
================================================================
```

### Deploy ChainBridge contracts to quorum network 2

```sh
cb-sol-cli deploy --url ${DST_GATEWAY} --privateKey ${DST_PK} --relayers ${DST_ADDR} --relayerThreshold 1 --chainId 20 --all

Contract Addresses
================================================================
Bridge:             0x3f217e1FE69d1B188385b761a2b17827616b9BDB
----------------------------------------------------------------
Erc20 Handler:      0x6D19a263c40D5e724D6aEcBf87BD9a3716CC6889
----------------------------------------------------------------
Erc721 Handler:     0xd8B6B876e320461e2703F46713a082F51Fc5CE47
----------------------------------------------------------------
Generic Handler:    0x70cF424A59BdBD636b40fccCB7f342525A9bb14f
----------------------------------------------------------------
Erc20:              0xA443f2511ab96fe3364b4eD109677Dfa2eE43dc9
----------------------------------------------------------------
Erc721:             0x674A02A3AF30712329770409dC20d20644141A67
----------------------------------------------------------------
Centrifuge Asset:   Not Deployed
----------------------------------------------------------------
WETC:               Not Deployed
================================================================
```

### Set up environment variables with details of contracts, for use in commands below

```sh
# replace these addresses if the contract addresses returned above are different
SRC_BRIDGE=0x1932c48b2bF8102Ba33B4A6B545C32236e342f34                                               # network1: address of bridge contract
SRC_HANDLER=0x1349F3e1B8D71eFfb47B840594Ff27dA7E603d17                                           # network1: address of ERC20 handler contract
SRC_TOKEN=0x8a5E2a6343108bABEd07899510fb42297938D41F                                                # network1: address of ERC20 contract
DST_BRIDGE=0x3f217e1FE69d1B188385b761a2b17827616b9BDB                                              # network2: address of bridge contact
DST_HANDLER=0x6D19a263c40D5e724D6aEcBf87BD9a3716CC6889                                          # network2: address of ERC20 handler contract
DST_TOKEN=0xA443f2511ab96fe3364b4eD109677Dfa2eE43dc9                                                 # network2: address of ERC20 contract
RESOURCE_ID=0x000000000000000000000000000000c76ebe4a02bbc34786d860b355f5a5ce00
```

## Configure contracts on both quorum networks

Network1: register the ERC20 token as a resource with a bridge contract and configure which handler to use.

```sh
cb-sol-cli bridge register-resource  --url ${SRC_GATEWAY} \
--privateKey ${SRC_PK} \
--bridge ${SRC_BRIDGE} \
--handler ${SRC_HANDLER} \
--targetContract ${SRC_TOKEN} \
--resourceId ${RESOURCE_ID}
```

Network2: register the ERC20 token as a resource with a bridge contract and configure which handler to use.

```sh
cb-sol-cli bridge register-resource  --url ${DST_GATEWAY} \
--privateKey ${DST_PK} \
--bridge ${DST_BRIDGE} \
--handler ${DST_HANDLER} \
--targetContract ${DST_TOKEN} \
--resourceId ${RESOURCE_ID}
```

Network1: register the token as burnable/mintable on the bridge.

```sh
cb-sol-cli bridge set-burn \
--url ${SRC_GATEWAY} \
--privateKey ${SRC_PK} \
--bridge ${SRC_BRIDGE} \
--handler ${SRC_HANDLER} \
--tokenContract ${SRC_TOKEN}
```

Network1: give permission to ERC20 handler to mint new tokens.

```sh
cb-sol-cli erc20 add-minter \
--url ${SRC_GATEWAY} \
--privateKey ${SRC_PK} \
--minter ${SRC_HANDLER} \
--erc20Address ${SRC_TOKEN}
```

Network2: register the token as burnable/mintable on the bridge.

```sh
cb-sol-cli bridge set-burn \
--url ${DST_GATEWAY} \
--privateKey ${DST_PK} \
--bridge ${DST_BRIDGE} \
--handler ${DST_HANDLER} \
--tokenContract ${DST_TOKEN}
```

Network2: give permission to ERC20 handler to mint new tokens.

```sh
cb-sol-cli erc20 add-minter \
--url ${DST_GATEWAY} \
--privateKey ${DST_PK} \
--minter ${DST_HANDLER} \
--erc20Address ${DST_TOKEN}
```

# Setup and run ChainBridge

**NOTE:** If the contract addresses returned earlier are different from those in this readme, then edit myconfig.json
and update it to have the correct contract addresses.

### Checkout & build ChainBridge relayer (executable ‘chainbridge’)

```sh
cd <working directory>
git clone https://github.com/ChainSafe/ChainBridge
cd ChainBridge
make install                                              # build local executable ‘chainbridge’
docker build -t chainsafe/chainbridge .                   # build docker container (not actually needed, as I run locally)
# the relayer maintains it’s own keystore, so import ‘from’ accounts into the relayer keystore
chainbridge accounts import --privateKey ${SRC_PK}        # NB: no password
chainbridge accounts import --privateKey ${DST_PK}        # NB: no password
# grab a copy of the config file
cp <path to checkout of chainbridge-quorum repo>/myconfig.json
# using myconfig.json, start chainbridge – make sure this has correct from addresses and contract addresses
chainbridge --config myconfig.json --verbosity trace --latest
```

### Create some tokens for our use

```sh
# mint ERC20 tokens on network1 (source), since we don’t have any to transfer yet
cb-sol-cli erc20 mint \
--url ${SRC_GATEWAY} \
--privateKey ${SRC_PK} \
--erc20Address ${SRC_TOKEN} \
--amount 1000
# (optional) mint ERC20 tokens on network2 (destination)
cb-sol-cli erc20 mint \
--url ${DST_GATEWAY} \
--privateKey ${DST_PK} \
--erc20Address ${DST_TOKEN} \
--amount 999
# check ERC20 token balance (on both source & destination) – should see 1000 on network1 and 999 on network2
cb-sol-cli erc20 balance \
--url ${SRC_GATEWAY} \
--erc20Address ${SRC_TOKEN} \
--address ${SRC_ADDR}
cb-sol-cli erc20 balance \
--url ${DST_GATEWAY} \
--erc20Address ${DST_TOKEN} \
--address ${DST_ADDR}
```

## Perform token transfer

### ERC20 token transfer from network1 to network2

```sh
# approve the handler to transfer ERC20 tokens on our behalf from network1 to network2 (approving up to 100 tokens in this example)
cb-sol-cli erc20 approve \
--url ${SRC_GATEWAY} \
--privateKey ${SRC_PK} \
--erc20Address ${SRC_TOKEN} \
--recipient ${SRC_HANDLER} \
--amount 100

# execute a deposit on network2 (must be less than or equal to the amount approved above)
cb-sol-cli erc20 deposit \
--url ${SRC_GATEWAY} \
--privateKey ${SRC_PK} \
--amount 99 \
--dest 20 \
--bridge ${SRC_BRIDGE} \
--recipient ${DST_ADDR} \
--resourceId ${RESOURCE_ID}
```

**Note** that the relayer will wait 10 block confirmations before submitting the request (this can be seen in the relayer console in the log message “target=XXXX”). It appears that you need to wait for 10 blocks to be minted on the source network followed by another 10 blocks on the destination network before the transfer is complete.

### Check ERC20 token balance (on both source & destination)

Expect to see 901 on network1 and 1098 on network2.

```sh
cb-sol-cli erc20 balance \
--url ${SRC_GATEWAY} \
--erc20Address ${SRC_TOKEN} \
--address ${SRC_ADDR}
cb-sol-cli erc20 balance \
--url ${DST_GATEWAY} \
--erc20Address ${DST_TOKEN} \
--address ${DST_ADDR}
```

### Transfer tokens back

Approve the handler to transfer ERC20 tokens on our behalf from network2 to network1 (approving up to 100 tokens in this example).

```sh
cb-sol-cli erc20 approve \
--url ${DST_GATEWAY} \
--privateKey ${DST_PK} \
--erc20Address ${DST_TOKEN} \
--recipient ${DST_HANDLER} \
--amount 100
```

Execute a deposit on network1 (must be less than or equal to the amount approved above).

```sh
cb-sol-cli erc20 deposit \
--url ${DST_GATEWAY} \
--privateKey ${DST_PK} \
--amount 11 \
--dest 10 \
--bridge ${DST_BRIDGE} \
--recipient ${SRC_ADDR} \
--resourceId ${RESOURCE_ID}
```

**Note** that the relayer will wait 10 block confirmations before submitting the request (this can be seen in the relayer console in the log message “target=XXXX”). It appears that you need to wait for 10 blocks to be minted on the source network followed by another 10 blocks on the destination network before the transfer is complete.

### Check ERC20 token balance (on both source & destination)

Expect to see 901 on network1 and 1098 on network2.

```sh
cb-sol-cli erc20 balance \
--url ${SRC_GATEWAY} \
--erc20Address ${SRC_TOKEN} \
--address ${SRC_ADDR}
cb-sol-cli erc20 balance \
--url ${DST_GATEWAY} \
--erc20Address ${DST_TOKEN} \
--address ${DST_ADDR}
 ```

