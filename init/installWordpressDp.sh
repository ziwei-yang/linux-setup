#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
echo "cd $DIR"
cd $DIR

source $DIR/util/util.sh
setupBasicEnv

os=$( osinfo )

if [[ $os == 'Darwin' ]]; then
	MAKE_CORE_NUM=4
	echo "For Darwin/MacOSX, assume CPU Core:$MAKE_CORE_NUM"
else
	lastCPUID=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk '{print $3}')
	MAKE_CORE_NUM=$(($lastCPUID + 1))
	echo "CPU Core:$MAKE_CORE_NUM"
fi

echoGreen "-------- Checking environment. --------"
# Check sudo privilege.
ret=$( sudo -n echo a 2>&1 )
sudoAllowed="0"
if [[ $ret == "a" ]] && [[ $os != "Darwin" ]]; then
	echoBlue "User has sudo privilege without password."
	sudoAllowed="1"
else
	echoRed "WARN: User has no sudo privilege without password. Change /etc/sudoers first."
	exit -1
fi

# Wordpress dependency.
if [[ $os == CentOS* ]]; then
	sudo yum -y install httpd php php-mysql php-fpm php-cli php-common php-curl libxml2-devel libxml2 ImageMagick ImageMagick-devel libpng-devel libcurl libcurl-devel gd gd-devel php-gd php5-dom
elif [[ $os == Ubuntu* ]]; then
	sudo apt-get -y install llibxml2-dev libxml2 gfortran imagemagick imagemagick-dev libpng-dev curl libcurl3 libcurl3-dev php5-curl php5-gd php5-dom
else
	echo "Unsupport OS:$os"
fi

echoBlue "Remeber to modify .htaccess to enable permalink on wordpress, Set 'All' to all 'AllowOverride' in /etc/apache/conf/httpd.conf"
