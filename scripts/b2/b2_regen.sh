#!/usr/bin/env bash
# B2 fail-closed clean 重生 runner(2026-07, 二审修订)。从 G0 canonical 源码快照在**全新目录**
# 本 runner 产出标记为 B2_REGEN_ATTEMPT: 即便 rc=0 也仅证 1854 .sv/.v 可复现,
# 不自动晋升 G0 为 canonical(完整1860/工具闭包/DTS/A0元数据晋升门另行, 见 B2_REGEN_RULES.md)。
# 重生 golden,用 fail-closed git shim 复现 DUT 的 git 派生常量(NewCSR gitCommitSHA/gitDirty)与
# SimTop 头,再与 G0 逐字节比对。任何步骤失败/缺文件/多文件/hash 不同即**非零退出**并留档。
set -euo pipefail

Q=/home/eda/xs-env/G0-quarantine
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RB="${1:-/home/eda/xs-env/G0-rebuilt}"
SHIM="$SIGNOFF/scripts/b2/git-shim"
LOCK="$SIGNOFF/scripts/b2/TOOL_LOCK.tsv"
LOG="${B2_LOG:-/tmp/b2_regen.log}"
export GIT_SHIM_DATA="$Q/G0-source-provenance/git-shim-inputs"
exec > >(tee "$LOG") 2>&1
fail() { echo "B2-FAIL: $*"; exit 1; }

lock_val() { awk -F'\t' -v k="$1" '$1==k{print $2}' "$LOCK"; }

echo "== B2: 前置校验(工具+源码 hash, fail-closed) =="
[ -f "$Q/G0-source-canonical.tar.gz" ] || fail "缺 canonical 源码 tar"
[ -d "$GIT_SHIM_DATA" ] || fail "缺 git-shim-inputs"
# 三工具 hash 全校验
for tk in firtool mill; do
  tp=$(lock_val "${tk}_path"); th=$(lock_val "${tk}_sha256")
  [ -n "$tp" ] && [ -f "$tp" ] || fail "$tk 路径无效: $tp"
  [ -n "$th" ] || fail "$tk 锁定 hash 为空"
  [ "$(sha256sum "$tp" | awk '{print $1}')" = "$th" ] || fail "$tk hash 不匹配锁定值"
  echo "$tk hash OK ($tp)"
done
JDK=$(lock_val jdk); JH=$(lock_val jdk_java_sha256)
[ -x "$JDK/bin/java" ] || fail "JDK 无效: $JDK"
[ "$(sha256sum "$JDK/bin/java" | awk '{print $1}')" = "$JH" ] || fail "JDK java hash 不匹配"
echo "JDK hash OK ($JDK)"
# canonical tar hash
TARH=$(awk -F'\t' '$1=="source_canonical_tar_sha256"{print $2}' "$Q/G0_DESCRIPTOR.tsv")
[ "$(sha256sum "$Q/G0-source-canonical.tar.gz" | awk '{print $1}')" = "$TARH" ] || fail "canonical tar hash 不匹配"
echo "canonical tar hash OK"

echo "== B2: 全新目录干净解包(不复用 .git/out/build) =="
[ -e "$RB" ] && fail "RB=$RB 已存在(不覆盖, 先移走)"
mkdir -p "$RB" && cd "$RB"
tar xzf "$Q/G0-source-canonical.tar.gz"
bad=0
while IFS=$'\t' read -r f sz h; do
  [ "$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)" = "$h" ] || { echo "SRC-MISMATCH $f"; bad=$((bad+1)); }
done < "$Q/G0-source-canonical.manifest.tsv"
[ "$bad" -eq 0 ] || fail "源码解包 $bad 个不匹配"
echo "源码解包校验 OK (1639 文件)"

echo "== B2: 固定工具 + fail-closed git shim 重生(非 difftest) =="
export JAVA_HOME="$JDK"
MILL_DIR=$(dirname "$(lock_val mill_path)")
FT_DIR=$(dirname "$(lock_val firtool_path)")
# PATH: shim 最前(拦所有 git)→ 锁定 mill 目录 → 锁定 firtool → JDK。不含系统 git 优先。
export PATH="$SHIM:$MILL_DIR:$FT_DIR:$JAVA_HOME/bin:$PATH"
command -v mill >/dev/null || fail "mill 不在 PATH(锁定目录 $MILL_DIR)"
export NOOP_HOME="$RB" NEMU_HOME="$RB"
make sim-verilog CONFIG=KunminghuV2Config || fail "重生 make 失败"
[ -f build/rtl/SimTop.sv ] || fail "重生无 SimTop.sv"

echo "== B2: 逐字节比对 G0(缺/多/异 均 fail-closed) =="
cd build/rtl
CAND=/tmp/b2_candidate.manifest.tsv
: > "$CAND"
miss=0
while read -r f; do
  if [ -f "$f" ]; then
    printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)" >> "$CAND"
  else echo "MISSING $f"; miss=$((miss+1)); fi
done < "$Q/G0-formal-rtl.list"
LC_ALL=C sort "$CAND" -o "$CAND"
[ "$miss" -eq 0 ] || fail "candidate 缺 $miss 个 formal 文件"
# candidate 多出的 .sv/.v(G0 没有的)也是不一致
extra=$(comm -13 <(LC_ALL=C sort "$Q/G0-formal-rtl.list") <(find . -maxdepth 1 \( -name '*.sv' -o -name '*.v' \) | sed 's|^\./||' | LC_ALL=C sort) | wc -l)

# 分类比对: DUT(1853 非 SimTop, 含 NewCSR git 常量, 权威 formal golden) vs SimTop(harness)
# diff rc 严格区分: 0=相同 / 1=内容不同 / >1=diff 本身出错 → 直接 fail(不当成"无差异")。
set +e
diff <(grep -v '^SimTop\.sv' "$Q/G0-formal-rtl.manifest.tsv") \
     <(grep -v '^SimTop\.sv' "$CAND") > /tmp/b2_dut.diff
drc=$?
set -e
[ "$drc" -le 1 ] || fail "diff 比较出错 rc=$drc(非内容差异, 环境问题)"
ndut=$(grep -c "^[<>]" /tmp/b2_dut.diff 2>/dev/null || true); ndut=${ndut:-0}
simtop_g0=$(awk -F'\t' '$1=="SimTop.sv"{print $3}' "$Q/G0-formal-rtl.manifest.tsv")
simtop_rb=$(awk -F'\t' '$1=="SimTop.sv"{print $3}' "$CAND")

echo "-- 比对结果 --"
echo "DUT(1853, 含NewCSR) 差异行: $ndut ; candidate 多余 formal 文件: $extra"
echo "SimTop.sv: G0=$simtop_g0 rebuilt=$simtop_rb $([ "$simtop_g0" = "$simtop_rb" ] && echo 一致 || echo 不同)"
cp "$CAND" "$RB/b2_candidate.manifest.tsv"

if [ "$ndut" -eq 0 ] && [ "$extra" -eq 0 ]; then
  echo "RESULT: DUT-GOLDEN-REPRODUCED (1853 文件含 NewCSR git 常量 逐字节一致)"
  [ "$simtop_g0" = "$simtop_rb" ] && echo "RESULT: SimTop-ALSO-REPRODUCED(harness 完整复现)" \
    || { echo "RESULT: SimTop-DIFF(harness, 见 /tmp/b2_dut.diff 外单列)"; exit 2; }
  exit 0
else
  echo "RESULT: DUT-MISMATCH (dut=$ndut extra=$extra) —— 两份都保留, 见 /tmp/b2_dut.diff"
  exit 3
fi
