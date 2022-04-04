#!/bin/bash

[[ "$st_file" = "" ]] && st_file=curated.txt

declare -a es=( ) # for parsing out files later
[[ "$vals" = "" ]] && declare -a vals=( "L2_LINES_OUT.NON_SILENT" "L2_LINES_OUT.SILENT" "UNC_M_CAS_COUNT.RD" "UNC_M_CAS_COUNT.WR" "UNC_CHA_TOR_INSERTS.IA_HIT" "UNC_CHA_TOR_INSERTS.IA_MISS" "llc_misses.pcie_read" "llc_misses.pcie_write" "PFM_LLC_MISSES" "PFM_LLC_REFERENCES" ) # values we are interested in
[[ "$rx_size" = "" ]] && declare -a rx_size=( "64" "1024" "2048" )
[[ "$burst_size" = "" ]] && declare -a burst_size=( ".25" ".50" ".75" )
perf_files=recent

genRowBurst() {
	declare -a stats=()
	tr=()
	sr=()
	slr=()
	lr=()
	for e in "${vals[@]}"; do
		for r in "${rx_size[@]}"; do
			for j in "${burst_size[@]}"; do
				tr+=("$(echo $e | sed 's/_[0-9].*//g' )")
				sr+=("$(echo $r)")
				slr+=("$(echo $j)")
				bsz=$(python -c "print(int($j * $r))")
				lr+=("$(echo $(cat ${band}_${time}${extr}/${e}_${r}_${bsz}_${band}))")
			done
		done
	done
	echo -n "" > ${band}_${time}${extr}_row.csv
	echo "$( echo "${tr[*]}" | sed 's/ /,/g') " >> ${band}_${time}${extr}_row.csv
	echo "$( echo "${sr[*]}" | sed 's/ /,/g')" >> ${band}_${time}${extr}_row.csv
	echo "$( echo "${slr[*]}" | sed 's/ /,/g')" >> ${band}_${time}${extr}_row.csv
	echo "$( echo "${lr[*]}" | sed 's/ /,/g')" >> ${band}_${time}${extr}_row.csv
	mv -f ${band}_${time}${extr}_row.csv ${band}_${time}${extr}
	echo "rows in ${band}_${time}${extr}/${band}_${time}${extr}_row.csv"
	[[ -d "$resdir" ]] && cp ${band}_${time}${extr}/${band}_${time}${extr}_row.csv $resdir
}

genAvgs () {
	rm -rf constr/*
	echo "writing events to constr"
	while IFS= read -r stat; do
		prepend=$(echo $stat | awk -F, 'NF>1{print $NF} NF==1{print $1}' | grep -Eo '([a-z0-9_A-Z\.]*)' | tail -n 1)
		echo $prepend
		es+=("$prepend")
		for file in $(ls $perf_files); do
			grFile="$perf_files/$file"
			append=$(echo $file | grep -Eo '([0-9_\.]*)|(idle)' | head -n 1)
			avg=$(grep --ignore-case $prepend $grFile | awk -F, 'BEGIN{ctr=0; sum=0;} {unit=$3; if(ctr>0)sum+=$2;ctr+=1} END{printf("%s%s\n", sum/ctr, unit)}')
			echo "$avg" > constr/${prepend}_${append}
			
		done
	done < $st_file
	if [[ "$band" = "" ]] && [[ "$time" = "" ]] && [[ "$(ls $perf_files | awk -F_ '{print NF}' )" > 1 ]]; then
		band=$( ls recent | awk -F_ '{print $2}' | head -n 1)
		time=120
	elif [[ "$band" = "" ]] && [[ "$time" = "" ]]; then
		band="idle"
		time=120
	fi
	[[ ! -d "${band}_${time}$extr" ]] && mkdir ${band}_${time}$extr
	echo "moving results to ${band}_${time}$extr"
	mv -f recent/* ${band}_${time}$extr #save perf stat files
	mv -f constr/* ${band}_${time}$extr #save individual stat files
}

genRow() {
	declare -a stats=()
	tr=()
	sr=()
	lr=()
	for e in "${vals[@]}"; do
		for r in "${rx_size[@]}"; do
			tr+=("$(echo $e | sed 's/_[0-9].*//g' )")
			sr+=("$(echo $r)")
			lr+=("$(echo $(cat ${band}_${time}${extr}/${e}_${r}_${band}))")
		done
	done
	echo -n "" > ${band}_${time}${extr}_row.csv
	echo "$( echo "${tr[*]}" | sed 's/ /,/g') " >> ${band}_${time}${extr}_row.csv
	echo "$( echo "${sr[*]}" | sed 's/ /,/g')" >> ${band}_${time}${extr}_row.csv
	echo "$( echo "${lr[*]}" | sed 's/ /,/g')" >> ${band}_${time}${extr}_row.csv
	mv -f ${band}_${time}${extr}_row.csv ${band}_${time}${extr}
	echo "rows in ${band}_${time}${extr}/${band}_${time}${extr}_row.csv"
	[[ -d "$resdir" ]] && cp ${band}_${time}${extr}/${band}_${time}${extr}_row.csv $resdir
}

