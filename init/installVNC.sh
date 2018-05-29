PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh

# Check sudo privilege.
ret=$( sudo -n echo a )
sudoAllowed="0"
if [ $ret == "a" ]; then
	log_blue "User has sudo privilege without password."
	sudoAllowed="1"
else
	abort "Error: User has no sudo privilege without password. Change /etc/sudoers first."
fi

os=$( osinfo )
if [[ $os != CentOS* ]]; then
	abort "Unsupport OS $os"
fi

sudo yum -y groups install "GNOME Desktop" 
sudo yum -y groupinstall "X Window System"
sudo yum -y install "tigervnc-server"
sudo yum -y install "xterm"
