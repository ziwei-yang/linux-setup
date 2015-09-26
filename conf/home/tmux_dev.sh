#!/bin/sh
tmux has-session -t dev
if [ $? != 0 ]; then
	tmux new-session -s dev -n bash -d
	#tmux new-session -s dev -n sql -d
	#tmux send-keys -t dev:sql 'mysql -uroot -p' C-m
fi

tmux attach -t dev
