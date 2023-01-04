#! /bin/bash
# Check and set environment before every scripts.
# Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "Only overwrite VIM and TMUX dotfiles and create directories"

USER_ARCHIVED="$HOME/archived"
USER_INSTALL="$HOME/install"

mkdir -p $USER_INSTALL
mkdir -p $USER_INSTALL/bin
mkdir -p $USER_INSTALL/include
mkdir -p $USER_INSTALL/lib
mkdir -p $USER_ARCHIVED

echo "-------- Overwrite VIM and TMUX conf -------"
mkdir -p $HOME/.vim/backupfiles
mkdir -p $HOME/.vim/swapfiles
mkdir -p $HOME/bin
mkdir -p $HOME/conf
export LINUX_SETUP_HOME="$( cd -P $DIR/../ && pwd )"
cp -v $LINUX_SETUP_HOME/conf/home/.vimrc $HOME/
cp -v $LINUX_SETUP_HOME/conf/home/.tmux*.conf $HOME/
cp -v $LINUX_SETUP_HOME/conf/home/tmux.sh $HOME/
