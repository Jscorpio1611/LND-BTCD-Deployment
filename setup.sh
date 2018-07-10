#!/bin/sh

git clone https://github.com/lightningnetwork/lnd.git tmp
mv tmp/docker/ltcd tmp/docker/lnd tmp/docker/btcd -t . 
rm -rf tmp 
