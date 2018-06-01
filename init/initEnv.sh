#! /bin/bash
# Check and set environment before every scripts.
# Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

cd $LINUX_SETUP_HOME/archived
$LINUX_SETUP_HOME/archived/download.sh || abort "Error in downloading files."
cd $LINUX_SETUP_HOME

USER_INSTALL="$HOME/install"
USER_ARCHIVED="$HOME/archived"
mkdir -p $USER_INSTALL
mkdir -p $USER_INSTALL/bin
mkdir -p $USER_INSTALL/include
mkdir -p $USER_INSTALL/lib
mkdir -p $USER_ARCHIVED

log_green "-------- Copying dot files -------"
mkdir -p $HOME/.vim/backupfiles
mkdir -p $HOME/.vim/swapfiles
mkdir -p $HOME/bin
mkdir -p $HOME/conf
cp $LINUX_SETUP_HOME/conf/home/.bash* $HOME/
cp $LINUX_SETUP_HOME/conf/home/.*rc $HOME/
cp $LINUX_SETUP_HOME/conf/home/.tmux*.conf $HOME/
cp $LINUX_SETUP_HOME/conf/home/tmux_dev.sh $HOME/
cp $LINUX_SETUP_HOME/conf/home/.profile $HOME/

log_green "-------- Refresh bash enviroment -------"

can_sudo && is_centos && (
	log_green "-------- Checking CentOS Development tools --------"
	[ $(yum grouplist groupinfo 'Development tools' | grep "Installed" | wc -l) == "0" ] && \
		status_exec sudo yum -y groupinstall 'Development tools' || \
	 	log_blue "OK"
)

( can_sudo || is_mac ) && (
	log_green "-------- Installing system tools --------"
	for app in sshfs openssl vim jq awk sed man tmux screen git curl wget \
		basename tput gpg tree finger nload telnet cmake clang ant
	do
		find_path $app && continue
		is_centos && status_exec sudo yum -y install $app
		is_ubuntu &&status_exec sudo apt-get -y install $app
		is_mac && [[ $app != 'sshfs' ]] && status_exec brew install $app
	done
	# Check unbuffer.
	echo "Checking unbuffer" && find_path "unbuffer" || (
		is_centos && status_exec sudo yum -y install expect
		is_ubuntu && status_exec sudo apt-get -y install expect-dev
		is_mac && status_exec brew install homebrew/dupes/expect
	)
	# Other library.
	is_centos && status_exec sudo yum -y install lapack lapack-devel blas \
		blas-devel libxslt-devel libxslt libxml2-devel libxml2 \
		ImageMagick ImageMagick-devel libpng-devel gcc gcc-java libgcj \
		libgcj-devel gcc-c++ bzip2-devel shadowsocks-libev curlftpfs \
		golang gmp-devel protobuf protobuf-devel ncurses-devel \
		openssl-devel libcurl-devel
	is_ubuntu && status_exec sudo apt-get -y install liblapack3gf \
		liblapack-dev libblas3gf libblas-dev libxslt1-dev libxslt1.1 \
		libxml2-dev libxml2 gfortran imagemagick imagemagick-dev \
		libpng-dev pdftk libbz2-dev curlftpfs protobuf-compiler \
		libprotobuf-dev libprotobuf-c-dev libncursesw5-dev \
		libopenssl-dev libssl-dev libcurl4-openssl-dev
	is_mac && (
		echo "Checking brew taps"
		taps=$(brew tap)
		echo "Checking brew tap homebrew/science" && \
			[ $(echo $taps | grep homebrew/science | wc -l) == '0' ] && \
			status_exec brew tap homebrew/science
		echo "Checking brew tap homebrew/python" && \
			[ $(echo $taps | grep homebrew/python | wc -l) == '0' ] && \
			status_exec brew tap homebrew/python
		echo "Checking brew list"
		list=$(brew list)
		for app in python lapack openblas pillow \
			imagemagick graphviz py2cairo qt pyqt
			# mysql-connector-c
		do
			echo "Checking $app in brew" && \
				[ $(echo $list | grep $app | wc -l) == '0' ] && \
				status_exec brew install $app
		done
		echo "Checking cairo in brew" && \
			[ $(echo $list | grep cairo | wc -l) == '0' ] && \
			status_exec brew install cairo --without-x
		echo "Checking numpy in brew" && \
			[ $(echo $list | grep numpy| wc -l) == '0' ] && \
			status_exec brew install numpy --with-openblas
		echo "Checking scipy in brew" && \
			[ $(echo $list | grep scipy | wc -l) == '0' ] && \
			status_exec brew install scipy --with-openblas
	)
	echo "OK"
) || log_red "-------- Skip installing system tools --------"

