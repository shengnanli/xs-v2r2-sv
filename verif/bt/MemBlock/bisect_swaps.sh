#!/bin/bash
source ../../../scripts/env.sh
CY=5000
report=bisect_report.txt
: > $report
for M in DCacheWrapper Uncache L2TLBWrapper Sbuffer TLBNonBlock PMP PMPChecker_10; do
  echo "######## SWAP=$M ########" | tee -a $report
  python3 gen_memblock_bt.py $M >/dev/null 2>&1
  make compile > make_$M.out 2>&1
  cexit=$?
  if [ $cexit -ne 0 ]; then echo "  COMPILE FAILED ($cexit)" | tee -a $report; tail -5 make_$M.out | tee -a $report; continue; fi
  ./simv +ntb_random_seed=1 +NCYCLES=$CY -l sim_swap_$M.log > /dev/null 2>&1
  res=$(grep -E "checks=|errors=" sim_swap_$M.log | tail -1)
  echo "  $res" | tee -a $report
  echo "  distinct diverging ports:" | tee -a $report
  grep -oE "\] [a-zA-Z0-9_]+ g=" sim_swap_$M.log | sed -E 's/\] (.*) g=/    \1/' | sort -u | tee -a $report
done
echo "ALL DONE" | tee -a $report
