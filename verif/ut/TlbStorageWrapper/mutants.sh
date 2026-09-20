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
#   3) ★编不过的变异体判「无效变异体」★ —— 它根本没产生电路，UT 没跑过它，
#      所以既不计 caught 也不计分母；但整体 rc 非零（变异体本身要修）。
#      唯一例外：声明期望就是 COMPILE_FAIL 的。
#   4) CAUGHT 不是二值：逐个报 errors 数，低于 THIN 的点名（换 seed 可能漏）。
#   5) ★逻辑等价的空变异（VIS=null）从分子分母同时剔除★，并在报告里写明为什么等价。
#
# ★2026-09-20：本脚本原来的判据是 fail-open 的，五个变异体被误报成"没抓出来"★
#   原判据 `grep -oP 'errors=\K\d+' sim.log | head -1` 取到的是日志**第一行**的
#   `DIRECTED mbmc_sfence errors=0`，不是最后的 `checks=N errors=M` 总结行。
#   实测对照（C2 变异体 60000 拍）：真值 errors=56350，老判据读出 0 ⇒ 报"★没抓出来"。
#   判据现在抽成 parse_sim_errors.sh，并带**四向自测**（真错要读出来 / 无错不误报 /
#   日志不完整要报错不许返 0 / 文件不存在要报错），自测不过本脚本直接退出。
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
# ★C1 是**空变异**（逻辑等价），按规矩从分子分母同时剔除，理由写在这里★
#   plru_next 在 always_comb 里先被赋成 refill_idx_state_reg，只有在
#   `io_access[i].valid` 为真时才被 plru_next_state 改写；而 any_touch 恰好就是
#   这些 valid 的或。所以 any_touch==0 的拍 plru_next === refill_idx_state_reg，
#   去掉门控后写回的是**寄存器自己的值**，电路没有任何变化。
#   （UT 报 errors=0 是正确结果，不是判别力缺口 —— 真正能验这条门控的是 C1b。）
add "C1 PLRU 状态更新不再受 any_touch 门控(空变异:逻辑等价)" xs_TlbStorageWrapper_core.sv \
    "    else if (any_touch) refill_idx_state_reg <= plru_next;" \
    "    else                refill_idx_state_reg <= plru_next;" 2 null

# C1b：C1 想验的那条门控，换成**真的会变电路**的打法 ——
#   只认端口 0 的 touch，于是"只有端口 1 命中"的那些拍状态不再更新。
add "C1b PLRU 更新只认端口 0 的 touch(丢掉端口 1 单独命中的拍)" xs_TlbStorageWrapper_core.sv \
    "    else if (any_touch) refill_idx_state_reg <= plru_next;" \
    "    else if (io_access[0].valid) refill_idx_state_reg <= plru_next;" 2 yes

# C5：victim 取**本拍组合后**的状态而不是寄存器值（差一拍），是经典的替换器错法
add "C5 victim way 取 plru_next 而不是寄存器状态(差一拍)" xs_TlbStorageWrapper_core.sv \
    "    io_w_bits_wayIdx = plru_replace_way(refill_idx_state_reg, /*state_lo*/0, /*tree_nways*/WAYS);" \
    "    io_w_bits_wayIdx = plru_replace_way(plru_next, /*state_lo*/0, /*tree_nways*/WAYS);" 2 yes

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

# ★先给判据做自测★：判据自己不过关，下面跑出来的一切都不作数
if ! bash "$HERE/parse_sim_errors.sh" --selftest; then
  echo "★errors 判据自测没过，拒绝继续（跑出来的判别力报告不可信）"; exit 2
fi

