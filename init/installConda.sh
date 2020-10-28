#! /bin/bash
PWD=$(pwd)
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source $DIR/../common/bootstrap.sh NORUBY

os=$( osinfo )
USER=$( whoami )

for app in conda
do
	find_path $app && echo "Conda exists already" && continue
	is_linux && status_exec wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $HOME/miniconda.sh
	is_mac && status_exec wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O $HOME/miniconda.sh
	[ ! -f $HOME/miniconda.sh ] && abort "Error in downlading miniconda.sh"
	status_exec bash $HOME/miniconda.sh -b -p $HOME/miniconda || abort "Conda installation failed"
	echo "Generating $HOME/miniconda/bin/init_conda.sh"
	$HOME/miniconda/bin/conda shell.bash hook > $HOME/miniconda/bin/init_conda.sh || \
		abort "Error in generating $HOME/miniconda/bin/init_conda.sh"
done

