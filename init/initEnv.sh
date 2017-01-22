#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.

PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
INIT_ENV_DIR=$DIR

source $DIR/archived/download.sh

# Avoid $DIR overwritten.
DIR=$INIT_ENV_DIR
echo "cd $DIR"
cd $DIR

source $DIR/util/util.sh

setupBasicEnv
os=$( osinfo )

if [[ $os == 'Darwin' ]]; then
	MAKE_CORE_NUM=4
	echo "For Darwin/MacOSX, assume CPU Core:$MAKE_CORE_NUM"
else
	lastCPUID=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk '{print $3}')
	MAKE_CORE_NUM=$(($lastCPUID + 1))
	echo "CPU Core:$MAKE_CORE_NUM"
fi

USER_INSTALL="$HOME/install"
USER_ARCHIVED="$HOME/archived"
mkdir -p $USER_INSTALL
mkdir -p $USER_INSTALL/include
mkdir -p $USER_INSTALL/lib
mkdir -p $USER_ARCHIVED

echoGreen "-------- Checking environment. --------"
# Check sudo privilege.
ret=$( sudo -n echo a 2>&1 )
sudoAllowed="0"
if [[ $ret == "a" ]] && [[ $os != "Darwin" ]]; then
	echoBlue "User has sudo privilege without password."
	sudoAllowed="1"
elif [[ $os == 'Darwin' ]]; then
	:
else
	echoRed "WARN: User has no sudo privilege without password. Change /etc/sudoers first."
fi

echoGreen "-------- Copying util configurations -------"
mkdir -p $HOME/.vim/backupfiles
mkdir -p $HOME/.vim/swapfiles
mkdir -p $HOME/bin
mkdir -p $HOME/conf
cp -v $DIR/conf/home/.bash* $HOME/
cp -v $DIR/conf/home/.*rc $HOME/
cp -v $DIR/conf/home/.tmux*.conf $HOME/
cp -v $DIR/conf/home/tmux_dev.sh $HOME/
cp -v $DIR/conf/home/.profile $HOME/
# Do not copy other files for safety.

echoGreen "-------- Refresh bash enviroment -------"
source $HOME/.bash_profile
source $HOME/.bashrc

if [[ $sudoAllowed == "1" ]] || [[ $os == "Darwin" ]]; then
	echoGreen "-------- Installing system tools --------"
	if [[ $os == CentOS* ]]; then
		if [ $(yum grouplist groupinfo 'Development tools' | grep "Installed" | wc -l) == "0" ]; then
			sudo yum -y groupinstall 'Development tools'
		else
			echoBlue "Skip Development tools"
		fi
	fi
	for app in vim jq awk sed man tmux screen git curl wget basename tput gpg tree finger nload telnet cmake dirmngr
	do
		checkBinPath $app
		ret=$?
		if [ $ret == "0" ]; then
			echoBlue "Skip $app."
		else
			echoBlue "Installing $app."
			if [[ $os == CentOS* ]]; then
				sudo yum -y install $app
			elif [[ $os == Ubuntu* ]]; then
				sudo apt-get -y install $app
			elif [[ $os == "Darwin" ]]; then
				brew install $app
			fi
		fi
	done
	# Check unbuffer.
	checkBinPath "unbuffer"
	ret=$?
	if [ $ret == "0" ]; then
		echoBlue "Skip unbuffer."
	else
		if [[ $os == CentOS* ]]; then
			sudo yum -y install expect
		elif [[ $os == Ubuntu* ]]; then
			sudo apt-get -y install expect-dev
		elif [[ $os == "Darwin" ]]; then
			brew install homebrew/dupes/expect
		fi
	fi
	# Other library.
	if [[ $os == CentOS* ]]; then
		sudo yum -y install lapack lapack-devel blas blas-devel libxslt-devel libxslt libxml2-devel libxml2 ImageMagick ImageMagick-devel libpng-devel
	elif [[ $os == Ubuntu* ]]; then
		sudo apt-get -y install liblapack3gf liblapack-dev libblas3gf libblas-dev libxslt1-dev libxslt1.1 libxml2-dev libxml2 gfortran imagemagick imagemagick-dev libpng-dev
	elif [[ $os == "Darwin" ]]; then
		brew tap homebrew/science
		brew tap homebrew/python
		brew install python lapack openblas pillow imagemagick graphviz py2cairo qt pyqt mysql-connector-c
		brew install cairo --without-x
		brew install numpy --with-openblas
		brew install scipy --with-openblas
	fi
else
	echoRed "-------- Skip installing system tools --------"
fi

# Basic settings.
git config --global color.ui auto

echoGreen "-------- Installing RVM --------"
checkExactBinPath "rvm" $HOME/.rvm/bin/rvm
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Update RVM."
	rvm get stable
