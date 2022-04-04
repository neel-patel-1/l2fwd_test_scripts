#!/bin/bash
#L2FWD

export st_file=curated.txt
export time=120
export proc=l2fwd_single_target.sh
export burst_proc=l2fwd_bursty.sh

declare -a vals=( "L2_LINES_OUT.NON_SILENT" "L2_LINES_OUT.SILENT" "UNC_M_CAS_COUNT.RD" "UNC_M_CAS_COUNT.WR" "UNC_CHA_TOR_INSERTS.IA_HIT" "UNC_CHA_TOR_INSERTS.IA_MISS" "llc_misses.pcie_read" "llc_misses.pcie_write" "PFM_LLC_MISSES" "PFM_LLC_REFERENCES" ) # values we are interested in
declare -a rx_size=( "64" "1024" "2048" )
declare -a burst_size=( ".25" ".5" ".75" )
declare -a b=( "8" "1000" "20000" )
#declare -a b=( "100000" )
#declare -a b=( "20000" "1000" "8" )

source process_recent.sh
source runAll.sh
source getArgs.sh

#verify extra field
[[ $extr != "" ]] && echo "$extr test"

#check for burst
[[ $doburst -eq 1 ]] && echo "evaluating burst" && export proc=${burst_proc}

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
		if [[ $doburst -eq 1 ]]; then
			echo "do burst"
			#runAllBurst
			genAvgs
			genRowBurst
		else
			runAll
			genAvgs
			genRow
		fi
	fi

	sed -i -E '/stats\+?=.*/d' ${proc} #delete events
done

#delete stats
sed -i '/stat.*=.*/d' ${proc}
