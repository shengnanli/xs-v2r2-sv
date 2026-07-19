#!/usr/bin/env bash
# 完整 1860 输出比对(canonical 晋升门, 2026-07 三审修订版, fail-closed)。
#
# 三审堵掉的假绿窗口:
#  ① 枚举源 = 冻结 G0-full-output.manifest.tsv(校验其 digest 绑定 descriptor + 行数 1860 +
#     G0 自身内容逐文件核验)——空目录/被改的 G0 不再能返回 REPRODUCED。
#  ② candidate 路径集必须与 manifest **完全一致**(缺/多任一即 fail)。
#  ③ SimTop.fir 只做 **candidate-root → G0-root 单向替换**, 且**断言替换次数恰为冻结值
#     6,759,209**(两侧路径数也各自断言)——不再全局双向 sed 掩盖硬件字符串常量。
#  ④ candidate root 从 candidate 目录参数派生(build/rtl 上两级, 去前导斜杠)——不硬编码,
#     换新重生目录不假红。
#  ⑤ 结果两级: 内容全过 = CONTENT_REPRODUCED(rc=0);内容 + mode 全 0644 + 规范化 manifest
#     核验过 = CANONICAL_ARTIFACT_REPRODUCED。mode 不再是无上限 advisory。
# 用法: b2_compare_1860.sh <G0-quarantine-dir> <candidate-build-rtl-dir>
set -euo pipefail
Q="${1:?G0 隔离区目录(含 G0-full-output/ 与 manifest)}"
CAND="${2:?candidate build/rtl 目录}"
G0="$Q/G0-full-output"
MF="$Q/G0-full-output.manifest.tsv"
DESC="$Q/G0_DESCRIPTOR.tsv"
fail() { echo "1860-FAIL: $*"; exit 1; }

# 冻结常量(绑定本 baseline)
EXPECT_COUNT=1860
EXPECT_FIR_PATHS=6759209
G0_ROOT="home/eda/xs-env/xs-clean"

echo "== ① 冻结 manifest 自校验 =="
[ -f "$MF" ] || fail "缺冻结 manifest $MF"
mfd=$(sha256sum "$MF" | cut -c1-16)
desc_d=$(awk -F'\t' '$1=="full_output_tree_digest"{print $2}' "$DESC")
[ "$mfd" = "$desc_d" ] || fail "manifest digest($mfd) != descriptor 绑定($desc_d)"
n=$(wc -l < "$MF")
[ "$n" -eq "$EXPECT_COUNT" ] || fail "manifest 行数 $n != $EXPECT_COUNT"
echo "manifest digest=$mfd 行数=$n OK"

echo "== ① G0 自身内容核验(防归档被改) =="
g0bad=0
while IFS=$'\t' read -r f ty mo sz h; do
  gh=$(sha256sum "$G0/$f" 2>/dev/null | cut -d' ' -f1) || true
  [ "$gh" = "$h" ] || { echo "G0-SELF-MISMATCH $f"; g0bad=$((g0bad+1)); }
done < "$MF"
[ "$g0bad" -eq 0 ] || fail "G0 归档自身 $g0bad 个文件与冻结 manifest 不符"
echo "G0 自身 $n 文件内容核验 OK"

echo "== ② candidate 路径集完全一致 =="
comm -3 <(awk -F'\t' '{print $1}' "$MF" | LC_ALL=C sort) \
        <(cd "$CAND" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) > /tmp/1860_pathdiff.txt || true
[ -s /tmp/1860_pathdiff.txt ] && { head /tmp/1860_pathdiff.txt; fail "candidate 路径集与 manifest 不一致($(wc -l < /tmp/1860_pathdiff.txt) 项)"; }
echo "路径集一致($n 文件)"

echo "== ③ 内容比对(SimTop.fir 单向替换 + 断言替换数) =="
# candidate root 从目录派生: <root>/build/rtl → root(去前导斜杠)
CAND_ABS=$(cd "$CAND" && pwd)
CAND_ROOT=$(dirname "$(dirname "$CAND_ABS")" | sed 's|^/||')
[ -n "$CAND_ROOT" ] || fail "无法派生 candidate root"
echo "candidate root: $CAND_ROOT"
mismatch=0
while IFS=$'\t' read -r f ty mo sz h; do
  cf="$CAND/$f"
  if [ "$f" = "SimTop.fir" ]; then
    # 两侧路径数断言
    gc=$(grep -o "$G0_ROOT" "$G0/$f" | wc -l)
    cc=$(grep -o "$CAND_ROOT" "$cf" | wc -l)
    [ "$gc" -eq "$EXPECT_FIR_PATHS" ] || fail "G0 .fir 路径数 $gc != 冻结值 $EXPECT_FIR_PATHS"
    [ "$cc" -eq "$EXPECT_FIR_PATHS" ] || fail "candidate .fir 路径数 $cc != 冻结值 $EXPECT_FIR_PATHS"
    # 单向替换 candidate-root → G0-root, после hash 必须等于冻结 manifest 的 G0 hash
    ch=$(sed "s#$CAND_ROOT#$G0_ROOT#g" "$cf" | sha256sum | cut -d' ' -f1)
  else
    ch=$(sha256sum "$cf" | cut -d' ' -f1)
  fi
  [ "$ch" = "$h" ] || { echo "CONTENT-MISMATCH $f"; mismatch=$((mismatch+1)); }
done < "$MF"
[ "$mismatch" -eq 0 ] || { echo "RESULT-1860: MISMATCH(content=$mismatch)"; exit 3; }
echo "内容全一致(1859 原始字节 + SimTop.fir 替换 $EXPECT_FIR_PATHS 处后一致)"

echo "== ⑤ mode 检查(canonical 级) =="
badmode=0
while IFS= read -r f; do
  m=$(stat -c %a "$CAND/$f")
  [ "$m" = "644" ] || badmode=$((badmode+1))
done < <(awk -F'\t' '{print $1}' "$MF")
if [ "$badmode" -eq 0 ]; then
  echo "RESULT-1860: CANONICAL_ARTIFACT_REPRODUCED(内容 + mode 0644 全过)"
  exit 0
else
  echo "RESULT-1860: CONTENT_REPRODUCED(内容全一致; $badmode 文件 mode!=0644, canonical 打包需 chmod 0644 后复验)"
  exit 0
fi
