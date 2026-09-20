#!/bin/bash
# =============================================================================
# TlbStorageWrapper_2 / _3 UT 判别力测试（mutation test）
#
# 一个 UT 报 errors=0，只有在"注入真 bug 它会红"的前提下才有意义。本脚本往**副本**里
# 逐个注入真 bug（副本在本 lane 专属临时目录，绝不进库），各自重编译并短跑，
# 要求每一个都被抓出来。抓不出来的是要报告的缺口，不是噪音。
#
# 变异点分两组：
#   C* 打在共享参数化核 xs_TlbStorageWrapper_core.sv（Tree-PLRU 替换器本身）；
#   W* 打在变体薄 wrapper TlbStorageWrapper_{2,3}.sv（端口透传与反馈接线）。
# 两组都要有：_2/_3 的"重写"其实就是这两块，只验核不验接线等于没验薄文件。
#
# 三条防"空变异"的构造（CONVENTIONS「变异体必须先自证改变了电路」）：
#   1) 注入点是**精确唯一**的整行文本，出现次数≠1 立即判失败 —— 保证 RTL 文本真变了；
#   2) 每个变异体在**全新**临时目录里编译与仿真（先 rm -rf 自己的唯一路径），
#      不可能读到上一轮的 sim.log；
#   3) ★编译/运行失败判 FAIL，不判 CAUGHT★ —— 编不过不等于"抓住了 bug"。
#   4) CAUGHT 不是二值：逐个报 errors 数，低于 THIN 的点名（换 seed 可能漏）。
#
# ★复位域这一类（C3/C4）UT 按构造可能看不见★：比较窗口在复位之后打开，
#   两侧都被写成确定值。所以这两个变异体若 UT 报 errors=0，**不算抓出**，
#   如实记成漏 —— 它们由 FM（逐个寄存器比，含复位语义）兜底，而不是由 UT。
#
# 用法: [CYCLES=8000] [THIN=200] bash verif/ut/TlbStorageWrapper/mutants.sh [工作目录]
# 退出码 0 = 全部 UT 可见的变异体都被抓出来
# =============================================================================
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
RTLSRC=$HERE/../../../rtl/memblock
# 共享 scratchpad 里只许用自己造的唯一标识界定作用域（CONVENTIONS 明令）
WORK=${1:-${TMPDIR:-/tmp}/tlbsw23-mutants-$$-$RANDOM}
CYCLES=${CYCLES:-8000}
THIN=${THIN:-200}

MUT_NAME=(); MUT_FILE=(); MUT_OLD=(); MUT_NEW=(); MUT_SIM=(); MUT_UTVISIBLE=()

add() { MUT_NAME+=("$1"); MUT_FILE+=("$2"); MUT_OLD+=("$3"); MUT_NEW+=("$4"); MUT_SIM+=("$5"); MUT_UTVISIBLE+=("$6"); }

# ---- C 组：共享 PLRU 核 ----
add "C1 PLRU 状态更新不再受 any_touch 门控" xs_TlbStorageWrapper_core.sv \
    "    else if (any_touch) refill_idx_state_reg <= plru_next;" \
    "    else                refill_idx_state_reg <= plru_next;" 2 yes

add "C2 多端口 foldLeft 顺序反过来(端口 0 不再先叠)" xs_TlbStorageWrapper_core.sv \
    "    for (int i = 0; i < PORTS; i++) begin" \
    "    for (int i = PORTS-1; i >= 0; i--) begin" 2 yes

add "C3 复位值由全 0 改成全 1(复位域)" xs_TlbStorageWrapper_core.sv \
    "    if (reset)          refill_idx_state_reg <= '0;" \
    "    if (reset)          refill_idx_state_reg <= '1;" 2 no

add "C4 异步复位被写成同步复位(复位域)" xs_TlbStorageWrapper_core.sv \
    "  always_ff @(posedge clock or posedge reset) begin" \
    "  always_ff @(posedge clock) begin" 2 no

# ---- W 组：变体薄 wrapper 的接线 ----
add "W1 _2 两个端口的 touch way 反馈接反" TlbStorageWrapper_2.sv \
    "      access[i].way   = acc_bits[i];" \
    "      access[i].way   = acc_bits[1-i];" 2 yes

add "W2 _2 refill wayIdx 钉死 0(替换器输出没接上)" TlbStorageWrapper_2.sv \
    "    .io_w_bits_wayIdx(refill_wayIdx)," \
    "    .io_w_bits_wayIdx('0)," 2 yes

add "W3 _2 读端口 0 的 vpn 误接端口 1" TlbStorageWrapper_2.sv \
    "    .io_r_req_0_bits_vpn(io_r_req_0_bits_vpn)," \
    "    .io_r_req_0_bits_vpn(io_r_req_1_bits_vpn)," 2 yes

