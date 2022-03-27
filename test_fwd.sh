#!/bin/bash
export PATH=$PATH:/home/n869p538/2021.7.1/bin64

[[ ! -d "./low_band_${1}_res" ]] && mkdir ./low_band_${1}_res
sudo rm -rf ./low_band_${1}_res/*

sudo vtune -collect memory-access -knob analyze-mem-objects=true  -result-dir ./low_band_${1}_res -quiet ./l2fwd_10_inst.sh

#csv results
sudo vtune  -report summary -result-dir ./low_band_${1}_res -format=csv -report-output ${1}MB_Summary.csv
#sudo ./build/l2fwd_touch -n12 -l1,21 -- -q1 -p 0x1
