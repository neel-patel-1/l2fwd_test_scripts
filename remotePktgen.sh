#!/bin/bash


export PktgenHome="/home/n869p538/Pktgen-DPDK"
[ "$genIP" = "" ] && export genIP=192.168.1.1
[ ! -z "$1" ] && export band=$1
startRemote(){
	#generate test script
	echo "passing scripts to remote pktgen"
	ssh n869p538@axdimm.ittc.ku.edu "cd $PktgenHome && ./genscript.sh $band"
	#load test script into pktgen
	for i in `seq 1 5`; do
		echo "f,e = loadfile('test${band}.lua'); f();" | socat - TCP4:${genIP}:22022
	done
}
startRemote
