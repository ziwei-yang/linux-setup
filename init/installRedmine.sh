#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh

os=$( osinfo )
USER=$( whoami )
can_sudo || abort "User has no privilege."

[[ $os == "CentOS"* ]] || abort "$os is not supported."

# https://www.howtoforge.com/tutorial/how-to-install-redmine-3-with-nginx-on-centos-7/
status_exec sudo yum install -y zlib-devel curl-devel openssl-devel \
	httpd-devel apr-devel apr-util-devel mysql-devel ftp wget \
	ImageMagick-devel gcc-c++ patch readline readline-devel zlib \
	libyaml-devel libffi-devel make bzip2 autoconf automake libtool bison \
	iconv-devel subversion || \
	abort "Fail to install dependencies"

# Redmine requires systemwide ruby.
status_exec sudo gpg2 --keyserver hkp://keys.gnupg.net \
	--recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
	7D2BAF1CF37B13E2069D6956105BD0E739499BDB || \
	abort "Fail to install rvm gpg keys"
curl -L https://get.rvm.io | bash -s stable --ruby=2.2
source /usr/local/rvm/scripts/rvm

# Must use ruby 2.3 with redmine 3.1
rvm use 2.3 || rvm install 2.3

echo "Execute this in mysql:"
echo "create database redmine;"
echo "create user redmine@localhost identified by 'pswd';"
echo "grant all privileges on redmine.* to redmine@localhost identified by 'pswd';"

# Step 6 - Install Redmine
root=$HOME/server
mkdir -p $root || abort "Could not mkdir $root"
cd $root
redmine_dir=$root/redmine
[ -d $redmine_dir ] && abort "$redmine_dir exists already."
svn co https://svn.redmine.org/redmine/branches/3.1-stable redmine
cd $redmine_dir
status_exec cp config/configuration.yml.example config/configuration.yml
status_exec cp config/database.yml.example config/database.yml
vim config/database.yml

rvm use 2.3
status_exec gem install bundler
status_exec bundle install --without development test
status_exec bundle exec rake generate_secret_token

# Initialize the Rails application under sub URI
# RedmineApp::Application.routes.default_scope = "/redmine" 
# ActionController::Base.relative_url_root = "/redmine" 
# Rails.application.initialize!
# Redmine::Utils::relative_url_root = "/redmine" 

echo '#! /bin/bash --login' >> $redmine_dir/start.sh
echo '[[ -z $CURRENT_DIR ]] && CURRENT_DIR=$( pwd )' >> $redmine_dir/start.sh
echo 'SOURCE="${BASH_SOURCE[0]}"' >> $redmine_dir/start.sh
echo 'DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"' >> $redmine_dir/start.sh
echo 'cd $DIR' >> $redmine_dir/start.sh
echo "rvm use 2.3" >> $redmine_dir/start.sh
echo "bundle exec ruby bin/rails server -b 0.0.0.0 webrick -e production" >> $redmine_dir/start.sh
chmod u+x $redmine_dir/start.sh

echo "Finished"
