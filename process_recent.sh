#!/bin/bash

[[ $st_file = "" ]] && st_file=currated.txt

declare -a es=( ) # for parsing out files later

genAvgs () {
	rm -rf constr/*
	while IFS= read -r stat; do
		prepend=$(echo $stat | awk -F, 'NF>1{print $NF} NF==1{print $1}' | grep -Eo '([a-z0-9_A-Z\.]*)' | tail -n 1)
		echo $prepend
		es+=("$prepend")
		echo "writing events to constr"
		for file in $(ls recent); do
			grFile="recent/$file"
			append=$(echo $file | grep -Eo '([0-9_\.]*)|(idle)' | head -n 1)
			avg=$(grep --ignore-case $prepend $grFile | awk -F, 'BEGIN{ctr=0; sum=0;} {unit=$3; if(ctr>0)sum+=$2;ctr+=1} END{printf("%s %s\n", sum/ctr, unit)}')
			echo "$avg" > constr/${prepend}_${append}
			
		done
	done < $st_file
}

genRow() {
declare -a stats=()
for e in "${es[@]}"; do
	#echo $e
	fs=$(ls -1 constr | grep $e | sort -n | sed -e 's/^/constr\//g' -e 's/^/\"/g' -e 's/$/\"/g')
	#echo $fs
	res=$( echo $fs | xargs cat | sed -e 's/^/\"/g' -e 's/$/\"/g' )
	#echo $res
	stats+=( $(echo $fs |  sed -e 's/constr\///g' ) )
	figs+=( $res )
	#echo $res
done
	[[ ! -d "./results" ]] && mkdir results
	if [[ "$(ls recent | awk -F_ '{print NF}' )" > 1 ]]; then
		band=$( ls recent | awk -F_ '{print $2}' | head -n 1)
	else
		band="idle"
	fi

	file=results/${band}_$(date '+%F_%T').txt
	echo "$(echo ${stats[*]} | sed 's/ /,/g')" > $file
	echo "$(echo ${figs[*]} | sed 's/ /,/g')" >> $file
}

genAvgs
exit
