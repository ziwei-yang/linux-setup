#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY NOPYTHON

can_sudo || abort "no sudo privilege without password"

is_centos7 || is_ubuntu || abort "Unsupport OS $os"

#################################################
# Step 1 install VirtualBox
#################################################
is_centos7 && (
# Install normal dependency.
sudo yum -y groupinstall 'Development Tools' SDL kernel-devel kernel-headers dkms
sudo yum -y install binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms

# Check kernel headers could be found.
kernelVer=$( uname -r )
if [[ -d /usr/src/kernels/$kernelVer ]]; then
	export KERN_DIR=/usr/src/kernels/$kernelVer
else
	status_exec sudo yum -y install "kernel-devel-$kernelVer"
	if [[ -d /usr/src/kernels/$kernelVer ]]; then
		export KERN_DIR=/usr/src/kernels/$kernelVer
	else
		abort "Failed in installing kernel-devel, try installing latest kernel and kernel-devel and reboot"
	fi
fi
echo export KERN_DIR=$KERN_DIR

# Download virtual box yum repo.
[[ -f /etc/yum.repos.d/virtualbox.repo ]] || (
	cd /tmp
	wget -nc https://www.virtualbox.org/download/oracle_vbox.asc || abort 'Error in downloading oracle_vbox.asc'
	sudo rpm --import oracle_vbox.asc
	cd /etc/yum.repos.d
	sudo wget -nc http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo || abort 'Error in downloading vbox.repo'
)
[[ -f /etc/yum.repos.d/virtualbox.repo ]] || abort "No virtualbox.repo found in /etc/yum.repos.d/"

# Install VirtualBox
[[ -f /sbin/vboxconfig ]] || (
	# Install latest version
	latest_ver=$( yum search VirtualBox | grep ^VirtualBox | tail -n1 | cut -d ' ' -f 1 )
	# When updating from virtualbox 6.1.24 to 6.1.26 vboxwebsrv is removed.
	# Do not use 6.1.26 !
	echo latest_ver: $latest_ver
	latest_ver_minor=$( yum list $latest_ver | tail -n1 | awk '{ print $2 }' )
	echo "latest 6.1 version is $latest_ver_minor"
	[[ $latest_ver_minor == 6.1.26_* ]] && \
		latest_ver_minor=VirtualBox-6.1-6.1.24
	echo latest_ver_minor: $latest_ver_minor
	echo sudo yum -y install $latest_ver_minor*
	sudo yum -y install $latest_ver_minor*

	# Setup kernel module
	echo "Run sudo /sbin/vboxconfig to setup"
	sudo /sbin/vboxconfig || abort 'Error in vboxdrv setup'
)
)
is_ubuntu && (
echo "Download deb file from https://www.virtualbox.org/wiki/Linux_Downloads"
echo "After deb file is installed, press enter"
read
)
[[ -f /sbin/vboxconfig ]] || abort 'Error in installing virtualbox'

#################################################
# Step 2 setup user and group
#################################################
user='vbox'
[[ -d /home/$user ]] || (
	# group 'vboxusers'. VM users must be member of that group!
	# Add user to vboxusers Group for web interface.
	status_exec sudo useradd $user
	echo "=========================="
	echo "Set linux-user($user) passwd here"
	echo "=========================="
	sudo passwd $user
	status_exec sudo usermod -a -G vboxusers $user
	status_exec sudo usermod -a -G daemon $user
	is_ubuntu && (
		sudo mkdir /home/vbox
		sudo chown vbox /home/vbox
		sudo chgrp vbox /home/vbox
	)
)
[[ -d /home/$user ]] || abort "No user home dir /home/$user"

#################################################
# Step 2 setup virtualbox conf, install extpack, enable service
#################################################
# Create the file /etc/default/virtualbox and put the line VBOXWEB_USER=vbox in it
# (so that the VirtualBox SOAP API which is called vboxwebsrv runs as the user vbox):
if [[ ! -f /etc/default/virtualbox ]]; then
	sudo bash -c " echo 'VBOXWEB_USER=$user' > /etc/default/virtualbox " || abort "Error in modifying /etc/default/virtualbox"
	sudo bash -c " echo 'VBOXWEB_HOST=localhost' >> /etc/default/virtualbox " || abort "Error in modifying /etc/default/virtualbox"
	sudo bash -c " echo 'VBOXWEB_PORT=18083' >> /etc/default/virtualbox " || abort "Error in modifying /etc/default/virtualbox"

	latest_vb_ver=$( curl 'http://download.virtualbox.org/virtualbox/LATEST.TXT' )
	vb_ver=$( vboxmanage --version | awk -Fr '{ print $1 }' ) # 6.1.24r145667 -> 6.1.24
	latest_ext_file=$( curl -s "http://download.virtualbox.org/virtualbox/$vb_ver/" | grep extpack | head -n1 | cut -d '"' -f 2 )
	target_url="http://download.virtualbox.org/virtualbox/$vb_ver/$latest_ext_file"
	echo "Download and install latest Virtualbox extension pack:$target_url"
	cd /tmp
	wget -nc $target_url || abort "Error in downloading $target_url"
	echo sudo VBoxManage extpack install $latest_ext_file
	sudo VBoxManage extpack install $latest_ext_file
fi

# Auto start vbox service
status_exec sudo systemctl enable vboxautostart-service
status_exec sudo systemctl restart vboxautostart-service
status_exec sudo systemctl enable vboxweb-service
status_exec sudo systemctl restart vboxweb-service

#################################################
# Step 3 Setup HTTP server and web-service
#################################################
# Download VBox web interface and put into apache service
is_centos7 && status_exec sudo yum -y install httpd php php-devel php-common php-soap php-gd
is_ubuntu && status_exec sudo apt -y install apache2 php libapache2-mod-php php-xml php-soap php-gd
cd /tmp
rm -rf phpvirtualbox_latest.zip phpvirtualbox_latest_dir phpvirtualbox
git clone 'https://github.com/phpvirtualbox/phpvirtualbox.git'
# Change vboxuser credential here.
echo "=========================="
echo "Type linux-user($user) passwd here"
echo "=========================="
# Read Password
echo -n Password: 
read -s vboxPswd
echo
sed s/username\ =\ \'vbox\'/username\ =\ \'$user\'/g ./phpvirtualbox/config.php-example > phpvirtualbox/config.php.1
sed s/password\ =\ \'pass\'/password\ =\ \'$vboxPswd\'/g ./phpvirtualbox/config.php.1 > phpvirtualbox/config.php.2
# Disable auth if you like.
sed s/\#var\ \$noAuth\ =\ true/var\ \$noAuth\ =\ true/g ./phpvirtualbox/config.php.2 > phpvirtualbox/config.php
# Install web gui.
sudo cp -r phpvirtualbox /var/www/html
is_centos7 && sudo chown -R apache /var/www/html/phpvirtualbox
is_centos7 && sudo chgrp -R apache /var/www/html/phpvirtualbox
sudo chmod -R 755 /var/www/html/phpvirtualbox

# Start service
is_centos7 && \
	status_exec sudo systemctl enable httpd.service && \
	status_exec sudo systemctl restart httpd.service
is_ubuntu && \
	status_exec sudo systemctl enable apache2.service && \
	status_exec sudo systemctl restart apache2.service