add "W4 _3 mbmc.BME 没透传给内层阵列" TlbStorageWrapper_3.sv \
    "    .io_csr_mbmc_BME(io_csr_mbmc_BME)," \
    "    .io_csr_mbmc_BME('0)," 3 yes

add "W5 _3 端口 1 的响应 hit 误接端口 0" TlbStorageWrapper_3.sv \
    "    .io_r_resp_1_bits_hit(io_r_resp_1_bits_hit)," \
    "    .io_r_resp_1_bits_hit(io_r_resp_0_bits_hit)," 3 yes

mkdir -p "$WORK" || exit 2
pass=0; fail=0; thinlist=""; blindlist=""
for i in "${!MUT_NAME[@]}"; do
  NAME=${MUT_NAME[$i]}; FILE=${MUT_FILE[$i]}; V=${MUT_SIM[$i]}; VIS=${MUT_UTVISIBLE[$i]}
  d=$WORK/m$i
  rm -rf "$d"; mkdir -p "$d/rtl/memblock" "$d/ut"
  cp "$RTLSRC"/memblock_common_pkg.sv "$RTLSRC"/xs_TlbStorageWrapper_core.sv \
     "$RTLSRC"/TlbStorageWrapper.sv "$RTLSRC"/TlbStorageWrapper_1.sv \
     "$RTLSRC"/TlbStorageWrapper_2.sv "$RTLSRC"/TlbStorageWrapper_3.sv \
     "$RTLSRC"/xs_TLBFA_core.sv "$RTLSRC"/TLBFA_2.sv "$RTLSRC"/TLBFA_3.sv \
     "$d/rtl/memblock/" || { echo "[$NAME] ★拷贝失败"; fail=$((fail+1)); continue; }
  if ! OLD="${MUT_OLD[$i]}" NEW="${MUT_NEW[$i]}" python3 - "$d/rtl/memblock/$FILE" <<'PY'
import os, sys
p = sys.argv[1]; s = open(p).read()
old, new = os.environ['OLD'], os.environ['NEW']
n = s.count(old)
if n != 1:
    sys.exit('变异点不唯一或不存在(%d 处): %r' % (n, old))
open(p, 'w').write(s.replace(old, new))
PY
  then echo "[$NAME] ★变异注入失败（锚点已随重构漂走，先修锚点）"; fail=$((fail+1)); continue; fi
  sed -e "s|^RTL_DIR = .*|RTL_DIR = $d/rtl|" \
      -e "s|^TB_SRCS = .*|TB_SRCS = $HERE/tb.sv|" \
      -e "s|tb_2\.sv|$HERE/tb_2.sv|g" -e "s|tb_3\.sv|$HERE/tb_3.sv|g" \
      -e "s|\.\./\.\./\.\./scripts/|$HERE/../../../scripts/|g" \
      "$HERE/Makefile" > "$d/ut/Makefile"
  ( cd "$d/ut" && make compile$V > compile.log 2>&1 && \
    ./simv$V +ntb_random_seed=1 +ncycles=$CYCLES -l sim.log > /dev/null 2>&1 )
  if [ ! -f "$d/ut/sim.log" ]; then
    echo "[$NAME] ★编译/运行失败 —— 判 FAIL 不判 CAUGHT（见 $d/ut/compile.log）"
    fail=$((fail+1)); continue
  fi
  errs=$(grep -oP 'errors=\K\d+' "$d/ut/sim.log" | head -1)
  if [ "${errs:-0}" -gt 0 ]; then
    if [ "$errs" -lt "$THIN" ]; then thin="  ★余量薄(<$THIN)，换 seed 可能漏★"; thinlist="$thinlist ${NAME%% *}(errors=$errs)"; else thin=""; fi
    echo "[$NAME] UT 抓出：errors=$errs (simv$V, $CYCLES 拍)$thin"
    pass=$((pass+1))
  elif [ "$VIS" = no ]; then
    echo "[$NAME] UT 看不见（errors=0）—— 已预期：复位域差异在比较窗口内观测不到，由 FM 兜底"
    blindlist="$blindlist ${NAME%% *}"
  else
    echo "[$NAME] ★没抓出来 —— 这条逻辑其实没在验"; fail=$((fail+1))
  fi
done
echo "--------------------------------------------------"
echo "变异体 ${#MUT_NAME[@]} 个：UT 抓出 $pass，漏 $fail，按构造 UT 不可见 $(echo $blindlist | wc -w)   （工作目录 $WORK）"
[ -n "$thinlist" ] && echo "★余量薄（errors < $THIN，不许报成\"判别力均匀\"）：$thinlist"
[ -n "$blindlist" ] && echo "★UT 按构造看不见、只能靠 FM 的：$blindlist"
[ $fail -eq 0 ]
