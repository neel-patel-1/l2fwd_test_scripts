#!/bin/bash


for i in `seq 1 10`
do
./l2fwd_inst.sh $i &
done
