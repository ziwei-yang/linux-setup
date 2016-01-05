PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
DIR=$DIR/../
cd $DIR

source $DIR/util/util.sh
setupBasicEnv

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
for pylib in simplejson chardet lxml numpy scipy scikit-learn matplotlib jieba redis pika pyquery request thrift cssselect xlrd MySQL-python readability-lxml; do
	checkPyLibVersion $pylib
	ret=$?
	if [ $ret == "0" ]; then
		echoBlue "Skip python lib $pylib"
	else
		pip install $pylib
	fi
done
