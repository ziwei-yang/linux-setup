source $HOME/.bash_profile
source $HOME/.bashrc

ARGS="$@"
echo "-------- setting up Linux environment $ARGS --------"
__SOURCE="${BASH_SOURCE[0]}"
__DIR="$( cd -P "$( dirname "$__SOURCE" )" && pwd )"

export LINUX_SETUP_COMMON=$__DIR
export LINUX_SETUP_HOME="$( cd -P $__DIR/../ && pwd )"
echo $LINUX_SETUP_HOME

export HOSTNAME=`hostname`
echo "HOST:$HOSTNAME"

source $LINUX_SETUP_HOME/util/util.sh

# Useful variables.
datetime=$( date +"%Y%m%d_%H%M%S_%N" )
datestr=$( date +"%Y%m%d" )
datestr_underline=$( date +"%Y_%m_%d" )

setup_sys_env

echo "-------- Overwritting functions. --------"
# Rewrite builtin echo with timestamp and file.
function log(){
	timeStr=$(date +'%m-%d %H:%M:%S')
	if [[ $0 == '-'* ]]; then
		filename=$0 # Detect interactive shells.
	else
		filename=$(basename $0)
	fi
	builtin echo -n "$timeStr [$filename]:"
	builtin echo $@
}

[[ ! -z $DIR ]] && echo "cd $DIR" && cd $DIR
