#!/bin/bash
time=${1}

bandwidth=${2}

declare -a rx_size=( "64" "1024" "2048" )
#declare -a rx_size=(  "2048" )

for i in "${rx_size[@]}"
do
	#./l2fwd_10_interval_inst.sh $i $bandwidth ${time}
	./l2fwd_testpmu.sh $i $bandwidth ${time}
done
mv *.csv recent
