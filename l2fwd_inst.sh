#!/bin/bash

[[ -d "/var/run/dpdk/pg$lCore" ]] && sudo rm -rf /var/run/dpdk/pg$lCore

time=5

#create l2fwd inst
#ps aux | grep perf | awk '{print $2}' | xargs sudo kill -KILL
lCore=${1}
hCore=$(( $lCore + 20 ))

sudo ./build/l2fwd_touch --file-prefix pg$lCore -n12 -l$lCore,$hCore -- -q1 -p 0x1 &
echo $!

sudo kill -s 2 $pid 
#rm shared page dir
sudo rm -rf /var/run/dpdk/pg$lCore