log_green "-------- Checking mosh --------"
is_mac && (
	find_path "mosh" && \
		log_blue "Skip mosh" || \
		status_exec brew install mosh
)
is_linux && (
	find_path "mosh" && \
	log_blue "Skip Mosh" || (
		filename=$(basename $( ls $LINUX_SETUP_HOME/archived/mosh-* )) && (
			rm -rf $USER_ARCHIVED/mosh-*
			status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			status_exec tar -zxf $USER_ARCHIVED/$filename || \
				abort "Extract mosh failed"
			rm $USER_ARCHIVED/$filename
			dirname=$(basename $USER_ARCHIVED/mosh-*)
			status_exec $USER_ARCHIVED/$dirname/configure \
				--prefix=$USER_INSTALL \
				--exec-prefix=$USER_INSTALL || \
				abort "configure failed"
			status_exec make install -j $CPU_CORE || \
				status_exec make install || \
				abort "Make mosh failed"
			rm -rf $USER_ARCHIVED/mosh-*
			echo "OK"
		) || log_red "Mosh file does not exist."
	)
)
find_path "mosh" || abort "mosh does not exist"

can_sudo && is_linux && (
	log_green "-------- Adding user privilege of fuse --------"
	username=$( whoami )
	sudo usermod -a -G fuse $username
)

log_green "-------- Enable color support in Git --------"
git config --global color.ui auto

log_green "-------- Checking RVM --------"
check_path "rvm" $HOME/.rvm/bin/rvm && \
	log_blue "Skip RVM." || (
	log_green "-------- Installing RVM --------"
	status_exec gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
	curl -sSL https://get.rvm.io | bash -s stable
	if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
		log_blue "source $HOME/.rvm/scripts/rvm"
		source "$HOME/.rvm/scripts/rvm"
	fi
	assert_path "rvm"
	echo 'rvm_auto_reload_flag=2' >> $HOME/.rvmrc
	# To start using RVM you need to run source ~/.rvm/scripts/rvm
	source $HOME/.rvm/scripts/rvm
)

RUBY_VER="2.4"
log_green "-------- Checking Ruby $RUBY_VER --------"
rvm use $RUBY_VER && \
	log_blue "Skip installing Ruby $RUBY_VER" || (
	log_blue "Update RVM before installing ruby."
	status_exec rvm get stable
	# Change rvm source code image to taobao for China.
	in_china && (
		sed -i.bak 's!http://cache.ruby-lang.org/pub/ruby!https://ruby.taobao.org/mirrors/ruby!' $HOME/.rvm/config/db
		log_blue "rvm install $RUBY_VER --disable-binary"
		rvm install $RUBY_VER --disable-binary
		echo "OK"
	) || (
		log_blue "rvm install $RUBY_VER"
		rvm install $RUBY_VER
	)
	source $HOME/.bashrc
	rvm use $RUBY_VER
)
source $HOME/.bashrc
rvm use $RUBY_VER
check_version "ruby" $RUBY_VER || abort "Ruby version is still not $RUBY_VER"
# Change rvm image to taobao for China.
in_china && \
	status_exec gem sources \
	--add https://ruby.taobao.org/ --remove https://rubygems.org/

log_green "-------- Checking aphrodite repo --------"
APD_HOME="$DIR/../../aphrodite"
[[ -d $APD_HOME ]] && \
	log_blue "Skip aphrodite repo" || (
	cd $USER_ARCHIVED
	status_exec rm -rf $USER_ARCHIVED/aphrodite
	status_exec git clone "git@github.com:celon/aphrodite.git" || \
		status_exec git clone "https://github.com/celon/aphrodite.git" || \
		abort "Failed to clone aphrodite"
	status_exec mv $USER_ARCHIVED/aphrodite $APD_HOME || \
		abort "Failed to mv aphrodite"
)
[[ -d $APD_HOME ]] || abort "Failed in initialize aphrodite"

log_green "-------- Checking PhantomJS --------"
check_path "phantomjs" $USER_INSTALL/bin/phantomjs && \
	log_blue "Skip PhantomJS" || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/phantomjs-* )) && (
		rm -rf $USER_ARCHIVED/phantomjs-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -xf $filename
		dirname=${filename%.tar.bz2}
		cd $USER_ARCHIVED/$dirname
		log_blue "cp bin/phantomjs $USER_INSTALL/bin/phantomjs"
		cp bin/phantomjs $USER_INSTALL/bin/phantomjs
		rm -rf $USER_ARCHIVED/phantomjs-*
		assert_path "phantomjs"
	) || log_red "File does not exist"
)

