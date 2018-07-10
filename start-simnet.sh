#!/bin/sh

export NETWORK="simnet" 

# Start Alice LND node with BTCD backend
docker-compose run -d --name alice lnd_btc > /dev/null

# Wait until Alice's node is up-and-running
{
    until ! [[ $(docker exec alice lncli getinfo) = "" ]]; do
        sleep 1
    done
} 2> /dev/null

# Create a new bitcoin address for Alice
ALICE_ADDRESS=$(docker exec alice lncli newaddress np2wkh | jq -r .address)

# Start a mining node with Alice's address as reward beneficiary
MINING_ADDRESS="$ALICE_ADDRESS" docker-compose up -d btcd

# Wait until the mining node is up-and-running
sleep 5

# Mine 400 blocks to wait for coinbase block maturity (100 blocks) and activate segwit (300 blocks)
docker-compose run btcctl generate 400 > /dev/null

# Check that segwit is activated successfully
SEGWIT_STATUS=$(docker-compose run btcctl getblockchaininfo | jq -r .bip9_softforks.segwit.status)
if ! [ "$SEGWIT_STATUS" = "active" ]; then
    echo "ERROR: Segwit is not activated. Aborting" >$2
    exit 1
fi

# Start Bob LND node with BTCD backend
docker-compose run -d --name bob lnd_btc > /dev/null

# Wait until Bob's node is up-and-runnig
{   
    until [[ $(docker exec bob lncli getinfo | jq -r .synced_to_chain) ]]; do
        sleep 1
    done
} 2> /dev/null

# Get Bob's identity public key
BOB_ID_PUBKEY=$(docker exec bob lncli getinfo | jq -r .identity_pubkey)

# Get Bob's Docker container's (local) IP Address
BOB_IPADDR=$(docker inspect bob | jq -r .[0].NetworkSettings.Networks.docker_default.IPAddress)

# Connect Alice's LND node with Bob's LND node. Wait until connection is made.
until [[ $(docker exec bob lncli listpeers | jq -r '.peers | length') = 1 ]]; do
    docker exec alice lncli connect "${BOB_ID_PUBKEY}@${BOB_IPADDR}" > /dev/null
    sleep 2
done

# Bob's node sometimes has to catch up with the blockchain first before a connection can be made.
# Therefore, the script waits a bit until Bob has caught up.
# Related issue: https://github.com/lightningnetwork/lnd/issues/941
sleep 5

# Create a Lightning Channel between Alice and Bob
docker exec alice lncli openchannel --node_key="$BOB_ID_PUBKEY" --local_amt=1000000 > /dev/null

# Generate 3 Blocks to confirm the channel creation
docker-compose run btcctl generate 3 > /dev/null

# Check that the Payment channel between Alice and Bob is opened
CHANNEL_IS_OPEN=$(docker exec alice lncli listchannels | jq -r '.channels | length')
if ! [ "$CHANNEL_IS_OPEN" = 1 ]; then 
    echo "ERROR: Payment channel is not open. Aborting" >$2
    exit 1
fi