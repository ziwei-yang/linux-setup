#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY NOPYTHON

can_sudo || abort "Current user must can sudo"

os=$( osinfo )
if [[ $os == Ubuntu* ]]; then
	sudo apt-get remove certbot
elif [[ $os == "CentOS Linux "* ]]; then
	sudo yum -y install epel-release
	sudo yum -y install snapd
	sudo systemctl enable --now snapd.socket
	sudo ln -s /var/lib/snapd/snap /snap
else
	echo Unsupported OS $os
	exit -1
fi

sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

[ ! -d /var/nginx/www ] && \
	sudo mkdir -p /var/nginx/www && \
	sudo chown -R nginx /var/nginx && \
	sudo chgrp -R nginx /var/nginx

echo "Applying cert for [$@]"
sudo /usr/bin/certbot certonly --webroot \
	--webroot-path=/var/nginx/www \
	$@ # -d domain1 -d domain2
