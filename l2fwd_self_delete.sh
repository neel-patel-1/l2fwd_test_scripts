#!/bin/bash

#create l2fwd inst
#ps aux | grep perf | awk '{print $2}' | xargs sudo kill -KILL
lCore=${1}
time=${2}
hCore=$(( $lCore + 20 ))
sudo rm -rf /var/run/dpdk/pg$lCore

>&2 sudo ./build/l2fwd_touch --file-prefix pg$lCore -n12 -l$lCore,$hCore -- -q1 -p 0x1 &

sleep ${time}

sudo kill -s 2 $!