else
	gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
	curl -sSL https://get.rvm.io | bash -s stable
	if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
		echoBlue "source $HOME/.rvm/scripts/rvm"
		source "$HOME/.rvm/scripts/rvm"
	fi
fi
assertBinPath "rvm"

isGFWFucked
GFWFucked=$?

RUBY_VER="2.3"
rvm use $RUBY_VER
echoGreen "-------- Installing Ruby $RUBY_VER --------"
checkExactBinPath "ruby" $HOME/.rvm/rubies/ruby-$RUBY_VER/bin/ruby
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip Ruby."
else
	# Change rvm source code image to taobao for China.
	if [ $GFWFucked == "1" ]; then
		sed -i.bak 's!http://cache.ruby-lang.org/pub/ruby!https://ruby.taobao.org/mirrors/ruby!' $HOME/.rvm/config/db
		echoBlue "rvm install $RUBY_VER --disable-binary"
		rvm install $RUBY_VER --disable-binary
	else
		echoBlue "rvm install $RUBY_VER"
		rvm install $RUBY_VER
	fi
fi
rvm use $RUBY_VER
checkBinVersion "ruby" $RUBY_VER || abort "Ruby version is still not $RUBY_VER"
# Change rvm image to taobao for China.
if [ $GFWFucked == "1" ]; then
	gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
fi

