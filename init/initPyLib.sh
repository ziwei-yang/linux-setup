#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh

# Install beautifulsoup4
check_py_lib "beautifulsoup4" "4.1.3"
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip python lib beautifulsoup4 4.1.3"
else
	log_blue "pip install 'http://www.crummy.com/software/BeautifulSoup/bs4/download/4.1/beautifulsoup4-4.1.3.tar.gz'"
	pip install "http://www.crummy.com/software/BeautifulSoup/bs4/download/4.1/beautifulsoup4-4.1.3.tar.gz"
fi
# Install feedparser5.2.0
check_py_lib "feedparser" "5.2.0"
ret=$?
if [ $ret == "0" ]; then
	log_blue "Skip python lib feedparser 5.2.0"
else
	echo 'pip install "https://pypi.python.org/packages/source/f/feedparser/feedparser-5.2.0.post1.tar.gz"'
	pip install "https://pypi.python.org/packages/source/f/feedparser/feedparser-5.2.0.post1.tar.gz"
fi
# Install official lib
for pylib in gevent click requests pycurl simplejson chardet lxml numpy scipy scikit-learn matplotlib jieba redis pika pyquery request requests thrift cssselect xlrd MySQL-python readability-lxml pillow
do
	check_py_lib $pylib && log_blue "Skip python lib $pylib" && continue
	log_blue "Installing python lib $pylib"
	pip install $pylib
done
# Copy system libs for python
PYTHON_VER="2.7"
ln -sf /usr/lib64/python*/lib-dynload/bz2.so $USER_INSTALL/lib/python$PYTHON_VER/
