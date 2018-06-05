function log {
	_time=$(date +'%m-%d %H:%M:%S')
	if [[ $0 == '-'* ]]; then
		_filename=$0 # Detect interactive shells.
	else
		_filename=$(basename $0)
	fi
	builtin echo -n "$_time [$_filename]:"
	builtin echo $@
}

function is_func {
	declare -f $1 > /dev/null
	return $?
}

function cursor_r {
	builtin echo -n -e "\r"
}

# Internal functions.
function log_red {
	log "$(tput setaf 1)$@$(tput sgr0)"
}

function echo_red {
	builtin echo "$(tput setaf 1)$@$(tput sgr0)"
}

function log_green {
	log "$(tput setaf 2)$@$(tput sgr0)"
}

function echo_green {
	builtin echo "$(tput setaf 2)$@$(tput sgr0)"
}

function log_blue {
	log "$(tput setaf 4)$@$(tput sgr0)"
}

function echo_blue {
	builtin echo "$(tput setaf 4)$@$(tput sgr0)"
}

function abort() {
	log_red "Script execution abort, reason: $@"
	exit -1
}

function find_path {
	_bin=$1
	_bin_path=`which $_bin 2>/dev/null`
	if [[ -z $_bin_path ]]; then
		# log_red "Could not locate [$_bin]"
		return 1
	else
		return 0
	fi
}

function assert_path {
	_bin=$1
	_bin_path=`which $_bin 2>/dev/null`
	if [[ -z $_bin_path ]]; then
		log_red "Could not locate [$_bin]"
		exit -1
	else
		return 0
	fi
}

function check_path {
	_bin=$1
	_bin_path=`which $_bin 2>/dev/null`
	if [[ $_bin_path == $2 ]]; then
		return 0
	else
		log_red "Could not locate [$2]"
		return 1
	fi
}

function check_version {
	_bin=$1
	find_path $_bin || return 1
	_sys_ver=`"$_bin" --version 2>&1`
	_req_ver=$2
	if [[ $_sys_ver =~ $_req_ver ]]; then
		log "[$_bin] version [${_sys_ver:0:20}] matched [$_req_ver]."
		return 0
	else
		log_red "[$_bin] version [$_sys_ver] not match [$_req_ver]."
		return 1
	fi
}

function check_newer_version {
	_bin=$1
	find_path $_bin || return -1
	_sys_ver=`"$_bin" --version 2>&1`
	_req_ver=$2
	if [[ $_sys_ver =~ $_req_ver ]]; then
		return 0
	elif [[ $_sys_ver > $_req_ver ]]; then
		return 0
	else
		log_red "[$_bin] version [$_sys_ver] is older than [$_req_ver]."
		return 1
	fi
}

function check_py_lib {
	_lib=$1
	_req_ver=$2
	_sys_ver=`pip freeze | grep "$_lib=="`
	if [[ -z $_sys_ver ]]; then
		log_red "Python lib $1 not exist."
		return 1
	elif [[ -z $2 ]]; then
		# Check lib existence is enough.
		:
	elif [[ "$_sys_ver" == "$_lib==$_req_ver" ]]; then
		:
	else
		log_red "[$_lib] version [$_sys_ver] not match [$_req_ver]."
		return 1
	fi
	return 0
}

function check_gem {
	_lib=$1
	_req_ver=$2
	_sys_ver=`gem list --local | grep -E "^$_lib\s"`
	if [[ -z $_sys_ver ]]; then
		log_red "Gem $1 not exist."
		return 1
	elif [[ -z $2 ]]; then
		# Check lib existence is enough.
		:
	elif [[ "$_sys_ver" == "$_lib ($_req_ver"* ]]; then
		:
	else
		log_red "[$_lib] version [$_sys_ver] not match [$_req_ver]."
		return 1
	fi
	return 0
}

function osinfo {
	if [[ -f /etc/redhat-release ]]; then
		head -n1 /etc/redhat-release
	elif [[ -f /etc/issue ]]; then
		head -n1 /etc/issue
	else
		uname
	fi
}

function ext_ip {
	curl 'http://ipinfo.io/ip'
}

