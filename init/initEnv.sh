#! /bin/bash
# Check and set environment before every scripts.
# Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../

source $DIR/util/util.sh
setupBasicEnv

cd $DIR/archived
$DIR/archived/download.sh || abort "Error in downloading files."
cd $DIR

USER_INSTALL="$HOME/install"
USER_ARCHIVED="$HOME/archived"
mkdir -p $USER_INSTALL
mkdir -p $USER_INSTALL/bin
mkdir -p $USER_INSTALL/include
mkdir -p $USER_INSTALL/lib
mkdir -p $USER_ARCHIVED

echoGreen "-------- Copying dot files -------"
mkdir -p $HOME/.vim/backupfiles
mkdir -p $HOME/.vim/swapfiles
mkdir -p $HOME/bin
mkdir -p $HOME/conf
cp $DIR/conf/home/.bash* $HOME/
cp $DIR/conf/home/.*rc $HOME/
cp $DIR/conf/home/.tmux*.conf $HOME/
cp $DIR/conf/home/tmux_dev.sh $HOME/
cp $DIR/conf/home/.profile $HOME/

echoGreen "-------- Refresh bash enviroment -------"
source $HOME/.bash_profile
source $HOME/.bashrc

isSudoAllowed && isCentOS && (
	echoGreen "-------- Checking CentOS Development tools --------"
	[ $(yum grouplist groupinfo 'Development tools' | grep "Installed" | wc -l) == "0" ] && \
		statusExec sudo yum -y groupinstall 'Development tools' || \
	 	echoBlue "OK"
)

( isSudoAllowed || isMacOS ) && (
	echoGreen "-------- Installing system tools --------"
	for app in sshfs openssl vim jq awk sed man tmux screen git curl wget \
		basename tput gpg tree finger nload telnet cmake clang ant
	do
		checkBinPath $app && continue
		isCentOS && statusExec sudo yum -y install $app
		isUbuntu &&statusExec sudo apt-get -y install $app
		isMacOS && statusExec brew install $app
	done
	# Check unbuffer.
	echo "Checking unbuffer" && checkBinPath "unbuffer" || (
		isCentOS && statusExec sudo yum -y install expect
		isUbuntu && statusExec sudo apt-get -y install expect-dev
		isMacOS && statusExec brew install homebrew/dupes/expect
	)
	# Other library.
	isCentOS && statusExec sudo yum -y install lapack lapack-devel blas \
		blas-devel libxslt-devel libxslt libxml2-devel libxml2 \
		ImageMagick ImageMagick-devel libpng-devel gcc gcc-java libgcj \
		libgcj-devel gcc-c++ bzip2-devel shadowsocks-libev curlftpfs
	isUbuntu && statusExec sudo apt-get -y install liblapack3gf \
		liblapack-dev libblas3gf libblas-dev libxslt1-dev libxslt1.1 \
		libxml2-dev libxml2 gfortran imagemagick imagemagick-dev \
		libpng-dev pdftk libbz2-dev curlftpfs
	isMacOS && (
		echo "Checking brew taps"
		taps=$(brew tap)
		echo "Checking brew tap homebrew/science" && \
			[ $(echo $taps | grep homebrew/science | wc -l) == '0' ] && \
			statusExec brew tap homebrew/science
		echo "Checking brew tap homebrew/python" && \
			[ $(echo $taps | grep homebrew/python | wc -l) == '0' ] && \
			statusExec brew tap homebrew/python
		echo "Checking brew list"
		list=$(brew list)
		for app in python lapack openblas pillow \
			imagemagick graphviz py2cairo qt pyqt
			# mysql-connector-c
		do
			echo "Checking $app in brew" && \
				[ $(echo $list | grep $app | wc -l) == '0' ] && \
				statusExec brew install $app
		done
		echo "Checking cairo in brew" && \
			[ $(echo $list | grep cairo | wc -l) == '0' ] && \
			statusExec brew install cairo --without-x
		echo "Checking numpy in brew" && \
			[ $(echo $list | grep numpy| wc -l) == '0' ] && \
			statusExec brew install numpy --with-openblas
		echo "Checking scipy in brew" && \
			[ $(echo $list | grep scipy | wc -l) == '0' ] && \
			statusExec brew install scipy --with-openblas
	)
	echo "OK"
) || echoRed "-------- Skip installing system tools --------"

