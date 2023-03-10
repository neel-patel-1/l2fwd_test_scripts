#!/bin/bash


rx_rings=${1}
bandwidth=${2}
time=${3}

[[ ! -d "./recent" ]] && mkdir recent

#STATS
stats=""
stats+="-e 'cpu/config=0x534f2e,name=PFM_LLC_REFERENCES/' " 
stats+="-e 'cpu/config=0x53412e,name=PFM_LLC_MISSES/' " 
stats+="-e llc_misses.pcie_write " 
stats+="-e llc_misses.pcie_read " 
stats+="-e UNC_CHA_TOR_INSERTS.IA_MISS " 
stats+="-e UNC_CHA_TOR_INSERTS.IA_HIT " 
stats+="-e UNC_M_CAS_COUNT.RD " 
stats+="-e UNC_M_CAS_COUNT.WR " 
stats+="-e L2_LINES_OUT.SILENT " 
stats+="-e L2_LINES_OUT.NON_SILENT " 


#check hugepages
[  $(cat /proc/meminfo | grep HugePages_Free | awk '{print $2}') -lt 100 ] && echo "less than 100 hugepages remaining... adding 100" && sudo bash -c "echo $(($(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages) + 100)) > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"

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


#sleep (let background instances run for 5 seconds before measuring)
sleep 5

#use last core for perf measurement
core=1
./pmu-tools/ocperf.py stat -o recent/${rx_rings}_${bandwidth} -I $(($time / 10 * 1000)) -C $core,$(($core + 20)) ${stats} -x, ./l2fwd_self_delete.sh $core ${time} ${test_dev} 


#in case l2fwd instances are still alive
ps aux | grep '\./build/l2fwd' | awk '{print $2}' | xargs sudo kill -s 2

#remove shared config dirs
for i in `seq 1 10`
do
	sudo rm -rf /var/run/dpdk/pg$i
done



