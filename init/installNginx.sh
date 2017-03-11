#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../

source $DIR/util/util.sh

setupBasicEnv
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
	checkBinPath $app && continue
	if [[ $os == CentOS* ]]; then
		isSudoAllowed || abort "Must be allowed"
		statusExec yum -y install $app
	elif [[ $os == Ubuntu* ]]; then
		isSudoAllowed || abort "Must be allowed"
		statusExec apt-get -y install $app
	elif [[ $os == "Darwin" ]]; then
		statusExec brew install $app
	fi
done

if [[ $os == CentOS* ]]; then
	statusExec yum -y remove nginx-mod-*
	statusExec yum -y install nginx-module-*
elif [[ $os == Ubuntu* ]]; then
	:
elif [[ $os == "Darwin" ]]; then
	:
fi
