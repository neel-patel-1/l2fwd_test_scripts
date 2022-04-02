#!/bin/bash

time=${1}
core=10

[[ ! -d "./recent" ]] && mkdir recent

#STATS
stats=""
stats+="-e UNC_I_COHERENT_OPS.RFO " 
stats+="-e UNC_I_COHERENT_OPS.PCITOM " 
stats+="-e UNC_I_CACHE_TOTAL_OCCUPANCY.MEM " 
stats+="-e UNC_IIO_COMP_BUF_OCCUPANCY.CMPD.ALL_PARTS " 
stats+="-e UNC_IIO_COMP_BUF_INSERTS.CMPD.ALL_PARTS " 
stats+="-e L2_LINES_OUT.SILENT " 
stats+="-e L2_LINES_OUT.NON_SILENT " 
stats+="-e L2_RQSTS.RFO_MISS " 
stats+="-e L2_RQSTS.RFO_HIT " 
stats+="-e L2_RQSTS.DEMAND_DATA_RD_MISS " 
stats+="-e L2_RQSTS.DEMAND_DATA_RD_HIT " 
stats+="-e 'cpu/config=0x534f2e,name=LLC_REFERENCES/' " 
stats+="-e 'cpu/config=0x53412e,name=LLC_MISSES/' " 
stats+="-e UNC_M_CAS_COUNT.RD " 
stats+="-e UNC_M_CAS_COUNT.WR " 
stats+="-e UNC_CHA_REQUESTS.WRITES_LOCAL " 
stats+="-e UNC_CHA_REQUESTS.READS_LOCAL " 
stats+="-e UNC_CHA_REQUESTS.INVITOE_LOCAL " 
stats+="-e UNC_CHA_TOR_OCCUPANCY.IA_MISS " 
stats+="-e UNC_CHA_TOR_OCCUPANCY.IA_HIT " 
stats+="-e UNC_CHA_TOR_INSERTS.IA_MISS " 
stats+="-e UNC_CHA_TOR_INSERTS.IA_HIT " 


#use last core for perf measurement
./pmu-tools/ocperf.py stat -o recent/idle   -I $(($time / 10 * 1000)) -C $core,$(($core + 20)) ${stats} -x, sleep $time
