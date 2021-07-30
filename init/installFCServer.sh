#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

can_sudo
if [[ $? == 0 ]]; then
	echo_red "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo_red "This script will initialize system JRE to 8u101"
	echo_red "This script will install MySQL 8.0 to system"
	echo_red "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo_red "Press enter to continue"
	read
else
	abort "User must have sudo privilege"
fi

function dl {
	wget -c --no-cookies --no-check-certificate -nc $@
}

##################################################
# JRE 8u101
# https://community.fundcount.com/knowledgebase/Installing_a_Client_Server_Setup_on_Linux?srid
##################################################
java_version=$( sudo java -version 2>&1 )
if [[ $java_version == *1.8.0_101* ]]; then
	echo_blue $java_version
else
	cd /tmp/
	status_exec sudo mkdir -p /usr/local/java || abort "Failed in mkdir"
	status_exec dl 'https://gigo.ai/download/jre-8u101-linux-x64.tar.gz' || abort "Failed in downloading jre-8u101"
	status_exec sudo tar zxvf jre-8u101-linux-x64.tar.gz -C /usr/local/java || abort "Failed in unpacking jre"
	status_exec sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/jre1.8.0_101/bin/java" 9999
	# Document does not mention this but we need to select 8u101 as default.
	status_exec sudo update-alternatives --set "java" "/usr/local/java/jre1.8.0_101/bin/java"
	java_version=$( sudo java -version 2>&1 )
	echo_blue $java_version
	[[ $java_version == *1.8.0_101* ]] || abort "Java version still not 1.8.0_101"
fi

##################################################
# MySQL 8.0.xx
##################################################
mysql_version=$( sudo mysql --version 2>&1 )
if [[ $mysql_version == *8.0.* ]]; then
	echo_blue $mysql_version
else
	# https://dev.mysql.com/downloads/repo/apt/
	cd /tmp/
	status_exec dl 'https://gigo.ai/download/mysql-apt-config_0.8.17-1_all.deb' || abort "Failed in downloading mysql apt deb"
	echo_blue "When prompted, please choose ok to continue, press enter to install mysql apt deb"
	read
	sudo dpkg -i /tmp/mysql-apt-config_0.8.17-1_all.deb || abort "Failed in installing mysql apt deb"
	status_exec sudo apt-get update -y # It is okay if failed partially.
	# Need user interaction
	sudo apt-get -y install mysql-server || abort "Failed in installing mysql server"
	mysql_version=$( sudo mysql --version 2>&1 )
	[[ $mysql_version == *8.0.* ]] || abort "mysql_version still not 8.0.xx"
	# Overwrite with predefined conf.
	# https://community.fundcount.com/knowledgebase/Installing_a_Client_Server_Setup_on_Linux?srid
	status_exec sudo cp $DIR/../conf/mysql/fundcount.my.cnf /etc/mysql/my.cnf || abort "Failed in writing mysql conf"
	status_exec sudo systemctl enable mysql || abort "Failed to autostart mysql"
	status_exec sudo systemctl restart mysql || abort "Failed to restart mysql, maybe data need to be purged by rm -rv /var/lib/mysql/"
fi

# The instructions below describe the process of creating a user if your MySQL server and FC Application Server are installed on the same machine:
sudo mysql -u root -e "CREATE USER 'fcadmin'@'localhost' IDENTIFIED BY 'fcadmin';GRANT ALL PRIVILEGES ON *.* TO 'fcadmin'@'localhost';FLUSH PRIVILEGES;" || echo_red "Creating fcadmin mysql user failed, maybe user existed"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'fcadmin'@'localhost';FLUSH PRIVILEGES;" || abort "Failed in granting fcadmin mysql privileges"

##################################################
# Installing OrientDB at $HOME/server/
# https://community.fundcount.com/knowledgebase/Installing_a_Client_Server_Setup_on_Linux?srid
##################################################
if [ ! -f $HOME/server/orientdb-community-tp2-3.0.2/bin/server.sh ]; then
	mkdir -p $HOME/server
	cd $HOME/server
	status_exec dl 'https://repo1.maven.org/maven2/com/orientechnologies/orientdb-community-tp2/3.0.2/orientdb-community-tp2-3.0.2.tar.gz' || abort "Failed in downloading OrientDB"
	status_exec tar -xzf orientdb-community-tp2-3.0.2.tar.gz || abort "Failed in unpacking OrientDB"
fi

cd $HOME/server
if [[ -f /etc/systemd/system/orientdb.service ]]; then
	echo "Required OrientDB service found, skip editing password"
else
	echo_blue "By default, FC Application Server requires user root with password root."
	echo_red "If asked, please set password as root, otherwise press Ctrl-C after server is active"
	echo_red "Press enter to continue"
	read
	cd $HOME/server
	orientdb-community-tp2-3.0.2/bin/server.sh
fi

