#!/bin/bash
source ../../../scripts/env.sh
for s in 1 7 42; do
  ./simv +ntb_random_seed=$s +vcs+initreg+0 +NCYCLES=100000 -l sim_$s.log > /dev/null 2>&1
  echo "seed $s: $(grep -E 'checks=|errors=' sim_$s.log | tail -1)"
done
echo "SEEDS DONE"
