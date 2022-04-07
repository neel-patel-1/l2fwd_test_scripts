#!/bin/bash


export PktgenHome="~/Pktgen-DPDK"
[ "$genIP" = "" ] && export genIP=192.168.1.1
startRemote(){
	#generate test script
	#ssh n869p538@castor.ittc.ku.edu $PktgenHome/genscript.sh $band
	#load test script into pktgen
	echo "f,e = loadfile('test${band}.lua'); f();" | socat - TCP4:${genIP}:22022
}
startRemote
