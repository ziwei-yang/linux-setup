# Use sudo to execute this.

cd /etc/yum.repos.d
wget http://public-yum.oracle.com/public-yum-ol6.repo
yum install gcc make patch  dkms qt libgomp kernel-headers kernel-devel fontforge binutils glibc-headers glibc-devel
yum install VirtualBox-4.3
KERN_DIR=/usr/src/kernels/`uname -r`-`uname -m`
service vboxdrv setup

usermod -a -G vboxusers $USER || exit

wget 'http://download.virtualbox.org/virtualbox/4.3.26/Oracle_VM_VirtualBox_Extension_Pack-4.3.26-98988.vbox-extpack'
VBoxManage extpack install ./Oracle_VM_VirtualBox_Extension_Pack-4.3.26-98988.vbox-extpack || exit
rm 'VBoxManage extpack install ./Oracle_VM_VirtualBox_Extension_Pack-4.3.26-98988.vbox-extpack'
