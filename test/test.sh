#! /bin/bash
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh

dir="$HOME/../"
log $dir
ret=$( absolute_dir_path "$dir" )
log $ret
ret=$( absolute_path "$dir" )
log $ret
