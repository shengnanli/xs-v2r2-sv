#!/bin/bash
# full_elab.sh —— 整芯片 elaborate（顶层默认 XSTop，重写件优先），可复跑。
#
# 为什么需要它（codex 0158 §3）：所有 UT/FM 都是**单目标**的——一次只把一个重写
# 文件和它的 golden 对照编进一次 elaboration。整芯片把 292 个重写件与 1700+ 个尚未
# 重写的 golden 件放进同一个编译单元，才会暴露「全局名字空间冲突」「重写件与 golden
# 同名撞车」「跨模块端口/参数不匹配」这一类只在集成时存在的问题。
#
# 用法:
#   scripts/full_elab.sh                 # 重写件优先，顶层 XSTop
#   scripts/full_elab.sh --golden-only   # 纯 golden 对照基线（先证明 golden 自己能过）
#   scripts/full_elab.sh --top SimTop --with-difftest
#   FULL_ELAB_OUT=/somewhere scripts/full_elab.sh
#
# 取舍规则不写在这里，写在 scripts/full_elab_filelist.py（机械可复算，fail-closed）。
# 本脚本只负责：生成清单 → 调 VCS → 把错误分类摘出来。
#
# 环境坑（本工程记录在案）：VCS_ARCH_OVERRIDE=linux 必须配 -full64，否则 VCS 选错
# 架构。这里按构造成对下发，不依赖谁记得加。
set -u
cd "$(dirname "$0")/.." || exit 2
REPO=$PWD

TOP=XSTop
MODE=impl                 # impl | golden
DIFFTEST=""
EXTRA_VCS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --top)           TOP=$2; shift 2;;
    --golden-only)   MODE=golden; shift;;
    --with-difftest) DIFFTEST=--with-difftest; shift;;
    --)              shift; EXTRA_VCS="$*"; break;;
    *) echo "未知参数: $1"; exit 2;;
  esac
done

OUT=${FULL_ELAB_OUT:-$REPO/build_full_elab/$MODE-$TOP}
mkdir -p "$OUT" || exit 2
FLIST=$OUT/files.f

echo "=== 1/3 生成源清单（$MODE, top=$TOP） ==="
gopt=""
[ "$MODE" = golden ] && gopt=--golden-only
python3 scripts/full_elab_filelist.py $gopt $DIFFTEST --out "$FLIST" | tee "$OUT/filelist.log" || exit 2

echo "=== 2/3 VCS elaborate ==="
export VCS_ARCH_OVERRIDE=linux
# -full64 与 VCS_ARCH_OVERRIDE 成对；+define+SYNTHESIS 与 UT/FM 两侧一致
# （golden 的断言/随机初值都在 `ifndef SYNTHESIS 里）。
# -error=noMPD 等不加：本轮的目的是**看到全部真实错误**，不是让它过。
( cd "$OUT" && \
  vcs -full64 -sverilog -timescale=1ns/1ps \
      +define+SYNTHESIS \
      -top "$TOP" \
      -f "$FLIST" \
      -o simv_$TOP \
      -l vcs.log $EXTRA_VCS )
rc=$?
echo "VCS 退出码: $rc"

echo "=== 3/3 错误分类 ==="
python3 scripts/full_elab_classify.py "$OUT/vcs.log" | tee "$OUT/classify.txt"
echo "（完整日志: $OUT/vcs.log  清单: $FLIST）"
exit $rc
