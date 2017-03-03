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
	wget -nc --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.tar.gz"
	
	pythonURL="https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz"
	wget -nc $pythonURL
	
	pyPipURL="https://bootstrap.pypa.io/get-pip.py"
	wget -nc $pyPipURL
fi

# gppURL="http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-6.3.0/gcc-6.3.0.tar.gz"
# wget -nc $gppURL

nodejs0_12URL="https://nodejs.org/dist/latest-v0.12.x/node-v0.12.18.tar.gz"
wget -nc $nodejs0_12URL
nodejs4URL="https://nodejs.org/dist/latest-v4.x/node-v4.8.0.tar.gz"
wget -nc $nodejs4URL
nodejs5URL="https://nodejs.org/dist/latest-v5.x/node-v5.12.0.tar.gz"
wget -nc $nodejs5URL
nodejs6URL="https://nodejs.org/dist/latest-v6.x/node-v6.10.0.tar.gz"
wget -nc $nodejs6URL
nodejs7URL="https://nodejs.org/dist/latest-v7.x/node-v7.7.1.tar.gz"
wget -nc $nodejs7URL

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

# jzmqURL="https://github.com/zeromq/jzmq/archive/v3.1.0.tar.gz"
jzmqURL="https://github.com/zeromq/jzmq/archive/master.zip"
wget -O jzmq-master.zip -nc --no-check-certificate $jzmqURL

nanomqURL="https://github.com/nanomsg/nanomsg/archive/0.9-beta.tar.gz"
wget -O nanomsg-0.9-beta.tar.gz -nc $nanomqURL

wkhtmlURL="http://download.gna.org/wkhtmltopdf/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz"
wget -nc $wkhtmlURL

pdftkURL="https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk-2.02-src.zip"
wget -nc $pdftkURL

cd $PWD
