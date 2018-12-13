#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

log_green "-------- Installing Redis -------"
check_path "redis-server" $USER_INSTALL/bin/redis-server
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip redis."
else
	filename=$(basename $( ls $DIR/archived/redis-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	dirname=${filename%.tar.gz}
	cd $USER_ARCHIVED/$dirname
	log_blue "make PREFIX=$USER_INSTALL install -j $MAKE_CORE_NUM > /dev/null"
	make PREFIX=$USER_INSTALL install -j $MAKE_CORE_NUM > /dev/null || make PREFIX=$USER_INSTALL install > /dev/null
fi
assert_path "redis-server"

log_green "-------- Installing redis-commander --------"
check_path "redis-commander" $USER_INSTALL/bin/redis-commander
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip redis-commander."
else
	npm install -g redis-commander
	npm install -g https://github.com/MegaGM/redis-commander.git
fi
assert_path "redis-commander"

log_green "-------- Installing redis-stat --------"
find_path "redis-stat"
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip redis-stat."
else
	gem install redis-stat
fi
assert_path "redis-stat"
