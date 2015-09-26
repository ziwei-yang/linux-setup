PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../

source $DIR/util/util.sh
setupBasicEnv

# Check sudo privilege.
ret=$( sudo -n echo a )
sudoAllowed="0"
if [ $ret == "a" ]; then
	echoBlue "User has sudo privilege without password."
	sudoAllowed="1"
else
	echoRed "Error: User has no sudo privilege without password. Change /etc/sudoers first."
	exit -1
fi

# Download MySQL yum repo.
mkdir -p $HOME/tmp
cd $HOME/tmp
os=$( osinfo )
if [[ $os == "CentOS release 6"* ]]; then
	wget -N http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
	sudo rpm -Uvh $HOME/tmp/mysql-community-release-el6-5.noarch.rpm
elif [[ $os == "CentOS Linux release 7"* ]]; then
	wget -N http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
	sudo rpm -Uvh $HOME/tmp/mysql-community-release-el7-5.noarch.rpm
else
	echo "Unsupport OS $os"
	exit -1
fi

# Install
sudo yum -y install mysql-community-server mysql-community-client mysql-community-common mysql-community-libs mysql-community-devel

# Set autostart.
sudo chkconfig --level 2345 mysqld on

# Start daemon.
sudo service mysqld start

# Reset root password
/usr/bin/mysqladmin -u root password 'x'

# Secure MySQL installation
sudo mysql_secure_installation
