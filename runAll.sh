#!/bin/bash
#declare -a rx_size=(  "2048" )

runAll(){
	for i in "${rx_size[@]}"
	do
		#./l2fwd_10_interval_inst.sh $i $bandwidth ${time}
		2>/dev/null ./${proc} $i $band ${time}
	done
}
