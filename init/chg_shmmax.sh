#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

os=$( uname )
[[ $os != Darwin ]] && echo "For macOS changing system SHMMAX only" && exit 1

echo "Checking current SHMMAX"
sysctl -a | grep shm
os_shmmax=$( sysctl -a | grep kern.sysv.shmmax | awk '{ print $2 }' )
if [[ $os_shmmax -gt 134217728 ]]; then
	echo "Seems shmmax is big enough than 128MB"
	exit 0
else
	echo "Will resize SHMMAX to 256MB"
fi

cp -v $DIR/../conf/macos/chg_shmmax.plist /Library/LaunchDaemons/chg_shmmax.plist
echo sudo launchctl load /Library/LaunchDaemons/chg_shmmax.plist
sudo launchctl load /Library/LaunchDaemons/chg_shmmax.plist

sysctl -a | grep shm
echo "New shmmax will be effected after reboot"
