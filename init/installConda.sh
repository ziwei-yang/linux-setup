#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )
USER=$( whoami )

for app in conda
do
	find_path $app && continue
	if [[ $os == CentOS* ]]; then
		status_exec wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
		status_exec bash ~/miniconda.sh -b -p $HOME/miniconda
	elif [[ $os == Ubuntu* ]]; then
		status_exec wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
		status_exec bash ~/miniconda.sh -b -p $HOME/miniconda
	elif [[ $os == "Darwin" ]]; then
		status_exec wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
		status_exec bash ~/miniconda.sh -b -p $HOME/miniconda
	elif [[ $os == MacOS* ]]; then
	  status_exec wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda.sh
	  status_exec bash ~/miniconda.sh -b -p $HOME/miniconda
	fi
done

