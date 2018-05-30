#!/bin/bash --login
source $HOME/.bash_profile
source $HOME/.bashrc

echo "Setting up Linux environment at $( date )"
echo "ARGS:$@"

__SOURCE="${BASH_SOURCE[0]}"
__DIR="$( cd -P "$( dirname "$__SOURCE" )" && pwd )"
export LINUX_SETUP_COMMON=$__DIR
export LINUX_SETUP_HOME="$( cd -P $__DIR/../ && pwd )"

source $LINUX_SETUP_HOME/util/util.sh

log_green "-------- Checking aphrodite repo --------"
export APD_HOME="$__DIR/../../aphrodite"
[[ -d $APD_HOME ]] && \
	log_blue "Skip aphrodite repo" || (
	USER_ARCHIVED="$HOME/archived"
	cd $USER_ARCHIVED
	status_exec rm -rf $USER_ARCHIVED/aphrodite
	status_exec git clone "git@github.com:celon/aphrodite.git" || \
		status_exec git clone "https://github.com/celon/aphrodite.git" || \
		abort "Failed to clone aphrodite"
	status_exec mv $USER_ARCHIVED/aphrodite $APD_HOME || \
		abort "Failed to mv aphrodite"
)
[[ -d $APD_HOME ]] || abort "Failed in initialize aphrodite"

export APD_HOME="$( cd -P $__DIR/../../aphrodite && pwd )"
export APD_BIN="$( cd -P $APD_HOME/bin && pwd )"

export USER_ARCHIVED="$HOME/archived"
export USER_INSTALL="$HOME/install"

for dir in $APD_BIN $USER_ARCHIVED $USER_INSTALL $LINUX_SETUP_COMMON
do
	[[ ! -d $dir ]] && abort "Could not locate $dir"
done

export HOSTNAME=`hostname`
log "HOST:$HOSTNAME"

# Useful variables.
datetime=$( date +"%Y%m%d_%H%M%S_%N" )
datestr=$( date +"%Y%m%d" )
datestr_underline=$( date +"%Y_%m_%d" )

setup_sys_env
