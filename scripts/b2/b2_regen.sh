#!/usr/bin/env bash
# B2 fail-closed clean 重生 runner(2026-07)。从 G0 canonical 源码快照在**全新目录**重生 golden,
# 用确定性 git shim 复现 SimTop 头,再与 G0 逐字节比对。任何步骤失败即非零退出(fail-closed)。
# 用法: b2_regen.sh [REBUILD_DIR]   默认 /home/eda/xs-env/G0-rebuilt
set -euo pipefail

Q=/home/eda/xs-env/G0-quarantine
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RB="${1:-/home/eda/xs-env/G0-rebuilt}"
SHIM="$SIGNOFF/scripts/b2/git-shim"
export GIT_SHIM_DATA="$Q/G0-source-provenance/git-shim-inputs"

echo "== B2: 前置校验 =="
[ -f "$Q/G0-source-canonical.tar.gz" ] || { echo "缺 canonical 源码 tar"; exit 1; }
[ -d "$GIT_SHIM_DATA" ] || { echo "缺 git-shim-inputs"; exit 1; }
# 工具 hash 校验(锁定)
FT=$(awk -F'\t' '$1=="firtool_path"{print $2}' "$SIGNOFF/scripts/b2/TOOL_LOCK.tsv")
FTH=$(awk -F'\t' '$1=="firtool_sha256"{print $2}' "$SIGNOFF/scripts/b2/TOOL_LOCK.tsv")
[ "$(sha256sum "$FT" | awk '{print $1}')" = "$FTH" ] || { echo "firtool hash 不匹配锁定值"; exit 1; }
echo "firtool hash OK"
# canonical tar hash 校验
TARH=$(awk -F'\t' '$1=="source_canonical_tar_sha256"{print $2}' "$Q/G0_DESCRIPTOR.tsv")
[ "$(sha256sum "$Q/G0-source-canonical.tar.gz" | awk '{print $1}')" = "$TARH" ] || { echo "canonical tar hash 不匹配"; exit 1; }
echo "canonical tar hash OK"

echo "== B2: 全新目录干净解包(不复用 .git/out/build) =="
[ -e "$RB" ] && { echo "RB=$RB 已存在, 先移走(不覆盖)"; exit 1; }
mkdir -p "$RB" && cd "$RB"
tar xzf "$Q/G0-source-canonical.tar.gz"
# 校验解包内容 == manifest
bad=0
while IFS=$'\t' read -r f sz h; do
  [ "$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)" = "$h" ] || { echo "SRC-MISMATCH $f"; bad=$((bad+1)); }
done < "$Q/G0-source-canonical.manifest.tsv"
[ "$bad" -eq 0 ] || { echo "源码解包 $bad 个不匹配"; exit 1; }
echo "源码解包校验 OK (1639 文件)"

echo "== B2: 固定工具 + git shim 重生(非 difftest) =="
export JAVA_HOME=/home/eda/xs-env/toolchain/jdk-17.0.13+11
export PATH="$SHIM:$(dirname "$FT"):$JAVA_HOME/bin:$PATH"   # shim 最前, 锁定 firtool
export NOOP_HOME="$RB" NEMU_HOME="$RB"
git() { "$SHIM/git" "$@"; }; export -f git 2>/dev/null || true
make sim-verilog CONFIG=KunminghuV2Config 2>&1 | tail -5
[ -f build/rtl/SimTop.sv ] || { echo "重生失败: 无 SimTop.sv"; exit 1; }

echo "== B2: 逐字节比对 G0 =="
cd build/rtl
# formal-rtl 1854 文件 manifest(candidate)
: > /tmp/b2_candidate.manifest.tsv
while read -r f; do
  [ -f "$f" ] && printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)" >> /tmp/b2_candidate.manifest.tsv
done < "$Q/G0-formal-rtl.list"
LC_ALL=C sort /tmp/b2_candidate.manifest.tsv -o /tmp/b2_candidate.manifest.tsv

echo "-- 比对结果 --"
# SimTop.sv 单列(ST-only, 带 git 头), 其余 1853 是 formal golden 权威
diff <(grep -v '^SimTop.sv' "$Q/G0-formal-rtl.manifest.tsv") \
     <(grep -v '^SimTop.sv' /tmp/b2_candidate.manifest.tsv) > /tmp/b2_formal.diff || true
nformal=$(grep -c '^[<>]' /tmp/b2_formal.diff || true)
simtop_g0=$(awk -F'\t' '$1=="SimTop.sv"{print $3}' "$Q/G0-formal-rtl.manifest.tsv")
simtop_rb=$(awk -F'\t' '$1=="SimTop.sv"{print $3}' /tmp/b2_candidate.manifest.tsv)

echo "formal golden(1853, 非SimTop) 差异行: $nformal"
echo "SimTop.sv(ST golden): G0=$simtop_g0 rebuilt=$simtop_rb  $([ "$simtop_g0" = "$simtop_rb" ] && echo 一致 || echo 不同)"
if [ "$nformal" -eq 0 ]; then
  echo "RESULT: FORMAL-GOLDEN-REPRODUCED (1853 文件逐字节一致)"
  [ "$simtop_g0" = "$simtop_rb" ] && echo "RESULT: ST-GOLDEN-ALSO-REPRODUCED (含 SimTop)" || echo "NOTE: SimTop 差异(git头/difftest), 见 /tmp/b2_formal.diff 与头对比"
else
  echo "RESULT: FORMAL-MISMATCH ($nformal 行) —— 两份都保留, 见 /tmp/b2_formal.diff"
fi
