#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
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
mkdir -p $USER_ARCHIVED

echoGreen "-------- Checking environment. --------"
# Check sudo privilege.
ret=$( sudo -n echo a 2>&1 )
sudoAllowed="0"
if [[ $ret == "a" ]] && [[ $os != "Darwin" ]]; then
	echoBlue "User has sudo privilege without password."
	sudoAllowed="1"
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
cp -v $DIR/conf/home/.tmux.conf $HOME/
cp -v $DIR/conf/home/tmux_dev.sh $HOME/
cp -v $DIR/conf/home/.profile $HOME/
# Do not copy other files for safety.

if [[ $sudoAllowed == "1" ]] || [[ $os == "Darwin" ]]; then
	echoGreen "-------- Installing system tools --------"
	if [[ $os == CentOS* ]]; then
		if [ $(yum grouplist groupinfo 'Development tools' | grep "Installed" | wc -l) == "0" ]; then
			sudo yum -y groupinstall 'Development tools'
		else
			echoBlue "Skip Development tools"
		fi
	fi
	for app in screen git curl wget basename tput gpg tree finger nload 
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

echoGreen "-------- Installing RVM --------"
checkExactBinPath "rvm" $HOME/.rvm/bin/rvm
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip RVM."
else
	gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
	curl -sSL https://get.rvm.io | bash -s stable
fi
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
	echoBlue "source $HOME/.rvm/scripts/rvm"
	source "$HOME/.rvm/scripts/rvm"
fi
assertBinPath "rvm"

RUBY_VER="2.1.2"
rvm use $RUBY_VER
echoGreen "-------- Installing Ruby $RUBY_VER --------"
checkExactBinPath "ruby" $HOME/.rvm/rubies/ruby-$RUBY_VER/bin/ruby
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip Ruby."
else
	echoBlue "rvm install $RUBY_VER"
	rvm install $RUBY_VER
fi
rvm use $RUBY_VER
checkBinVersion "ruby" $RUBY_VER

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

echoGreen "-------- Installing redis-commander --------"
checkExactBinPath "redis-commander" $USER_INSTALL/bin/redis-commander
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip redis-commander."
else
	npm install -g redis-commander
fi
assertBinPath "redis-commander"

PYTHON_VER="2.7"
echoGreen "-------- Installing Python --------"
if [ $os != "Darwin" ]; then
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
checkBinVersion "python" $PYTHON_VER

# Install PIP
echoGreen "-------- Installing PIP and Py lib --------"
if [ $os != "Darwin" ]; then
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
# Install beautifulsoup4
checkPyLibVersion "beautifulsoup4" "4.1.3"
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip python lib beautifulsoup4 4.1.3"
else
	echoBlue "pip install 'http://www.crummy.com/software/BeautifulSoup/bs4/download/4.1/beautifulsoup4-4.1.3.tar.gz'"
	pip install "http://www.crummy.com/software/BeautifulSoup/bs4/download/4.1/beautifulsoup4-4.1.3.tar.gz"
fi
# Install feedparser5.2.0
checkPyLibVersion "feedparser" "5.2.0"
ret=$?
if [ $ret == "0" ]; then
	echoBlue "Skip python lib feedparser 5.2.0"
else
	echo 'pip install "https://pypi.python.org/packages/source/f/feedparser/feedparser-5.2.0.post1.tar.gz"'
	pip install "https://pypi.python.org/packages/source/f/feedparser/feedparser-5.2.0.post1.tar.gz"
fi
# Install official lib
for pylib in numpy scipy scikit-learn matplotlib jieba redis pika pyquery cssselect xlrd MySQL-python; do
	checkPyLibVersion $pylib
	ret=$?
	if [ $ret == "0" ]; then
		echoBlue "Skip python lib $pylib"
	else
		pip install $pylib
	fi
done

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
fi

echoGreen "-----------------------------------------------"
echoGreen "Environment set up, reopen bash to take effect."

cd $PWD
