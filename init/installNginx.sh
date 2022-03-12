#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )
USER=$( whoami )
can_sudo || abort "Current user can not sudo"

if [[ $os == "CentOS Linux release 7"* ]]; then
	if [[ ! -f /etc/yum.repos.d/nginx.repo ]]; then
		sudo echo "[nginx]" > /etc/yum.repos.d/nginx.repo
		sudo echo "name=nginx repo" >> /etc/yum.repos.d/nginx.repo
		sudo echo "baseurl=http://nginx.org/packages/centos/7/\$basearch/" >> /etc/yum.repos.d/nginx.repo
		sudo echo "gpgcheck=0" >> /etc/yum.repos.d/nginx.repo
		sudo echo "enabled=1" >> /etc/yum.repos.d/nginx.repo
	fi
elif [[ $os == "CentOS Linux release 6"* ]]; then
	if [[ ! -f /etc/yum.repos.d/nginx.repo ]]; then
		sudo echo "[nginx]" > /etc/yum.repos.d/nginx.repo
		sudo echo "name=nginx repo" >> /etc/yum.repos.d/nginx.repo
		sudo echo "baseurl=http://nginx.org/packages/centos/6/\$basearch/" >> /etc/yum.repos.d/nginx.repo
		sudo echo "gpgcheck=0" >> /etc/yum.repos.d/nginx.repo
		sudo echo "enabled=1" >> /etc/yum.repos.d/nginx.repo
	fi
fi

for app in nginx
do
	find_path $app && continue
	if [[ $os == CentOS* ]]; then
		status_exec sudo yum -y install $app
	elif [[ $os == Ubuntu* ]]; then
		status_exec sudo apt-get -y install $app
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
