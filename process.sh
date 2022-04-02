#!/bin/bash

dir=${1}
events=${2}
source $events
rx_sizes="$(ls $dir | grep -Eo '(1024|64|2048)' |  sort -n )"
band="$(echo $dir | grep -Eo '[0-9]*MB' )"
[[ ! -d "./constr" ]] && mkdir constr
echo "bandwidth: $band"
for j in $rx_sizes; do
	i="$(echo ${dir})/$(ls $dir | grep -E "($j)")"
	cur_rx=$(echo $i | grep -Eo '(1024|64|2048)')
	echo -n "" >  constr/${band}_${cur_rx}.csv
	echo "processing $(echo $i | grep -Eo '(1024|64|2048)')"

	#l2 evictions
	NON_SILENT_L2_EVICTIONS=$(grep -e "l2_lines_out.non_silent" $i | awk -F, 'BEGIN {seen=0} $4 == "l2_lines_out.non_silent" { if (seen) sum += $2;seen=1;} END {print sum / (NR-1)} ' )
	SILENT_L2_EVICTIONS=$(grep -e "l2_lines_out.silent" $i | awk -F, 'BEGIN {seen=0} $4 == "l2_lines_out.silent" { if (seen) sum += $2;seen=1;} END {print sum / (NR-1)} ' )
	echo "average non_silent_l2_cache_evictions: $NON_SILENT_L2_EVICTIONS"
	echo "average silent_l2_cache_evictions: $SILENT_L2_EVICTIONS"

	echo "non_silent_l2_evict $NON_SILENT_L2_EVICTIONS" >> constr/${band}_${cur_rx}.csv
	echo "silent_l2_evict $SILENT_L2_EVICTIONS" >>  constr/${band}_${cur_rx}.csv


	#DRAMREAD && WRITE
	MEM_READ=$(grep -e "MEM_READ_TRAFFIC" $i | awk -F, 'BEGIN {seen=0;} {if(seen)sum += $2;seen=1;} END {print sum/(NR-1)} ' ) #skip first entry and divide by decremented num rows
	echo "average dram reads: $MEM_READ"
	MEM_WRITE=$(grep -e "MEM_WRITE_TRAFFIC" $i | awk -F, 'BEGIN{seen=0} NR>1 {if (seen) sum += $2;seen=1;} END {print sum/(NR-1)} ' )
	echo "average dram writes: $MEM_WRITE"

	#PCIe Hit Rate



	#llc hit rates
	LLC_REFERENCES=$(grep -e "LLC_REFERENCES" $i | awk -F, 'NR>1 {sum += $2;} END {print sum/(NR-1)} ' )
	LLC_MISSES=$(grep -e "LLC_MISSES" $i | awk -F, 'NR>1 {sum += $2;} END { print sum / (NR-1) }' )
	LLC_HIT_RATE=$(grep -e "LLC_MISSES" -e "LLC_REFERENCES" $i | awk -F, 'NR>2 && $4 == "LLC_REFERENCES" {refs += $2; nr+=1;} NR>2 && $4 == "LLC_MISSES" {misses += $2;} END { print ((refs - misses) / refs) }' )
	echo "LLC Hit rate: $LLC_HIT_RATE"


done
