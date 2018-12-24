#!/bin/bash --login
declare -F status_exec && [[ $LINUX_SETUP_LOAD == '1' ]] && echo "Skip loading linux-setup again." && return
source $HOME/.bash_profile
source $HOME/.bashrc

export HOSTNAME=`hostname`
echo "HOST:$HOSTNAME"

echo "Setting up Linux environment at $( date )"
[ ! -z $1 ] && echo "bootstrap args:$@"

__SOURCE="${BASH_SOURCE[0]}"
__DIR="$( cd -P "$( dirname "$__SOURCE" )" && pwd )"

export LINUX_SETUP_COMMON=$__DIR
export LINUX_SETUP_HOME="$( cd -P $__DIR/../ && pwd )"
source $LINUX_SETUP_HOME/util/util.sh
export LINUX_SETUP_COMMON=$( absolute_path $LINUX_SETUP_HOME )
export LINUX_SETUP_HOME=$( absolute_path $LINUX_SETUP_HOME )

if [[ $@ != *NORUBY* ]]; then
	export APD_HOME=$( absolute_path $LINUX_SETUP_HOME/../aphrodite )
	export APD_BIN="$APD_HOME/bin"
	setup_basic_ruby_env
fi

export USER_ARCHIVED="$HOME/archived"
export USER_INSTALL="$HOME/install"
[ ! -d $USER_ARCHIVED ] && mkdir -p $USER_ARCHIVED
[ ! -d $USER_INSTALL ] && mkdir -p $USER_INSTALL

for dir in $APD_BIN $USER_ARCHIVED $USER_INSTALL $LINUX_SETUP_COMMON
do
	[[ ! -d $dir ]] && abort "Could not locate $dir"
done

# Useful variables.
datetime=$( date +"%Y%m%d_%H%M%S_%N" )
datestr=$( date +"%Y%m%d" )
datestr_underline=$( date +"%Y_%m_%d" )

setup_sys_env

export LINUX_SETUP_LOAD=1