log_green "-------- Checking Python 2.7 --------"
PYTHON_VER="2.7"
is_mac && (
	check_version "python" $PYTHON_VER && \
		log_blue "Skip python $PYTHON_VER" || \
		status_exec brew install python
)
is_linux && (
	check_path "python" $USER_INSTALL/bin/python && \
	log_blue "Python $PYTHON_VER is exist." || (
		filename=$(basename $( ls $LINUX_SETUP_HOME/archived/Python-2* )) && (
			rm -rf $USER_ARCHIVED/Python-2*
			cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			tar -xf $filename
			dirname=${filename%.tar.xz}
			cd $USER_ARCHIVED/$dirname
			status_exec $USER_ARCHIVED/$dirname/configure \
				--prefix=$USER_INSTALL \
				--exec-prefix=$USER_INSTALL || \
				abort "configure failed"
			status_exec make install -j $CPU_CORE || \
				status_exec make install || \
				abort "Make python failed"
			rm -rf $USER_ARCHIVED/Python-*
			echo "OK"
		) || log_red "Python 2 files does not exist"
	)
)
check_version "python" $PYTHON_VER || abort "Python $PYTHON_VER is not in bin path."

log_green "-------- Checking Python pip --------"
is_linux && (
	check_path "pip" $USER_INSTALL/bin/pip && \
	log_blue "pip for Python $PYTHON_VER is exist." || (
		[ -f $LINUX_SETUP_HOME/archived/get-pip.py ] && \
			status_exec python $LINUX_SETUP_HOME/archived/get-pip.py || \
			log_red "File $LINUX_SETUP_HOME/archived/get-pip.py does not exist"
	)
)

log_green "-------- Checking Python 3.6 --------"
PYTHON3_VER="3.6"
is_mac && log_blue "Skip python3 $PYTHON3_VER"
is_linux && (
	check_path "python3" $USER_INSTALL/bin/python3 && \
	log_blue "Python $PYTHON_VER is exist." || (
		filename=$(basename $( ls $LINUX_SETUP_HOME/archived/Python-3* )) && (
			rm -rf $USER_ARCHIVED/Python-3*
			cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			tar -xf $filename
			dirname=${filename%.tar.xz}
			cd $USER_ARCHIVED/$dirname
			status_exec $USER_ARCHIVED/$dirname/configure \
				--prefix=$USER_INSTALL \
				--exec-prefix=$USER_INSTALL || \
				abort "configure failed"
			status_exec make install -j $CPU_CORE || \
				status_exec make install || \
				abort "Make python failed"
			rm -rf $USER_ARCHIVED/Python-*
			echo "OK"
		) || log_red "Python 3 files does not exist"
	)
	check_version "python3" $PYTHON3_VER || abort "Python $PYTHON3_VER is not in bin path."
)
check_version "python3" $PYTHON3_VER || abort "Python $PYTHON3_VER is not in bin path."

log_green "-------- Checking Python pip3 --------"
is_linux && (
	check_path "pip3" $USER_INSTALL/bin/pip3 && \
	log_blue "pip for Python $PYTHON_VER is exist." || (
		[ -f $LINUX_SETUP_HOME/archived/get-pip.py ] && \
			status_exec python3 $LINUX_SETUP_HOME/archived/get-pip.py || \
			log_red "File $LINUX_SETUP_HOME/archived/get-pip.py does not exist"
	)
)

log_green "-------- Checking pyenv --------"
[ -d $HOME/.pyenv ] || \
	status_exec git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv

