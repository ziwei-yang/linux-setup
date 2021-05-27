#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY NOPYTHON

if [[ $USER != 'root' ]]; then
	echo Current user must be root.
	exit -1
fi

os=$( osinfo )
if [[ $os == Ubuntu* ]]; then
	status_exec snap install core
	status_exec snap refresh core
	status_exec apt-get remove certbot
	status_exec snap install --classic certbot
	status_exec ln -s /snap/bin/certbot /usr/bin/certbot
	echo "Applying cert for [$@]"
	sudo /usr/bin/certbot certonly --webroot \
		--webroot-path=/var/nginx/www \
		$@ # -d domain1 -d domain2
elif [[ $os == "CentOS Linux "* ]]; then
	cd /tmp
	status_exec wget https://dl.eff.org/certbot-auto
	status_exec chmod u+x /tmp/certbot-auto
	echo "Applying cert for [$@]"
	sudo /tmp/certbot-auto certonly --webroot \
		--webroot-path=/var/nginx/www \
		$@ # -d domain1 -d domain2
else
	echo Unsupported OS $os
	exit -1
fi
