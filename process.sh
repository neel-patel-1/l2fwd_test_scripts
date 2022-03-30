#!/bin/bash

dir=${1}
for i in $dir/*; do
	echo "processing $i"

	#l2 evictions
	NON_SILENT_L2_EVICTIONS=$(grep -e "l2_lines_out.non_silent" $i | \
	awk -F, 'NR>1 && $4 == "l2_lines_out.non_silent" {sum += $2;} END {print sum / NR} ' )
	SILENT_L2_EVICTIONS=$(grep -e "l2_lines_out.silent" $i | \
	awk -F, 'NR>1 && $4 == "l2_lines_out.silent" {sum += $2;} END {print sum / NR} ' )
	BOTH_L2_EVICTIONS=$(grep -e "l2_lines_out.silent" -e "l2_lines_out.non_silent" $i | \
	awk -F, 'NR>2 && $4 == "l2_lines_out.non_silent" {non_silent += $2;} NR>2 && $4 == "l2_lines_out.silent" {silent += $2;} END {print (non_silent + silent)} ' )
	echo "average non_silent_l2_cache_evictions: $NON_SILENT_L2_EVICTIONS"
	echo "average silent_l2_cache_evictions: $SILENT_L2_EVICTIONS"
	#echo "Both l2_cache_evictions: $BOTH_L2_EVICTIONS"


	#llc hit rates
	LLC_REFERENCES=$(grep -e "LLC_REFERENCES" $i | awk -F, 'NR>1 {sum += $2;} END {print sum/(NR-1)} ' )
	LLC_MISSES=$(grep -e "LLC_MISSES" $i | awk -F, 'NR>1 {sum += $2;} END { print sum / (NR-1) }' )
	LLC_HIT_RATE=$(grep -e "LLC_MISSES" -e "LLC_REFERENCES" $i | awk -F, 'NR>2 && $4 == "LLC_REFERENCES" {refs += $2; nr+=1;} NR>2 && $4 == "LLC_MISSES" {misses += $2;} END { print ((refs - misses) / refs) }' )
	echo "LLC Hit rate: $LLC_HIT_RATE"

	MEM_READ=$(grep -e "MEM_READ_TRAFFIC" $i | awk -F, 'NR>1 {sum += $2;} END {print sum/NR} ' )
	MEM_WRITE=$(grep -e "MEM_WRITE_TRAFFIC" $i | awk -F, 'NR>1 {sum += $2;} END {print sum/NR} ' )

	#grep -e "LLC_MISSES" $i | \
	#awk -F, 'NR>1 {print $2; sum += $2;} END {print sum / NR} ' 


done
