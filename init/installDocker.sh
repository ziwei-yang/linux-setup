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
	require_version='17.09'
	if [[ $os < "CentOS Linux release 7.3" ]]; then
		abort "$os is not supported"
	fi
	isSudoAllowed || abort "User has no privilege."
	statusExec sudo yum install -y yum-utils device-mapper-persistent-data lvm2
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
	statusExec sudo wget --quiet -O /tmp/docker-machine https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m`
	statusExec sudo chmod +x /tmp/docker-machine
	statusExec sudo mv /tmp/docker-machine $USER_INSTALL/bin/
	statusExec $USER_INSTALL/bin/docker-machine --version

	# Install docker compose
	statusExec sudo curl -L \
		https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` \
		-o /usr/local/bin/docker-compose
	statusExec sudo chmod +x /usr/local/bin/docker-compose
	checkBinVersion "/usr/local/bin/docker-compose" '1.17' || \
		abort "docker-compose version is still not 1.17"
else
	abort "$os is not supported"
fi
