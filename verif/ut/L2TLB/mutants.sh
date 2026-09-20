#!/usr/bin/env bash
# L2TLB UT 判别力负测：往 rtl/memblock/L2TLB.sv 里注入变异，要求 UT 转红。
#
# 记分口径（2026-09-20 裁定，五个桶互斥）：
#   CAUGHT   变异编译通过、跑出 errors>0  —— 计入分子与分母
#   MISSED   变异编译通过、跑出 errors=0  —— 只计入分母
#   INVALID  **编不过**                   —— 分子分母都不计（编不过 = 根本没被测到；
#            算成"抓到了"是给自己发奖状，算成"漏检"又冤枉了 UT）
#   NULL     自证**没有改变电路**（锚点不唯一 / 替换后文件没变）—— 分子分母都不计
#   INFRA    license / 磁盘 / 工具环境类失败 —— 单列，且**整体 rc 非零**
#
# 判别力 = CAUGHT / (CAUGHT + MISSED)；INVALID/NULL/INFRA 都不进这个分式，
# 但逐条打出来，谁都能核对"剔掉的是哪几个、为什么"。
#
# 其它规矩（CONVENTIONS「验证件自身的两个坑」）：
#   * 变异必须**改在原块之内**，不许新开一个 always 块——那样 VCS 不报错、
#     排在后面的块赢、变异根本没生效，跟了一整轮 errors=0 会被误读成"UT 漏检"。
#   * MISSED 的要单独查「它到底改没改电路 / 激励到不到得了」，不能默认"UT 不行"。
#
# 跑法: bash verif/ut/L2TLB/mutants.sh [工作根目录]
#   工作根目录默认落在 scratchpad 里一个**带唯一后缀**的目录（共享 scratchpad
#   里禁止用语义名做破坏性操作的作用域，见 CONVENTIONS）。
#   变量: NCYC(默认 20000) SEED(默认 1) INITREG(默认 0 —— 本 UT 的两档是 0/1
#         不是 0/random，理由见 Makefile 里 INITREG 那段)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
WORK="${1:-${TMPDIR:-/tmp}/l2tlb-mutants-$$-$(date +%s)}"
NCYC="${NCYC:-20000}"
SEED="${SEED:-1}"
INITREG="${INITREG:-0}"

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
n_caught=0; n_missed=0; n_invalid=0; n_null=0; n_infra=0
for m in "${mutants[@]}"; do
  name="${m%%|*}"; rest="${m#*|}"; old="${rest%%|*}"; new="${rest#*|}"
  cp "$WORK/L2TLB.sv.pristine" "$SV"
  # 唯一性 + 应用（用 python 做定点替换，避免 sed 的转义地狱）
  if ! MUT_OLD="$old" MUT_NEW="$new" python3 "$HERE/apply_mutant.py" "$SV"; then
    printf '%-38s %-8s %s\n' "$name" "NULL" "锚点不唯一/未命中 = 没改电路，分子分母都不计"
    n_null=$((n_null+1)); continue
  fi

  # ★先自证改了电路★：文本必须真的变了
  if cmp -s "$SV" "$WORK/L2TLB.sv.pristine"; then
    printf '%-38s %-8s %s\n' "$name" "NULL" "替换后文件与原文一致 = 没改电路，分子分母都不计"
    n_null=$((n_null+1)); continue
  fi

  ( cd "$WORK/verif/ut/L2TLB" && rm -f sim_$SEED.log && make compile ) > "$WORK/$name.compile.log" 2>&1
  crc=$?
  if [[ $crc -ne 0 ]]; then
    if grep -qiE "license|Licensed|No space left|cannot create|Cannot allocate" "$WORK/$name.compile.log"; then
      printf '%-38s %-8s %s\n' "$name" "INFRA" "工具/环境类失败（见 $name.compile.log）"
      n_infra=$((n_infra+1)); continue
    fi
    printf '%-38s %-8s %s\n' "$name" "INVALID" "编不过 = 没被测到，分子分母都不计"
    n_invalid=$((n_invalid+1)); continue
  fi
  ( cd "$WORK/verif/ut/L2TLB" && ./simv +ntb_random_seed=$SEED +ncycles=$NCYC \
       +vcs+initreg+$INITREG -l sim_$SEED.log ) > /dev/null 2>&1
  line="$(grep -E '^checks=' "$WORK/verif/ut/L2TLB/sim_$SEED.log" | tail -1)"
  if [[ -z "$line" ]]; then
    printf '%-38s %-8s %s\n' "$name" "INFRA" "跑完没有 checks= 行（仿真没跑起来）"
    n_infra=$((n_infra+1)); continue
  fi
  errs="$(sed -E 's/.*errors=([0-9]+).*/\1/' <<<"$line")"
  if [[ "${errs:-0}" -gt 0 ]]; then
    printf '%-38s %-8s %s\n' "$name" "CAUGHT" "errors=$errs"; n_caught=$((n_caught+1))
  else
    printf '%-38s %-8s %s\n' "$name" "MISSED" "$line"; n_missed=$((n_missed+1))
  fi
done
cp "$WORK/L2TLB.sv.pristine" "$SV"
den=$((n_caught + n_missed))
echo "----"
echo "判别力 = $n_caught/$den   (CAUGHT=$n_caught MISSED=$n_missed)"
echo "不计分式：INVALID=$n_invalid（编不过）  NULL=$n_null（没改电路）  INFRA=$n_infra（环境）"
echo "work=$WORK"
rc=0
[[ $n_missed -gt 0 ]] && rc=1
[[ $n_infra  -gt 0 ]] && rc=2
exit $rc
