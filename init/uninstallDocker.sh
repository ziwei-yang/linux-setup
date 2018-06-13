#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

USER_INSTALL="$HOME/install"
os=$( osinfo )
if [[ $os = "CentOS Linux release 7."* ]]; then
	if [[ $os < "CentOS Linux release 7.3" ]]; then
		abort "$os is not supported"
	fi
	can_sudo || abort "User has no privilege."
	status_exec sudo yum -y remove docker \
		docker-client \
		docker-client-latest \
		docker-common \
		docker-latest \
		docker-latest-logrotate \
		docker-logrotate \
		docker-selinux \
		docker-engine-selinux \
		docker-engine
	if [ -d /var/lib/docker/ ]; then
		log "/var/lib/docker/ still exists, purge it if needed"
	fi
else
	abort "$os is not supported"
fi
