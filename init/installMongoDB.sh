#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

log_green "-------- Checking MongoDB --------"
find_path "mongod" && \
log_blue "Skip MongoDB" || (
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/mongodb-* | head -n1 )) && (
		rm -rf $USER_ARCHIVED/mongodb-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -zxf $USER_ARCHIVED/$filename || \
			abort "Extract mongodb failed"
		rm $USER_ARCHIVED/$filename
		dirname=$(basename $USER_ARCHIVED/mongodb-*)
		cp -v $USER_ARCHIVED/$dirname/bin/* $USER_INSTALL/bin/ || \
			abort "Extract mongodb failed"
		rm -rf $USER_ARCHIVED/$dirname
		echo "OK"
	) || log_red "MongoDB file does not exist."
)
find_path "mongod" || abort "mongod does not exist"
