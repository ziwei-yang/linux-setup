# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
cd $DIR

source $DIR/util/util.sh
setup_sys_env

assert_path "echo"
assert_path "sudo"
assert_path "yum"
assert_path "cp"
assert_path "wc"

find_path "rabbitmq-server"
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip installing rabbitMQ..."
else
	# Install EPEL repo.
	sudo rpm -Uvh "http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
	
	# Install erlang.
	sudo yum -y install erlang
	
	# Install rabbit mq.
	sudo rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
	sudo yum -y install "https://www.rabbitmq.com/releases/rabbitmq-server/v3.4.3/rabbitmq-server-3.4.3-1.noarch.rpm"
fi

echo "Make rabbitMQ start with power on."
sudo chkconfig --level 2345 rabbitmq-server on

echo "Starting rabbitMQ."
sudo service rabbitmq-server start

echo "Setting up user privilege."
sudo rabbitmqctl add_user bigdata changeit
sudo rabbitmqctl change_password bigdata x
sudo rabbitmqctl set_user_tags bigdata administrator
sudo rabbitmqctl set_permissions -p / bigdata ".*" ".*" ".*"

echo "Enabling web management UI."
sudo rabbitmq-plugins enable rabbitmq_management
