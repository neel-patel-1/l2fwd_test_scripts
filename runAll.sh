#!/bin/bash
#declare -a rx_size=(  "2048" )

ps aux | grep '/bin/bash \./l2fwd.*\.sh' | awk '{print $2}' | xargs sudo kill -s 2
ps aux | grep '\./build/l2fwd' | awk '{print $2}' | xargs sudo kill -s 2

runAll(){
	for i in "${rx_size[@]}"
	do
		#./l2fwd_10_interval_inst.sh $i $bandwidth ${time}
		2>/dev/null ./${proc} $i $band ${time}
	done
}

runAllBurst(){
	for i in "${rx_size[@]}"
	do
		for j in "${burst_size[@]}"
		do
			#./l2fwd_10_interval_inst.sh $i $bandwidth ${time}
			burstsz=$(python -c "print(int($i * $j))")
			2>/dev/null ./${proc} $i $band ${time} ${burstsz}
		done
	done


}

runAllRDT(){
	for i in "${rx_size[@]}"
	do
		for j in "${rdt_masks[@]}"
		do
			#./l2fwd_10_interval_inst.sh $i $bandwidth ${time}
			2>/dev/null ./${proc} $i $band ${time} ${j}
		done
	done


}
