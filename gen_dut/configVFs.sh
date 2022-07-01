#!/bin/bash
#sudo mst start


numvfsdut=$(sudo cat /sys/class/net/ens4f0/device/sriov_numvfs)
numvfsgen=$(sudo cat /sys/class/net/ens4f1/device/sriov_numvfs)

#[[ ! "$numvfsdut" = "10" ]] && echo 10 | sudo tee /sys/class/net/ens4f0/device/sriov_numvfs 
#[[ ! "$numvfsgen" = "10" ]] && echo 10 | sudo tee /sys/class/net/ens4f1/device/sriov_numvfs 


netdevs=$(sudo ibdev2netdev -v | grep -E 'mlx5_(([2-9])|([0-9][0-9]))' | awk '{print $12}')
devs=$(sudo ibdev2netdev -v | grep -E 'mlx5_(([2-9])|([0-9][0-9]))' | awk '{print $1}')
echo $netdevs
echo ""
echo $devs 

if [[ "$devs" = "" ]]; then
	echo "finding devs"
	devs=$(lspci -D | grep Mellanox | awk '{print $1}' | grep -vE "(17.00.1|17.00.0)")
	echo "$devs"
fi

for i in $devs; do
	echo "unbinding $i"
	echo $i | sudo tee /sys/bus/pci/drivers/mlx5_core/unbind
done

for i in $netdevs; do
	if [ -z "$(echo $i | grep -Eo 'f1')" ]; then
		mac=00:66:55:44:33:"${i: -1}""${i: -1}"
		echo "assigning $mac mac to $i" 
		sudo ip link set ens4f0 vf "${i: -1}" mac $mac
	else
		mac=00:77:55:44:33:"${i: -1}""${i: -1}"
		echo "assigning $mac mac to $i" 
		sudo ip link set ens4f1 vf "${i: -1}" mac $mac
	fi
done

for i in $devs; do
	echo "rebinding $i"
	echo $i | sudo tee /sys/bus/pci/drivers/mlx5_core/bind
done

