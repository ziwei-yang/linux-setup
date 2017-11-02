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
	# version: 17.09
	if [[ $os < "CentOS Linux release 7.3" ]]; then
		abort "$os is not supported"
	fi
	isSudoAllowed || abort "User has no privilege."
	statusExec sudo yum remove docker docker-common docker-selinux docker-engine
else
	abort "$os is not supported"
fi
