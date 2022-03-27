#!/bin/bash

#start l2fwd_instances ++ collect pids
for i in `seq 5 5`
do
	./l2fwd_inst.sh $i  > pidf
	read -r pid < pidf
	sudo perf stat -e l2_lines_out.useless_hwpf,l2_lines_out.non_silent,unc_m_cas_count.rd_reg,unc_m_act_count.wr -p $pid sleep 10
	kill -s 2 $pid
done



