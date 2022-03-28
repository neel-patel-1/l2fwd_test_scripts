#!/bin/bash

#start l2fwd_instances ++ collect pids

#change to proper rx_rings and recompile
rx_rings=${1}
bandwidth=${2}
devs=${3}
time=60
[[ ! "$rx_rings" = "" ]] && sed -i "s/#define RTE_TEST_RX_DESC_DEFAULT [0-9][0-9]*/#define RTE_TEST_RX_DESC_DEFAULT ${rx_rings}/" main.c
>&2 make


#check NMI watcdog
#enable memory accesses
nmi=$(sudo cat /proc/sys/kernel/nmi_watchdog)
para=$(sudo cat /proc/sys/kernel/perf_event_paranoid)
[[ ! "$nmi" = "0" ]] && sudo bash -c "echo 0 > /proc/sys/kernel/nmi_watchdog"
[[ ! "$para" = "0" ]] && sudo bash -c "echo 0 > /proc/sys/kernel/perf_event_paranoid"


#start background l2fwds
back=( "" )

core=1
for i in $devs
do
	>&2 ./l2fwd_inst.sh $core $i > pidf
	read -r pid < pidf
	back+=("$pid")
	core=$((core + 1))
done

#use last core for perf measurement
perf stat -o ${rx_rings}_ring_${bandwidth}_Mbits.csv -C 10,30 -e l2_lines_out.useless_hwpf,l2_lines_out.non_silent,imc/cas_count_read/,imc/cas_count_write/ -x, ./l2fwd_self_delete.sh 10 ${time}

#kill background l2fwds
for i in "${back[@]}"
do
	>&2 echo $i
	>&2 sudo kill -s 2 $i
done

for i in `seq 1 10`
do
	sudo rm -rf /var/run/dpdk/pg$i
done
