# /sbin/bash

path=$PWD

#param: server close/wait
function closewait()
{
	waittime=10
	cmd="ps -ef | grep -v grep | grep $path | grep $1"

	if [[ $2 == "close" ]]; then
		pids=`eval $cmd | awk '{print $2}'`
		for pid in $pids
		do
			kill -15 $pid
			echo kill $pid
		done
	fi

	for (( i = 1; i <= $waittime; i++ ))  
	do  
		process=`eval $cmd`
		if [[ ! $process ]]; then
			echo close $1 successful
			break
		else
			echo waitting $1 close ......$i
		fi
		sleep 1
	done  

	if (($i > $waittime)); then
		echo close $1 fail\(timeout\)
	fi
}

closewait "WGlobalServer" "close"
closewait "WGlobalServer2" "close"
ping 127.0.0.1 -c 4
closewait "LogicServer" "close"