isSudoAllowed && isLinux && (
	echoGreen "-------- Adding user privilege of fuse --------"
	username=$( whoami )
	sudo usermod -a -G fuse $username
)

echoGreen "-------- Enable color support in Git --------"
git config --global color.ui auto

echoGreen "-------- Checking RVM --------"
checkExactBinPath "rvm" $HOME/.rvm/bin/rvm && \
	echoBlue "Skip RVM." || (
	echoGreen "-------- Installing RVM --------"
	statusExec gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
	curl -sSL https://get.rvm.io | bash -s stable
	if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
		echoBlue "source $HOME/.rvm/scripts/rvm"
		source "$HOME/.rvm/scripts/rvm"
	fi
	assertBinPath "rvm"
)

RUBY_VER="2.4"
echoGreen "-------- Checking Ruby $RUBY_VER --------"
rvm use $RUBY_VER
checkExactBinPath "ruby" $HOME/.rvm/rubies/ruby-$RUBY_VER*/bin/ruby && \
	echoBlue "Skip installing Ruby $RUBY_VER" || (
	echoBlue "Update RVM before installing ruby."
	statusExec rvm get stable
	# Change rvm source code image to taobao for China.
	isGFWFucked && (
		sed -i.bak 's!http://cache.ruby-lang.org/pub/ruby!https://ruby.taobao.org/mirrors/ruby!' $HOME/.rvm/config/db
		echoBlue "rvm install $RUBY_VER --disable-binary"
		rvm install $RUBY_VER --disable-binary
		echo "OK"
	) || (
		echoBlue "rvm install $RUBY_VER"
		rvm install $RUBY_VER
	)
	rvm use $RUBY_VER
)
source $HOME/.bashrc
rvm use $RUBY_VER
checkBinVersion "ruby" $RUBY_VER || abort "Ruby version is still not $RUBY_VER"
# Change rvm image to taobao for China.
isGFWFucked && \
	statusExec gem sources \
	--add https://ruby.taobao.org/ --remove https://rubygems.org/

echoGreen "-------- Checking PhantomJS --------"
checkExactBinPath "phantomjs" $USER_INSTALL/bin/phantomjs && \
	echoBlue "Skip PhantomJS" || (
	filename=$(basename $( ls $DIR/archived/phantomjs-* )) && (
		rm -rf $USER_ARCHIVED/phantomjs-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -xf $filename
		dirname=${filename%.tar.bz2}
		cd $USER_ARCHIVED/$dirname
		echoBlue "cp bin/phantomjs $USER_INSTALL/bin/phantomjs"
		cp bin/phantomjs $USER_INSTALL/bin/phantomjs
		rm -rf $USER_ARCHIVED/phantomjs-*
		assertBinPath "phantomjs"
	) || echoRed "File does not exist"
)

echoGreen "-------- Checking Python --------"
PYTHON_VER="2.7"
isMacOS && (
	checkBinVersion "python" "2.7" && \
		echoBlue "Skip python 2.7" || \
		statusExec brew install python
)
isLinux && (
	checkExactBinPath "python" $USER_INSTALL/bin/python && \
	echoBlue "Python $PYTHON_VER is exist." || (
		filename=$(basename $( ls $DIR/archived/Python-* )) && (
			rm -rf $USER_ARCHIVED/Python-*
			cp $DIR/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			tar -xf $filename
			dirname=${filename%.tgz}
			cd $USER_ARCHIVED/$dirname
			statusExec $USER_ARCHIVED/$dirname/configure \
				--prefix=$USER_INSTALL \
				--exec-prefix=$USER_INSTALL || \
				abort "configure failed"
			statusExec make install -j $CPU_CORE || \
				statusExec make install || \
				abort "Make python failed"
			rm -rf $USER_ARCHIVED/Python-*
			echo "OK"
		) || echoRed "Python files does not exist"
	)
)
checkBinVersion "python" 2.7 || abort "Python 2.7 is not in bin path."

