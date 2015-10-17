PWD=$(pwd)

# Check and set environment before every scripts. Golbal vars should be not affect others.
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "cd $DIR"
cd $DIR

uname=$( uname )
source $DIR/../util/util.sh
checkBinPath "wget"

#btsyncURL="http://download.getsyncapp.com/endpoint/btsync/os/linux-x64/track/stable/bittorrent_sync_x64.tar.gz"
#wget -nc $btsyncURL

if [[ $uname == 'Linux' ]]; then
	wget -nc --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.tar.gz"
	
	pythonURL="https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz"
	wget -nc $pythonURL
	
	pyPipURL="https://bootstrap.pypa.io/get-pip.py"
	wget -nc $pyPipURL
fi

nodejsURL="http://nodejs.org/dist/v0.12.7/node-v0.12.7.tar.gz"
wget -nc $nodejsURL

redisURL="http://download.redis.io/releases/redis-2.8.21.tar.gz"
wget -nc $redisURL

cd $PWD
