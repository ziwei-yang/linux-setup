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

for app in conda
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

