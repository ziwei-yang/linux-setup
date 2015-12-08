source $HOME/.bashrc
USER_ARCHIVED="$HOME/archived"
USER_INSTALL="$HOME/install"

# Internal functions.
function echoRed {
	echo "$(tput setaf 1)$1$(tput sgr0)"
}

function echoGreen {
	echo "$(tput setaf 2)$1$(tput sgr0)"
}

function echoBlue {
	echo "$(tput setaf 4)$1$(tput sgr0)"
}

function checkBinPath {
	bin=$1
	binPath=`which $bin`
	if [[ -z $binPath ]]; then
		echoRed "Could not locate [$bin]"
		return 1
	else
		return 0
	fi
}

function assertBinPath {
	bin=$1
	binPath=`which $bin`
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
	binPath=`which $bin`
	if [[ $binPath == $2 ]]; then
		return 0
	else
		echoRed "Could not locate [$2]"
		return 1
	fi
}

function checkBinVersion {
	bin=$1
	sysVer=`"$bin" --version 2>&1`
	ver=$2
	if [[ $sysVer =~ $ver ]]; then
		:
	else
		echoRed "[$bin] version [$sysVer] not match [$ver]."
		exit -1
	fi
}

function checkPyLibVersion {
	libName=$1
	libVer=$2
	sysLibVer=`pip freeze | grep "$libName=="`
	if [ -z $sysLibVer ]; then
		echoRed "Python lib $1 not exist."
		return 1
	elif [ -z $2 ]; then
		# Check lib existence is enough.
		:
	elif [ "$sysLibVer" == "$libName==$libVer" ]; then
		:
	else
		echoRed "[$libName] version [$sysLibVer] not match [$libVer]."
		return 1
	fi
	return 0
}

function osinfo {
	if [ -f /etc/redhat-release ]; then
		head -n1 /etc/redhat-release
	elif [ -f /etc/issue ]; then
		head -n1 /etc/issue
	else
		uname
	fi
}

function externalIP {
	curl 'http://ipinfo.io/ip'
}

function isGFWFucked {
	country=$( curl http://ipinfo.io/ | jq '.country' )
	echoGreen "Country Code: $country"
	if [[ $country == '"CN"' ]]; then
		echoRed ' ============ OH NO, GFW sucks! =============='
		return 1
	else
		return 0
	fi
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
	os=$( osinfo )
	if [[ $os == CentOS* ]]; then
		echoBlue "Current OS: $os"
		assertBinPath "yum"
		assertBinPath "rpm"
	elif [[ $os == Ubuntu* ]]; then
		echoBlue "Current OS: $os"
		assertBinPath "apt-get"
	elif [[ $os == Darwin ]]; then
		echoBlue "Current OS: Darwin/MacOSX"
		checkBinPath "brew"
		ret=$?
		if [ $ret == "0" ]; then
			echoBlue "Skip install brew."
		else
			echoBlue "Installing brew."
			ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		fi
	else
		echoRed "Error: OS is not CentOS/Ubuntu/MacOSX."
		exit -1
	fi
}

