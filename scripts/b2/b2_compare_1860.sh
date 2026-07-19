#!/usr/bin/env bash
# 完整 1860 输出比对(B2 canonical 晋升门之一)。规范化规则:
#  ① 内容: FIRRTL 中间产物 SimTop.fir 嵌入构建根源码路径(home/eda/xs-env/{xs-clean,G0-rebuilt}),
#     属构建位置依赖、非逻辑。比对前把两侧构建根统一为 token BUILDROOT。其余 1859 文件原始字节比。
#  ② mode: 文件权限是文件系统元数据非内容(G0 只读归档=444 / 新生成=664 / 源 manifest 记录=644)。
#     canonical 期望 mode = 0644(生成文件典型)。mode 偏差记为**advisory**, 不算 content mismatch。
# 用法: b2_compare_1860.sh <G0-full-output-dir> <candidate-build-rtl-dir>
set -euo pipefail
G0="${1:?G0 full-output 目录}"
CAND="${2:?candidate build/rtl 目录}"
BR='s#home/eda/xs-env/xs-clean#BUILDROOT#g; s#home/eda/xs-env/G0-rebuilt#BUILDROOT#g'
CANON_MODE=644

norm_hash() {  # 文件路径 → 规范化内容 hash(仅 .fir 做路径 canonicalize)
  case "$1" in
    *.fir) sed "$BR" "$1" | sha256sum | cut -d' ' -f1 ;;
    *)     sha256sum "$1" | cut -d' ' -f1 ;;
  esac
}

content_mismatch=0 mode_advisory=0 miss=0
while IFS= read -r f; do
  gf="$G0/$f"; cf="$CAND/$f"
  [ -f "$gf" ] || { echo "G0缺 $f"; continue; }
  [ -f "$cf" ] || { echo "MISSING $f"; miss=$((miss+1)); continue; }
  gh=$(norm_hash "$gf"); ch=$(norm_hash "$cf")
  if [ "$gh" != "$ch" ]; then echo "CONTENT-MISMATCH $f"; content_mismatch=$((content_mismatch+1)); fi
  cm=$(stat -c %a "$cf")
  [ "$cm" = "$CANON_MODE" ] || mode_advisory=$((mode_advisory+1))
done < <(cd "$G0" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)

# candidate 多余文件
extra=$(comm -13 <(cd "$G0" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) \
                 <(cd "$CAND" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) | wc -l)

echo "== 1860 比对(规范化后) =="
echo "content mismatch: $content_mismatch ; missing: $miss ; extra: $extra ; mode advisory(!=644): $mode_advisory"
if [ "$content_mismatch" -eq 0 ] && [ "$miss" -eq 0 ] && [ "$extra" -eq 0 ]; then
  echo "RESULT-1860: FULL-OUTPUT-REPRODUCED(规范化后内容逐字节一致; mode 差异属 advisory 元数据)"
  exit 0
else
  echo "RESULT-1860: MISMATCH(content=$content_mismatch miss=$miss extra=$extra)"
  exit 3
fi