# Set required attributes.
cd $HOME/server
file=orientdb-community-tp2-3.0.2/config/orientdb-server-config.xml
lines=$( grep -n storage.diskCache.bufferSize orientdb-community-tp2-3.0.2/config/orientdb-server-config.xml | wc -l )
if [[ $lines > 0 ]]; then
	echo "Required OrientDB config found, skip editing"
	grep -n ridBag.embeddedToSbtreeBonsaiThreshold $file
	grep -n storage.diskCache.bufferSize $file
else
	echo_red "Then add below lines after config/orientdb-server-config.xml:line 85 under <properties>"
	echo_blue '<entry value="-1" name="ridBag.embeddedToSbtreeBonsaiThreshold"/>'
	echo_blue '<entry value="4096" name="storage.wal.maxSize"/>'
	echo_blue '<entry value="67108864" name="memory.chunk.size"/>'
	echo_blue '<entry value="4096" name="storage.diskCache.bufferSize"/>'
	echo_blue '<entry value="65536" name="network.binary.maxLength"/>'
	echo_red "Please copy lines and press enter"
	read
	vim $file
fi

# Setup orientdb.service
cd $HOME/server
if [[ -f /etc/systemd/system/orientdb.service ]]; then
	echo "Required OrientDB service found, skip adding service file"
else
	file=orientdb-community-tp2-3.0.2/bin/orientdb.service
	echo_red "Will edit $file"
	echo_blue "EDIT User=$( whoami )"
	echo_blue "EDIT Group=$( whoami )"
	echo_blue "ExecStart=$HOME/server/orientdb-community-tp2-3.0.2/bin/server.sh"
	echo_red "Please copy lines and press enter"
	read
	vim $file
	status_exec sudo cp $file /etc/systemd/system/orientdb.service
fi
status_exec sudo systemctl enable orientdb.service
sudo systemctl start orientdb.service || abort "Failed in starting OrientDB"

##################################################
# Installing dependencies and FC Server
# https://community.fundcount.com/knowledgebase/Installing_a_Client_Server_Setup_on_Linux?srid
##################################################
status_exec sudo apt update -y
status_exec sudo apt install -y libxrender1 || abort "Required libxrender1 could not be installed"
status_exec sudo apt install -y libxtst6 || abort "Required libxtst6 could not be installed"
status_exec sudo apt install -y libxi6 || abort "Required libxi6 could not be installed"
status_exec sudo apt install -y xvfb || abort "Required xvfb could not be installed"
status_exec sudo apt install -y tightvncserver || abort "Required tightvncserver could not be installed"
# This might take long time and user interaction UI, show progress.
sudo apt install -y ubuntu-mate-desktop || abort "Required DE could not be installed"

# Setup xvfb.service
cd $HOME/server
if [[ -f /etc/systemd/system/xvfb.service ]]; then
	echo "Required xvfb service found, skip adding service file"
else
	file=orientdb-community-tp2-3.0.2/bin/orientdb.service
	cp $file xvfb.service
	file=xvfb.service
	echo_red "Will edit $file"
	echo_blue "EDIT User=$( whoami )"
	echo_blue "EDIT Group=$( whoami )"
	echo_blue "ExecStart=Xvfb :1 -screen 0 640x480x8 -nolisten tcp"
	echo_red "Please copy lines and press enter"
	read
	vim $file
	status_exec sudo cp $file /etc/systemd/system/xvfb.service
fi
status_exec sudo systemctl enable xvfb.service
sudo systemctl start xvfb.service || abort "Failed in starting xvfb service"

if [[ -f /etc/init.d/fcoffice ]]; then
	echo "Required fcoffice service found, skip installation"
else
	cd /tmp/
	status_exec dl 'https://gigo.ai/download/fc_setup-3.39.2.sh' || abort "Failed in downloading FC script"
	chmod u+x /tmp/fc_setup-3.39.2.sh
	sudo /tmp/fc_setup-3.39.2.sh
fi

# Enable OrientDB in /opt/fcoffice/FC Office/FC Office.cfg
lines=$( grep -Rn dependencyGraph.storage=ORIENT_DB /opt/fcoffice/FC\ Office/FC\ Office.cfg )
if [[ $lines == *dependencyGraph.storage=ORIENT_DB* ]]; then
	echo_blue "dependencyGraph.storage=ORIENT_DB found in /opt/fcoffice/FC Office/FC Office.cfg"
else
	echo_blue "Add dependencyGraph.storage=ORIENT_DB into /opt/fcoffice/FC Office/FC Office.cfg"
	echo_blue "Press enter to continue"
	read
	sudo vim /opt/fcoffice/FC\ Office/FC\ Office.cfg
	lines=$( grep -Rn dependencyGraph.storage=ORIENT_DB /opt/fcoffice/FC\ Office/FC\ Office.cfg )
	[[ $lines == *dependencyGraph.storage=ORIENT_DB* ]] || abort "Required conf not found in file"
fi

 sudo /etc/init.d/fcoffice restart
