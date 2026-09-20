#!/usr/bin/env bash
# L2TLB UT 判别力负测：往 rtl/memblock/L2TLB.sv 里注入变异，要求 UT 转红。
#
# 规矩（CONVENTIONS「验证件自身的两个坑」）：
#   · 变异必须**改在原块之内**，不许新开一个 always 块——那样 VCS 不报错、
#     排在后面的块赢、变异根本没生效，跟了一整轮 errors=0 会被误读成"UT 漏检"。
#   · **编译失败判 FAIL，不判 CAUGHT。** 编不过说明这个变异根本没被测到，
#     把它算成"抓到了"是给自己发奖状（IBuffer M6 实测栽过）。
#   · MISSED 的那些要单独查「它到底改没改电路」，不能默认"UT 不行"。
#
# 跑法: bash verif/ut/L2TLB/mutants.sh [工作根目录]
#   工作根目录默认落在 scratchpad 里一个**带唯一后缀**的目录（共享 scratchpad
#   里禁止用语义名做破坏性操作的作用域，见 CONVENTIONS）。
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
WORK="${1:-${TMPDIR:-/tmp}/l2tlb-mutants-$$-$(date +%s)}"
NCYC="${NCYC:-20000}"
SEED="${SEED:-1}"

mkdir -p "$WORK/verif/ut"
cp -r "$REPO/scripts" "$WORK/scripts"
cp -r "$REPO/rtl"     "$WORK/rtl"
cp -r "$HERE"         "$WORK/verif/ut/L2TLB"
rm -rf "$WORK/verif/ut/L2TLB/simv"* "$WORK/verif/ut/L2TLB/csrc" \
       "$WORK/verif/ut/L2TLB/ut_gen" "$WORK/verif/ut/L2TLB"/*.log
SV="$WORK/rtl/memblock/L2TLB.sv"
cp "$SV" "$WORK/L2TLB.sv.pristine"

# 每个变异一行: 名字 | 原文 | 替换文
# 原文必须在文件里**唯一**出现，否则 apply 会拒绝（防"以为改了其实没改"）。
mutants=(
"M1_level_not_flattened|    s.entry.level = bm_final ? 2'h0 : es.level;|    s.entry.level = es.level;"
"M2_n_not_cleared|    s.entry.n     = bm_final ? 1'b0 : es.n;|    s.entry.n     = es.n;"
"M3_ppn_not_flattened|    s.entry.ppn   = bm_final ? sector_gen_ppn(es.ppn, es.tag, es.level, es.n) : es.ppn;|    s.entry.ppn   = es.ppn;"
"M4_validx_wrong_rule|      s.valididx[i] = bm_final ? (mr.not_super \& eq \& ~not_merge)|      s.valididx[i] = bm_final ? ((eq | ~mr.not_super) \& ~not_merge)"
"M5_gen_ppn_cut_off_by_one|      2'h2:    return {ppn[SECTOR_PTE_PPN_W-1:15], tag[14:0]};   // 1GB|      2'h2:    return {ppn[SECTOR_PTE_PPN_W-1:16], tag[15:0]};   // 1GB"
"M6_probe_index_swapped|    .index   (8'h0));|    .index   (8'h1));"
"M7_difftest_addr_r_gets_reset|  always_ff @(posedge clock)\n    if (d_valid) difftest_addr_r <= d_src;|  always_ff @(posedge clock or posedge reset)\n    if (reset) difftest_addr_r <= 4'h0;\n    else if (d_valid) difftest_addr_r <= d_src;"
"M8_probe_valid_port0_drops_ready|    .valid   (tlb0_resp_fire \& ~io_tlb_0_resp_bits_s1_af \& ~io_tlb_0_resp_bits_s2_gaf),|    .valid   (io_tlb_0_resp_valid \& ~io_tlb_0_resp_bits_s1_af \& ~io_tlb_0_resp_bits_s2_gaf),"
"M9_bm_final_ignores_bitmap_enable|  wire       bm_final_0  = bitmap_enable \& marb0_nos2;|  wire       bm_final_0  = marb0_nos2;"
)

printf '%-38s %-8s %s\n' "MUTANT" "VERDICT" "DETAIL"
rc_all=0
for m in "${mutants[@]}"; do
  name="${m%%|*}"; rest="${m#*|}"; old="${rest%%|*}"; new="${rest#*|}"
  cp "$WORK/L2TLB.sv.pristine" "$SV"
  # 唯一性 + 应用（用 python 做定点替换，避免 sed 的转义地狱）
  if ! MUT_OLD="$old" MUT_NEW="$new" python3 - "$SV" <<'PY'
import os, sys
p = sys.argv[1]
old = os.environ["MUT_OLD"].replace("\\n", "\n").replace("\\&", "&")
new = os.environ["MUT_NEW"].replace("\\n", "\n").replace("\\&", "&")
t = open(p).read()
n = t.count(old)
if n != 1:
    sys.stderr.write(f"anchor count={n} (need exactly 1)\n"); sys.exit(2)
open(p, "w").write(t.replace(old, new, 1))
PY
  then printf '%-38s %-8s %s\n' "$name" "FAIL" "锚点不唯一/未命中，变异没应用"; rc_all=1; continue; fi

  # ★先自证改了电路★：文本必须真的变了
  if cmp -s "$SV" "$WORK/L2TLB.sv.pristine"; then
    printf '%-38s %-8s %s\n' "$name" "FAIL" "替换后文件与原文一致 = 没改电路"; rc_all=1; continue; fi

  ( cd "$WORK/verif/ut/L2TLB" && rm -f sim_$SEED.log && make compile ) > "$WORK/$name.compile.log" 2>&1
  if [[ $? -ne 0 ]]; then
    printf '%-38s %-8s %s\n' "$name" "FAIL" "编译失败（编不过 ≠ 抓到）"; rc_all=1; continue; fi
  ( cd "$WORK/verif/ut/L2TLB" && ./simv +ntb_random_seed=$SEED +ncycles=$NCYC \
       +vcs+initreg+0 -l sim_$SEED.log ) > /dev/null 2>&1
  line="$(grep -E '^checks=' "$WORK/verif/ut/L2TLB/sim_$SEED.log" | tail -1)"
  errs="$(sed -E 's/.*errors=([0-9]+).*/\1/' <<<"$line")"
  if [[ "${errs:-0}" -gt 0 ]]; then
    printf '%-38s %-8s %s\n' "$name" "CAUGHT" "errors=$errs"
  else
    printf '%-38s %-8s %s\n' "$name" "MISSED" "$line"; rc_all=1
  fi
done
cp "$WORK/L2TLB.sv.pristine" "$SV"
echo "work=$WORK"
exit $rc_all