echoGreen "-------- Installing Node.js --------"
checkExactBinPath "node" $USER_INSTALL/bin/node
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip Nodejs."
else
	filename=$(basename $( ls $DIR/archived/node-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	dirname=${filename%.tar.gz}
	cd $USER_ARCHIVED/$dirname
	echoBlue "$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL > /dev/null"
	$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL > /dev/null
	echoBlue "make install -j $MAKE_CORE_NUM > /dev/null"
	make install -j $MAKE_CORE_NUM > /dev/null || make install > /dev/null
fi
assertBinPath "node"
assertBinPath "npm"
echoGreen "-------- Installing npm utilities --------"
for app in tmux-cpu tmux-mem
do
	checkBinPath $app
	ret=$?
	if [ $ret == "0" ]; then
		echoBlue "Skip $app."
	else
		echoBlue "Installing $app."
		npm install -g $app
	fi
done

echoGreen "-------- Installing PhantomJS --------"
checkExactBinPath "phantomjs" $USER_INSTALL/bin/phantomjs
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip PhantomJS"
else
	filename=$(basename $( ls $DIR/archived/phantomjs-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	dirname=${filename%.tar.bz2}
	cd $USER_ARCHIVED/$dirname
	echoBlue "cp -v bin/phantomjs $USER_INSTALL/bin/phantomjs"
	cp -v bin/phantomjs $USER_INSTALL/bin/phantomjs
fi
assertBinPath "phantomjs"

PYTHON_VER="2.7"
echoGreen "-------- Installing Python --------"
if [[ $os != "Darwin" ]]; then
	filename=$(basename $( ls $DIR/archived/Python-* ))
	checkExactBinPath "python" $USER_INSTALL/bin/python
	ret=$?
	if [ $ret == "0" ] || [ $os == "Darwin" ]; then
		echoBlue "Skip Python."
	else
		cp -v $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		tar -xf $filename
		dirname=${filename%.tgz}
		cd $USER_ARCHIVED/$dirname
		echoBlue "$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL > /dev/null"
		$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL > /dev/null
		echoBlue "make install -j $MAKE_CORE_NUM > /dev/null"
		make install -j $MAKE_CORE_NUM > /dev/null || make install > /dev/null
	fi
else
	echoBlue "Skip python."
fi
checkBinVersion "python" $PYTHON_VER || abort "Python version is still not $PYTHON_VER"

# Install PIP
echoGreen "-------- Installing PIP and Py lib --------"
if [[ $os != "Darwin" ]]; then
	checkExactBinPath "pip" $USER_INSTALL/bin/pip
	ret=$?
	if [ $ret == "0" ]; then
		echoBlue "Skip pip."
	else
		echoBlue "python $DIR/archived/get-pip.py"
		python $DIR/archived/get-pip.py
	fi
else
	echoBlue "Skip pip."
fi

echoGreen "-------- Installing Java 8 -------"
javaVer=`java -version 2>&1 | grep 'java version'`
if [[ $javaVer == *1.8.* ]]; then
	echoBlue "Current JAVA:$javaVer"
elif [[ $os == "Darwin" ]]; then
	echoRed "Current JAVA:$javaVer, Java should be manually install on MacOSX."
else
	filename=$(basename $( ls $DIR/archived/jdk-8u* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	rm $filename
fi

MVN_VER="3.3"
echoGreen "-------- Installing Maven --------"
filename=$(basename $( ls $DIR/archived/apache-maven-* ))
checkBinPath "mvn"
ret=$?
if [ $ret == "0" ]; then
	checkBinVersion "mvn" $MVN_VER
	ret=$?
fi
if [ $ret == "0" ]; then
	echoBlue "Skip maven"
else
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	rm $filename
	source $HOME/.bashrc
fi
checkBinVersion "mvn" $MVN_VER || abort "Maven version is still not $MVN_VER"

echoGreen "-------- Installing libsodium --------"
if [[ -f $USER_INSTALL/lib/libsodium.so ]]; then
	echoBlue "Skip libsodium"
else
	filename=$(basename $( ls $DIR/archived/libsodium-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	rm $filename
	dirname=${filename%.tar.gz}
	cd $USER_ARCHIVED/$dirname
	echoBlue "$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL > /dev/null"
	$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL > /dev/null || abort "configure failed"
	echoBlue "make install -j $MAKE_CORE_NUM > /dev/null"
	make install -j $MAKE_CORE_NUM > /dev/null || make install > /dev/null || abort "make failed"
fi

echoGreen "-------- Installing ZeroMQ --------"
if [[ -f $USER_INSTALL/lib/libzmq.so ]]; then
	echoBlue "Skip zeromq"
else
	filename=$(basename $( ls $DIR/archived/zeromq-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	rm $filename
	dirname=${filename%.tar.gz}
	cd $USER_ARCHIVED/$dirname
	export sodium_CFLAGS="-I$USER_INSTALL/include"
	export sodium_LIBS="-L$USER_INSTALL/lib"
	export CFLAGS=$(pkg-config --cflags libsodium)
	export LDFLAGS=$(pkg-config --libs libsodium)
	echoBlue "$USER_ARCHIVED/$dirname/autogen.sh > /dev/null"
	$USER_ARCHIVED/$dirname/autogen.sh > /dev/null || abort "autogen failed"
	echoBlue "$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL > /dev/null"
	$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL > /dev/null || abort "configure failed"
	echoBlue "make install -j $MAKE_CORE_NUM > /dev/null"
	make install -j $MAKE_CORE_NUM > /dev/null || make install > /dev/null || abort "make failed"
fi

echoGreen "-------- Installing jzmq --------"
if [[ -f $USER_INSTALL/lib/libjzmq.so ]]; then
	echoBlue "Skip jzmq"
else
	filename=$(basename $( ls $DIR/archived/jzmq-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	unzip -o $filename
	rm $filename
	dirname=${filename%.zip}/jzmq-jni
	cd $USER_ARCHIVED/$dirname
	export CFLAGS=$(pkg-config --cflags libsodium)
	export LDFLAGS=$(pkg-config --libs libsodium)
	echoBlue "$USER_ARCHIVED/$dirname/autogen.sh > /dev/null"
	$USER_ARCHIVED/$dirname/autogen.sh > /dev/null || abort "autogen failed"
	echoBlue "$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL --with-zeromq=$USER_INSTALL > /dev/null"
	$USER_ARCHIVED/$dirname/configure --prefix=$USER_INSTALL --exec-prefix=$USER_INSTALL --with-zeromq=$USER_INSTALL > /dev/null || abort "configure failed"
	echoBlue "make install -j $MAKE_CORE_NUM > /dev/null"
	make install -j $MAKE_CORE_NUM > /dev/null || make install > /dev/null || abort "make failed"
fi

echoGreen "-------- Installing Nanomsg --------"
checkBinPath "nanocat"
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip nanomsg"
else
	filename=$(basename $( ls $DIR/archived/nanomsg-* ))
	cp -v $DIR/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	tar -xf $filename
	rm $filename
	dirname=${filename%.tar.gz}
	cd $USER_ARCHIVED/$dirname
	builddir=$USER_ARCHIVED/$dirname/build
	mkdir $builddir
	cd $builddir
	cmake $USER_ARCHIVED/$dirname > /dev/null || abort "cmake configure failed"
	echoBlue "cmake --build $builddir"
	cmake --build $builddir > /dev/null || abort "cmake build failed"
	echoBlue "ctest $builddir > /dev/null"
	ctest $builddir > /dev/null || abort "ctest failed"
	echoBlue "cmake -DCMAKE_INSTALL_PREFIX:PATH=$USER_INSTALL $builddir"
	cmake -DCMAKE_INSTALL_PREFIX:PATH=$USER_INSTALL $builddir || abort "cmake install failed"
	echoBlue "make all install"
	make all install || abort "make install failed"
	ln -v -sf $USER_INSTALL/lib64/libnanomsg* $USER_INSTALL/lib/
fi

echoGreen "-----------------------------------------------"
echoGreen "Environment set up, reopen bash to take effect."

cd $PWD
