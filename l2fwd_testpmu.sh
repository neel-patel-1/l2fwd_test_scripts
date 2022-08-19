#!/bin/bash


rx_rings=${1}
bandwidth=${2}
time=${3}
dev_name=ens4f1
num_backs=1

[[ ! -d "./recent" ]] && mkdir recent

#STATS


#check hugepages
[ $(( $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages) - $(cat /proc/meminfo | grep HugePages_Free | awk '{print $2}') )) -lt 100 ] && echo "less than 100 hugepages remaining... adding 100" && sudo bash -c "echo $(($(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages) + 100)) > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages"

# get sriov devices
devs=( $( sudo ibdev2netdev -v | grep $dev_name | grep -E "$dev_name[a-z0-9]+" | grep -Eo '[0-9]+:[0-9]+:[0-9]+\.[0-9]+' ) )
back_devs=( ${devs[*]} )
while [ "${#back_devs[@]}" -gt $num_backs ]; do
	unset 'back_devs[${#back_devs[@]}-1]'
done
# take dev after last back_dev
test_dev=${devs[${#back_devs[@]}]}
echo -e "devs:${devs[*]} \n background: ${back_devs[*]} \n test: ${test_dev}"

if [[ "$devs" = "" ]];
then
	echo "Error no devs found"
	exit
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

core=11

for i in "${back_devs[@]}"
do
	echo ">&2 ./l2fwd_inst.sh $core $i > pidf"
	>&2 ./l2fwd_inst.sh $core $i > pidf
	read -r pid < pidf
	back+=("$pid")
	core=$((core + 1))
done

#sleep (let background instances run for 5 seconds before measuring)
sleep 5

#use last core for perf measurement
echo "sriov under test: $test_dev" >> $the_log
./pmu-tools/ocperf.py stat -o recent/${rx_rings}_${bandwidth} -I $(($time / 10 * 1000)) -C $core,$(($core + 20)) ${stats} -x, ./l2fwd_self_delete.sh $core ${time} ${test_dev} 

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


