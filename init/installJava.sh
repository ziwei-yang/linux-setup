#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
source $DIR/common/bootstrap.sh NORUBY

log_green "-------- Checking Java compiler 8+ -------"
javac_ver=`javac -version 2>&1 | grep 'javac'`
[[ $javac_ver == *1.8.* ]] && log_blue "Current JAVAC:$javac_ver" || (
	is_mac && \
		brew install --cask oracle-jdk
	is_linux && ( # Install jdk 8u2xx
		filename=$(basename "$( ls -1t $LINUX_SETUP_HOME/archived/jdk-8u2* | head -n1 )" ) && (
			rm -rf $USER_ARCHIVED/jdk-*
			status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			status_exec tar -xf $filename
			rm $filename
			echo "OK"
		) || log_red "JDK files does not exist."
	)
)

MVN_VER="3"
log_green "-------- Checking Maven --------"
check_version "mvn" $MVN_VER && \
log_blue "Skip Maven" || (
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/apache-maven-* | head -n1 )) && (
		rm -rf $USER_ARCHIVED/apache-maven-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -xf $filename
		rm $filename
		source $HOME/.bashrc
		echo "OK"
	) || ehco "Maven files does not exist."
)
source $HOME/.bashrc
check_version "mvn" $MVN_VER || \
	abort "Maven version is still not $MVN_VER"

log_green "-------- Checking ANT --------"
ANT_VER=`ant -version 2>&1 | grep Ant`
[[ $ANT_VER == *1.10* ]] && \
log_blue "Current ANT:$ANT_VER" || (
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/apache-ant-* | head -n1 )) && (
		rm -rf $USER_ARCHIVED/apache-ant-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec unzip $USER_ARCHIVED/$filename
		rm $USER_ARCHIVED/$filename
		source $HOME/.bashrc
		echo "OK"
	) || log_red "Ant file does not exist."
)

