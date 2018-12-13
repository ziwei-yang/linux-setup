#!/bin/bash --login
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "$SOURCE received args: $@"
source $DIR/../common/bootstrap.sh NORUBY

# Download and install tws_latest
if [ ! -d $HOME/Jts ]; then
	log_blue "Installing TWS latest"
	status_exec wget -O $DIR/install_tws_latest.sh 'https://download2.interactivebrokers.com/installers/tws/latest/tws-latest-linux-x64.sh'
	status_exec chmod u+x $DIR/install_tws_latest.sh
	builtin echo 'n' | $DIR/install_tws_latest.sh || abort 'Install tws failed'
	status_exec rm $DIR/install_tws_latest.sh
else
	log_green "TWS is already installed."
fi

if [ ! -d $HOME/Jts/ibgateway ]; then
	log_blue 'Installing IBGateway'
	status_exec wget -O $DIR/ibgateway-latest-standalone-linux-x64.sh 'https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/ibgateway-latest-standalone-linux-x64.sh'
	status_exec chmod u+x $DIR/ibgateway-latest-standalone-linux-x64.sh
	builtin echo 'n' | $DIR/ibgateway-latest-standalone-linux-x64.sh || abort 'Install ibgateway failed'
	status_exec rm $DIR/ibgateway-latest-standalone-linux-x64.sh
else
	log_green "IBGateway is already installed."
fi

# Checkout latest ib-controller.
proj_dir="$LINUX_SETUP_HOME/../"
ibcontroller_dir="$proj_dir/ib-controller"
ibcontroller_ver='3.2.0'
if [ ! -d $ibcontroller_dir ]; then
	log_blue "Cloning ib-controller"
	cd $proj_dir
	status_exec git clone 'https://github.com/ib-controller/ib-controller.git'
fi

# Build ib-controller.
if [ ! -f $ibcontroller_dir/dist/IBController-$ibcontroller_ver.zip ]; then
	log_blue "Building ib-controller $ibcontroller_ver"
	cd $ibcontroller_dir
	status_exec git checkout $ibcontroller_ver
	export TWS="$HOME/Jts"
	status_exec ant clean
	status_exec ant dist
else
	log_green "ib-controller $ibcontroller_ver is already built"
fi

if [ ! -f $HOME/IBController/IBController.jar ]; then
	rm -rf $HOME/IBController > /dev/null 2>&1
	mkdir $HOME/IBController
	status_exec cp $ibcontroller_dir/dist/IBController-$ibcontroller_ver.zip $HOME/IBController/
	cd $HOME/IBController
	status_exec unzip $HOME/IBController/IBController-$ibcontroller_ver.zip
	status_exec chmod u+x $HOME/IBController/*.sh
	status_exec chmod u+x $HOME/IBController/Scripts/*.sh
else
	log_green "$HOME/IBController is installed"
fi
