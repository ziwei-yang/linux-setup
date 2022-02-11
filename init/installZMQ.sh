#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

log_green "-------- Checking libsodium --------"
(
	[[ -f $USER_INSTALL/lib/libsodium.dylib && is_mac ]] || \
	[[ -f $USER_INSTALL/lib/libsodium.so && is_linux ]]
) && \
log_blue "Skip libsodium." || (
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/libsodium-* | head -n1 )) && (
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
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/zeromq-* | head -n1 )) && (
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
# JAVA 10 dropped javah
(
	[[ -f $USER_INSTALL/lib/libjzmq.dylib && is_mac ]] || \
	[[ ! -f $JAVA_HOME/bin/javah ]] || \
	[[ -f $USER_INSTALL/lib/libjzmq.so && is_linux ]]
) && \
log_blue "Skip jzmq" || (
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/jzmq-* | head -n1 )) && (
		rm -rf $USER_ARCHIVED/jzmq-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec unzip -o $filename || abort "unzip $filename failed"
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
	[[ ! -f $JAVA_HOME/bin/javah ]] || \
	[[ -f $USER_INSTALL/lib/libjzmq.so && is_linux ]]
) || abort "JZMQ does not exist."

log_green "-------- Installing Nanomsg --------"
find_path "nanocat" && \
log_blue "Skip nanomsg" || (
	filename=$(basename $( ls -1t $LINUX_SETUP_HOME/archived/nanomsg-* | head -n1 )) && (
		rm -rf $USER_ARCHIVED/nanomsg-*
		status_exec cp $LINUX_SETUP_HOME/archived/$filename $USER_ARCHIVED/
		cd $USER_ARCHIVED
		status_exec unzip -o $filename || abort "unzip failed"
		rm $filename
		dirname=${filename%.zip}
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
