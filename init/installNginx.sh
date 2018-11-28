#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )
USER=$( whoami )
if [[ $USER != 'root' ]]; then
	echo Current user must be root.
	exit -1
fi

if [[ $os == "CentOS Linux release 7"* ]]; then
	if [[ ! -f /etc/yum.repos.d/nginx.repo ]]; then
		echo "[nginx]" > /etc/yum.repos.d/nginx.repo
		echo "name=nginx repo" >> /etc/yum.repos.d/nginx.repo
		echo "baseurl=http://nginx.org/packages/centos/7/\$basearch/" >> /etc/yum.repos.d/nginx.repo
		echo "gpgcheck=0" >> /etc/yum.repos.d/nginx.repo
		echo "enabled=1" >> /etc/yum.repos.d/nginx.repo
	fi
elif [[ $os == "CentOS Linux release 6"* ]]; then
	if [[ ! -f /etc/yum.repos.d/nginx.repo ]]; then
		echo "[nginx]" > /etc/yum.repos.d/nginx.repo
		echo "name=nginx repo" >> /etc/yum.repos.d/nginx.repo
		echo "baseurl=http://nginx.org/packages/centos/6/\$basearch/" >> /etc/yum.repos.d/nginx.repo
		echo "gpgcheck=0" >> /etc/yum.repos.d/nginx.repo
		echo "enabled=1" >> /etc/yum.repos.d/nginx.repo
	fi
fi

for app in nginx
do
	find_path $app && continue
	if [[ $os == CentOS* ]]; then
		can_sudo || abort "Must be allowed"
		status_exec yum -y install $app
	elif [[ $os == Ubuntu* ]]; then
		can_sudo || abort "Must be allowed"
		status_exec apt-get -y install $app
	elif [[ $os == "Darwin" ]]; then
		status_exec brew install $app
	fi
done

if [[ $os == CentOS* ]]; then
	status_exec yum -y remove nginx-mod-*
	status_exec yum -y install nginx-module-*
	echo "Installing certbot"
	status_exec yum -y install python2-certbot-nginx
elif [[ $os == Ubuntu* ]]; then
	:
elif [[ $os == "Darwin" ]]; then
	:
fi
