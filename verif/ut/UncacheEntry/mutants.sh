#!/bin/bash
# =============================================================================
# UncacheEntry UT 判别力测试（mutation test）
#
# 一个 UT 报 errors=0，只有在"注入真 bug 它会红"的前提下才有意义。本脚本往重写核的
# **副本**里逐个注入 bug（副本在临时目录，绝不进库），各自重新编译并短跑。
#
# ★这份表里有两个变异体是 EXPECTED_MISSED，它们是本脚本的"不该报警"对照★
# （CONVENTIONS「闸的负测必须是双向的」：只造"该抓的"，等于只验证了它会响。）
#   · M9  把 pendingPtr 打拍的"值变了才写"使能去掉 —— 写同一个值和不写完全等价，
#         这是 golden 的**功能恒等冗余**，UT 与 FM 都抓不到，也都不该抓到。
#         它在这里的作用是反过来验证：本 harness 不会把"改了文本"当成"抓到了"。
#   · M15 req_valid 的 (slaveAck | ~writeback) 项 —— **立项时按 CAUGHT 写，被实测推翻**：
#         UT 两轮 errors=0，再拿 FM 复核得 native SUCCEEDED / passing 5020 / failing 0，
#         即逻辑等价。见该条自己的注释（含一句话的手算理由）。
#         这一条是本表里唯一一个"声明被证据改掉"的，留着它的过程比留结论有用。
#   · M6  把 flushPipe 的自与衰减改成保持 —— 见该条自己的注释，**依赖 initreg**：
#         +vcs+initreg+random 能抓，+vcs+initreg+0 抓不到（两侧都恒 0）。
#         这一条实测下来同一个变异在两轮里一红一绿，正是"两轮 initreg 各验各的"
#         这条规矩的实例，所以两轮都跑并分别记数。
#
# 三条防"空变异"的构造（对照 CONVENTIONS「变异体必须先自证改变了电路」）：
#   1) 注入点是**精确唯一**的整行文本，出现次数不等于 1 即判失败 —— 保证 RTL 文本真
#      的变了；且变异一律改在**原 always 块之内**（不新开块），避免"同一变量被两个
#      always_ff 驱动、VCS 不报错、排后面的块赢、变异根本没生效"那种空变异。
#   2) 每个变异体在**全新的临时目录**里编译与仿真（先 rm -rf 自己刚建的那个目录），
#      不可能读到上一轮的 sim.log。
#   3) 编译或运行没产出 sim.log 一律判 FAIL，不继续。
#   4) CAUGHT 不是二值：逐个报 errors 数，低于 THIN 的点名。
#
# 复位域这类"UT 按构造可能观测不到"的变异，UT 报 0 时再问一次结构闸
# reset_domain_check.py（它自己的双向负测在 test_reset_domain_gate.py）。
#
# 用法: [CYCLES=8000] [THIN=200] bash verif/ut/UncacheEntry/mutants.sh [工作目录]
# 本轮实测（CYCLES=8000, seed=1）：15/15 与声明相符，13 个 CAUGHT + M6 只在
# initreg=random 下可见 + M9/M15 两个逻辑等价对照两道闸都不报。
# 退出码 0 = 每个变异体的实际结果都与表里声明的期望一致
# =============================================================================
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
RTLSRC=$HERE/../../../rtl/memblock
WORK=${1:-/tmp/uncentry-mutants-$$-$(date +%s)}
CYCLES=${CYCLES:-8000}
mkdir -p "$WORK"

MUT_NAME=(); MUT_OLD=(); MUT_NEW=(); MUT_EXPECT=()

