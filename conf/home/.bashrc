# .bashrc
uname=$( uname )

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

export LC_ALL="en_US.utf8"

# Global variables.
export JMX_ARGS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port="

# Platform specified aliases.
if [[ $uname == "Linux" ]]; then
	JAVA_HOME=$( ls $HOME/archived/ | grep jdk | grep -v .gz | tail -1 )
	export JAVA_HOME=$HOME/archived/$JAVA_HOME
	ANT_HOME=$( ls $HOME/archived/ | grep apache-ant| grep -v .zip | tail -1 )
	export ANT_HOME=$HOME/archived/$ANT_HOME
elif [[ $uname == "Darwin" ]]; then
	export PS1='\u:\W$'
	JAVA_HOME=$( ls "/Library/Java/JavaVirtualMachines/" | grep jdk | tail -1 )
	export JAVA_HOME="/Library/Java/JavaVirtualMachines/$JAVA_HOME/Contents/Home"
	export VIMRUNTIME="/usr/share/vim/vim74"
fi

# PATH
M2_HOME=$( ls $HOME/archived/ | grep maven | grep -v .gz | tail -1 )
export M2_HOME=$HOME/archived/$M2_HOME
export M2="$M2_HOME/bin"
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PYENV_ROOT/bin:$M2:$ANT_HOME/bin:$JAVA_HOME/bin:$HOME/.rvm/bin:$HOME/install/bin:$PATH
export CPATH=$HOME/install/include:$CPATH
export LIBRARY_PATH=$HOME/install/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$HOME/install/lib:$LD_LIBRARY_PATH
export LD_RUN_PATH=$HOME/install/lib:$LD_RUN_PATH
export PKG_CONFIG_PATH=$HOME/install/lib:$HOME/install/lib/pkgconfig:$PKG_CONFIG_PATH

# RVM
export rvm_path=$HOME/.rvm
# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

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

PATH="$GEM_HOME/bin:$HOME/.rvm/bin:$PATH"
