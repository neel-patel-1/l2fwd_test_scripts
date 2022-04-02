#!/bin/bash
#L2FWD

#st_file=pcie_events.txt
st_file=curated.txt

time=120
#clear out recent results 
#mv recent/* res

#run l2fwd_test with specified stats to measure
declare -a b=( "1000" "200000" )
for e in "${b[@]}"; do

	#ins events
	while IFS= read -r stat; do
		sed -i "/#STATS/a stats+=\"-e $stat \" " l2fwd_testpmu.sh 
	done < $st_file
	sed -i "/#STATS/a stats=\"\"" l2fwd_testpmu.sh 
	sed -n '/#STATS/,$p' l2fwd_testpmu.sh | sed '/#check hugepages/q' 

	read -p "$e Mbit/s generator started? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] && ./runAll.sh $time $e || sed -i '/stat.*=.*/d' l2fwd_testpmu.sh && continue
	#./runAll.sh $time $e
	sed -i '/stat.*=.*/d' l2fwd_testpmu.sh
done

#delete stats
sed -i '/stat.*=.*/d' l2fwd_testpmu.sh
./process_recent.sh
