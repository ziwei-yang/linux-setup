source $HOME/.bashrc
USER_ARCHIVED="$HOME/archived"
USER_INSTALL="$HOME/install"

function isFunction {
	declare -f $1 > /dev/null
	return $?
}

# Internal functions.
function echoRed {
	echo "$(tput setaf 1)$@$(tput sgr0)"
}

function echoRed_builtin {
	builtin echo "$(tput setaf 1)$@$(tput sgr0)"
}

function echoGreen {
	echo "$(tput setaf 2)$@$(tput sgr0)"
}

function echoGreen_builtin {
	builtin echo "$(tput setaf 2)$@$(tput sgr0)"
}

function echoBlue {
	echo "$(tput setaf 4)$@$(tput sgr0)"
}

function echoBlue_builtin {
	builtin echo "$(tput setaf 4)$@$(tput sgr0)"
}

function abort() {
	echoRed "Script execution abort, reason: $@"
	exit -1
}

function checkBinPath {
	bin=$1
	binPath=`which $bin 2>/dev/null`
	if [[ -z $binPath ]]; then
		echoRed "Could not locate [$bin]"
		return 1
	else
		return 0
	fi
}

function assertBinPath {
	bin=$1
	binPath=`which $bin 2>/dev/null`
	if [[ -z $binPath ]]; then
		echoRed "Could not locate [$bin]"
		exit -1
	else
		return 0
	fi
}

function checkExactBinPath {
	bin=$1
	correctPath=$2
	binPath=`which $bin 2>/dev/null`
	if [[ $binPath == $2 ]]; then
		return 0
	else
		echoRed "Could not locate [$2]"
		return 1
	fi
}

function checkBinVersion {
	bin=$1
	checkBinPath $bin || return 1
	sysVer=`"$bin" --version 2>&1`
	ver=$2
	if [[ $sysVer =~ $ver ]]; then
		echo "[$bin] version [${sysVer:0:20}] matched [$ver]."
		return 0
	else
		echoRed "[$bin] version [$sysVer] not match [$ver]."
		return 1
	fi
}

function checkNewerBinVersion {
	bin=$1
	checkBinPath $bin || return -1
	sysVer=`"$bin" --version 2>&1`
	ver=$2
	if [[ $sysVer =~ $ver ]]; then
		return 0
	elif [[ $sysVer > $ver ]]; then
		return 0
	else
		echoRed "[$bin] version [$sysVer] is older than [$ver]."
		return 1
	fi
}

function checkPyLibVersion {
	libName=$1
	libVer=$2
	sysLibVer=`pip freeze | grep "$libName=="`
	if [[ -z $sysLibVer ]]; then
		echoRed "Python lib $1 not exist."
		return 1
	elif [[ -z $2 ]]; then
		# Check lib existence is enough.
		:
	elif [[ "$sysLibVer" == "$libName==$libVer" ]]; then
		:
	else
		echoRed "[$libName] version [$sysLibVer] not match [$libVer]."
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

function externalIP {
	curl 'http://ipinfo.io/ip'
}

function isGFWFucked {
	[[ $GFW_FUCKED == '0' ]] && return 0
	[[ $GFW_FUCKED == '1' ]] && return 1
	echo "Checking if is fucked by GFW"
	country=$( curl http://ipinfo.io/ | jq '.country' )
	echoGreen "Country Code: $country"
	if [[ $country == '"CN"' ]]; then
		echoRed ' ============ OH NO, GFW sucks! =============='
		GFW_FUCKED=1
		return 0
	else
		GFW_FUCKED=0
		return 1
	fi
}

function isSudoAllowed {
	[[ $SUDO_PRIVILEGE == '1' ]] && return 0
	[[ $SUDO_PRIVILEGE == '0' ]] && return 1
	ret=$( sudo -n echo a 2>&1 )
	if [[ $ret == "a" ]]; then
		echoBlue "User has sudo privilege without password."
		SUDO_PRIVILEGE=1
		return 0
	else
		echoRed "User has no sudo privilege."
		SUDO_PRIVILEGE=0
		return 1
	fi
}

function silentExec {
	$@ > /dev/null 2>&1
	return $?
}

function statusExec {
	echo -n "$@"
	silentExec $@
	ret=$?
	if [[ $ret == 0 ]]; then
		isFunction 'success' && success "$@" && builtin echo || \
			echoGreen_builtin "    [  OK  ]"
	else
		isFunction 'failure' && failure "$@" && builtin echo || \
			echoRed_builtin "    [FAILED]"
	fi
	return $ret
}

function isCentOS {
	[[ $OS == CentOS* ]] && return 0
	return 1
}
function isCentOS6 {
	[[ $OS == "CentOS release 6"* ]] && return 0
	return 1
}
function isCentOS7 {
	[[ $OS == "CentOS Linux release 7"* ]] && return 0
	return 1
}
function isMacOS {
	[[ $OS == Darwin ]] && return 0
	return 1
}
function isUbuntu {
	[[ $OS == Ubuntu* ]] && return 0
	return 1
}
function isUnknownOS {
	isCentOS || isMacOS || isUbuntu || return 0
	return 1
}
function isLinux {
	[[ $( uname ) == 'Linux' ]] && return 0
	return 1
}
function isFailed {
	eval "$@"
	[[ $? == '0' ]] && return 1
	return 0
}

function setupBasicEnv {
	echoGreen "-------- Checking environment. --------"
	assertBinPath "echo"
	assertBinPath "sudo"
	assertBinPath "cp"
	assertBinPath "wc"
	assertBinPath "cat"
	assertBinPath "head"
	
	# Check OS
	OS=$( osinfo )
	echoBlue "Current OS: $OS"
	isCentOS && (
		assertBinPath "yum"
		assertBinPath "rpm"
	)
	isUbuntu && assertBinPath "apt-get"
	isMacOS && (
		checkBinPath "brew" && echoBlue "Skip install brew." || (
			echoBlue "Installing brew."
			ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		)
	)
	isUnknownOS && abort "Error: OS is not CentOS/Ubuntu/MacOSX."

	# Check CPU Core num.
	CPU_CORE=4
	isMacOS && (
		echo "For Darwin/MacOSX, assume CPU Core:$CPU_CORE"
	) || (
		lastCPUID=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk '{print $3}')
		CPU_CORE=$(($lastCPUID + 1))
		echo "CPU Core:$CPU_CORE"
	)

	unset SUDO_PRIVILEGE
	unset GFW_FUCKED
}
