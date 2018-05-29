PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
cd $DIR

source $DIR/util/util.sh
setup_sys_env

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

# Download yum repo.
mkdir -p $HOME/tmp
cd $HOME/tmp
wget -nc https://www.virtualbox.org/download/oracle_vbox.asc || abort 'Error when downloading oracle_vbox.asc'
sudo rpm --import oracle_vbox.asc
cd /etc/yum.repos.d
sudo wget -nc http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo || abort 'Error when downloading vbox.repo'
cd $DIR

# Install dependency.
sudo yum -y groupinstall 'Development Tools' SDL kernel-devel kernel-headers dkms
sudo yum -y install binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms

# Install latest version
latest_ver=$( yum search VirtualBox | grep ^VirtualBox | tail -n1 | cut -d ' ' -f 1 )
sudo yum -y install $latest_ver

# Check kernel headers could be found.
kernelVer=$( uname -r )
if [[ -d /usr/src/kernels/$kernelVer ]]; then
	echo "Kernel header $kernelVer could be found."
	export KERN_DIR=/usr/src/kernels/`uname -r`
else
	abort "Kernel header $kernelVer could not be found, should reboot then retry."
fi

# Setup
sudo /etc/init.d/vboxdrv setup || abort 'Error in vboxdrv setup'

# Add user to vboxusers Group for web interface.
user='vbox'
sudo useradd $user || echoRed  "Error in adding user $user, it might be existed."
# echo "=========================="
# echo "Set user($user) passwd here"
# echo "=========================="
# sudo passwd $user
sudo usermod -a -G vboxusers $user

# Create the file /etc/default/virtualbox and put the line VBOXWEB_USER=vbox in it
# (so that the VirtualBox SOAP API which is called vboxwebsrv runs as the user vbox):
sudo bash -c " echo 'VBOXWEB_USER=$user' > /etc/default/virtualbox " || abort "Error in modifying /etc/default/virtualbox"

latest_ext_ver=$( curl 'http://download.virtualbox.org/virtualbox/LATEST.TXT' )
latest_ext_file=$( curl -s 'http://download.virtualbox.org/virtualbox/5.0.12/' | grep extpack | head -n1 | cut -d '"' -f 2 )
target_url="http://download.virtualbox.org/virtualbox/$latest_ext_ver/$latest_ext_file"
echo "Download and install latest Virtualbox extension pack:$target_url"
cd $HOME/tmp
wget -nc $target_url || abort "Error in downloading $target_url"
sudo VBoxManage extpack install $latest_ext_file

# Download VBox web interface.
sudo yum -y install httpd php php-devel php-common php-soap php-gd
rm -rf phpvirtualbox_latest.zip phpvirtualbox_latest_dir
wget -nc 'http://sourceforge.net/projects/phpvirtualbox/files/latest/download' -O phpvirtualbox_latest.zip || abort "Error in downloading phpvirtualbox"
unzip phpvirtualbox_latest.zip -d phpvirtualbox_latest_dir > /dev/null
mv phpvirtualbox_latest_dir/phpvirtualbox* phpvirtualbox_latest
rm -rf phpvirtualbox_latest_dir
# Change vboxuser credential here.
echo "=========================="
echo "Type linux-user($user) passwd here"
echo "=========================="
# Read Password
echo -n Password: 
read -s vboxPswd
echo
sed s/username\ =\ \'vbox\'/username\ =\ \'$user\'/g ./phpvirtualbox_latest/config.php-example > phpvirtualbox_latest/config.php.1
sed s/password\ =\ \'pass\'/password\ =\ \'$vboxPswd\'/g ./phpvirtualbox_latest/config.php.1 > phpvirtualbox_latest/config.php.2
# Disable auth if you like.
# sed s/\#var\ \$noAuth\ =\ true/var\ \$noAuth\ =\ true/g ./phpvirtualbox_latest/config.php.2 > phpvirtualbox_latest/config.php
# Install web gui.
sudo cp -r phpvirtualbox_latest /var/www/html
sudo chown -R apache /var/www/html/phpvirtualbox_latest
sudo chgrp -R apache /var/www/html/phpvirtualbox_latest
sudo chmod -R 755 /var/www/html/phpvirtualbox_latest

cd $DIR
# Start service
sudo /etc/init.d/vboxautostart-service stop
sudo /etc/init.d/vboxautostart-service start
sudo /etc/init.d/vboxballoonctrl-service restart
sudo /etc/init.d/vboxweb-service restart
if [[ $os == "CentOS release 6"* ]]; then
	sudo /etc/init.d/httpd restart
elif [[ $os == "CentOS Linux release 7"* ]]; then
	sudo systemctl restart httpd.service
else
	abort "Unsupport OS $os"
fi
