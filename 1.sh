#!/bin/bash
#L2FWD

#st_file=pcie_events.txt
export st_file=curated.txt
export time=120
export proc=l2fwd_rdt_set.sh

source process_recent.sh
#clear out recent results 
#mv recent/* res

#run l2fwd_test with specified stats to measure
declare -a b=( "8" "20000" "1000")
#declare -a b=("8")
for e in "${b[@]}"; do

	#ins events
	while IFS= read -r stat; do
		sed -i "/#STATS/a stats+=\"-e $stat \" " ${proc}
	done < $st_file
	sed -i "/#STATS/a stats=\"\"" ${proc}
	sed -n '/#STATS/,$p' ${proc}| sed '/#check hugepages/q' 

	read -p "$e Mbit/s generator started? (Y/N): " confirm 
	if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
		./runAll.sh $time $e 
		genAvgs
	else
		sed -i '/stat.*=.*/d' ${proc} && continue
	fi
	#./runAll.sh $time $e
	sed -i '/stat.*=.*/d' ${proc}
done

#delete stats
sed -i '/stat.*=.*/d' l2fwd_testpmu.sh
