#!/usr/bin/env bash
# mutants.sh —— Sbuffer UT 判别力负测。
#
# 规矩（CONVENTIONS「验证件自身的两个坑」）：
#   1. 每个变异先自证**改变了电路文本**（sed 必须真的替换到，否则判 BAD_MUTANT）；
#   2. 编译失败一律判 FAIL，不许拿上一轮的 sim 日志当本轮结果（每次先删日志）；
#   3. CAUGHT 不是二值——逐个报 errors 数；
#   4. 逻辑等价的空变异要**剔除并注明理由**，不许混在 CAUGHT 里充数。
#
# 用法: bash mutants.sh [seed] [ncycles]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../../../rtl/memblock/Sbuffer.sv"
SEED="${1:-1}"
NCY="${2:-30000}"
BAK="$HERE/.mutants.orig.sv"

cp "$SRC" "$BAK"
restore() { cp "$BAK" "$SRC"; }
trap restore EXIT

declare -A DESC
declare -A OLD
declare -A NEW

DESC[M1]="PLRU 逐层下标位置参数 nsub 从 1 改成 0（quad 层选边位压到子下标上）"
OLD[M1]='pair_v[2*k+1], pair_i[2*k+1], plru_state[QUAD_S[k]], 1);'
NEW[M1]='pair_v[2*k+1], pair_i[2*k+1], plru_state[QUAD_S[k]], 0);'

DESC[M2]="coh 超时比较 >= 改成 >（G1 新增的 CSR 门限边界）"
OLD[M2]='cohTimeOutMask[i] = ({1'"'"'b0, cohCount[i]} >= io_csrCtrl_sbuffer_timeout)'
NEW[M2]='cohTimeOutMask[i] = ({1'"'"'b0, cohCount[i]} >  io_csrCtrl_sbuffer_timeout)'

DESC[M3]="prio_enc16_deflast 的「全 0 默认末项 15」改成默认 0"
OLD[M3]='    prio_enc16_deflast = 4'"'"'hF;'
NEW[M3]='    prio_enc16_deflast = 4'"'"'h0;'

DESC[M4]="cohCount 的优先级翻转：merge/alloc 清 0 抢在 +1 之前"
OLD[M4]='          if (st_is_active(stateVec[ge]) & ~cohTimeOutMask[ge])
            cohCount[ge] <= cohCount[ge] + 1'"'"'b1;
          else if (sel_merge0 | sel_merge1 | sel_ins0 | sel_ins1)
            cohCount[ge] <= '"'"'0;'
NEW[M4]='          if (sel_merge0 | sel_merge1 | sel_ins0 | sel_ins1)
            cohCount[ge] <= '"'"'0;
          else if (st_is_active(stateVec[ge]) & ~cohTimeOutMask[ge])
            cohCount[ge] <= cohCount[ge] + 1'"'"'b1;'

DESC[M5]="forwardData 被 forwardMask 门控为 0（"'"'"看起来更合理"'"'"、实际 golden 不这么做）"
OLD[M5]='          fwd_o_data[gf][j] = selValidMask[j] ? selValidData[j] : selInflData[j];'
NEW[M5]='          fwd_o_data[gf][j] = fwd_o_mask[gf][j]
                            ? (selValidMask[j] ? selValidData[j] : selInflData[j]) : 8'"'"'h0;'

DESC[M6]="io_sbFull 用 ActiveCount==16 而不是 ValidCount==16"
OLD[M6]='      sbFull_q      <= sbufferFull;          // G1 新增输出 io_sbFull'
NEW[M6]='      sbFull_q      <= (ActiveCount == 5'"'"'(SB_SIZE));'

DESC[M7]="difftest bore 50/51 的 index 字段两路对调"
OLD[M7]='         8'"'"'(gs)};                               // index'
NEW[M7]='         8'"'"'(1-gs)};                             // index'

DESC[M8]="alloc 时 ptag/vtag 的覆盖优先级从 port1 改成 port0（sameTag 同拍双写）"
OLD[M8]='        if      (sel_ins1) begin ptag[ge] <= inptag[1]; vtag[ge] <= invtag[1]; end
        else if (sel_ins0) begin ptag[ge] <= inptag[0]; vtag[ge] <= invtag[0]; end'
NEW[M8]='        if      (sel_ins0) begin ptag[ge] <= inptag[0]; vtag[ge] <= invtag[0]; end
        else if (sel_ins1) begin ptag[ge] <= inptag[1]; vtag[ge] <= invtag[1]; end'

DESC[M9]="mask 清除的 wvec 只比 id 的低 4 位（漏掉 id>=16 时应全 0 的边界）"
OLD[M9]='      dm_flush_wvec[0][i] = (io_dcache_main_pipe_hit_resp_bits_id == 6'"'"'(i));'
NEW[M9]='      dm_flush_wvec[0][i] = (io_dcache_main_pipe_hit_resp_bits_id[3:0] == 4'"'"'(i));'

DESC[M10]="out_s1_valid 的两条更新语句互换（fire 清零与 s0 推进的覆盖次序）"
OLD[M10]='      if (sbuffer_out_s1_fire) sbuffer_out_s1_valid <= 1'"'"'b0;
      if (sbuffer_out_s0_cango) sbuffer_out_s1_valid <= sbuffer_out_s0_valid;'
NEW[M10]='      if (sbuffer_out_s0_cango) sbuffer_out_s1_valid <= sbuffer_out_s0_valid;
      if (sbuffer_out_s1_fire) sbuffer_out_s1_valid <= 1'"'"'b0;'

printf "%-5s %-9s %-12s %s\n" MUT VERDICT ERRORS 说明
for M in M1 M2 M3 M4 M5 M6 M7 M8 M9 M10; do
  restore
  python3 - "$SRC" "${OLD[$M]}" "${NEW[$M]}" <<'PY'
import sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
if s.count(old) != 1:
    print("BAD_MUTANT: 锚点出现 %d 次" % s.count(old)); sys.exit(9)
open(p, "w").write(s.replace(old, new))
PY
  if [ $? -ne 0 ]; then printf "%-5s %-9s %-12s %s\n" "$M" BAD_MUTANT - "${DESC[$M]}"; continue; fi
  if cmp -s "$SRC" "$BAK"; then
    printf "%-5s %-9s %-12s %s\n" "$M" NULL_EDIT - "${DESC[$M]}"; continue
  fi
  rm -f "$HERE/sim_$SEED.log" "$HERE/sim_${SEED}_initregrandom.log" "$HERE/mut_$M.log"
  if ! ( cd "$HERE" && make compile > "mut_${M}_compile.log" 2>&1 ); then
    printf "%-5s %-9s %-12s %s\n" "$M" COMPILE_FAIL - "${DESC[$M]}"; continue
  fi
  ( cd "$HERE" && ./simv +ntb_random_seed=$SEED +ncycles=$NCY +vcs+initreg+random -l "mut_$M.log" > /dev/null 2>&1 )
  E=$(grep -oE "errors=[0-9]+" "$HERE/mut_$M.log" | tail -1 | cut -d= -f2)
  if [ -z "$E" ]; then V=NO_RESULT; E="-";
  elif [ "$E" = "0" ]; then V=ESCAPED; else V=CAUGHT; fi
  printf "%-5s %-9s %-12s %s\n" "$M" "$V" "$E" "${DESC[$M]}"
done
restore
( cd "$HERE" && make compile > /dev/null 2>&1 )
echo "（已还原原文件并重编）"
