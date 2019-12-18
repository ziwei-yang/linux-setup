#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

uname=$( uname )
source $DIR/../util/util.sh
find_path "wget"
cd $DIR

function dl {
	wget -c --no-cookies --no-check-certificate -nc $@
}

function dl_oracle {
	wget --header "Cookie: oraclelicense=accept-securebackup-cookie" -c --no-cookies --no-check-certificate -nc $@
}

function dl_dir {
	dl --execute robots=off --no-parent -nH --level=1 --recursive $@
}

if [[ $uname == 'Linux' ]]; then
	url="http://www.oracle.com"
	jdk_version=8
	ext='tar.gz'
	jdk_download_url1="$url/technetwork/java/javase/downloads/index.html"
	jdk_download_url2=$(
		curl -L -s $jdk_download_url1 | \
		egrep -o "\/technetwork\/java/\javase\/downloads\/jdk${jdk_version}-downloads-.+?\.html" | \
		head -1 | \
		cut -d '"' -f 1
	    )
	jdk_download_url3="${url}${jdk_download_url2}"
	jdk_download_url4=$(
		curl -L -s $jdk_download_url3 | \
	        egrep -o "https\:\/\/download.oracle\.com\/otn\/java\/jdk\/[8-9](u[0-9]+|\+).*\/jdk-${jdk_version}.*(-|_)linux-(x64|x64_bin).$ext"
	)
	jdk_downloaded=0
	for u in $jdk_download_url4; do
		# TODO Still needs a Oracle login.
		status_exec dl_oracle $u && jdk_downloaded=1
	done
	if [[ $jdk_downloaded == 0 ]]; then
		# Fallback to download from bithkex.
		status_exec dl 'https://gigo.ai/download/jdk-8u201-linux-x64.tar.gz'
	fi
	
	# 2.7.14 could not be compiled on CentOS 8, 2.7.17 could make it.
	pythonURL="https://www.python.org/ftp/python/2.7.17/Python-2.7.17.tar.xz"
	status_exec dl $pythonURL
	
	python3URL="https://www.python.org/ftp/python/3.5.9/Python-3.5.9.tar.xz"
	status_exec dl $python3URL
	
	pyPipURL="https://bootstrap.pypa.io/get-pip.py"
	status_exec dl $pyPipURL
fi

redisURL="http://download.redis.io/releases/redis-4.0.8.tar.gz"
status_exec dl $redisURL

phantomjsURL="http://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2"
status_exec dl $phantomjsURL

mavenURL="http://ftp.cuhk.edu.hk/pub/packages/apache.org/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz"
status_exec dl $mavenURL

libsodiumURL="http://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz"
zeromqURL="https://github.com/zeromq/libzmq/releases/download/v4.3.2/zeromq-4.3.2.tar.gz"
is_centos6 && \
	zeromqURL="https://github.com/zeromq/zeromq4-1/releases/download/v4.1.6/zeromq-4.1.6.tar.gz"
status_exec dl $libsodiumURL
status_exec dl $zeromqURL

jzmqURL="https://github.com/zeromq/jzmq/archive/master.zip"
status_exec wget -nc -O jzmq-master.zip $jzmqURL

nanomqURL="https://github.com/nanomsg/nanomsg/archive/1.1.5.zip"
status_exec wget -nc -O nanomsg-1.1.5.zip $nanomqURL

pdftkURL="https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk-2.02-src.zip"
status_exec dl $pdftkURL

mongoURL="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.4.2.tgz"
status_exec dl $mongoURL

antURL="http://apache.communilink.net/ant/binaries/"
status_exec dl_dir --cut-dirs=2 -A 'bin.zip' $antURL

moshURL='https://mosh.org/mosh-1.3.2.tar.gz'
status_exec dl $moshURL

pdftkURL='https://www.linuxglobal.com/static/blog/pdftk-2.02-1.el7.x86_64.rpm'
status_exec dl $pdftkURL

cd $PWD