mkdir -p "$WORK" || exit 2
pass=0; fail=0; thinlist=""; blindlist=""; nulllist=""; invalidlist=""; infralist=""
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
  # ---- 基础设施类失败（license / 磁盘）单列一桶，不许混进判别力统计 ----
  if grep -qEi "License .*(not available|checkout failed|expired)|No space left on device|Cannot allocate memory" \
       "$d/ut/compile.log" 2>/dev/null; then
    echo "[$NAME] ☠ 基础设施失败（license/磁盘），本条不作数（见 $d/ut/compile.log）"
    infralist="$infralist ${NAME%% *}"; continue
  fi
  if [ ! -f "$d/ut/sim.log" ]; then
    # ★编不过 = 无效变异体★：它没产生电路，UT 根本没跑，既不计 caught 也不计分母。
    echo "[$NAME] ★无效变异体：编译/运行没产出 sim.log —— 不计 caught 也不计分母（见 $d/ut/compile.log）"
    invalidlist="$invalidlist ${NAME%% *}"; continue
  fi
  # ★判据锚定最终总结行★（见 parse_sim_errors.sh 的文件头：老的 head -1 是 fail-open 的）
  if ! errs=$(bash "$HERE/parse_sim_errors.sh" "$d/ut/sim.log"); then
    echo "[$NAME] ★无效变异体：sim.log 读不出总结行（仿真没跑完）—— 不计 caught 也不计分母"
    invalidlist="$invalidlist ${NAME%% *}"; continue
  fi
  covline=$(grep -E "^COVERAGE " "$d/ut/sim.log" | tail -1)
  covfail=$(grep -c "COVERAGE GATE FAILED" "$d/ut/sim.log")
  if [ "$VIS" = null ]; then
    # 逻辑等价的空变异：从分子分母同时剔除（理由见变异体表里的注释）
    echo "[$NAME] 空变异（逻辑等价）errors=$errs —— ★分子分母都不计★"
    nulllist="$nulllist ${NAME%% *}"; continue
  fi
  if [ "${errs:-0}" -gt 0 ]; then
    if [ "$errs" -lt "$THIN" ]; then thin="  ★余量薄(<$THIN)，换 seed 可能漏★"; thinlist="$thinlist ${NAME%% *}(errors=$errs)"; else thin=""; fi
    echo "[$NAME] UT 抓出：errors=$errs (simv$V, $CYCLES 拍)$thin"
    pass=$((pass+1))
  elif [ "$covfail" -gt 0 ]; then
    # errors=0 但覆盖闸红了：这条变异体是被**覆盖闸**抓住的（它把激励打残了）
    echo "[$NAME] 覆盖闸抓出（errors=0 但 COVERAGE GATE FAILED）：$covline"
    pass=$((pass+1))
  elif [ "$VIS" = no ]; then
    echo "[$NAME] UT 看不见（errors=0）—— 已预期：复位域差异在比较窗口内观测不到，由 FM 兜底"
    blindlist="$blindlist ${NAME%% *}"
  else
    echo "[$NAME] ★没抓出来 —— 这条逻辑其实没在验   $covline"; fail=$((fail+1))
  fi
done
echo "--------------------------------------------------"
nnull=$(echo $nulllist | wc -w); ninv=$(echo $invalidlist | wc -w)
ninf=$(echo $infralist | wc -w); nblind=$(echo $blindlist | wc -w)
denom=$((pass + fail + nblind))
echo "变异体 ${#MUT_NAME[@]} 个，计入分母 $denom（= 抓出 $pass + 漏 $fail + UT 按构造不可见 $nblind）"
echo "  剔除：空变异(逻辑等价) $nnull、无效变异体(编不过/没跑完) $ninv、基础设施失败 $ninf"
echo "  工作目录 $WORK"
[ -n "$thinlist" ]   && echo "★余量薄（errors < $THIN，不许报成\"判别力均匀\"）：$thinlist"
[ -n "$blindlist" ]  && echo "★UT 按构造看不见、只能靠 FM 的：$blindlist"
[ -n "$nulllist" ]   && echo "★空变异（逻辑等价，分子分母都不计）：$nulllist"
[ -n "$invalidlist" ] && echo "★无效变异体（要修锚点或变异内容）：$invalidlist"
[ -n "$infralist" ]  && echo "☠ 基础设施失败（license/磁盘），整体判失败：$infralist"
[ $fail -eq 0 ] && [ $ninv -eq 0 ] && [ $ninf -eq 0 ]