function in_china {
	[[ $GFW_FUCKED == '0' ]] && return 0
	[[ $GFW_FUCKED == '1' ]] && return 1
	log "Checking if is fucked by GFW"
	_country=$( curl http://ipinfo.io/ | jq '.country' )
	log_green "Country Code: $_country"
	if [[ $_country == '"CN"' ]]; then
		log_red ' ============ OH NO, GFW sucks! =============='
		GFW_FUCKED=1
		return 0
	else
		GFW_FUCKED=0
		return 1
	fi
}

function can_sudo {
	[[ $SUDO_PRIVILEGE == '1' ]] && return 0
	[[ $SUDO_PRIVILEGE == '0' ]] && return 1
	_ret=$( sudo -n echo a 2>&1 )
	if [[ $_ret == "a" ]]; then
		log_blue "User has sudo privilege without password."
		SUDO_PRIVILEGE=1
		return 0
	else
		log_red "User has no sudo privilege."
		SUDO_PRIVILEGE=1
		return 1
	fi
}

function silent_exec {
	$@ > /dev/null 2>&1
	return $?
}

function status_exec {
	log -n "$@"
	silent_exec $@
	_ret=$?
	if [[ $_ret == 0 ]]; then
		is_func 'success' && success "$@" || \
			cursor_r && echo_green "[ OK ]"
	else
		is_func 'failure' && failure "$@" || \
			cursor_r && echo_red   "[FAIL]"
	fi
	return $_ret
}

function is_centos {
	[[ $OS == CentOS* ]] && return 0
	return 1
}
function is_centos6 {
	[[ $OS == "CentOS release 6"* ]] && return 0
	return 1
}
function is_centos7 {
	[[ $OS == "CentOS Linux release 7"* ]] && return 0
	return 1
}
function is_mac {
	[[ $OS == Darwin ]] && return 0
	return 1
}
function is_ubuntu {
	[[ $OS == Ubuntu* ]] && return 0
	return 1
}
function is_unknown_os {
	is_centos || is_mac || is_ubuntu || return 0
	return 1
}
function is_linux {
	[[ $( uname ) == 'Linux' ]] && return 0
	return 1
}
function is_failed {
	eval "$@"
	[[ $? == '0' ]] && return 1
	return 0
}

function absolute_path {
	[[ -z $1 ]] && echo $@ && return
	find_path "realpath" && realpath $@ && return
	_dir=$( dirname $1 )
	_bname=$( basename $1 )
	if [[ -d "$1" ]]; then
		_path=$( absolute_dir_path "$1/a" )
		builtin echo "$_path"
	elif [[ -d "$_dir" ]]; then
		_dir=$( absolute_dir_path $1 )
		builtin echo "$_dir/$_bname"
	else
		builtin echo $_dir
	fi
}

# If directory exists, return $dir/$file. Otherwise just echo same arguments.
function absolute_dir_path {
	[[ -z $1 ]] && echo $@ && return
	find_path "realpath" && dirname $( realpath $@ ) && return
	_dir=$( dirname $1 )
	[[ -d "$1" ]] && _dir=$( cd -P "$1" && cd ..  && pwd )
	[ ! -d "$_dir" ] && builtin echo $@ && return
	_dir=$( cd -P "$_dir" && pwd )
	builtin echo $_dir
}

function setup_sys_env {
	log_green "-------- checking system --------"
	assert_path "echo"
	assert_path "sudo"
	assert_path "cp"
	assert_path "wc"
	assert_path "cat"
	assert_path "head"
	assert_path "dirname"
	assert_path "basename"
	
	# Check OS
	OS=$( osinfo )
	log_blue "Current OS: $OS"
	is_centos && (
		assert_path "yum"
		assert_path "rpm"
	)
	is_ubuntu && assert_path "apt-get"
	is_mac && (
		find_path "brew" && log_blue "Skip install brew." || (
			log_blue "Installing brew."
			ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		)
	)
	is_unknown_os && abort "Error: OS is not CentOS/Ubuntu/MacOSX."

	# Check CPU Core num.
	is_mac && (
		CPU_CORE=4
		log "For Darwin/MacOSX, assume CPU Core:$CPU_CORE"
	) || (
		_lastCPUID=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk '{print $3}')
		CPU_CORE=$(($_lastCPUID + 1))
		log "CPU Core:$CPU_CORE"
	)

	unset SUDO_PRIVILEGE
	unset GFW_FUCKED
}

