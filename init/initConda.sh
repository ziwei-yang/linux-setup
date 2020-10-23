#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

# use; install
if [[ $os == CentOS* ]]; then
  if $1 == "install"; then
    conda create --$2 $3
  elif $2 == 'use'; then
    source activate $2
  fi
fi
