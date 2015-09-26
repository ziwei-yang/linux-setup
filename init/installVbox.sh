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

# Turnoff SELINUX
sudo cp /etc/sysconfig/selinux /etc/sysconfig/selinux.bk
sudo echo 'SELINUX=disabled' > /etc/sysconfig/selinux

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
sudo yum -y install binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms

# Install
sudo yum update
sudo yum -y install VirtualBox-5.0

# Check kernel headers could be found.
kernelVer=$( uname -r )
if [[ -f /usr/src/kernels/$kernelVer ]]; then
	echo "Kernel header $kernelVer could be found."
	export KERN_DIR=/usr/src/kernels/`uname -r`
else
	echo "Kernel header $kernelVer could not be found, should reboot then retry."
	exit -1
fi

# Setup
sudo /etc/init.d/vboxdrv setup

# Add user to vboxusers Group
user='vbox'
sudo useradd $user
echo "=========================="
echo "Set user($user) passwd here"
echo "=========================="
sudo passwd $user
sudo usermod -a -G vboxusers $user

# Download and install Virtualbox extension pack.
cd $HOME/tmp
wget http://download.virtualbox.org/virtualbox/5.0.4/Oracle_VM_VirtualBox_Extension_Pack-5.0.4-102546.vbox-extpack
sudo VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-5.0.4-102546.vbox-extpack

# Download VBox web interface.
sudo yum -y install httpd php php-devel php-common php-soap php-gd
wget http://nchc.dl.sourceforge.net/project/phpvirtualbox/phpvirtualbox-5.0-3.zip
unzip phpvirtualbox-5.0-3.zip > /dev/null
# Change vboxuser credential here.
echo "=========================="
echo "Retype user($user) passwd here"
echo "=========================="
# Read Password
echo -n Password: 
read -s vboxPswd
echo
sed s/username\ =\ \'vbox\'/username\ =\ \'$user\'/g ./phpvirtualbox-5.0-3/config.php-example > phpvirtualbox-5.0-3/config.php.1
sed s/password\ =\ \'pass\'/password\ =\ \'$vboxPswd\'/g ./phpvirtualbox-5.0-3/config.php.1 > phpvirtualbox-5.0-3/config.php
# Install web gui.
sudo cp -r phpvirtualbox-5.0-3 /var/www/html
sudo chown -R apache /var/www/html/phpvirtualbox-5.0-3
sudo chgrp -R apache /var/www/html/phpvirtualbox-5.0-3
sudo chmod -R 755 /var/www/html/phpvirtualbox-5.0-3

# Start service
sudo /etc/init.d/vboxautostart-service start
sudo /etc/init.d/vboxballoonctrl-service start
sudo /etc/init.d/vboxweb-service start
sudo service httpd restart
