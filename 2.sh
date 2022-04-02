#!/bin/bash
#IDLE

#st_file=pcie_events.txt
export st_file=allevents.txt

#clear out recent results 
mv recent/* res

#ins events
while IFS= read -r stat; do
	sed -i "/#STATS/a stats+=\"-e $stat \" " idle.sh 
done < $st_file
sed -i "/#STATS/a stats=\"\"" idle.sh 
sed -n '/#STATS/,$p' idle.sh | sed '/#check hugepages/q' 

#run l2fwd_test with specified stats to measure
./idle.sh 120

#delete stats
sed -i '/stat.*=.*/d' l2fwd_testpmu.sh

#process data in recent
./process_recent.sh
