#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../

source $DIR/util/util.sh

setupBasicEnv
USER_INSTALL="$HOME/install"
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
	statusExec wget --quiet -O /tmp/docker-machine https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m` && \
		chmod +x /tmp/docker-machine && \
		statusExec mv /tmp/docker-machine $USER_INSTALL/bin/
	statusExec $USER_INSTALL/bin/docker-machine --version
else
	abort "$os is not supported"
fi
