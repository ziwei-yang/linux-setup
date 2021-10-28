# .bashrc
uname=$( uname )

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Global variables.
export JMX_ARGS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port="

# Platform specified aliases.
if [[ $uname == "Linux" ]]; then
        # Only when java/ant missing by default, or is pointed to ~/archived/ already.
        which java 2>&1 > /dev/null || java_missed=1
	[ -z $JAVA_HOME ] && java_missed=1
        if [[ $java_missed == 1 ]] || [[ $( which java ) == $HOME/archived/* ]]; then
                JAVA_HOME=$( ls $HOME/archived/ | grep jdk | grep -v .gz | tail -1 )
                export JAVA_HOME=$HOME/archived/$JAVA_HOME
                export PATH=$JAVA_HOME/bin:$PATH
        fi
        which ant 2>&1 > /dev/null || ant_missed=1
        if [[ $ant_missed == 1 ]] || [[ $( which ant ) == $HOME/archived/* ]]; then
                ANT_HOME=$( ls $HOME/archived/ | grep apache-ant| grep -v .zip | tail -1 )
                export ANT_HOME=$HOME/archived/$ANT_HOME
                export PATH=$ANT_HOME/bin:$PATH
        fi
elif [[ $uname == "Darwin" ]]; then
	export PS1='\u:\W$'
	JAVA_HOME=$( ls "/Library/Java/JavaVirtualMachines/" | grep jdk | tail -1 )
	export JAVA_HOME="/Library/Java/JavaVirtualMachines/$JAVA_HOME/Contents/Home"
	VIMRUNTIME=$( ls /usr/share/vim/ | grep -E 'vim[0-9]{2}' | tail -1 )
	export VIMRUNTIME="/usr/share/vim/$VIMRUNTIME"
	# Add path for brew
	export PATH=/usr/local/bin:$PATH
	export CPATH=/usr/local/include:$CPATH
	export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
	export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
	export LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH

	export LC_ALL=en_US.UTF-8  
	export LANG=en_US.UTF-8
fi

# PATH
M2_HOME=$( ls $HOME/archived/ | grep maven | grep -v .gz | tail -1 )
export M2_HOME=$HOME/archived/$M2_HOME
export M2="$M2_HOME/bin"
export PYENV_ROOT=$HOME/.pyenv
export AWS_ROOT=$HOME/.local
export PATH=$HOME/Proj/linux-setup/bin:$PYENV_ROOT/bin:$M2:$HOME/install/bin:$HOME/.rvm/bin:$AWS_ROOT/bin:$PATH
export CPATH=$HOME/install/include:$CPATH
export LIBRARY_PATH=$HOME/install/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$HOME/install/lib:$LD_LIBRARY_PATH
export LD_RUN_PATH=$HOME/install/lib:$LD_RUN_PATH
export PKG_CONFIG_PATH=$HOME/install/lib:$HOME/install/lib/pkgconfig:$PKG_CONFIG_PATH

# RVM
export rvm_path=$HOME/.rvm
# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
trap SIGINT # Some RVM script could ignore SIGINT.

# History control
export HISTCONTROL='ignorespace:ignoredups:erasedups'
#append history file instead of overwritting it
#shopt -s
#history file will be re-written and re-read each time bash shows the prompt
#PROMPT_COMMAND="$PROMPT_COMMAND;history -a; history -n"
export HISTIGNORE='ls:ll'
export HISTTIMEFORMAT='%y/%m/%d %T '

# User specific aliases and functions
if [[ $uname == "Linux" ]]; then
	alias ll=" ls -Alh --color "
elif [[ $uname == "Darwin" ]]; then
	alias ll=" ls -AlhG "
fi
alias ssh=" ssh -C "
alias grep=" grep -a "
alias make=" make -j 6 "
alias wget=' wget --no-check-certificate'
alias less=' less -R '
alias tree=' tree -C '

# More fancy aliases.
alias HTTP_SEVER=' python -m SimpleHTTPServer'
alias memsum='sudo echo $(ps -axfm -o "rss" | cut -c 66-80 | awk "FNR>1" | awk -F: "{total+=\$1} END{print total}")KB memory used.'

# Platform specified aliases.
if [[ $uname == "Linux" ]]; then
	alias WATCH_DB_IDX="sudo watch -n 1 'sudo ls -l /var/lib/mysql/bigdata/share_hold_data.MY[ID] /var/lib/mysql/bigdata/*sql-*.MY[ID] '"
elif [[ $uname == "Darwin" ]]; then
	alias RAM_DISK="diskutil erasevolume HFS+ 'RAM Disk' \`hdiutil attach -nomount ram://1048576\`"
fi

export CONDA_HOME=$HOME/miniconda
# [ -d $HOME/miniconda/bin ] && export PATH=$HOME/miniconda/bin:$PATH

[ -z $GEM_HOME ] || PATH=$GEM_HOME/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
