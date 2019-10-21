PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )
[[ $os == "CentOS Linux release 7"* ]] || abort "For centos 7 GPG upgrading only"

mkdir -p $USER_INSTALL
mkdir -p $USER_INSTALL/bin
mkdir -p $USER_INSTALL/include
mkdir -p $USER_INSTALL/lib
mkdir -p $USER_ARCHIVED
USER_ARCHIVED="$HOME/archived"
# Install libraries from https://www.gnupg.org/download/index.html#gpgme
for lib in libgpg-error- libgcrypt- libksba- libassuan- ntbtls- npth- pinentry- ; do
	echo "Installing $lib"
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/$lib* | head -n1 ))
	echo "File located $filename"
	rm -rf $USER_ARCHIVED/$lib*
	cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	status_exec tar -xf $filename
	dirname=$(basename $USER_ARCHIVED/$lib*)
	cd $USER_ARCHIVED/$dirname
	status_exec $USER_ARCHIVED/$dirname/configure \
		--prefix=$USER_INSTALL \
		--exec-prefix=$USER_INSTALL \
		--with-libgpg-error-prefix=$USER_INSTALL || \
		abort "configure failed"
	status_exec make install -j $CPU_CORE || \
		status_exec make install || \
		abort "Make $lib failed"
	rm -rf $USER_ARCHIVED/$lib*
	echo "OK"
done

# Install GnuPG based on previous libraries
for lib in gnupg- ; do
	echo "Installing $lib"
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/$lib* | head -n1 ))
	echo "File located $filename"
	rm -rf $USER_ARCHIVED/$lib*
	cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
	cd $USER_ARCHIVED
	status_exec tar -xf $filename
	dirname=$(basename $USER_ARCHIVED/$lib*)
	cd $USER_ARCHIVED/$dirname
	status_exec $USER_ARCHIVED/$dirname/configure \
		--prefix=$USER_INSTALL \
		--exec-prefix=$USER_INSTALL \
		--with-libgpg-error-prefix=$USER_INSTALL \
		--with-pinentry-pgm=$USER_INSTALL \
		--with-libgcrypt-prefix=$USER_INSTALL \
		--with-libassuan-prefix=$USER_INSTALL \
		--with-ksba-prefix=$USER_INSTALL \
		--with-npth-prefix=$USER_INSTALL \
		--with-ntbtls-prefix=$USER_INSTALL || \
		abort "configure failed"
	status_exec make install -j $CPU_CORE || \
		status_exec make install || \
		abort "Make $lib failed"
	rm -rf $USER_ARCHIVED/$lib*
	echo "OK"
done
