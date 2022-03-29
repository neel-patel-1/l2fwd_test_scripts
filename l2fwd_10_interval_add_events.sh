#!/bin/bash


rx_rings=${1}
bandwidth=${2}
time=${3}
#stats="-e 'l2_lines_out.useless_hwpf,l2_lines_out.non_silent,imc/cas_count_read/,imc/cas_count_write/' "
stats="-e 'cpu/event=0x35,umask=0x11,name=IO_HIT/u' " #PCIe write hits
stats+="-e 'cpu/event=0x35,umask=0x21,name=IO_MISS/u' " #misses
stats+="-e 'uncore_cha/event=0x36,umask=0x11,name=OCCUPANCY_IO_HIT/' " #hits
stats+="-e 'uncore_cha/event=0x36,umask=0x21,name=OCCUPANCY_IO_MISS/' " #misses
stats+="-e 'cpu/event=0x50,umask=0x01,name=CHA_READ_REQUESTS/u' " #cha requests
stats+="-e 'cpu/event=0x50,umask=0x04,name=CHA_WRITE_REQUESTS/u' " #misses
stats+="-e 'cpu/event=0x50,umask=0x10,name=CHA_INVITOE_REQUESTS/u' " #misses
stats+="-e 'cpu/config=0x53412e,name=LLC_MISSES/' " #LLC Misses

#check hugepages
[ $(( $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages) - $(cat /proc/meminfo | grep HugePages_Free | awk '{print $2}') )) -lt 100 ] && echo "less than 100 hugepages remaining... adding 100" && sudo bash -c "echo $(($(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages) + 100)) > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"

# get sriov devices
devs=$(sudo ibdev2netdev -v | grep -E 'mlx5_(([2-9])|([0-9][0-9]))' | awk '{print $1}')
back_devs=$(echo $devs | awk '{NF--; print}')
test_dev=$(echo $devs | awk 'NF>1{print $NF}')

if [[ "$devs" = "" ]];
then
	echo "finding devs"
	devs=$(lspci -D | grep Mellanox | awk '{print $1}' | grep -vE "(17.00.1|17.00.0)")
	echo "$devs"
fi

#change to proper rx_rings and recompile
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
for i in $back_devs
do
	>&2 ./l2fwd_inst.sh $core $i > pidf
	read -r pid < pidf
	back+=("$pid")
	core=$((core + 1))
done

#sleep (let background instances run for 5 seconds before measuring)
sleep 5

#use last core for perf measurement
perf stat -o add_events_${rx_rings}_ring_${bandwidth}_Mbits_$(date '+%F_%T').csv -I $(($time / 10 * 1000)) -C $core,$(($core + 20)) ${stats} -x, ./l2fwd_self_delete.sh $core ${time} ${test_dev} 

#kill background l2fwds
for i in "${back[@]}"
do
	>&2 echo $i
	>&2 sudo kill -s 2 $i
done

#in case l2fwd instances are still alive
ps aux | grep '\./build/l2fwd' | awk '{print $2}' | xargs sudo kill -s 2

#remove shared config dirs
for i in `seq 1 10`
do
	sudo rm -rf /var/run/dpdk/pg$i
done

