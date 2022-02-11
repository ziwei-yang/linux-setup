#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
source $DIR/common/bootstrap.sh NORUBY

log_green "-------- Installing Redis -------"
find_path "redis-server"
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip redis."
else
	is_mac && (
		brew install redis
	)
	is_linux && (
		filename=$(basename $( ls $DIR/archived/redis-* ))
		[ -d $USER_ARCHIVED ] || mkdir -p $USER_ARCHIVED
		cp -v $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		tar -xf $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		log_blue "make PREFIX=$USER_INSTALL install -j $MAKE_CORE_NUM > /dev/null"
		make PREFIX=$USER_INSTALL install -j $MAKE_CORE_NUM > /dev/null || make PREFIX=$USER_INSTALL install > /dev/null
	)
fi
assert_path "redis-server"
