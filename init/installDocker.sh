#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../

source $DIR/util/util.sh

setupBasicEnv
os=$( osinfo )
if [[ $os = "CentOS Linux release 7."* ]]; then
	if [[ $os < "CentOS Linux release 7.3" ]]; then
		abort "$os is not supported"
	fi
	isSudoAllowed || abort "User has no privilege."
	statusExec sudo yum install -y yum-utils
	statusExec sudo yum-config-manager \
		--add-repo \
	        https://download.docker.com/linux/centos/docker-ce.repo
	statusExec sudo yum makecache fast
	statusExec sudo yum -y install docker-ce
	silentExec sudo groupadd docker
	statusExec sudo usermod -aG docker $USER
	# Configure Docker to start on boot
	# To disable this behavior, use disable instead.
	statusExec sudo systemctl enable docker
	statusExec sudo systemctl start docker
	statusExec docker run hello-world || \
		echoBlue "Log out and log back in so that your group membership is re-evaluated."
else
	abort "$os is not supported"
fi
