USER_ARCHIVED="$HOME/archived"
USER_INSTALL="$HOME/install"

function is_func {
	declare -f $1 > /dev/null
	return $?
}

# Internal functions.
function log_red {
	echo "$(tput setaf 1)$@$(tput sgr0)"
}

function echo_red {
	builtin echo "$(tput setaf 1)$@$(tput sgr0)"
}

function log_green {
	echo "$(tput setaf 2)$@$(tput sgr0)"
}

function echo_green {
	builtin echo "$(tput setaf 2)$@$(tput sgr0)"
}

function log_blue {
	echo "$(tput setaf 4)$@$(tput sgr0)"
}

function echo_blue {
	builtin echo "$(tput setaf 4)$@$(tput sgr0)"
}

function abort() {
	log_red "Script execution abort, reason: $@"
	exit -1
}

function find_path {
	bin=$1
	binPath=`which $bin 2>/dev/null`
	if [[ -z $binPath ]]; then
		log_red "Could not locate [$bin]"
		return 1
	else
		return 0
	fi
}

function assert_path {
	bin=$1
	binPath=`which $bin 2>/dev/null`
	if [[ -z $binPath ]]; then
		log_red "Could not locate [$bin]"
		exit -1
	else
		return 0
	fi
}

function check_path {
	bin=$1
	correctPath=$2
	binPath=`which $bin 2>/dev/null`
	if [[ $binPath == $2 ]]; then
		return 0
	else
		log_red "Could not locate [$2]"
		return 1
	fi
}

function check_version {
	bin=$1
	find_path $bin || return 1
	sysVer=`"$bin" --version 2>&1`
	ver=$2
	if [[ $sysVer =~ $ver ]]; then
		echo "[$bin] version [${sysVer:0:20}] matched [$ver]."
		return 0
	else
		log_red "[$bin] version [$sysVer] not match [$ver]."
		return 1
	fi
}

function check_newer_version {
	bin=$1
	find_path $bin || return -1
	sysVer=`"$bin" --version 2>&1`
	ver=$2
	if [[ $sysVer =~ $ver ]]; then
		return 0
	elif [[ $sysVer > $ver ]]; then
		return 0
	else
		log_red "[$bin] version [$sysVer] is older than [$ver]."
		return 1
	fi
}

function check_py_lib {
	libName=$1
	libVer=$2
	sysLibVer=`pip freeze | grep "$libName=="`
	if [[ -z $sysLibVer ]]; then
		log_red "Python lib $1 not exist."
		return 1
	elif [[ -z $2 ]]; then
		# Check lib existence is enough.
		:
	elif [[ "$sysLibVer" == "$libName==$libVer" ]]; then
		:
	else
		log_red "[$libName] version [$sysLibVer] not match [$libVer]."
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
	echo "Checking if is fucked by GFW"
	country=$( curl http://ipinfo.io/ | jq '.country' )
	log_green "Country Code: $country"
	if [[ $country == '"CN"' ]]; then
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
	ret=$( sudo -n echo a 2>&1 )
	if [[ $ret == "a" ]]; then
		log_blue "User has sudo privilege without password."
		SUDO_PRIVILEGE=1
		return 0
	else
		log_red "User has no sudo privilege."
		SUDO_PRIVILEGE=0
		return 1
	fi
}

function silent_exec {
	$@ > /dev/null 2>&1
	return $?
}

function status_exec {
	echo -n "$@"
	silent_exec $@
	ret=$?
	if [[ $ret == 0 ]]; then
		is_func 'success' && success "$@" && builtin echo || \
			echo_green "    [  OK  ]"
	else
		is_func 'failure' && failure "$@" && builtin echo || \
			echo_red "    [FAILED]"
	fi
	return $ret
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

function setup_sys_env {
	log_green "-------- checking system --------"
	assert_path "echo"
	assert_path "sudo"
	assert_path "cp"
	assert_path "wc"
	assert_path "cat"
	assert_path "head"
	
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
	CPU_CORE=4
	is_mac && (
		echo "For Darwin/MacOSX, assume CPU Core:$CPU_CORE"
	) || (
		lastCPUID=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk '{print $3}')
		CPU_CORE=$(($lastCPUID + 1))
		echo "CPU Core:$CPU_CORE"
	)

	unset SUDO_PRIVILEGE
	unset GFW_FUCKED
}

# Send email with content in file.
function mail_file {
	datetime=$1
	filepath=$2
	message=$3
	title=$4
	recipient=$5
	format=$6

	if [ -z "$recipient" ]; then
		echo 'No mail recipient found, skip sending email.'
        return
	elif [[ ! -f $filepath ]]; then
		echo "Sending email to $recipient with NO content"
		echo "ruby $__DIR/mail_task.rb -s '$title' -r '$recipient'"
		ruby $__DIR/mail_task.rb -s "$title" -r "$recipient"
    fi
	# Extract error lines in front of log, replaced the original file in email.
	bname=`basename $filepath`

	echo "Sending email to $recipient with file $filepath"
	if [[ $format == "html" ]]; then
		echo "Sending email to $recipient with file $filepath in $format"
		ruby $LINUX_SETUP_COMMON/mail_task.rb -s "$title" -r "$recipient" -h "$filepath"
	elif [[ $format == "ansi2html" ]]; then
		echo "Sending email to $recipient with file $filepath in $format"
		file2html="/tmp/$bname.html"
		aha -f $filepath > $file2html || abort "Failed in converting file to html"
		echo "ruby $__DIR/mail_task.rb -s '$title' -r '$recipient' -h '$file2html'"
		ruby $__DIR/mail_task.rb -s "$title" -r "$recipient" -h "$file2html"
	elif [[ $format == "attachment" ]]; then
		echo "Sending email to $recipient with file $filepath"
		ruby $__DIR/mail_task.rb -s "$title" -r "$recipient" -a "$filepath"
	else
		echo "Using plain text format."
		cat -v $filepath | mail -s "$title" $recipient
	fi
}

function find_process {
	if [ -z $1 ]; then
		return
	fi

	keyword=""
	user=""
	IFS="@"
	for seg in $1;do
		if [[ $keyword == "" ]];then keyword=$seg; continue; fi
		if [[ $user == "" ]];then user=$seg; continue; fi
	done
	IFS=" "
	res=$(ps aux | grep -v grep | grep "^$user" | grep -F $keyword)
	builtin echo $res
}