echoGreen "-------- Checking Python pip --------"
isLinux && (
	checkExactBinPath "pip" $USER_INSTALL/bin/pip && \
	echoBlue "pip for Python $PYTHON_VER is exist." || (
		[ -f $DIR/archived/get-pip.py ] && \
			statusExec python $DIR/archived/get-pip.py || \
			echoRed "File $DIR/archived/get-pip.py does not exist"
	)
)

echoGreen "-------- Checking pyenv --------"
[ -d $HOME/.pyenv ] || \
	statusExec git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv

echoGreen "-------- Checking Node.js --------"
# Only install Node.js within current user.
# To install Node.js in Centos as root, check this:
# https://nodejs.org/en/download/package-manager/
(
	checkBinVersion "node" 'v8' || \
	checkBinVersion "node" 'v7' || \
	checkBinVersion "node" 'v6' || \
	checkBinVersion "node" 'v5' || \
	checkBinVersion "node" 'v4' || \
	checkExactBinPath "node" $USER_INSTALL/bin/node
) && echoBlue "Skip Nodejs." || (
	# Copy system libs for python
	[ -d $USER_INSTALL/lib/python$PYTHON_VER ] && \
		ln -sf /usr/lib64/python*/lib-dynload/bz2.so \
		$USER_INSTALL/lib/python$PYTHON_VER/
	for filehead in node-v7 node-v6 node-v5 node-v4 node-v0
	do
		filename=$(basename $( ls $DIR/archived/$filehead* ))
		[ $? != 0 ] && \
			echoRed "File $filehead does not exist" && \
			continue
		echoBlue "Installing $filename"
		rm -rf $USER_ARCHIVED/node-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -xf $filename
		rm $USER_ARCHIVED/$filename
		dirname=$(basename $( ls $USER_ARCHIVED | grep '^node-' ))
		dirname=${dirname%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		statusExec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL || abort "configure failed"
		statusExec make install -j $CPU_CORE || \
			statusExec make install
		[ $? == "0" ] && break
		echoRed "Make failed, skip installing $filename"
		echoBlue "rm -rf $USER_ARCHIVED/$filehead*"
		rm -rf $USER_ARCHIVED/node-*
	done
)
assertBinPath "node"
assertBinPath "npm"

echoGreen "-------- Checking npm utilities --------"
checkBinPath 'npm' && (
	for app in tmux-cpu tmux-mem ; do
		checkBinPath $app && echoBlue "Skip $app" && continue
		echoBlue "Installing $app."
		npm install -g $app
	done
	echo "OK"
) || echoRed "npm could not be found."

echoGreen "-------- CheckingJava 8 -------"
javaVer=`java -version 2>&1 | grep 'java version'`
[[ $javaVer == *1.8.* ]] && \
echoBlue "Current JAVA:$javaVer" || (
	isMacOS && \
		echoRed "Java should be manually install on MacOSX."
	isLinux && (
		filename=$(basename "$( ls $DIR/archived/jdk-8u* )" ) && (
			rm -rf $USER_ARCHIVED/jdk-*
			statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			statusExec tar -xf $filename
			rm $filename
			echo "OK"
		) || echoRed "JDK files does not exist."
	)
)

MVN_VER="3.3"
echoGreen "-------- Checking Maven --------"
checkBinVersion "mvn" $MVN_VER && \
echoBlue "Skip Maven" || (
	filename=$(basename $( ls $DIR/archived/apache-maven-* )) && (
		rm -rf $USER_ARCHIVED/apache-maven-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -xf $filename
		rm $filename
		source $HOME/.bashrc
		echo "OK"
	) || ehco "Maven files does not exist."
)
checkBinVersion "mvn" $MVN_VER || \
	abort "Maven version is still not $MVN_VER"

echoGreen "-------- Checking ANT --------"
ANT_VER=`ant -version 2>&1 | grep Ant`
[[ $ANT_VER == *1.10* ]] && \
echoBlue "Current ANT:$ANT_VER" || (
	filename=$(basename $( ls $DIR/archived/apache-ant-* )) && (
		rm -rf $USER_ARCHIVED/apache-ant-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec unzip $USER_ARCHIVED/$filename
		rm $USER_ARCHIVED/$filename
		source $HOME/.bashrc
		echo "OK"
	) || echoRed "Ant file does not exist."
)

echoGreen "-------- Checking libsodium --------"
(
	[[ -f $USER_INSTALL/lib/libsodium.dylib && isMacOS ]] || \
	[[ -f $USER_INSTALL/lib/libsodium.so && isLinux ]]
) && \
echoBlue "Skip libsodium." || (
	filename=$(basename $( ls $DIR/archived/libsodium-* )) && (
		rm -rf $USER_ARCHIVED/libsodium-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -xf $filename
		rm $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		statusExec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL \
			--exec-prefix=$USER_INSTALL || \
			abort "configure failed"
		statusExec make install -j $CPU_CORE || \
			statusExec make install || \
			abort "make failed"
		rm -rf $USER_ARCHIVED/libsodium-*
		echo "OK"
	) || echoRed "libsodium file does not exist."
)
(
	[[ -f $USER_INSTALL/lib/libsodium.dylib && isMacOS ]] || \
	[[ -f $USER_INSTALL/lib/libsodium.so && isLinux ]]
) || abort "libsodium does not exist."

echoGreen "-------- Checking ZeroMQ --------"
(
	[[ -f $USER_INSTALL/lib/libzmq.dylib && isMacOS ]] || \
	[[ -f $USER_INSTALL/lib/libzmq.so && isLinux ]]
) && \
echoBlue "Skip ZeroMQ." || (
	filename=$(basename $( ls $DIR/archived/zeromq-* )) && (
		rm -rf $USER_ARCHIVED/zeromq-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -xf $filename
		rm $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		export sodium_CFLAGS="-I$USER_INSTALL/include"
		export sodium_LIBS="-L$USER_INSTALL/lib"
		export CFLAGS=$(pkg-config --cflags libsodium)
		export LDFLAGS=$(pkg-config --libs libsodium)
		statusExec $USER_ARCHIVED/$dirname/autogen.sh || \
			abort "autogen failed"
		statusExec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL \
			--exec-prefix=$USER_INSTALL || \
			abort "configure failed"
		statusExec make install -j $CPU_CORE || \
			statusExec make install || \
			abort "make failed"
		rm -rf $USER_ARCHIVED/zeromq-*
		echo "OK"
	) || echoRed "ZeroMQ file does not exist."
)
(
	[[ -f $USER_INSTALL/lib/libzmq.dylib && isMacOS ]] || \
	[[ -f $USER_INSTALL/lib/libzmq.so && isLinux ]]
) || abort "libzmq does not exist."

echoGreen "-------- Checking jzmq --------"
(
	[[ -f $USER_INSTALL/lib/libjzmq.dylib && isMacOS ]] || \
	[[ -f $USER_INSTALL/lib/libjzmq.so && isLinux ]]
) && \
echoBlue "Skip jzmq" || (
	filename=$(basename $( ls $DIR/archived/jzmq-* )) && (
		rm -rf $USER_ARCHIVED/jzmq-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec unzip -o $filename || \
			abort "unzip failed"
		rm $filename
		dirname=${filename%.zip}/jzmq-jni
		cd $USER_ARCHIVED/$dirname
		export CFLAGS=$(pkg-config --cflags libsodium)
		export LDFLAGS=$(pkg-config --libs libsodium)
		statusExec $USER_ARCHIVED/$dirname/autogen.sh || \
			abort "autogen failed"
		statusExec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL \
			--exec-prefix=$USER_INSTALL \
			--with-zeromq=$USER_INSTALL || \
			abort "configure failed"
		statusExec make install -j $CPU_CORE || \
			statusExec make install || \
			abort "make failed"
		rm -rf $USER_ARCHIVED/jzmq-*
		echo "OK"
	) || echoRed "jzmq file does not exist."
)
(
	[[ -f $USER_INSTALL/lib/libjzmq.dylib && isMacOS ]] || \
	[[ -f $USER_INSTALL/lib/libjzmq.so && isLinux ]]
) || abort "libzmq does not exist."

echoGreen "-------- Installing Nanomsg --------"
checkBinPath "nanocat" && \
echoBlue "Skip nanomsg" || (
	filename=$(basename $( ls $DIR/archived/nanomsg-* )) && (
		rm -rf $USER_ARCHIVED/nanomsg-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -xf $filename
		rm $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		builddir=$USER_ARCHIVED/$dirname/build
		mkdir $builddir
		cd $builddir
		statusExec cmake $USER_ARCHIVED/$dirname || \
			abort "cmake configure failed"
		statusExec cmake --build $builddir || \
			abort "cmake build failed"
		statusExec ctest $builddir || \
			abort "ctest failed"
		statusExec cmake \
			-DCMAKE_INSTALL_PREFIX:PATH=$USER_INSTALL $builddir || \
			abort "cmake install failed"
		statusExec make all install || \
			abort "make install failed"
		ln -v -sf $USER_INSTALL/lib64/libnanomsg* $USER_INSTALL/lib/
		rm -rf $USER_ARCHIVED/nanomsg-*
		echo "OK"
	) || echoRed "nanomsg file does not exist."
)
checkBinPath "nanocat" || abort "nanocat does not exist."

echoGreen "-------- Checking wkhtmltox --------"
checkBinPath "wkhtmltopdf" && \
echoBlue "Skip wkhtmltox" || (
	filename=$(basename $( ls $DIR/archived/wkhtmltox-* )) && (
		statusExec tar xf $DIR/archived/$filename \
			-C $USER_INSTALL --strip 1 wkhtmltox/
	) || echoRed "wkhtmltox file does not exist."
)

echoGreen "-------- Checking pdftk --------"
checkBinPath "pdftk" && \
echoBlue "Skip pdftk" || (
	filename=$(basename $( ls $DIR/archived/pdftk-* )) && (
		isCentOS6 && (
			rm -rf $USER_ARCHIVED/pdftk-*
			statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			statusExec unzip -o $USER_ARCHIVED/$filename || \
				abort "Unzip pdftk failed"
			dirname=$(basename $USER_ARCHIVED/pdftk-*-dist)
			cd $USER_ARCHIVED/$dirname/pdftk
			echoBlue "make -f Makefile.Redhat"
			cd $USER_ARCHIVED/$dirname/pdftk/
			statusExec make -f \
				$USER_ARCHIVED/$dirname/pdftk/Makefile.Redhat || \
				abort "Making pdftk failed"
			statusExec cp $USER_ARCHIVED/$dirname/pdftk/pdftk \
				$USER_INSTALL/bin/
			rm -rf $USER_ARCHIVED/pdftk-*
			echo "OK"
		) || echoRed "Installing pdftk is not implemented on $OS."
	) || echoRed "pdftk file does not exist."
)
isCentOS6 && isFailed checkBinPath "pdftk" && abort "pdftk does not exist."

echoGreen "-------- Checking MongoDB --------"
checkBinPath "mongod" && \
echoBlue "Skip MongoDB" || (
	filename=$(basename $( ls $DIR/archived/mongodb-* )) && (
		rm -rf $USER_ARCHIVED/mongodb-*
		statusExec cp $DIR/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		statusExec tar -zxf $USER_ARCHIVED/$filename || \
			abort "Extract mongodb failed"
		rm $USER_ARCHIVED/$filename
		dirname=$(basename $USER_ARCHIVED/mongodb-*)
		cp -v $USER_ARCHIVED/$dirname/bin/* $USER_INSTALL/bin/ || \
			abort "Extract mongodb failed"
		rm -rf $USER_ARCHIVED/$dirname
		echo "OK"
	) || echoRed "MongoDB file does not exist."
)
checkBinPath "mongod" || abort "mongod does not exist"

echoGreen "-----------------------------------------------"
echoGreen "Environment set up, reopen bash to take effect."

cd $PWD
