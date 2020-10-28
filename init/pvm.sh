#! /bin/bash
# Check and set environment before every scripts. Golbal vars should be not affect others.
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )

echo "Sourcing init_conda.sh"
source $CONDA_HOME/bin/init_conda.sh || echo "Error in sourcing init_conda.sh"

[ -d $HOME/miniconda/bin ] && export PATH=$HOME/miniconda/bin:$PATH

# use; install
if [[ $os == CentOS* ]]; then
  if [[ $1 == "install" ]]; then
    $CONDA_HOME/bin/conda create --name $2 python=$3
  elif [[ $1 == "use" ]]; then
    echo $CONDA_HOME/bin/conda activate $2
    $CONDA_HOME/bin/conda activate $2
  elif [[ $1 == "envs" ]]; then
    $CONDA_HOME/bin/conda info --envs
  elif [[ $1 == "help" ]]; then
    echo "install env_name python_ver. Example: install py3.8 3.8"
    echo "use env_name. Example: use py3.8"
    echo "envs. Example: envs"
  fi
fi

which python
python --version