log_green "-------- Checking Node.js --------"
# Only install Node.js within current user.
# To install Node.js in Centos as root, check this:
# https://nodejs.org/en/download/package-manager/
(
	check_version "node" 'v8' || \
	check_version "node" 'v7' || \
	check_version "node" 'v6' || \
	check_version "node" 'v5' || \
	check_version "node" 'v4' || \
	check_path "node" $USER_INSTALL/bin/node
) && log_blue "Skip Nodejs." || (
	# Copy system libs for python
	[ -d $USER_INSTALL/lib/python$PYTHON_VER ] && \
		ln -sf /usr/lib64/python*/lib-dynload/bz2.so \
		$USER_INSTALL/lib/python$PYTHON_VER/
	for filehead in node-v7 node-v6 node-v5 node-v4 node-v0
	do
		filename=$(basename $( ls $LINUX_SETUP_HOME/archived/$filehead* ))
		[ $? != 0 ] && \
			log_red "File $filehead does not exist" && \
			continue
		log_blue "Installing $filename"
		rm -rf $USER_ARCHIVED/node-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -xf $filename
		rm $USER_ARCHIVED/$filename
		dirname=$(basename $( ls $USER_ARCHIVED | grep '^node-' ))
		dirname=${dirname%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		status_exec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL || abort "configure failed"
		status_exec make install -j $CPU_CORE || \
			status_exec make install
		[ $? == "0" ] && break
		log_red "Make failed, skip installing $filename"
		log_blue "rm -rf $USER_ARCHIVED/$filehead*"
		rm -rf $USER_ARCHIVED/node-*
	done
)
assert_path "node"
assert_path "npm"

log_green "-------- Checking npm utilities --------"
find_path 'npm' && (
	for app in tmux-cpu tmux-mem ; do
		find_path $app && log_blue "Skip $app" && continue
		log_blue "Installing $app."
		npm install -g $app
	done
	echo "OK"
) || log_red "npm could not be found."

log_green "-------- CheckingJava 8 -------"
javaVer=`java -version 2>&1 | grep 'java version'`
[[ $javaVer == *1.8.* ]] && \
log_blue "Current JAVA:$javaVer" || (
	is_mac && \
		log_red "Java should be manually install on MacOSX."
	is_linux && (
		filename=$(basename "$( ls $LINUX_SETUP_HOME/archived/jdk-8u* )" ) && (
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
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/apache-maven-* )) && (
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
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/apache-ant-* )) && (
		rm -rf $USER_ARCHIVED/apache-ant-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec unzip $USER_ARCHIVED/$filename
		rm $USER_ARCHIVED/$filename
		source $HOME/.bashrc
		echo "OK"
	) || log_red "Ant file does not exist."
)

log_green "-------- Checking libsodium --------"
(
	[[ -f $USER_INSTALL/lib/libsodium.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libsodium.so && is_linux ]]
) && \
log_blue "Skip libsodium." || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/libsodium-* )) && (
		rm -rf $USER_ARCHIVED/libsodium-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -xf $filename
		rm $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		status_exec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL \
			--exec-prefix=$USER_INSTALL || \
			abort "configure failed"
		status_exec make install -j $CPU_CORE || \
			status_exec make install || \
			abort "make failed"
		rm -rf $USER_ARCHIVED/libsodium-*
		echo "OK"
	) || log_red "libsodium file does not exist."
)
(
	[[ -f $USER_INSTALL/lib/libsodium.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libsodium.so && is_linux ]]
) || abort "libsodium does not exist."

log_green "-------- Checking ZeroMQ --------"
(
	[[ -f $USER_INSTALL/lib/libzmq.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libzmq.so && is_linux ]]
) && \
log_blue "Skip ZeroMQ." || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/zeromq-* )) && (
		rm -rf $USER_ARCHIVED/zeromq-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -xf $filename
		rm $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		export sodium_CFLAGS="-I$USER_INSTALL/include"
		export sodium_LIBS="-L$USER_INSTALL/lib"
		export CFLAGS=$(pkg-config --cflags libsodium)
		export LDFLAGS=$(pkg-config --libs libsodium)
		status_exec $USER_ARCHIVED/$dirname/autogen.sh || \
			abort "autogen failed"
		status_exec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL \
			--exec-prefix=$USER_INSTALL || \
			abort "configure failed"
		status_exec make install -j $CPU_CORE || \
			status_exec make install || \
			abort "make failed"
		rm -rf $USER_ARCHIVED/zeromq-*
		echo "OK"
	) || log_red "ZeroMQ file does not exist."
)
(
	[[ -f $USER_INSTALL/lib/libzmq.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libzmq.so && is_linux ]]
) || abort "libzmq does not exist."