MUT_NAME+=("M1 needFlush 丢掉 level 精确冲刷分支")
MUT_OLD+=("                    & ((io_redirect_bits_level & (req_rob_idx == redirect_rob_idx))")
MUT_NEW+=("                    & ((1'b0 & (req_rob_idx == redirect_rob_idx))")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M2 S_RESP 的延迟 flush 漏看 need_flush_q")
MUT_OLD+=("      S_RESP : flush = io_uncache_resp_valid & (need_flush | need_flush_q);")
MUT_NEW+=("      S_RESP : flush = io_uncache_resp_valid & need_flush;")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M3 认领常数写死成 0（= 薄 wrapper 把 ENTRY_ID 传错）")
MUT_OLD+=("                   & (io_uncache_idResp_bits_mid == ENTRY_ID);")
MUT_NEW+=("                   & (io_uncache_idResp_bits_mid == 7'd0);")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M4 denied 收新请求时不再清零")
MUT_OLD+=("        denied  <= ~enq & denied;")
MUT_NEW+=("        denied  <= denied;")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M5 slaveId 多加一个复位（golden 不复位）")
MUT_OLD+=("    if (~(flush | io_req_valid) & slave_ack)")
MUT_NEW+=("    if (reset) slave_id <= 4'h0;
    else if (~(flush | io_req_valid) & slave_ack)")
MUT_EXPECT+=("CAUGHT")

# ★依赖 initreg 的一条★：+random 那轮重写侧的 flushPipe 起始值是随机的，golden 侧
# 暖机第一拍就被压成 0，于是两侧分歧；+0 那轮两侧都从 0 起，改了也看不见。
MUT_NAME+=("M6 flushPipe 的自与衰减被抹平成保持")
MUT_OLD+=("    req_uop_flushPipe  <= ~enq & req_uop_flushPipe;")
MUT_NEW+=("    req_uop_flushPipe  <= req_uop_flushPipe;")
MUT_EXPECT+=("CAUGHT_INITREG_RANDOM_ONLY")

MUT_NAME+=("M7 uncache.req.mask 的半字选择位选错")
MUT_OLD+=("  assign io_uncache_req_bits_mask = req_paddr[3] ? req_mask[15:8] : req_mask[7:0];")
MUT_NEW+=("  assign io_uncache_req_bits_mask = req_paddr[2] ? req_mask[15:8] : req_mask[7:0];")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M8 writeback 的 nc/mmio 选择写反")
MUT_OLD+=("  assign writeback = req_nc ? (io_ncOut_ready   & nc_out_valid)")
MUT_NEW+=("  assign writeback = req_nc ? (io_mmioOut_ready & mmio_out_valid)")
MUT_EXPECT+=("CAUGHT")

# ★不该报警的对照★：golden 的功能恒等冗余，改掉之后电路逻辑上完全一样。
MUT_NAME+=("M9 pendingPtr 的\"值变了才写\"使能去掉（golden 的恒等冗余）")
MUT_OLD+=("      if ({io_rob_pendingPtr_flag, io_rob_pendingPtr_value} != rob_pending_ptr) begin")
MUT_NEW+=("      if (1'b1) begin")
MUT_EXPECT+=("EXPECTED_MISSED")

MUT_NAME+=("M10 hardwareError 位漏掉 ~denied")
MUT_OLD+=("  assign io_mmioOut_bits_uop_exceptionVec_19 = corrupt & ~denied;")
MUT_NEW+=("  assign io_mmioOut_bits_uop_exceptionVec_19 = corrupt;")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M11 MMIO 不再等 ROB 头就发车")
MUT_OLD+=("                      & (req_nc | (pending_mmio_ld_q & (req_rob_idx == rob_pending_ptr)));")
MUT_NEW+=("                      & (req_nc | 1'b1);")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M12 mmioSelect 的状态条件收窄")
MUT_OLD+=("  assign io_mmioSelect = (state != S_IDLE) & req_mmio;")
MUT_NEW+=("  assign io_mmioSelect = (state == S_WAIT) & req_mmio;")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M13 slaveAccept 丢掉 io_req_valid 门控（优先级写错）")
MUT_OLD+=("      slave_accept <= ~(flush | io_req_valid) & (slave_ack | ~writeback & slave_accept);")
MUT_NEW+=("      slave_accept <= ~flush & (slave_ack | ~writeback & slave_accept);")
MUT_EXPECT+=("CAUGHT")

MUT_NAME+=("M14 payload 锁存使能丢掉 flush 优先")
MUT_OLD+=("  assign enq = ~flush & io_req_valid;")
MUT_NEW+=("  assign enq = io_req_valid;")
MUT_EXPECT+=("CAUGHT")

# ★不该报警的对照之二 —— 这一条是**先当成 CAUGHT 写进来、被实测推翻的**★
# 立项时以为「slaveAck 那一拍必须保住 req_valid」是条真逻辑，声明成 CAUGHT；
# 实测 UT 两轮都 errors=0。按 CONVENTIONS「UT 看不见时先问 FM，别急着说 UT 漏了」，
# 把这个变异注进核的副本再跑一次 Formality：
#     signoff-strict native SUCCEEDED / passing 5020 / failing 0 / unmatched 0
#     （与未注入的基线逐个数字相同）
# ⇒ 它是**逻辑等价**的改动，UT 抓不到是对的。
# 手算复核（FM 的结论有一个一句话的理由）：writeback 只可能在 S_WAIT 抬起
# （nc_out_valid / mmio_out_valid 都带 state==S_WAIT），而 S_WAIT 下
# flush = need_flush | writeback ⇒ writeback=1 必然 flush=1 ⇒ 外面那个 ~flush
# 已经把 req_valid 清零了，里面 (slave_ack | ~writeback) 与 (~writeback) 取值不同的
# 那一格根本到不了。golden 这一项是 firtool 从 Chisel 的 elsewhen 链展开出来的**冗余**。
# ★照抄它仍然是对的★：冗余归冗余，照抄零成本，而"化简掉"要靠这段推理背书。
MUT_NAME+=("M15 req_valid 丢掉 slaveAck 的保持项（实测为逻辑等价冗余）")
MUT_OLD+=("      req_valid    <= ~flush & (io_req_valid | (slave_ack | ~writeback) & req_valid);")
MUT_NEW+=("      req_valid    <= ~flush & (io_req_valid | (~writeback) & req_valid);")
MUT_EXPECT+=("EXPECTED_MISSED")

THIN=${THIN:-200}
pass=0; fail=0; thinlist=""
for i in "${!MUT_NAME[@]}"; do
  NAME=${MUT_NAME[$i]}
  EXP=${MUT_EXPECT[$i]}
  d=$WORK/m$i
  rm -rf "$d"; mkdir -p "$d/rtl/memblock" "$d/ut"
  cp "$RTLSRC"/xs_UncacheEntry_core.sv "$d/rtl/memblock/"
  for v in "" _1 _2 _3 _4 _5 _6 _7 _8 _9 _10 _11 _12 _13 _14 _15; do
    cp "$RTLSRC/UncacheEntry$v.sv" "$d/rtl/memblock/"
  done
  if ! OLD="${MUT_OLD[$i]}" NEW="${MUT_NEW[$i]}" python3 - "$d/rtl/memblock/xs_UncacheEntry_core.sv" <<'PY'
import os, sys
p = sys.argv[1]
s = open(p).read()
old, new = os.environ['OLD'], os.environ['NEW']
if s.count(old) != 1:
    sys.exit('变异点不唯一或不存在(%d 处): %r' % (s.count(old), old))
t = s.replace(old, new)
if t == s:
    sys.exit('变异后文本与原文相同 —— 空变异')
open(p, 'w').write(t)
PY
  then echo "[$NAME] ★变异注入失败（锚点已随重构漂走，先修锚点）"; fail=$((fail+1)); continue; fi
  sed -e "s|^RTL_DIR = .*|RTL_DIR = $d/rtl|" -e "s|^TB_SRCS = .*|TB_SRCS = $HERE/tb.sv|" \
      -e "s|\.\./\.\./\.\./scripts/|$HERE/../../../scripts/|" \
      "$HERE/Makefile" > "$d/ut/Makefile"
  ( cd "$d/ut" && make compile > compile.log 2>&1 )
  if [ ! -x "$d/ut/simv" ]; then
    echo "[$NAME] ★编译失败（见 $d/ut/compile.log）"; fail=$((fail+1)); continue
  fi
  # 两轮 initreg 各跑一遍：有的变异只有随机上电值才看得见（见 M6）。
  er=""; e0=""
  for ir in random 0; do
    rm -f "$d/ut/sim_$ir.log"
    ( cd "$d/ut" && ./simv +ntb_random_seed=1 +ncycles=$CYCLES +vcs+initreg+$ir \
        -l sim_$ir.log > /dev/null 2>&1 )
    if [ ! -f "$d/ut/sim_$ir.log" ]; then
      echo "[$NAME] ★运行没产出 sim_$ir.log"; fail=$((fail+1)); continue 2
    fi
    n=$(grep -oP 'errors=\K\d+' "$d/ut/sim_$ir.log" | tail -1)
    if [ "$ir" = random ]; then er=${n:-0}; else e0=${n:-0}; fi
  done
  if XSSV_UNCENTRY_CORE="$d/rtl/memblock/xs_UncacheEntry_core.sv" \
     python3 "$HERE/reset_domain_check.py" > "$d/reset_check.log" 2>&1
  then struct=ok; else struct=caught; fi

  case "$EXP" in
    CAUGHT)
      if [ "$er" -gt 0 ] && [ "$e0" -gt 0 ]; then
        thin=""
        m=$er; [ "$e0" -lt "$m" ] && m=$e0
        if [ "$m" -lt "$THIN" ]; then thin="  ★余量薄(<$THIN)，换 seed 可能漏★"; fi
        echo "[$NAME] UT 抓出：errors(initreg=random)=$er  errors(initreg=0)=$e0$thin"
        [ -n "$thin" ] && thinlist="$thinlist $NAME(min=$m)"
        pass=$((pass+1))
      elif [ "$struct" = caught ]; then
        echo "[$NAME] UT 看不见（$er/$e0），但复位域结构闸拦下了 —— 两道闸互补，算抓出"
        pass=$((pass+1))
      else
        echo "[$NAME] ★两道闸都没抓出来（errors random=$er, 0=$e0）—— 这条逻辑其实没在验"
        fail=$((fail+1))
      fi ;;
    CAUGHT_INITREG_RANDOM_ONLY)
      if [ "$er" -gt 0 ] && [ "$e0" -eq 0 ]; then
        echo "[$NAME] 如声明：initreg=random 抓出 errors=$er；initreg=0 看不见（=0）"
        pass=$((pass+1))
      else
        echo "[$NAME] ★与声明不符：期望 random>0 且 0==0，实测 random=$er, 0=$e0"
        fail=$((fail+1))
      fi ;;
    EXPECTED_MISSED)
      if [ "$er" -eq 0 ] && [ "$e0" -eq 0 ] && [ "$struct" = ok ]; then
        echo "[$NAME] 如声明：两道闸都不报（功能恒等冗余，本就不该报）"
        pass=$((pass+1))
      else
        echo "[$NAME] ★与声明不符：期望两轮都 0 且结构闸不报，实测 random=$er, 0=$e0, 结构闸=$struct"
        fail=$((fail+1))
      fi ;;
  esac
done
echo "--------------------------------------------------"
echo "变异体 $((pass+fail)) 个：与声明相符 $pass，不符 $fail   （工作目录 $WORK）"
if [ -n "$thinlist" ]; then
  echo "★余量薄的变异体（errors < $THIN，不许报成\"判别力均匀\"）：$thinlist"
fi
[ $fail -eq 0 ]
