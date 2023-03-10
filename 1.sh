#!/bin/bash
#L2FWD

export st_file=curated.txt
export time=10
export proc=l2fwd_testpmu.sh
export genIP="192.168.1.1"

export defproc=l2fwd_testpmu.sh
export burst_proc=l2fwd_bursty.sh
export sweep_proc=l2fwd_rdt_set.sh

declare -a vals=( "L2_LINES_OUT.NON_SILENT" "L2_LINES_OUT.SILENT" "UNC_M_CAS_COUNT.RD" "UNC_M_CAS_COUNT.WR"  ) # values we are interested in
declare -a rx_size=( "64" "1024" "2048" "4096" )
#declare -a rx_size=( "64"  )
declare -a rdt_masks=(  "0x80"  )
#declare -a rdt_masks=( "0x400" "0x200" "0x100" "0x80" "0x40" "0x20" "0x10" "0x8" "0x4" "0x2" "0x1" )
declare -a burst_size=( ".25" ".5" ".75" )
#declare -a b=( "1" "8" "25" "50" "100" "1000"  "5000" "10000" "20000" )
declare -a b=( "50000" )
#declare -a b=( "1000" )

source process_recent.sh
source runAll.sh
echo "getting args"
source getArgs.sh

#verify extra field
[[ $extr != "" ]] && echo "$extr test"

#check for burst
[[ $doburst -eq 1 ]] && echo "evaluating burst" && export proc=${burst_proc}

#check for sweep
[[ $dosweep -eq 1 ]] && echo "evaluating sweep" && export proc=${sweep_proc}

#check for default
[[ $dodefault -eq 1 ]] && echo "evaluating default" && export proc=${defproc}

#clear out recent results 
#rm -rf recent/*

#run l2fwd_test with specified stats to measure
for e in "${b[@]}"; do

	#change band
	export band=$e	
	#configure remote pktgen
	#./remotePktgen.sh

	sed -i -E '/stats\+?=.*/d' ${proc} #delete events

	#ins events
	while IFS= read -r stat; do
		sed -i "/#STATS/a stats+=\"-e $stat \" " ${proc}
	done < $st_file
	sed -i "/#STATS/a stats=\"\"" ${proc}
	sed -n '/#STATS/,$p' ${proc}| sed '/#check hugepages/q' # print events


	#give user chance to cancel tests
	for (( i=3; i>0; i--)); do
	printf "\rStarting $e Mbit/s test in $i seconds.  Hit any key to continue."
	read -s -n 1 -t 1 key
	if [ $? -eq 0 ]
	then
		echo ""
		break
	fi
	done


	if [[ $doburst -eq 1 ]]; then
		runAllBurst
		genAvgs
		genRowBurst
	elif [[ $dosweep -eq 1 ]]; then
		echo "starting rdt tests"
		runAllRDT
		genAvgs
		genRowSweep
	else
		runAll
		genAvgs
		genRow
	fi

	sed -i -E '/stats\+?=.*/d' ${proc} #delete events
done

#delete stats
sed -i '/stats\+?=.*/d' ${proc}
