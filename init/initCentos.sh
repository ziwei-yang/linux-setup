#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
echo "cd $DIR"
cd $DIR

# Pre-defined vars.
newhostname=''

source $DIR/util/util.sh

USER=$( whoami )
if [[ $USER != 'root' ]]; then
	echo Current user must be root.
	exit -1
fi

os=$( osinfo )
if [[ $os == "CentOS release 6"* ]]; then
	wget -O /etc/yum.repos.d/libredhat-shadowsocks-epel-6.repo "https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-6/librehat-shadowsocks-epel-6.repo"
elif [[ $os == "CentOS Linux release 7"* ]]; then
	wget -O /etc/yum.repos.d/libredhat-shadowsocks-epel-7.repo "https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo"
else
	echo "Unsupport OS $os"
	exit -1
fi

# Turnoff SELINUX
cp /etc/sysconfig/selinux /etc/sysconfig/selinux.bk
bash -c " echo 'SELINUX=disabled' > /etc/sysconfig/selinux "
bash -c " echo 'SELINUXTYPE=targeted' >> /etc/sysconfig/selinux "
echo "Need to reboot to disable SELinux."

# Install essential tools.
status_exec yum install -y man curl wget net-tools w3m nmap

# Configure Network with Static IP Address
echo "========================================="
echo "CURRENT NETWORK STATUS:"
echo "========================================="
ip addr show
echo "========================================="
echo "Change it according to sample/ifcg-em1 if you want."
echo "========================================="

# Checking network status.
echo "========================================="
echo "Ping yahoo.com"
echo "========================================="
ping -c4 yahoo.com

# Change hostname
echo "Current hostname: $HOSTNAME"
if [[ $newhostname != '' ]]; then
	echo $newhostname > /etc/hostname
	echo "New hostname: $newhostname"
	echo "Re-login to take effect"
else
	echo "Remain hostname not changed."
fi

# Install Nmap to Monitor Open Ports
# nmap 127.0.0.1

# Enable Third Party Repositories
status_exec yum -y install epel-release