# Check basic ruby environment for email script.
function setup_basic_ruby_env {
	log_green "-------- checking Basic Ruby Env --------"
	log "APD_HOME: $APD_HOME"
	assert_path "ruby"
	assert_path "gem"
	check_gem 'mail' || gem install 'mail' || abort "Gem mail installation failed."
	_mail_script=$APD_HOME/bin/mail_task.rb
	if [[ -f $_mail_script ]]; then
		# Try to pull latest version if no diff exists.
		_diff=$( cd $APD_HOME && git diff )
		[[ -z $_diff ]] && ( cd $APD_HOME && status_exec git pull ) || \
			log_blue "git diff exists inside $APD_HOME"
		return
	fi
	log "Cloning aphrodite ruby repo: $APD_HOME"
	USER_ARCHIVED="$HOME/archived"
	cd $USER_ARCHIVED
	status_exec rm -rf $USER_ARCHIVED/aphrodite
	status_exec git clone "git@github.com:celon/aphrodite.git" || \
		status_exec git clone "https://github.com/celon/aphrodite.git" || \
		abort "Failed to clone aphrodite"
	status_exec mv $USER_ARCHIVED/aphrodite $APD_HOME || \
		abort "Failed to mv aphrodite"
}

# Send email with content in file.
function mail_file {
	_file=$1
	_title=$2
	_recipient=$3
	_format=$4

	_mail_script=$APD_HOME/bin/mail_task.rb
	if [ ! -f $_mail_script ]; then
		log "No mail script $_mail_script found, skip sending email."
	elif [ -z "$_recipient" ]; then
		log 'No mail recipient found, skip sending email.'
	elif [[ ! -f $_file ]]; then
		log "Sending email to $_recipient with NO content"
		log "ruby $_mail_script -s '$_title' -r '$_recipient'"
		ruby $_mail_script -s "$_title" -r "$_recipient"
	elif [[ $_format == "html" ]]; then
		log "Sending email to $_recipient with file $_file in $_format"
		ruby $_mail_script -s "$_title" -r "$_recipient" -h "$_file"
	elif [[ $_format == "ansi2html" ]]; then
		log "Sending email to $_recipient with file $_file in $_format"
		_file2html="/tmp/$bname.html"
		aha -f $_file > $_file2html || abort "Failed in converting file to html"
		ruby $_mail_script -s "$_title" -r "$_recipient" -h "$_file2html"
	elif [[ $_format == "attachment" ]]; then
		log "Sending email to $_recipient with file $_file"
		ruby $_mail_script -s "$_title" -r "$_recipient" -a "$_file"
	else
		log "Sending email to $_recipient with file $_file in plain text"
		cat -v $_file | mail -s "$_title" $_recipient
	fi
}

# Usage: mail_task_log recipient task_script start_time log_file (error_msgs)
function mail_task_log {
	log "Sending log via email at $( date ): $@"
	_recipient=$1
	shift
	_script=$1
	shift
	_start_datetime=$1
	shift
	_log_file=$1
	shift

	# Build short _title: max_shown_length=30
	_script_length=${#_script}
	_chopped_script_name=$_script
	if [[ $_script_length -gt 30 ]]; then
		_chopped_script_name=${_script:$((_script_length-27)):$_script_length}
		_chopped_script_name="...$_chopped_script_name"
	fi
	# display datetime length 15=8+1+6
	_chopped_time=${_start_datetime:0:15}
	_title="Log $_chopped_script_name at $_chopped_time"

	# Append error message if available.
	_errmsg=$1
	[[ ! -z $_errmsg && $_errmsg != '' ]] && _title="$_title : terminated : $@"

	mail_file "$_log_file" "$_title" "$_recipient" 'ansi2html'
}

function find_process {
	if [ -z $1 ]; then
		return
	fi

	_keyword=""
	_user=""
	IFS="@"
	for seg in $1;do
		if [[ $_keyword == "" ]];then _keyword=$seg; continue; fi
		if [[ $_user == "" ]];then _user=$seg; continue; fi
	done
	IFS=" "
	_res=$(ps aux | grep -v grep | grep "^$_user" | grep -F $_keyword)
	log $_res
}
