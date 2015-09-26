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

os=$( osinfo )
if [[ $os != CentOS* ]]; then
	echo "Unsupport OS $os"
	exit -1
fi
# Download yum repo.
mkdir -p $HOME/tmp
cd $HOME/tmp
wget https://www.virtualbox.org/download/oracle_vbox.asc
sudo rpm --import oracle_vbox.asc
cd /etc/yum.repos.d
sudo wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
sudo yum update

# Install dependency.
sudo yum -y groupinstall 'Development Tools' SDL kernel-devel kernel-headers dkms
sudo yum -y install binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel kernel-PAE-devel dkms

# Install
sudo yum -y install VirtualBox-5.0
# Download and install Virtualbox extension pack.
cd $HOME/tmp
wget http://download.virtualbox.org/virtualbox/5.0.4/Oracle_VM_VirtualBox_Extension_Pack-5.0.4-102546.vbox-extpack
sudo VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-5.0.4-102546.vbox-extpack

# Install VBox web interface.
sudo yum -y install httpd php php-devel php-common php-soap php-gd
wget http://nchc.dl.sourceforge.net/project/phpvirtualbox/phpvirtualbox-5.0-3.zip
unzip phpvirtualbox-5.0-3.zip > /dev/null
# Should change web credential here.
cp phpvirtualbox-5.0-3/config.php-example phpvirtualbox-5.0-3/config.php
sudo cp -r phpvirtualbox-5.0-3 /var/www/html
sudo chown -R apache /var/www/html/phpvirtualbox-5.0-3
sudo chgrp -R apache /var/www/html/phpvirtualbox-5.0-3
sudo chmod -R 755 /var/www/html/phpvirtualbox-5.0-3

# Setup
sudo /etc/init.d/vboxdrv setup

# Add VirtualBox User(s) to vboxusers Group
usermod -a -G vboxusers $( whoami )

# Start service
service vbox-service restart
service httpd restart
