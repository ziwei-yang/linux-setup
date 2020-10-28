#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )

# use; install
if [[ $os == CentOS* ]]; then
  if [[ $1 == "install" ]]; then
    status_exec ~/miniconda/bin/conda create --name $2 python=$3
  elif [[ $1 == "use" ]]; then
    status_exec source ~/miniconda/bin/activate $2
  elif [[ $1 == "envs" ]]]; then
    ~/miniconda/bin/conda info --envs
  elif [[ $1 == "help" ]]; then
    echo "install env_name python_ver. Example: install py3.8 3.8"
    echo "use env_name. Example: use py3.8"
    ehco "envs. Example: envs"
  fi
fi
