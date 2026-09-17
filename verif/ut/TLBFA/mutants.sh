#!/bin/bash
# =============================================================================
# TLBFA UT 判别力测试（mutation test）
#
# 一个 UT 报 errors=0，只有在"注入真 bug 它会红"的前提下才有意义。本脚本往重写核的
# **副本**里逐个注入真 bug（副本在 /tmp，绝不进库），各自重新编译并短跑，要求每一个
# 都被 UT 抓出来。哪个抓不出来，就说明 UT 在那条逻辑上其实没在验 —— 那是要报告的
# 缺口，不是可以忽略的噪音。
#
# 12 个变异点覆盖本模块的 12 条独立逻辑：命中比较（最高段 tag / asid 的 global 豁免）/
# fence 优先级 / genPPN 段选择 / refill 字段合成 / 两处打拍方式 / 复位类型 / 两处多余复位 /
# 多命中时的 Mux1H 语义 / refill 屏蔽。
#
# 其中 M9/M10（多加一个 golden 没有的复位）**UT 按构造看不见**：复位后 v=0 读不出任何
# entry，被 refill 写过的 way 内容又已覆盖，模块边界上观测不到。所以本脚本在 UT 报
# errors=0 时会再问一次 reset_domain_check.py（结构闸），两道闸都看不见才算漏 ——
# 这样"漏了"就不会被粉饰成"过了"。
#
# 用法: [CYCLES=8000] bash verif/ut/TLBFA/mutants.sh [工作目录]
# 退出码 0 = 全部变异体都被抓出来
# =============================================================================
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
RTLSRC=$HERE/../../../rtl/memblock
WORK=${1:-/tmp/tlbfa-mutants-$$}
CYCLES=${CYCLES:-8000}
mkdir -p "$WORK"

# 四个并列数组（不用单行分隔符：变异文本里本来就含 | 和 &，任何分隔符都会咬到）
MUT_NAME=(); MUT_OLD=(); MUT_NEW=()

MUT_NAME+=("M1 最高段 tag 匹配被超页放行")
MUT_OLD+=("      level_match[LEVELS] = tag_match[LEVELS];")
MUT_NEW+=("      level_match[LEVELS] = tag_match[LEVELS] || (e.level >= 2'd3);")

MUT_NAME+=("M2 fence 优先级 hg/hv 写反")
MUT_OLD+=("    end else if (sfence_valid && sfence_hg) begin")
MUT_NEW+=("    end else if (sfence_valid && sfence_hg && !sfence_hv) begin")

MUT_NAME+=("M3 genPPN 中段选择阈值差一")
MUT_OLD+=("                       (e.level >= 2'd2) ? vpn[VPNN_W*2-1 -: VPNN_W]")
MUT_NEW+=("                       (e.level >= 2'd3) ? vpn[VPNN_W*2-1 -: VPNN_W]")

MUT_NAME+=("M4 refill 超页不再置满 valididx")
MUT_OLD+=("    refill_entry.valididx = is_super_page ? '1")
MUT_NEW+=("    refill_entry.valididx = 1'b0 ? '1")

MUT_NAME+=("M5 reqVpn 误用 RegEnable(Chisel 读起来像、golden 不是)")
MUT_OLD+=("      req_vpn_q    <= req_vpn[p];")
MUT_NEW+=("      if (req_valid[p]) req_vpn_q <= req_vpn[p];")

MUT_NAME+=("M6 v 的异步复位被写成同步复位")
MUT_OLD+=("  always_ff @(posedge clock or posedge reset) begin")
MUT_NEW+=("  always_ff @(posedge clock) begin")

MUT_NAME+=("M7 OHToUInt 由按位或改成后者胜(只有多命中才看得见)")
MUT_OLD+=("          sel_way     = sel_way     | WAY_W'(way);")
MUT_NEW+=("          sel_way     = WAY_W'(way);")

MUT_NAME+=("M8 refill_mask 失效(当拍在写的 way 也允许命中)")
MUT_OLD+=("  assign refill_mask = refill_oh;")
MUT_NEW+=("  assign refill_mask = '0;")

