#!/bin/bash
#L2FWD

export st_file=curated.txt
export time=120
export proc=l2fwd_rdt_set.sh

declare -a vals=( "L2_LINES_OUT.NON_SILENT" "L2_LINES_OUT.SILENT" "UNC_M_CAS_COUNT.RD" "UNC_M_CAS_COUNT.WR" "llc_misses.pcie_read" "llc_misses.pcie_write" "PFM_LLC_MISSES" "PFM_LLC_REFERENCES" ) # values we are interested in
declare -a rx_size=( "64" "1024" "2048" )
declare -a b=( "8" "20000" "1000")

source process_recent.sh
source runAll.sh
source getArgs.sh

#clear out recent results 
#rm -rf recent/*

#run l2fwd_test with specified stats to measure
for e in "${b[@]}"; do

	#change band
	export band=$e	

	sed -i -E '/stats\+?=.*/d' ${proc} #delete events
	#ins events
	while IFS= read -r stat; do
		sed -i "/#STATS/a stats+=\"-e $stat \" " ${proc}
	done < $st_file
	sed -i "/#STATS/a stats=\"\"" ${proc}
	sed -n '/#STATS/,$p' ${proc}| sed '/#check hugepages/q' # print events

	read -p "$e Mbit/s generator started? (Y/N): " confirm 
	if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
		#runAll
		#genAvgs
		genRow
	fi

	sed -E '/stats\+?=.*/d' ${proc} #delete events
done

#delete stats
sed -i '/stat.*=.*/d' ${proc}
