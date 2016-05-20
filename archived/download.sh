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
	wget -nc --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz"
	
	pythonURL="https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz"
	wget -nc $pythonURL
	
	pyPipURL="https://bootstrap.pypa.io/get-pip.py"
	wget -nc $pyPipURL
fi

nodejsURL="http://nodejs.org/dist/v0.12.7/node-v0.12.7.tar.gz"
wget -nc $nodejsURL

redisURL="http://download.redis.io/releases/redis-3.0.5.tar.gz"
wget -nc $redisURL

phantomjsURL="http://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2"
wget -nc $phantomjsURL

mavenURL="http://apache.communilink.net/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz"
wget -nc $mavenURL

# libsodiumURL="http://download.libsodium.org/libsodium/releases/libsodium-1.0.3.tar.gz"
libsodiumURL="https://37.59.238.213/libsodium/releases/libsodium-1.0.10.tar.gz"
zeromqURL="http://download.zeromq.org/zeromq-4.1.4.tar.gz"
wget --no-check-certificate -nc $libsodiumURL
wget -nc $zeromqURL

nanomqURL="https://github.com/nanomsg/nanomsg/archive/0.9-beta.tar.gz"
wget -O nanomsg-0.9-beta.tar.gz -nc $nanomqURL

cd $PWD
