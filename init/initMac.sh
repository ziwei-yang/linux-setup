#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
echo "cd $DIR"
cd $DIR

# Pre-defined vars.
newhostname=''

source $DIR/util/util.sh

USER=$( whoami )
os=$( osinfo )
if [[ $os != 'Darwin' ]]; then
	echo "Unsupport OS $os"
	exit -1
fi

# Install apple git.
xcode-select --install > /dev/null 2>&1

# Install homebrew.
find_path brew
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip installing homebrew."
else
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install wget git curl.
brew install wget git curl
