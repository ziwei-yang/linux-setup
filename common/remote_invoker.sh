#!/bin/bash --login
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/bootstrap.sh NOARG
log "$SOURCE received args: $@"

setup_basic_ruby_env

######################### FUNC #########################
function finished {
	log "remote_invoker:Finished() called: $@"
	mail_task_log "$email_recipient" "$script" "$start_datetime" "$log_file" $@
	_errmsg=$1
	[[ ! -z $_errmsg && $_errmsg != '' ]] && abort $_errmsg
	exit 0
}

######################### ARGS #########################
start_datetime=$datetime
log_file=''
email_recipient=''
# Load email recipient by default.
recipient_file="$DIR/../conf/log_mail_recipients"
if [[ -f $recipient_file ]]; then
	email_recipient=`cat $recipient_file`
fi
loop=0
parsed_arg_ct=0
max_time=86400 # Default timeout: 24*3600=1day
while getopts "t:e:l:L" opt; do
	case $opt in
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
			log "Output will be saved to: $log_file"
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
log "Args shifted: $parsed_arg_ct"
while [[ $parsed_arg_ct -gt 0 ]]; do
	parsed_arg_ct=$((parsed_arg_ct-1))
	shift
done

# Extract script.
log "Remained are script and args: $@"
script=$1
[[ -z $script || ! -f $script ]] && finished "Target script $script not exist!"
script=$( absolute_path "$1" )
script_dir=$( absolute_dir_path $script )
script_basename=$( basename $script )
log "script: $script"
shift

# Prepare log dir.
if [[ $log_file == '' ]]; then
	log_dir="$script_dir/logs/$script_basename"
	log_file="$log_dir/$datetime"
	[[ -d $log_dir ]] || \
		mkdir -p $log_dir || \
		finished "Log directory $log_dir can not be created!"
fi
log "Output will be saved to: $log_file"

# Check args.
[[ $loop == 1 && ! -z $log_file ]] && finished "Log should not be specified in loop mode."

# Make runner.sh running at background.
log "scrpit : $script" >> $log_file
log "args   : $@" >> $log_file
log "command: $DIR/runner.sh -r 'service_status' -t $max_time -e '$email_recipient' -l '$log_file' '$script' $@"
nohup unbuffer bash --login "$DIR/runner.sh" -r 'service_status' -t $max_time -e "$email_recipient" -l "$log_file" "$script" $@ >> $log_file 2>&1 &
