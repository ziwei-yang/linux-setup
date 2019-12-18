#!/bin/sh
name=$1
[ -z $name ] && name=dev
tmux has-session -t $name
if [ $? != 0 ]; then
	tmux new-session -s $name -n bash -d
fi

tmux attach -t $name