# --- 复位域专项（Predictor 教训：golden 有寄存器不复位，照抄成全复位是真 bug，
#     elaborate 与 lint 都不报）。本模块 golden 只有 48 个 v 位带复位（且是异步），
#     entries / hitVecReg / reqVpn / resp_valid / refill 打拍寄存器**全部无复位**。
#     M9~M11 逐个把"多加一个复位 / 打拍方式写错"注进去，看 UT 认不认得出来。---
MUT_NAME+=("M9 entries 多加一个复位(golden 不复位)")
MUT_OLD+=("      if (refill_oh[way]) entries[way] <= refill_entry;")
MUT_NEW+=("      if (reset) entries[way] <= '0; else if (refill_oh[way]) entries[way] <= refill_entry;")

MUT_NAME+=("M10 hitVecReg 多加一个复位(golden 不复位)")
MUT_OLD+=("      if (req_valid[p]) hit_vec_q <= hit_vec;")
MUT_NEW+=("      if (reset) hit_vec_q <= '0; else if (req_valid[p]) hit_vec_q <= hit_vec;")

MUT_NAME+=("M11 hitVecReg 由 RegEnable 改成无条件打拍")
MUT_OLD+=("      if (req_valid[p]) hit_vec_q <= hit_vec;")
MUT_NEW+=("      hit_vec_q <= hit_vec;")

MUT_NAME+=("M12 asid 比较漏掉 global 页(perm.g)豁免")
MUT_OLD+=("                                     : ((e.asid == asid) || e.perm.g));")
MUT_NEW+=("                                     : (e.asid == asid));")

pass=0; fail=0
for i in "${!MUT_NAME[@]}"; do
  NAME=${MUT_NAME[$i]}
  d=$WORK/m$i
  rm -rf "$d"; mkdir -p "$d/rtl/memblock" "$d/ut"
  cp "$RTLSRC"/xs_TLBFA_core.sv "$RTLSRC"/TLBFA.sv "$RTLSRC"/TLBFA_1.sv \
     "$RTLSRC"/TLBFA_2.sv "$RTLSRC"/TLBFA_3.sv "$d/rtl/memblock/"
  if ! OLD="${MUT_OLD[$i]}" NEW="${MUT_NEW[$i]}" python3 - "$d/rtl/memblock/xs_TLBFA_core.sv" <<'PY'
import os, sys
p = sys.argv[1]
s = open(p).read()
old, new = os.environ['OLD'], os.environ['NEW']
if s.count(old) != 1:
    sys.exit(f'变异点不唯一或不存在({s.count(old)} 处): {old!r}')
open(p, 'w').write(s.replace(old, new))
PY
  then echo "[$NAME] ★变异注入失败（锚点已随重构漂走，先修锚点）"; fail=$((fail+1)); continue; fi
  sed -e "s|^RTL_DIR = .*|RTL_DIR = $d/rtl|" -e "s|^TB_SRCS = .*|TB_SRCS = $HERE/tb.sv|" \
      -e "s|\.\./\.\./\.\./scripts/|$HERE/../../../scripts/|" \
      "$HERE/Makefile" > "$d/ut/Makefile"
  ( cd "$d/ut" && make compile > compile.log 2>&1 && \
    ./simv +ntb_random_seed=1 +ncycles=$CYCLES -l sim.log > /dev/null 2>&1 )
  if [ ! -f "$d/ut/sim.log" ]; then
    echo "[$NAME] ★编译/运行失败（见 $d/ut/compile.log）"; fail=$((fail+1)); continue
  fi
  errs=$(grep -oP 'errors=\K\d+' "$d/ut/sim.log" | tail -1)
  # UT 抓不到的，再问一次结构闸（复位域这类差异在模块边界上可能根本观测不到）
  if XSSV_TLBFA_CORE="$d/rtl/memblock/xs_TLBFA_core.sv" \
     python3 "$HERE/reset_domain_check.py" > "$d/reset_check.log" 2>&1
  then struct=ok; else struct=caught; fi
  if [ "${errs:-0}" -gt 0 ]; then
    echo "[$NAME] UT 抓出：errors=$errs  首次 $(grep -m1 MISMATCH "$d/ut/sim.log" | cut -c1-40)"
    pass=$((pass+1))
  elif [ "$struct" = caught ]; then
    echo "[$NAME] UT 看不见（errors=0），但复位域结构闸拦下了 —— 两道闸互补，算抓出"
    pass=$((pass+1))
  else
    echo "[$NAME] ★两道闸都没抓出来 —— 这条逻辑其实没在验"; fail=$((fail+1))
  fi
done
echo "--------------------------------------------------"
echo "变异体 $((pass+fail)) 个：抓出 $pass，漏掉 $fail   （工作目录 $WORK）"
[ $fail -eq 0 ]
