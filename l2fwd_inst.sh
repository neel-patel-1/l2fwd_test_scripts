#!/bin/bash


lCore=${1}
hCore=$(( $lCore + 20 ))
./build/l2fwd_touch --file-prefix pg$lCore -n12 -l$lCore,$hCore -- -q1 -p 0x1 &
pid=$!
sleep 60
echo $pid
kill -s 2 $pid
#rm shared page dir
rm -rf /var/run/dpdk/pg$lCore
