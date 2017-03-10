#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../

source $DIR/util/util.sh

setupBasicEnv
os=$( osinfo )

for app in nginx
do
	checkBinPath $app && continue
	if [[ $os == CentOS* ]]; then
		isSudoAllowed || abort "Must be sudo allowed"
		statusExec sudo yum -y install $app
	elif [[ $os == Ubuntu* ]]; then
		isSudoAllowed || abort "Must be sudo allowed"
		statusExec sudo apt-get -y install $app
	elif [[ $os == "Darwin" ]]; then
		statusExec brew install $app
	fi
done

if [[ $os == CentOS* ]]; then
	statusExec sudo yum -y install nginx-all-modules
elif [[ $os == Ubuntu* ]]; then
	:
elif [[ $os == "Darwin" ]]; then
	:
fi
