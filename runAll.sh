#!/bin/bash

bandwidth=${1}
declare -a rx_size=( "64" "256" "1024" "2048" )
for i in "${rx_size[@]}"
do
	./l2fwd_10_inst.sh $i $bandwidth
done
