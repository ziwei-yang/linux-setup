#!/bin/bash --login
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cd $DIR/../
redis-server conf/redis/redis.conf --port 6379
#redis-server conf/redis/redis.conf --port 6379 --slaveof 127.0.0.1 8888
