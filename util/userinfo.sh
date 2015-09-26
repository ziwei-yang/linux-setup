echo -e "User  \t: Groups"
echo -e "-----------------------------"
for userpath in /home/*; do
	user=$(basename $userpath)
	if [[ $user == "automator" ]]; then
		continue
	fi
	echo -e -n "$user\t:"
	group=$(groups $user 2>/dev/null)
	for seg in $group; do
		if [[ $seg == $user ]]; then
			continue
		fi
		if [[ $seg == ":" ]]; then
			continue
		fi
		echo -e -n " [$seg]"
	done
	echo ""
done
