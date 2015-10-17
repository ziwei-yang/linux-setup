DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
source $DIR/init/initEnv.sh

echoGreen "-------- Installing Redis -------"
checkExactBinPath "redis-server" $USER_INSTALL/bin/redis-server
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip redis."
else
	filename=$(basename $( ls $DIR/archived/redis-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	dirname=${filename%.tar.gz}
	cd $USER_ARCHIVED/$dirname
	echoBlue "make PREFIX=$USER_INSTALL install -j $MAKE_CORE_NUM > /dev/null"
	make PREFIX=$USER_INSTALL install -j $MAKE_CORE_NUM > /dev/null || make PREFIX=$USER_INSTALL install > /dev/null
fi
assertBinPath "redis-server"

echoGreen "-------- Installing redis-commander --------"
checkExactBinPath "redis-commander" $USER_INSTALL/bin/redis-commander
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip redis-commander."
else
	npm install -g redis-commander
fi
assertBinPath "redis-commander"
