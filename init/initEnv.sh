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
	for app in vim jq awk sed man tmux screen git curl wget basename tput gpg tree finger nload telnet
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
	echoBlue "Skip RVM."
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

RUBY_VER="2.1.2"
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
checkBinVersion "ruby" $RUBY_VER
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
checkBinVersion "python" $PYTHON_VER

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

echoGreen "-----------------------------------------------"
echoGreen "Environment set up, reopen bash to take effect."

cd $PWD