log_green "-------- Checking jzmq --------"
(
	[[ -f $USER_INSTALL/lib/libjzmq.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libjzmq.so && is_linux ]]
) && \
log_blue "Skip jzmq" || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/jzmq-* )) && (
		rm -rf $USER_ARCHIVED/jzmq-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec unzip -o $filename || \
			abort "unzip failed"
		rm $filename
		dirname=${filename%.zip}/jzmq-jni
		cd $USER_ARCHIVED/$dirname
		export CFLAGS=$(pkg-config --cflags libsodium)
		export LDFLAGS=$(pkg-config --libs libsodium)
		status_exec $USER_ARCHIVED/$dirname/autogen.sh || \
			abort "autogen failed"
		status_exec $USER_ARCHIVED/$dirname/configure \
			--prefix=$USER_INSTALL \
			--exec-prefix=$USER_INSTALL \
			--with-zeromq=$USER_INSTALL || \
			abort "configure failed"
		status_exec make install -j $CPU_CORE || \
			status_exec make install || \
			abort "make failed"
		rm -rf $USER_ARCHIVED/jzmq-*
		echo "OK"
	) || log_red "jzmq file does not exist."
)
(
	[[ -f $USER_INSTALL/lib/libjzmq.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libjzmq.so && is_linux ]]
) || abort "libzmq does not exist."

log_green "-------- Installing Nanomsg --------"
find_path "nanocat" && \
log_blue "Skip nanomsg" || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/nanomsg-* )) && (
		rm -rf $USER_ARCHIVED/nanomsg-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec tar -xf $filename
		rm $filename
		dirname=${filename%.tar.gz}
		cd $USER_ARCHIVED/$dirname
		builddir=$USER_ARCHIVED/$dirname/build
		mkdir $builddir
		cd $builddir
		status_exec cmake $USER_ARCHIVED/$dirname || \
			abort "cmake configure failed"
		status_exec cmake --build $builddir || \
			abort "cmake build failed"
		status_exec ctest $builddir || \
			abort "ctest failed"
		status_exec cmake \
			-DCMAKE_INSTALL_PREFIX:PATH=$USER_INSTALL $builddir || \
			abort "cmake install failed"
		status_exec make all install || \
			abort "make install failed"
		ln -v -sf $USER_INSTALL/lib64/libnanomsg* $USER_INSTALL/lib/
		rm -rf $USER_ARCHIVED/nanomsg-*
		echo "OK"
	) || log_red "nanomsg file does not exist."
)
find_path "nanocat" || abort "nanocat does not exist."

log_green "-------- Checking wkhtmltox --------"
find_path "wkhtmltopdf" && \
log_blue "Skip wkhtmltox" || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/wkhtmltox-* )) && (
		status_exec tar xf $LINUX_SETUP_HOME/archived/$filename \
			-C $USER_INSTALL --strip 1 wkhtmltox/
	) || log_red "wkhtmltox file does not exist."
)

log_green "-------- Checking pdftk --------"
find_path "pdftk" && \
log_blue "Skip pdftk" || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/pdftk-* )) && (
		is_centos6 && (
			rm -rf $USER_ARCHIVED/pdftk-*
			status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
			cd $USER_ARCHIVED
			status_exec unzip -o $USER_ARCHIVED/$filename || \
				abort "Unzip pdftk failed"
			dirname=$(basename $USER_ARCHIVED/pdftk-*-dist)
			cd $USER_ARCHIVED/$dirname/pdftk
			log_blue "make -f Makefile.Redhat"
			cd $USER_ARCHIVED/$dirname/pdftk/
			status_exec make -f \
				$USER_ARCHIVED/$dirname/pdftk/Makefile.Redhat || \
				abort "Making pdftk failed"
			status_exec cp $USER_ARCHIVED/$dirname/pdftk/pdftk \
				$USER_INSTALL/bin/
			rm -rf $USER_ARCHIVED/pdftk-*
			echo "OK"
		) || log_red "Installing pdftk is not implemented on $OS."
	) || log_red "pdftk file does not exist."
)
is_centos6 && is_failed find_path "pdftk" && abort "pdftk does not exist."

log_green "-------- Checking MongoDB --------"
find_path "mongod" && \
log_blue "Skip MongoDB" || (
	filename=$(basename $( ls $LINUX_SETUP_HOME/archived/mongodb-* )) && (
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

log_green "-------- Checking aha Ansi HTML Adapter --------"
find_path "aha" && \
log_blue "Skip aha" || (
    cd $USER_ARCHIVED
    status_exec rm -rf $USER_ARCHIVED/aha
    status_exec git clone 'https://github.com/theZiz/aha.git'
    cd $USER_ARCHIVED/aha
    status_exec make install PREFIX=$USER_INSTALL
)
find_path "mongod" || abort "mongod does not exist"

log_green "-----------------------------------------------"
log_green "Environment set up, reopen bash to take effect."

cd $PWD
