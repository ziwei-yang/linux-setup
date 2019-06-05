#!/bin/bash --login
[[ -z $CURRENT_DIR ]] && CURRENT_DIR=$( pwd )
SOURCE="${BASH_SOURCE[0]}"
RUNNER_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $RUNNER_DIR/bootstrap.sh NOARG
log "$SOURCE received args: $@"

setup_basic_ruby_env

######################### FUNC #########################
function record_status {
	if [[ ! -f $APD_BIN/redis_cmd.rb ]]; then
		log_red "Could not locate $APD_BIN/redis_cmd.rb to record status"
		return
	fi
	if [[ -z $REDIS_HOST ]]; then
		log_red "No REDIS_HOST to record status"
		return
	fi
	_redis_hash=$1
	[[ -z $_redis_hash ]] && _redis_hash="unkown_status"
	shift
	_timestr=$( date +'%Y%m%d_%H%M%S_%N' )
	log "Redis [$REDIS_HOST] hset: $_redis_hash $script_key -> $_timestr $@"
	_value=$( builtin echo -n $_timestr $@ | openssl base64 )
	ruby $APD_BIN/redis_cmd.rb -h "$_redis_hash" -k "$script_key" -v "$_value" -e base64
	ruby $APD_BIN/redis_cmd.rb -k "$_redis_hash:$script_key" -v "$_value" -e base64 -m array_append
}

function finished {
	log "runner.sh:Finished() called: $@"
	_errmsg=$1
	if [[ -z $_errmsg || $_errmsg == '' ]]; then
		# No message is good message.
		record_status $redis_hash 'FINISH' $@
	else
		record_status $redis_hash $@
	fi
	if [[ -z $log_file ]]; then
		_tmp_log='/tmp/tmp.log'
		echo "$@" > $_tmp_log
	else
		_tmp_log=$log_file
	fi
	mail_task_log "$email_recipient" "$script" "$start_datetime" "$_tmp_log" $@
	[[ ! -z $_errmsg && $_errmsg != '' ]] && abort $_errmsg
	exit 0
}

function signal_caught {
	log_red "Abnormal signal caught while running $script"
	finished "signal_caught"
}

######################### ARGS #########################
start_datetime=$LINUX_SETUP_DATETIME
log_file=''
email_recipient=''
redis_hash=''
loop=0
parsed_arg_ct=0
max_time=86400 # Default timeout: 24*3600=1day
while getopts "r:t:e:l:L" opt; do
	case $opt in
		r)
			parsed_arg_ct=$((parsed_arg_ct+2))
			log "Record status in redis hash: $OPTARG"
			redis_hash=$OPTARG
			;;
		t)
			parsed_arg_ct=$((parsed_arg_ct+2))
			log "Allowed max-time : $OPTARG"
			max_time=$OPTARG
			;;
		e)
			parsed_arg_ct=$((parsed_arg_ct+2))
			log "Log will be email to: $OPTARG"
			email_recipient=$OPTARG
			;;
		l)
			parsed_arg_ct=$((parsed_arg_ct+2))
			log_file=$( absolute_path "$OPTARG" )
			log "Treat $log_file as log_file."
			[[ ! -d $log_file ]] || \
				finished "Target log file $log_file is a directory."
			touch $log_file || \
				finished "Target log file $log_file could not be created!"
			;;
		L)
			parsed_arg_ct=$((parsed_arg_ct+1))
			log "Loop mode: ON"
			loop=1
			;;
		\?)
			log "Unknown opt: $OPT-$OPTARG, arguments parser break."
			break
			;;
		:)
			finished "Option -$OPTARG requires an argument."
	esac
done
# Continue parsing arguments.
log "Args shifted: $parsed_arg_ct"
while [[ $parsed_arg_ct -gt 0 ]]; do
	parsed_arg_ct=$((parsed_arg_ct-1))
	shift
done

# Parse and reformat script path.
log "Remained are script and args: $@"
script=$1
[[ -z $script || ! -f $script ]] && finished "Target script $script not exist!"
script=$( absolute_path "$1" )
script_dir=$( absolute_dir_path $script )
script_basename=$( basename $script )
shift

# Checking arguments.
[[ $loop == 1 && ! -z $log_file ]] && finished "Log should not be specified in loop mode."
[[ $loop != 1 && -z $log_file ]] && finished "Log should be specified in normal mode."
# Set default redis_hash prefix for loop task.
[[ $loop == 1 && -z $redis_hash ]] && redis_hash='loop_tasks'
if [[ -z $email_recipient ]]; then
	recipient_file="$RUNNER_DIR/../conf/log_mail_recipients"
	if [[ -f $recipient_file ]]; then
		email_recipient=`cat $recipient_file`
		log "Use default log_mail_recipients: $email_recipient"
	fi
fi

proj_dir=''
# Search for Proj dir for redis key
current_dir=$script_dir
while true; do
	[[ -d "$current_dir/.git" ]] && proj_dir=$current_dir && break
	current_dir=$( cd $current_dir/.. && pwd )
	[[ $current_dir == '/' ]] && break
done
unset current_dir
if [[ $proj_dir == '' ]]; then
	log "Cannot find proj dir of $script_name"
else
	proj_dir_len=${#proj_dir}
	script_key=${script_dir:$proj_dir_len}
	script_key="$script_key/$script_basename"
	log "Proj dir: $proj_dir"
	log "Script key: $script_key"
fi

######################### MAIN #########################
log "cd $script_dir"
cd $script_dir
if [ $loop -eq 1 ]; then
	# Prepare log dir.
	log_dir="$script_dir/logs/$script_basename/"
	if [ ! -d $log_dir ]; then
		mkdir -p $log_dir || finished "Log directory $log_dir can not be created!"
	fi
	# Log for each time of running. 
	while true; do
		log_file="$log_dir/$( date +'%Y%m%d_%H%M%S_%N' )"
		log "source $script $@ >> $log_file"
		record_status $redis_hash 'START' $@
		unbuffer $script $@ 2>&1 | tee $log_file
		record_status $redis_hash 'FINISH' $@
		log "$script finished"
		if [ ! -z $email_recipient ]; then
			log_blue "Email alert after 3 seconds."
			sleep 3
			log_snap_file="/tmp/err_$( date +'%Y%m%d_%H%M%S_%N' )_$script_basename.log"
			tail -n 250 $log_file > $log_snap_file
			sendFileAsMail "$dateTime" "$log_snap_file" "content." "$script terminated" "$email_recipient" 'ansi2html'
		fi
		log_blue "Retry script after 3 seconds."
		sleep 3
	done
else
	# Trap fatal error for email, 'cd' after trap will make it useless?
	trap "signal_caught $script $log_file" EXIT SIGKILL
	record_status $redis_hash 'START' $@
	if [[ $max_time -gt 0 ]]; then
		# With homebrew-installed coreutils on OS X
		# the command is available as gtimeout
		log "timeout $max_time $script $@ 2>&1"
		timeout $max_time $script $@ 2>&1
	else
		log "$script $@ 2>&1"
		$script $@ 2>&1
	fi
	ret=$?
	errmsg=''
	if [[ $max_time -gt 0 && $ret == 124 ]]; then
		errmsg="terminated for timeout"
		log $errmsg
	elif [[ $ret -gt 0 ]]; then
		errmsg="terminated with code $ret"
		log $errmsg
	else
		log "exit successfully with code $ret"
	fi
	log "cd $RUNNER_DIR"
	cd $RUNNER_DIR
	finished $errmsg
fi
