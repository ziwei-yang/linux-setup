#!/bin/sh
tmux has-session -t server
if [ $? != 0 ]; then
	tmux source ~/.tmux.conf

	tmux new-window -n rds -t server
	tmux send-keys -t server:rds 'source ~/bin/startRedis.sh' C-m

	tmux new-window -n rdsWeb -t server
	tmux send-keys -t server:rdsWeb '~/install/bin/redis-commander' C-m

	tmux new-window -n dtSv -t server
	tmux send-keys -t server:dtSv 'source ~/Proj/bigdata/server/start.sh' C-m

	tmux new-window -n hkexnews -t server
	tmux send-keys -t server:hkexnews 'source ~/Proj/bigdata/news/spider/start.sh' C-m

	tmux new-window -n web -t server
	tmux send-keys -t server:web 'source ~/Proj/bitex.web/client_new/startWeb.sh' C-m

	tmux new-window -n classify -t server
	tmux send-keys -t server:classify 'source ~/server/startClassify.sh' C-m

	tmux new-window -n newsIdx -t server
	tmux send-keys -t server:newsIdx 'ruby ~/Proj/bigdata/index/news_classify/newsIndexBuilder.rb' C-m

	tmux new-window -n newsTag -t server
	tmux send-keys -t server:newsIdx 'ruby ~/Proj/bigdata/index/news_classify/newsTagByRule.rb' C-m

	tmux new-window -n newsSQLTag -t server
	tmux send-keys -t server:newsIdx 'ruby ~/Proj/bigdata/index/news_classify/newsTagBySQL.rb' C-m

	tmux new-window -n newsDupByGen -t server
	tmux send-keys -t server:newsIdx 'ruby ~/Proj/bigdata/index/news_classify/newsDupFilter.rb' C-m

	tmux new-window -n newsImp -t server
	tmux send-keys -t server:newsSpd 'source ~/Proj/bigdata/spider/rss2mq/start.sh' C-m

	tmux new-window -n cn0 -t server
	tmux send-keys -t server:newsSpd 'source ~/Proj/bigdata/news/rss/rssspider.sh cn 0 210' C-m

	tmux new-window -n cn1 -t server
	tmux send-keys -t server:newsSpd 'source ~/Proj/bigdata/news/rss/rssspider.sh cn 1 210' C-m

	tmux new-window -n cn2 -t server
	tmux send-keys -t server:newsSpd 'source ~/Proj/bigdata/news/rss/rssspider.sh cn 2 210' C-m

	tmux new-window -n cnN -t server
	tmux send-keys -t server:newsSpd 'source ~/Proj/bigdata/news/rss/rssspider.sh cn null 210' C-m

	tmux new-window -n enN -t server
	tmux send-keys -t server:newsSpd 'source ~/Proj/bigdata/news/rss/rssspider.sh en null 100' C-m

	tmux new-window -n bash -t server
	tmux send-keys -t server:bash 'pwd' C-m

	tmux select-window -t server:bash
fi

tmux attach -t server
