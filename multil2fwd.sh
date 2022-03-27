#!/bin/bash
secondCore=$1+20
./build/l2fwd --file-prefix pg$1 -w 17:00.3 -l $1 -n12 -- -q1 -p0x1
