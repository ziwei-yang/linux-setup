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
	wget -nc --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.tar.gz"
	
	pythonURL="https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz"
	wget -nc $pythonURL
	
	pyPipURL="https://bootstrap.pypa.io/get-pip.py"
	wget -nc $pyPipURL
fi

nodejs0_12URL="https://nodejs.org/dist/latest-v0.12.x/node-v0.12.18.tar.gz"
wget -nc $nodejs0_12URL
nodejs4URL="https://nodejs.org/dist/latest-v4.x/node-v4.8.4.tar.gz"
wget -nc $nodejs4URL
nodejs5URL="https://nodejs.org/dist/latest-v5.x/node-v5.12.0.tar.gz"
wget -nc $nodejs5URL
nodejs6URL="https://nodejs.org/dist/latest-v6.x/node-v6.11.3.tar.gz"
wget -nc $nodejs6URL
nodejs7URL="https://nodejs.org/dist/latest-v7.x/node-v7.10.1.tar.gz"
wget -nc $nodejs7URL

redisURL="http://download.redis.io/releases/redis-3.0.5.tar.gz"
wget -nc $redisURL

phantomjsURL="http://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2"
wget -nc $phantomjsURL

mavenURL="http://apache.website-solution.net/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz"
wget -nc $mavenURL

libsodiumURL="http://download.libsodium.org/libsodium/releases/libsodium-1.0.14.tar.gz"
zeromqURL="https://github.com/zeromq/zeromq4-1/releases/download/v4.1.6/zeromq-4.1.6.tar.gz"
wget --no-check-certificate -nc $libsodiumURL
wget -nc $zeromqURL

# jzmqURL="https://github.com/zeromq/jzmq/archive/v3.1.0.tar.gz"
jzmqURL="https://github.com/zeromq/jzmq/archive/master.zip"
wget -O jzmq-master.zip -nc --no-check-certificate $jzmqURL

nanomqURL="https://github.com/nanomsg/nanomsg/archive/0.9-beta.tar.gz"
wget -O nanomsg-0.9-beta.tar.gz -nc $nanomqURL

wkhtmlURL="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz"
wget -O wkhtmltox-0.12.4_linux-generic-amd64.tar.xz -nc $wkhtmlURL

pdftkURL="https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk-2.02-src.zip"
wget -nc $pdftkURL

mongoURL="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.4.2.tgz"
wget -nc $mongoURL

antURL="http://ftp.cuhk.edu.hk/pub/packages/apache.org//ant/binaries/apache-ant-1.10.1-bin.zip"
wget -nc $antURL

cd $PWD
