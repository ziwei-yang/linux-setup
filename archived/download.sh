PWD=$(pwd)

# Check and set environment before every scripts. Golbal vars should be not affect others.
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "cd $DIR"
cd $DIR

uname=$( uname )
source $DIR/../util/util.sh
checkBinPath "wget"

rm -v `ls $DIR | grep -v download.sh`


#btsyncURL="http://download.getsyncapp.com/endpoint/btsync/os/linux-x64/track/stable/bittorrent_sync_x64.tar.gz"
#wget -N $btsyncURL

if [[ $uname == 'Linux' ]]; then
	curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.tar.gz"
	
	pythonURL="https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz"
	wget -N $pythonURL
	
	pyPipURL="https://bootstrap.pypa.io/get-pip.py"
	wget -N $pyPipURL
fi

nodejsURL="http://nodejs.org/dist/v0.12.7/node-v0.12.7.tar.gz"
wget -N $nodejsURL

redisURL="http://download.redis.io/releases/redis-2.8.21.tar.gz"
wget -N $redisURL

cd $PWD
