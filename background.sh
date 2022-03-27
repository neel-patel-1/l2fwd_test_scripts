#!/bin/bash
sudo /home/n869p538/dpdk-stable-20.11.3/examples/l2fwd_touch/build/l2fwd_touch --file-prefix pg$1 -w $2 -l $1 -n12 -- -q1 -p0x1 &
