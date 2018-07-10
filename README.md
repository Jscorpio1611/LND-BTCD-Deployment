# LND-BTCD: Easy Deployment Scripts
Scripts to quickly deploy a local [LND](https://github.com/lightningnetwork/lnd)-[BTCD](https://github.com/btcsuite/btcd) simnet with an open Lightning channel 

### Related works
The scripts were based or depend upon:

- `LND` [Dockerfiles](https://github.com/lightningnetwork/lnd/tree/master/docker)
- `LND` [Docker guide](https://dev.lightning.community/guides/docker/)

## Dependencies
- [jq](https://stedolan.github.io/jq/) for the Bash scripts
- [docker-compose](https://docs.docker.com/compose/install/) *1.9.0* or later
- [docker](https://docs.docker.com/install/) *1.13.0* or later

## Setup
`./setup.sh`

This will download the latest `LND` docker files and unpack them into the current folder. If you have problems running the script, first change its permissions with `chmod +x setup.sh`

## Deploy
`./start-simnet.sh`

This will take around 2min to start the all three container, to connect the two `LND` container, and to setup a Lightning Payment channel between the two. Again, if you have problems running the script, change its permissions with `chmod +x start-simnet.sh`

## Stop
`./stop-simnet.sh`

This will stop and delete all Docker container. _Watch out if you have any other Docker container running!_
