#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )
if [[ $os = "CentOS Linux release 7."* ]]; then
	if [[ $os < "CentOS Linux release 7.3" ]]; then
		abort "$os is not supported"
	fi
	can_sudo || abort "User has no privilege."
	status_exec sudo yum install -y yum-utils device-mapper-persistent-data lvm2
	status_exec sudo yum-config-manager \
		--add-repo \
	        https://download.docker.com/linux/centos/docker-ce.repo
	status_exec sudo yum makecache fast
	status_exec sudo yum -y install docker-ce
	silent_exec sudo groupadd docker
	status_exec sudo usermod -aG docker $USER
	# Configure Docker to start on boot
	# To disable this behavior, use disable instead.
	status_exec sudo systemctl enable docker
	status_exec sudo systemctl start docker
	status_exec docker run hello-world || \
		log_blue "Log out and log back in so that your group membership is re-evaluated."
	status_exec sudo wget --quiet -O /tmp/docker-machine https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m`
	status_exec sudo chmod +x /tmp/docker-machine
	status_exec sudo mv /tmp/docker-machine $USER_INSTALL/bin/
	status_exec $USER_INSTALL/bin/docker-machine --version

	# Install docker compose
	status_exec sudo curl -L \
		https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` \
		-o /usr/local/bin/docker-compose
	status_exec sudo chmod +x /usr/local/bin/docker-compose
	check_version "/usr/local/bin/docker-compose" '1.22' || \
		abort "docker-compose version is still not 1.22"
else
	abort "$os is not supported"
fi
